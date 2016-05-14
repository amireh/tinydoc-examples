module Rack::API::ParameterValidators
  class ArrayValidator < Rack::API::ParameterValidator
    def validate(value, options)
      if !value.is_a?(Array)
        unless Rails.env.production?
          puts "[DEBUG]: #{value} #{value.class.name}"
        end
        "#{options[:_key] || 'Value'} must be an array."
      end
    end

    def coerce(value, options)
      Array(value)
    end
  end
end