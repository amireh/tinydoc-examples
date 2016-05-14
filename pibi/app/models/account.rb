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

# require File.join(Rails.root, '/app/models/income')

class Account < ActiveRecord::Base
  include Journallable

  A_SAVINGS = 'savings'

  default_scope { order('label ASC') }

  acts_as_journallable :scope_key => "user"

  belongs_to :user
  has_many :transactions, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :recurrings, dependent: :destroy
  has_many :budgets, dependent: :destroy

  validates_presence_of :label,
    message: '[ACC_MISSING_LABEL] You must provide a label for the account.'
  validates_uniqueness_of :label, :scope => [ :user_id ],
    message: '[ACC_LABEL_TAKEN] You already have such an account.'

  validates_inclusion_of :currency, {
    in: proc { Currency.all.map(&:name) },
    message: "Unrecognized currency."
  }

  before_update :apply_currency_differences, if: :currency_changed?

  protected

  def apply_currency_differences
    old_iso = self.currency_was
    new_iso = self.currency

    self.balance = Currency[new_iso].from(old_iso, self.balance)
  end
end
