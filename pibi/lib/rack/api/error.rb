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

module Rack::API
  # An API error with a consistent format that can represent several error
  # messages along with model field error messages.
  #
  # Example output"
  #
  # {
  #   "status": "error",
  #   "messages": [
  #     "We need your name."
  #   ],
  #   "field_errors": {
  #     "name": "We need your name."
  #   }
  # }
  class Error < StandardError
    attr_accessor :status, :message
    attr_reader :messages, :field_errors

    # Create a new API error that can be rendered as JSON by the integrating
    # application.
    #
    # @param [Integer] status
    #   HTTP Status Code.
    #
    # @param [String|Any|NilClass] message
    #   Either a string error message, a JSON object, an AR error hash,
    #   or nothing, in which case we'll use the HTTP verb message, ie: 200 -> OK,
    #   400 -> Bad Request.
    #
    def initialize(status, message = nil)
      self.status = status
      self.message = message

      unless self.message.present?
        status_message = Rack::Utils::HTTP_STATUS_CODES[status]
        self.message = "[#{status_message.gsub(' ', '_').underscore.upcase}] #{status_message}"
      end

      @messages = []
      @field_errors = {}

      parse(self.message)

      super(self.message)
    end

    def as_json(*args)
      {
        status: 'error',
        messages: @messages,
        field_errors: @field_errors
      }
    end

    private

    def parse(message)
      @messages = case
      when message.is_a?(String)
        [ message ]
      when message.is_a?(Array)
        message
      when message.is_a?(Hash), message.is_a?(ActiveModel::Errors)
        @field_errors = message.to_hash
        @field_errors.map { |k,v| v }.flatten
      else
        [ message.to_s ]
      end
    end
  end
end