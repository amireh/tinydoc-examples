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

class AuthenticationController < ApplicationController
  before_filter :require_user, only: [ :show, :destroy ]

  skip_filter :require_json_format, only: [
    :authorize_by_oauth,
    :oauth_failure
  ]

  def show
    expose current_user
  end

  def create
    unless current_user.present?
      user = authenticate(params[:email], params[:password])

      if user.nil?
        user = User.new
        user.errors.add :email, 'The email or password you entered were incorrect.'
        halt! 400, user.errors
      end

      authorize(user)
    end

    expose current_user
  end

  def destroy
    deauthorize
    no_content!
  end

  def authorize_by_oauth
    user_service = UserService.new

    svc = user_service.find_or_create_from_oauth(*[
      params[:provider],
      omniauth_hash,
      current_user
    ])

    if !svc.successful?
      logger.debug "Unable to create user from auth: #{svc.error.to_json}"

      redirect_oauth_failure('internal_error')
    elsif svc.output.nil? # i have no idea how this is happening
      logger.warn "User from auth creation seems to be empty!!!"

      redirect_oauth_failure('internal_error')
    else
      authorize(svc.output)
      redirect_oauth_success
    end
  end

  def oauth_failure
    redirect_oauth_failure(params[:message], params[:strategy])
  end

  private

  def redirect_oauth_success(provider=params[:provider])
    redirect_to "#{omniauth_origin}/oauth/success/#{provider}"
  end

  def redirect_oauth_failure(message, provider=params[:provider])
    redirect_to "#{omniauth_origin}/oauth/failure/#{provider}?message=#{message}"
  end

  def expose(user)
    render json: { id: user.id }
  end

  def omniauth_hash
    request.env['omniauth.auth']
  end

  def omniauth_origin
    Rails.application.config.oauth[:origin]
  end
end
