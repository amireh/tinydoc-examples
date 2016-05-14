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

class ApplicationController < ActionController::Base
  include Rack::API::Pagination

  respond_to :json

  before_filter :require_json_format
  before_filter :accept_authenticity
  after_filter :broadcast_journal_playback

  rescue_from StandardError, with: :render_internal_error
  rescue_from ActionDispatch::ParamsParser::ParseError, with: :render_parser_error
  rescue_from Rack::API::Error, with: :render_error

  # Catch 404s
  def rogue_route
    halt! 404
  end

  protected

  if Rails.env.production?
    def default_url_options(options={})
      options.merge({ protocol: "https" })
    end
  end

  def current_user
    @current_user ||= begin
      if session[:id].nil?
        return nil
      end

      begin
        User.find(session[:id])
      rescue ActiveRecord::RecordNotFound => e
        deauthorize
        nil
      end
    end
  end

  # Halt the execution of the current controller handler and respond with
  # the specified HTTP Status Code and a given message.
  #
  # See Rack::API::Error#initialize for the arguments.
  def halt!(status, message = nil)
    raise Rack::API::Error.new(status, message)
  end

  # Respond with a 204 No Content, useful for DELETE operations, or ones that
  # request no-content (such as requests with the [:headless] parameter).
  #
  # @warning
  # Calling this method halts the execution.
  def no_content!
    broadcast_journal_playback
    halt! 204
  end

  def render_internal_error(error)
    NewRelic::Agent.agent.error_collector.notice_error(error, env)

    if Rails.env.test?
      raise error
    elsif Rails.env.development?
      puts error.message
      puts error.backtrace
    end

    render_error Rack::API::Error.new(500)
  end

  def render_not_found_error(error)
    render_error Rack::API::Error.new(404)
  end

  def render_parser_error(error)
    render_error Rack::API::Error.new(400, "Malformed JSON.")
  end

  def render_error(error)
    response.status = error.status

    # Render a "No Content" response
    if error.status == 204
      return head :no_content
    end

    render json: error
  end

  def expose(object, options={})
    object.respond_to?(:to_ary) ?
      expose_collection(object, options) :
      expose_object(object, options)
  end

  def expose_collection(collection, options={})
    paginated_set = if options[:paginate] != false
      api_paginate(collection)
    else
      collection
    end

    expose_object(paginated_set, options)
  end

  def expose_object(object, options={})
    includes = if params[:include]
      includes = params[:include].split(',').map(&:strip).map(&:to_sym)
    else
      []
    end

    includes = ['*'] if includes == [:all]

    render options.merge({
      json: object,
      root: false,
      includes: true,
      # meta: {
      #   primaryCollection: self.class.name.sub('Controller', '').underscore
      # },
      scope: {
        current_user: current_user,
        controller: self,
        includes: includes,
        params: params,
        options: options
      }
    })
  end

  def require_json_format
    accept = request.headers['HTTP_ACCEPT'] || ''

    unless ['*', '*/*' ].include?(accept) || accept =~ /json/
      render :text => 'Not Acceptable', status: 406
    end
  end

  # Authenticate through HTTP Basic Auth or X-Access-Token if passed.
  def accept_authenticity
    if current_user.present?
      return true
    end

    authenticate_with_http_basic do |email, password|
      if user = authenticate(email, password)
        authorize(user)
      end
    end

    if digest = request.headers['HTTP_X_ACCESS_TOKEN']
      if access_token = AccessToken.find_by({ digest: digest })
        authorize(access_token.user)
      end
    end
  end

  # Authenticate the client, and require that the client must be properly
  # authenticated before proceeding.
  #
  # `current_user` will be available if this passes.
  #
  # @throws
  def require_user
    accept_authenticity

    unless current_user.present?
      halt! 401
    end

    if params[:user_id].present?
      if params[:user_id].to_s == 'self'
        @user = current_user
      else
        with :user
      end
    end
  end

  def authenticate(email, password)
    User.find_by({
      provider: 'pibi',
      email: email,
      password: User.encrypt(password)
    })
  end

  # Create a new client session.
  #
  # This is currently stored in Redis via Moneta.
  def authorize(user)
    deauthorize

    # mark the master account as the current user
    user = user.link if user.link

    session[:id] = user.id

    current_user
  end

  # Destroy the client session.
  def deauthorize
    session[:id] = nil
    reset_session
  end

  def with_service(svc, &block)
    unless svc.successful?
      halt! 400, svc.error
    end

    yield(svc.output)
  end

  def cache(k, v)
    Rails.application.config.redis_instance.set(k, v)
  end

  def playback(opcode, resource)
    @journal_output ||= Journal::Output.new
    @journal_output.mark_processed(opcode, {
      id: "#{resource.id}"
    }, resource.journal_path)
  end

  def broadcast_journal_playback
    if current_user && @journal_output
      Pibi::Messenger.publish(current_user.id, ClientMessage::JournalPlayback, @journal_output, {
        client_id: current_client_id
      })
    end
  end

  def current_client_id
    request.headers['HTTP_X_PIBI_CLIENT']
  end
end
