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

class RecurringSerializer < Rack::API::Serializer
  hypermedia context: :account, only: [ :attachments ], as: Recurring

  attributes *%w[
    id
    name
    amount
    flow_type
    currency
    active
    frequency
    every
    weekly_days
    monthly_days
    yearly_months
    yearly_day
    created_at
    updated_at
    committed_at
    commit_anchor
    next_billing_date
    account_id
    payment_method_id
    category_ids
  ].map(&:to_sym)

  stringify_attributes :account_id, :payment_method_id, :category_ids

  has_many :attachments, embed: :objects

  def category_ids
    object.categories.pluck(:id)
  end
end
