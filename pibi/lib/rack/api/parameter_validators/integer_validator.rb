module Rack::API::ParameterValidators
  class IntegerValidator < Rack::API::ParameterValidator
    def validate(value, options)
      if options[:allow_nil] && value.nil?
        return false
      end

      Integer(value)
    rescue
      "Not a valid integer."
    end

    def coerce(value, options)
      value ? Integer(value) : nil
    end
  end
end