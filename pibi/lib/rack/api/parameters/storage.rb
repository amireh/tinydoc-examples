module Rack::API::Parameters
  class Storage
    attr_reader :required, :optional

    def initialize
      reset
    end

    # Allows access to the @required and @optional sets in Hash-style.
    #
    # @example
    #   self.api[:required]
    #   self.api[:optional][:key] = "value"
    def [](set)
      self.instance_variable_get("@#{set}")
    end

    # Returns a Hash of the *supplied* request parameters. Rejects
    # any parameter that was not defined in the REQUIRED or OPTIONAL
    # maps (or was consumed).
    #
    # @param [Hash] params
    #   A Hash of attributes to merge with the parameters, useful for defining
    #   defaults.
    def parameters(params = {})
      self.optional.deep_merge(self.required).deep_merge(params)
    end

    # Lookup a parsed (and possibly processed) API parameter.
    #
    # @param [String] key
    #   Parameter name.
    # @param [:required|:optional] set
    #   The set of parameters to look-up from. When absent, both required
    #   and optional parameter sets are looked up, in that order.
    def get(key, set = nil)
      if set
        return self[set][key]
      end

      self.required[key.to_sym] || self.optional[key.to_sym]
    end

    # Consumes supplied parameters with the given keys from the API
    # parameter map, and yields the consumed values for processing by
    # the supplied block (if any).
    #
    # This is useful when a certain parameter does not correspond to a model
    # attribute and needs to be renamed, or is used only in a validation context.
    #
    # Use #transform if you only need to convert the value or process it.
    def consume(keys)
      out  = nil

      keys = [ keys ] unless keys.is_a?(Array)
      keys.each do |k|
        if val = self.required.delete(k.to_sym)
          out = val
          out = yield(val) if block_given?
        end

        if val = self.optional.delete(k.to_sym)
          out = val
          out = yield(val) if block_given?
        end
      end

      out
    end

    # Transform the value for the given parameter in-place. Useful for
    # post-processing or converting raw values.
    #
    # @param [String, Symbol] key
    #   The key of the parameter defined earlier.
    #
    # @param [#call] handler
    #   A callable construct that will receive the original value and should
    #   return the transformed one.
    def transform(key, &handler)
      if block_given?
        key = key.to_sym

        if value = self.get(key, :required)
          self.required[key] = yield(value)
        elsif value = self.get(key, :optional)
          self.optional[key] = yield(value)
        end
      end
    end

    def reset
      @required = {}.with_indifferent_access
      @optional = {}.with_indifferent_access
    end
  end
end