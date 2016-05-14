module Rack::API::ParameterValidators
  class StringValidator < Rack::API::ParameterValidator
    def validate(value, options)
      if value.present? && !value.is_a?(String)
        return "Expected value to be of type String, got #{value.class.name}"
      end

      if options[:format] && !value =~ options[:format]
        return "Value '#{value}' does not conform to the expected format."
      end
    end
  end
end