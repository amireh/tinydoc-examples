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

class UserSerializer < Rack::API::Serializer
  attributes *%w[
    id
    name
    email
    preferences
    linked_providers
    email_verified
    realtime_channel
  ].map(&:to_sym)

  hypermedia only: %w[
    accounts
    categories
    payment_methods
    journals
    budgets
  ], links: {
    access_tokens: -> {
      user_access_tokens_url
    },
    reset_password: -> {
      user_reset_password_url({ email: object.email })
    },
    verify_email: -> {
      user_verify_email_url(object)
    },
    export_transactions: -> {
      export_transactions_url
    },
    cross_account_transactions: -> {
      cross_account_transactions_url
    },
    upcoming_recurrings: -> {
      upcoming_recurrings_url
    },
    favorite_budgets: -> {
      user_favorite_budgets_url(object)
    },
    unlink_provider: -> {
      user_unlink_provider_url(object)
    }
  }

  has_many :access_tokens, embed: :objects
  has_one :privacy_policy, embed: :objects

  def email_verified
    !!object.email_verified
  end

  def linked_providers
    object.links.map(&:provider)
  end

  def realtime_channel
    "/channels/#{object.id}"
  end
end
