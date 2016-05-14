# Pibi API - The official JSON API for Pibi, the personal financing software.
# Copyright (C) 2014 Ahmad Amireh <ahmad@algollabs.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Budgets help keep track of amounts of spendings, savings, or frequency of
# transactions.
#
# Budgets need to answer questions like these:
#
#   - did i put at least A, or A% of my income into the account X?
#   - did i spend more than A, or A% this month using payment method X?
#   - did i spend more than A, or A% of my income on X, Y, or Z?
#   - did i spend money more than A times on X, Y, or Z this month?
#
class Budget < ActiveRecord::Base
  extend Enumerize

  default_scope { order('name ASC') }

  belongs_to :user
  belongs_to :payment_method
  belongs_to :account

  has_and_belongs_to_many :categories, validate: false
  has_many :category_transactions, {
    class_name: 'Transaction',
    through: :categories,
    source: :transactions,
    validate: false
  }

  scope :overdue, -> { all { |budget| budget.due_for_reset? } }
  scope :favorite, -> { where(favorite: true) }

  validates_presence_of :name,
    message: '[BDGT:MISSING_NAME] You must name the budget.'

  validates_presence_of :quantifier,
    message: '[BDGT:MISSING_QUANTIFIER] You must specify the quantifier.'

  validates_presence_of :goal,
    message: '[BDGT:MISSING_GOAL] You must specify the budget goal.'

  validates_presence_of :interval,
    message: '[BDGT:MISSING_INTERVAL] You must specify the interval.'

  validates_numericality_of :quantifier, {
    greater_than: 0,
    message: '[BDGT:BAD_QUANTIFIER] Budget quantifier must be greater than 0.'
  }

  validate :ensure_valid_context
  validate :ensure_valid_quantifier

  enumerize :goal, in: {
    # Examples:
    #
    # - Make a deposit of at least 1,000 in Savings account every week
    # - Make a deposit of at least 10% of monthly income in Savings account
    #
    # Applies to accounts only.
    # Applies to incomes only.
    savings_control: 1,

    # Examples:
    #
    # - Don't spend more than 1,000 on Clothes and Gear
    # - Don't spend more than 1,000 using Credit Card
    # - Don't spend more than 25% on Food
    # - Don't spend more than 60 JOD on Candy
    #
    # Applies to categories and payment methods.
    # Applies to expenses and incomes.
    spendings_control: 2,

    # Examples:
    #
    # - Don't spend money on Shopping more than once every 2 weeks
    # - Don't spend money on Dinner, or Luxury more than once every 3 days
    #
    # Applies to categories and payment methods.
    # Applies to expenses only.
    # Can not be a ratio.
    frequency_control: 3
  }, scope: true

  enumerize :interval, in: { days: 1, weeks: 2, months: 3 }, scope: true

  before_destroy { categories.clear }

  # Ratio is ignored in case of frequency_control goals, in which case only
  # the quantifier is used to calculate the tally.
  def ratio?
    !!self.is_ratio
  end

  # This is funky, but it works. It could be improved to take the goal into
  # account.
  def context_type
    if self.account.present?
      # then we're in savings_control
      :account
    elsif self.payment_method.present?
      # then we're in either spendings or frequency control
      :payment_method
    elsif self.categories.any?
      # then we're also in either spendings or frequency control
      :categories
    else
      # ??
      :none
    end
  end

  def context
    case context_type
    when :account then self.account
    when :payment_method then self.payment_method
    when :categories then self.categories
    end
  end

  def transactions
    if context_type.to_s == 'categories'
      category_transactions
    else
      context.transactions
    end
  end

  # The time at which the budget started calculating its current goal.
  def started_at
    (self.resetted_at || self.created_at).beginning_of_day
  end

  # Calculates the time at which the budget should reset.
  #
  # @param [DateTime] anchor
  #   The time anchor from which the next reset should be calculated.
  #
  # @return [DateTime]
  def next_reset(anchor = started_at)
    self.every.send(self.interval).from_now(anchor).beginning_of_day
  end

  # The current period of time the budget covers.
  #
  # This is nice to use with the Transaction#occurred_in scope. For example,
  # doing the following will give you all the transactions covered by this
  # budget:
  #
  #     budget = Budget.first
  #     budget.transactions.occurred_in(*budget.period)
  #
  # @return [Array<Time>]
  def period
    [started_at, next_reset]
  end

  # Has the budget current period run out?
  def due_for_reset?
    next_reset <= Time.zone.now
  end

  # Please don't call this unless due_for_reset? returns true...
  def reset!
    update({ resetted_at: Time.zone.now.beginning_of_day })
  end

  private

  def ensure_valid_context
    unless context.present?
      errors.add :base,
        '[BDGT:MISSING_CONTEXT] Missing budget context (either an account, a' +
        ' category, or a payment method).'
    end
  end

  def ensure_valid_quantifier
    if self.is_ratio?
      if quantifier.to_i > 100 || quantifier.to_i < 0
        errors.add :quantifier, '[BDGT_BAD_QUANTIFIER] Amount must be between 0 and 100%.'
      end
    end
  end
end
