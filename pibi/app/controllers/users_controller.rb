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

# @API Users
#
# An interface for managing your Pibi user account.
#
# @model User
#   {
#     "id": "User",
#     "required": [ "id" ],
#     "properties": {
#       "id": {
#         "type": "integer",
#         "description": "teehee"
#       }
#     }
#   }
class UsersController < ApplicationController
  include Rack::API::Parameters
  include Rack::API::Resources

  before_filter :require_user, only: [ :show, :update, :destroy ]
  before_filter :prepare_service, only: [ :create, :update, :destroy ]

  # @API Signing up
  #
  # Create a new Pibi account.
  #
  # @argument [String] name
  #   Your real name.
  #
  # @throws "[USR:EMAIL_MISSING] We need your email address."
  # @throws "[USR:NAME_MISSING] We need your name."
  # @throws "[USR:PASSWORD_MISSING] You must provide a password."
  # @throws "[USR:PASSWORD_CONFIRMATION_MISSING] You must confirm the password."
  # @throws "[USR:PASSWORD_MISMATCH] Passwords must match."
  # @throws "[USR:PASSWORD_TOO_SHORT] Password is too short, it must be at least 7 characters long."
  # @throws "[USR:EMAIL_UNAVAILABLE] There's already an account registered to this email address."
  # @throws "[USR:EMAIL_INVALID] Doesn't look like an email address to me..."
  #
  def create
    requires :name, :email, :password, :password_confirmation

    with_service @service.create(api.parameters) do |user|
      expose authorize(user)
    end
  end

  def show
    cache("/channels/#{current_user.id}", current_user.access_tokens.find_or_create_by({
      udid: 'realtime'
    }).digest)

    expose current_user
  end

  # @API Updating your profile
  #
  # Update your profile and account data.
  #
  # @argument [String] name
  #   A new name to use.
  # @argument [String] email
  #   A new email address to identify your account.
  # @argument [Hash] preferences
  #   Update a single preference, or a bunch of preferences.
  # @argument [String] current_password
  #   Your current password. Required if you attempt to change it.
  # @argument [String] password
  #   Your new password.
  # @argument [String] password_confirmation
  #   Your new password, again.
  #
  # @throws "[USR:EMAIL_MISSING] We need your email address."
  #   Because you specified an empty email address.
  # @throws "[USR:PASSWORD_CONFIRMATION_MISSING] You must confirm the password."
  # @throws "[USR:PASSWORD_MISMATCH] Passwords must match."
  # @throws "[USR:PASSWORD_TOO_SHORT] Password is too short, it must be at least 7 characters long."
  # @throws "[USR:EMAIL_UNAVAILABLE] There's already an account registered to this email address."
  # @throws "[USR:EMAIL_INVALID] Doesn't look like an email address to me..."
  # @throws "[USR_BAD_PASSWORD] The current password you entered is wrong."
  #   You attempted to change your password without supplying the current one
  #   correctly.
  #
  # @returns [ User ]
  def update
    accepts [
      :name,
      :email,
      :preferences,
      :current_password,
      :password_change_token,
      :password,
      :password_confirmation
    ]

    api.consume(:password_change_token) do |token|
      current_user.token = token
    end

    with_service @service.update(current_user, api.parameters) do |user|
      if params[:headless]
        no_content!
      end

      expose user
    end
  end

  def change_password
    requires :reset_password_token, :password, :password_confirmation

    user = api.consume(:reset_password_token) do |token|
      unless user = User.find_by({ reset_password_token: token })
        halt! 404
      end

      user.token = token
      user
    end

    user.update_attributes(api.parameters)
    authorize(user)
    no_content!
  end

  # @API Destroying your account
  #
  # Unregister from Pibi.
  #
  # @warning
  #   This action is **irreversible**. All financial data attached to your
  #   Pibi account will be removed if you unregister.
  #
  # @no_content
  def destroy
    with_service @service.destroy(current_user) do |user|
      no_content!
    end
  end

  # @API Unlinking a 3rd-party account
  #
  # If you had linked your Pibi account to a 3rd-party one, like Facebook or
  # Google+, this endpoint allows you to remove that link.
  #
  # @warning
  #   You will no longer be able to log-in to Pibi using the provider you unlink
  #   from. However, your data will not be lost.
  #
  # @note
  #   If you only used a 3rd-party account to login to Pibi previously and had
  #   not changed your password, you are recommended to change your password
  #   before unlinking as you will no longer have access to your Pibi account
  #   unless you provide a password. Alternatively, you can issue a
  #   password-reset request.
  #
  # @argument [String] provider
  #   The provider you wish to unlink from.
  #   Accepted values: [ 'facebook', 'google_oauth2' ]
  #
  # @throws "[USR_LINK_UNAVAILABLE] That account is not linked to a %{provider} one."
  #   You're attempting to unlink from a provider you had not previously linked
  #   your account to.
  #
  # @no_content
  def unlink
    parameter :provider, type: :string, required: true

    provider = api.get :provider

    unless linked_user = current_user.links.find_by({ provider: provider })
      halt! 400, "[USR_LINK_UNAVAILABLE] That account is not linked to a #{provider} one."
    end

    unless linked_user.detach_from_master
      halt! 500, linked_user.errors
    end

    no_content!
  end

  # @API Resetting your password
  #
  # Visiting this endpoint will deliver an email with instructions to reset
  # the password for your Pibi account.
  #
  # Resetting a password is done by using a code specified in the email and
  # following the instructions on the website.
  #
  # @no_content
  def reset_password
    unless user = User.find_by({ email: params[:email] })
      halt! 404
    end

    user.generate_reset_password_token

    UserMailer.reset_password(user.id).deliver

    no_content!
  end

  def verify_email
    current_user.generate_email_verification_notice
    UserMailer.verify_email(current_user.id).deliver
    no_content!
  end

  private

  def prepare_service
    @service = UserService.new
  end
end