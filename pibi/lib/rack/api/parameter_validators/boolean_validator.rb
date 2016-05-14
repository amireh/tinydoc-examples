module Rack::API::ParameterValidators
  class BooleanValidator < Rack::API::ParameterValidator
    def validate(value, options)
    end

    def coerce(value, options)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end
  end
end