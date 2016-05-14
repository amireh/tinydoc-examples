module Rack::API::ParameterValidators
  # Supported dates:
  #
  #   - Epoch timestamps
  #   - JSON timezone-aware dates: 2014-02-18T00:00:00Z
  #   - String with the format "MM/DD/YYYY"
  #   - Time or DateTime objects
  #
  class DateValidator < Rack::API::ParameterValidator
    def validate(value, options)
      unless date = coerce(value, options)
        "#{value} is not a valid date."
      end
    end

    def coerce(value, options=nil)
      date = if value.is_a?(String)
        if value =~ /\d{2}\/\d{2}\/\d{4}/
          from_string(value)
        elsif value =~ /^\d+$/
          from_epoch(value)
        else
          from_json_string(value)
        end
      elsif %w[Time DateTime].include?(value.class.name.to_s)
        value
      elsif value.is_a?(Integer)
        from_epoch(value)
      end

      if date
        # if options[:zero]
        #   date = Time.utc(date.year, date.month, date.day)
        # end

        date.utc
      end
    end

    private

    # JSON timezone strings
    def from_json_string(value)
      Time.zone.parse(value).in_time_zone(Time.zone) rescue nil
    end

    # MM/DD/YYYY strings
    def from_string(value)
      Time.strptime(value, '%m/%d/%Y').in_time_zone(Time.zone) rescue nil
    end

    # Epoch timestamp
    def from_epoch(value)
      Time.at(value.to_i)
    end
  end
end