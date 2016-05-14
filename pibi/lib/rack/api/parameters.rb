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
  # Helpers for defining parameters an endpoint requires or accepts, their types,
  # and type validators.
  module Parameters
    include Rack::API::Logger

    # @property [Storage] api
    #   The API parameter storage for the current request context.
    attr_reader :api

    # Define a list of required arguments with no validators.
    #
    # @example
    # requires :name, :email
    # requires :name, :email, my_custom_params
    def requires(*args)
      hash = args.pop if args.last.is_a?(Hash)
      hash ||= params

      args.flatten.each do |arg|
        parameter arg, { required: true }, hash
      end
    end

    # @example
    # accepts :name, :email
    # accepts :name, :email, my_custom_params
    # accepts 'foo.bar'
    def accepts(*args)
      hash = args.pop if args.last.is_a?(Hash)
      hash ||= params

      args.flatten.each do |arg|
        parameter arg, { required: false }, hash
      end
    end

    def parameter(id, options = {}, hash = params)
      parameter_type = options[:required] ? :required : :optional
      parameter_validator = options[:validator]

      # resolve the hash to point to the parameter group if it's a nested
      # parameter
      if id.to_s.include?('.')
        path = id.to_s.split('.')
        path.pop
        hash = path.inject(hash) { |hash, key| hash.fetch(key, {}) }
      end

      parse_api_parameter(id, parameter_validator, parameter_type, hash, options)
    end

    # Get the value of the given API parameter, if any.

    private

    def parse_api_parameter(name, cnd, type, hash = params, options = {})
      name = name.to_s

      options[:validator] ||= cnd

      unless [ :required, :optional ].include?(type)
        raise ArgumentError, 'API Argument type must be either :required or :optional'
      end

      hash = (hash || {}).with_indifferent_access

      if type == :optional && options.has_key?(:default)
        hash[name] = options[:default] unless hash[name].present?
      end

      log "Parsing API parameter: #{name}"

      if hash.has_key?(name)
        Rack::API.trigger :parameter_parsed, name, hash, options

        api[type][name.to_sym] = hash[name]
        log "\tValue: #{hash[name]} #{hash[name].class}"
      elsif type == :required
        raise Error.new(400, "Missing required parameter :#{name}")
      end
    end

    def api
      @api ||= Storage.new
    end
  end
end