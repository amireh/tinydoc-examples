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

class AccountSerializer < Rack::API::Serializer
  attributes :id, :label, :currency, :balance, :created_at, :updated_at,
    :href, :links, :account_type

  optional_attributes :created_at, :updated_at

  def href
    user_account_url(object.user_id, object.id)
  end

  def links
    {}.tap do |hsh|
      hsh[:user] = user_url(object.user_id) unless compact?
      hsh[:transactions] = account_transactions_url(object.id)
      hsh[:recurrings] = account_recurrings_url(object.id)
      hsh[:transfers] = create_account_transfer_url()
    end
  end
end
