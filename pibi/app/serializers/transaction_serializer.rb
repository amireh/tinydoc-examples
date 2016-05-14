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

class TransactionSerializer < Rack::API::Serializer
  hypermedia context: :account, only: [ :attachments ], as: Transaction

  attributes *%w[
    id
    type
    amount
    note
    currency
    currency_rate
    occurred_on
    fudge_occurrence
    account_id
    payment_method_id
    category_ids
    splits
    committed
    transfer
  ].map(&:to_sym)

  stringify_attributes :account_id, :payment_method_id, :category_ids

  has_many :attachments, embed: :objects

  def type
    object.type.to_s.underscore
  end

  def fudge_occurrence
    object.occurred_on && object.occurred_on <= FUDGE_DATES_PRIOR_TO
  end

  def category_ids
    object.categories.map(&:id)
  end

  def transfer
    spouse = object.transfer_spouse

    {
      type: object.inbound_transfer.present? ? 'inbound' : 'outbound',
      account_id: "#{spouse.account.id}",
      account_url: user_account_url(spouse.account.user, spouse.account),
      transaction_id: "#{spouse.id}",
      transaction_url: account_transaction_url(spouse.account, spouse)
    }
  end

  def include_transfer?
    object.transfer?
  end
end
