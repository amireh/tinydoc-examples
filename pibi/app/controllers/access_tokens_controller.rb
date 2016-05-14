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

# @API AccessTokens
#
# Access tokens provide an alternative mechanism for authenticating with the Pibi
# API to using HTTP Basic Authorization.
#
# An access token can be generated for a given *UDID*, and it can be revoked
# at any time. The UDID may map to a smartphone's UDID if your client is a
# smartphone app, but in all cases, it should be unique *per user scope*.
#
# Please refer to the [authentication guide](file.authentication.html) for more on
# authenticating using Access Tokens.
#
# @object AccessToken
#  {
#    // The UDID this access token was registered for.
#    "udid": "helloWorld",
#
#    // This is the digest that you use to authenticate.
#    //
#    // This MUST be kept secret!
#    "digest": "5878a193de1f6a584b58a32e10be8edc0dc18499"
#  }
class AccessTokensController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user
  before_filter :require_access_token, only: [ :show, :destroy ]

  # @API Retrieving all access tokens
  #
  # @returns {AccessToken}
  def index
    expose current_user.access_tokens
  end

  # @API Creating access tokens
  #
  # @argument [String] udid
  #   Unique identifier for the access token.
  #
  # @returns {AccessToken}
  def create
    parameter :udid, type: :string, required: true

    access_token = current_user.access_tokens.first_or_create({
      udid: api.get(:udid)
    })

    authorize(access_token.user)

    expose access_token
  end

  # @API Retrieving an access token
  #
  # @returns {AccessToken}
  def show
    expose @access_token
  end

  # @API Revoking access tokens
  #
  # @no_content
  def destroy
    @access_token.destroy

    no_content!
  end

  private

  def require_access_token
    unless @access_token = current_user.access_tokens.find_by({ udid: params[:udid] })
      halt! 404
    end
  end
end