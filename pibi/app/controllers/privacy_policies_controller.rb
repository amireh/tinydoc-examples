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
class PrivacyPoliciesController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user

  def show
    expose current_user.privacy_policy
  end

  # @API Update your privacy policy
  #
  # Create a brand new account.
  #
  # @argument [Boolean] wants_newsletter
  #   Whether you would like to receive Pibi's monthly newsletter which includes
  #   the latest updates and changes.
  #
  # @argument [Boolean] trackable
  #   Whether you allow Pibi to track analytical metrics while you use the
  #   application. Tracking these metrics is completely anonymous (e.g, your
  #   data is never exposed) and helps us optimize your experience.
  #
  # @argument [Boolean] mobile_trackable
  #   Whether we can track analytical metrics when you are using Pibi from
  #   a mobile phone. You can disable this to save bandwidth.
  #
  # @argument [String[]] metric_blacklist
  #   A list of analytical metrics you want to dis-allow us from tracking, in
  #   case you don't want to opt-out of analytics tracking entirely.
  #
  # @returns PrivacyPolicy
  def update
    parameter :wants_newsletter, type: :boolean
    parameter :trackable, type: :boolean
    parameter :mobile_trackable, type: :boolean
    parameter :metric_blacklist, type: :array, allow_nil: true

    policy = current_user.privacy_policy
    accepted_params = api.parameters

    api.consume(:metric_blacklist) do |value|
      metric_blacklist = Array(value).compact.uniq

      if metric_blacklist.any?
        accepted_params[:metric_blacklist] = metric_blacklist & PrivacyPolicy::METRICS
      end
    end

    policy.update_attributes!(accepted_params)

    expose policy
  end

  def all_metrics
    render json: PrivacyPolicy::METRICS, root: false
  end
end