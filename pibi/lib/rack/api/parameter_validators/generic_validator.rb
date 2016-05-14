module Rack::API::ParameterValidators
  class GenericValidator < Rack::API::ParameterValidator
    def validate(value, options)
      if options[:in] && value.present?
        items = value.is_a?(Array) ? value : [ value ]

        items.each do |item|
          unless options[:in].include?(item)
            return "Value must be one of #{options[:in]}"
          end
        end

        nil
      end
    end
  end
end