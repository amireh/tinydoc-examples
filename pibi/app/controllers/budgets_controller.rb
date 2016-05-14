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

##
# @API Budgets
#
# Budgets help keep track of amounts of spendings, savings, or frequency of
# transactions. They're useful to help answer questions like these:
#
# - Did I spend more than 3,000 this month using Credit Card?
#   (_helps with credit card ceilings or thresholds_)
#
# - Did I spend more than 25% of my income on Shopping this month?
#   (_helps keep one from spending too much on shopping)
#
# - Did I put at least 2,500 of my income into the Savings account the last 3 months?
#   (_helps with savings_)
#
# ## Budget Goals
#
# ### Savings Control
#
# Examples:
#
#   - Make a deposit of at least 1,000 in Savings account
#   - Make a deposit of at least 10% of monthly income in Savings account
#
# Applies to accounts.
#
# ### Spendings Control
#
#   - Don't spend more than 1,000 on Clothes and Gear
#   - Don't spend more than 1,000 using Credit Card
#   - Don't spend more than 25% USD on Food
#   - Don't spend more than 60 USD on Smokes
#   - Spend at least 250 every month on Baby.
#
# Applies to categories and payment methods.
#
# ### Frequency Control
#
# Examples:
#
#   - Don't spend money on Shopping more than once every 2 weeks
#   - Don't spend money on Dinner, or Luxury more than once every 3 days
#
# Applies to categories and payment methods.
#
# @object Budget
#  {
#
#  }
class BudgetsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user, except: [ :transactions ]
  before_filter :require_budget, except: [ :index, :create, :transactions, :favorites ]
  before_filter :prepare_service, only: [ :create, :update, :destroy ]

  def index
    expose current_user.budgets.includes(:user, :account, :payment_method, :categories, :category_transactions)
  end

  def favorites
    expose current_user.budgets.favorite
  end

  # @API Create a new budget.
  #
  # @argument [String] name
  #   A unique name for the budget that describes why you're setting it.
  #   A good example would be "Saving for a new car".
  #
  # @argument [String] interval
  #   The interval of time in which the budget should track its goal completion.
  #
  #   Accepted values: [ 'days', 'weeks', 'months' ]
  #
  # @argument [String] goal
  #   The goal of the budget.
  #
  #   Accepted values: [ 'savings_control', 'spendings_control', 'frequency_control']
  #
  # @argument [Integer] quantifier
  #   This is the number that defines the budget's completion. This can either
  #   be a scalar number (like 2500 USDs), or a ratio (10% of all income) if
  #   the `is_ratio` parameter is set to `true`.
  #
  # @argument [Boolean] is_ratio (optional)
  #   If you set this to true, the `quantifier` will be interpreted as a ratio
  #   quantifier and needs to range from 1 to 100%.
  #
  #   Defaults to false.
  #
  # @argument [String] currency (optional)
  #   The currency in which the budget's goal should be calculated.
  #
  # @argument [Integer] every (optional)
  #   Interval quantifier, like "every 3 months", or "every 10 days".
  #
  # @returns Budget
  def create
    parameter_group(true)

    with_service @service.create(current_user, api.parameters) do |budget|
      expose budget
    end
  end

  def update
    parameter_group

    with_service @service.update(@budget, api.parameters) do |budget|
      expose budget
    end
  end

  def show
    expose @budget, { include_ids: true }
  end

  def transactions
    with :budget
    expose @budget.transactions
  end

  def destroy
    with_service @service.destroy(@budget) do |rc|
      no_content!
    end
  end

  private

  def prepare_service
    @service = BudgetService.new
  end

  def require_budget
    with :user, :budget
  end

  def parameter_group(strict=false)
    parameter :name, type: :string
    parameter :currency, type: :string
    parameter :quantifier, type: :integer
    parameter :is_ratio, type: :boolean
    parameter :goal, type: :string
    parameter :every, type: :integer
    parameter :interval, type: :string
    parameter :account_id
    parameter :payment_method_id
    parameter :category_ids, type: :array
    parameter :icon, type: :string
    parameter :favorite, type: :boolean
  end
end