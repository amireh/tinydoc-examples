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

class BudgetSerializer < Rack::API::Serializer
  embed :ids
  hypermedia context: :user, only: [ :user, :transactions ]

  attributes *%w[
    id
    name
    context_type
    currency
    goal
    favorite
    resetted_at
    created_at
    every
    interval
    quantifier
    is_ratio
    icon
    next_reset
    completion
    total
    overflow
    underflow
  ].map(&:to_sym)

  has_one :payment_method, :account
  has_many :categories
  has_many :transactions, embed: :ids

  [ :completion, :total, :overflow, :underflow ].each do |calculation_prop|
    define_method(calculation_prop) do
      progress[calculation_prop].to_f.round(2)
    end

    define_method(:"include_#{calculation_prop}?") do
      has_context?
    end
  end

  def include_transactions?
    scope && scope[:options] && scope[:options][:include_ids]
  end

  def context_type
    object.context_type
  end

  private

  def progress
    @progress ||= BudgetCalculator.new(object).calculate
  end

  def has_context?
    @has_context ||= object.context.present?
  end
end
