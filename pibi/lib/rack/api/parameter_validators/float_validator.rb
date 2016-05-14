module Rack::API::ParameterValidators
  class FloatValidator < Rack::API::ParameterValidator
    def validate(value, options)
      Float(value)
    rescue
      "Not a valid float."
    end

    def coerce(value, options)
      Float(value)
    end
  end
end