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
# @API Accounts
#
# An interface for managing a user's financial accounts.
#
# @url /users/:user_id/accounts
# @topic Account
#
# @object Account
#  {
#    // The unique id of the account.
#    "id": 1,
#
#    // A unique label for the account.
#    "label": "Personal",
#
#    // A currency ISO code to specify the currency of the account, which will
#    // affect its balance.
#    "currency": "USD",
#
#    // The current standing balance of the account in its specified currency.
#    // This is calculated from the balances of the transactions the account
#    // contains.
#    "balance": 2.5,
#
#    // Path to this account.
#    "href": "/users/2/accounts/1",
#
#    "links": {
#      // Path to the user this account belongs to.
#      "user": "/users/2"
#    },
#
#    // ID of the user this account belongs to.
#    "user_id": 2
#  }
class AccountsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user
  before_filter :require_account, except: [ :index, :create ]
  before_filter :prepare_service, except: [ :index, :show ]

  def index
    expose current_user.accounts
  end

  # @API Create a new account.
  #
  # Create a brand new account.
  #
  # @argument [String] label
  #   A unique label for the account.
  #
  # @argument [String] currency
  #   The currency of the account which will affect the account's balance.
  #
  # @return [ Account ]
  def create
    requires :label, :currency
    parameter :balance, type: :float, coerce: true

    with_service @service.create(current_user, api.parameters) do |account|
      expose account
    end
  end

  def show
    expose @account
  end

  # @API Update an account.
  #
  # Create a brand new account.
  #
  # @url [PUT] /users/:user_id/accounts/:account_id
  #
  # @argument [String] label (optional)
  #   A unique label for the account.
  # @argument [String] currency
  #   The currency of the account which will affect the account's balance.
  #
  def update
    accepts :label, :currency

    with_service @service.update(@account, api.parameters) do |account|
      expose account
    end
  end

  def destroy
    with_service @service.destroy(@account) do |rc|
      no_content!
    end
  end

  private

  def prepare_service
    @service = AccountService.new
  end

  def require_account
    with :user, :account
  end
end