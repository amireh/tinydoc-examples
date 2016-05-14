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
  class ParameterValidator
    extend Rack::API::Logger

    # Validate a given parameter value.
    #
    # @param [Any] value
    #   The parameter value to validate.
    #
    # @param [Hash] options
    #   Custom validator options defined by the user.
    #
    # @return [String] Error message if the parameter value is invalid.
    # @return [Any] Any other value means the parameter is valid.
    def validate(value, options = {})
      raise NotImplementedError
    end

    class << self
      def install(api)
        api.on :parameter_parsed, &method(:run_validators!)
      end

      private

      def run_validators!(key, hash, definition)
        value = hash[key]
        validators = []
        definition[:coerce] = true unless definition.has_key?(:coerce)
        definition[:_key] = key

        validators << Rack::API::ParameterValidators::GenericValidator.new
        validators << validator_for(definition)

        log "Running #{validators.length} validators for value of type #{definition[:type]}"

        # Run the type validations
        validators.compact.each do |validator|
          # Custom proc validator?
          if validator.respond_to?(:call)
            error = validator.call(value)
          # Strongly-defined ParameterValidator objects
          elsif validator.respond_to?(:validate)
            error = validator.validate(value, definition)
          # ?
          else
            raise "" +
              "Invalid ParameterValidator #{validator.class}," +
              " must respond to #call or #validate"
          end

          if error.is_a?(String)
            return reject(key, error)
          end

          # coerce the value, if viable
          if validator.respond_to?(:coerce) && definition[:coerce]
            hash[:"#{key}_original"] = original = value
            hash[key] = validator.coerce(value, definition)
            log "Coerced value: #{hash[key]} (#{original} [#{key}_original])"
          end
        end
      end

      def reject(field, cause)
        raise Error.new(400, { "#{field}" => [ cause ] })
      end

      def validator_for(definition)
        if definition[:validator].respond_to?(:call)
          return definition[:validator]
        end

        typename = if definition[:validator].is_a?(Symbol)
          definition[:validator]
        else
          definition[:type].try(:to_sym)
        end

        validator = if typename
          "Rack::API::ParameterValidators::#{typename.to_s.classify}Validator".constantize
        end

        validator.new if validator.present?
      end
    end
  end
end