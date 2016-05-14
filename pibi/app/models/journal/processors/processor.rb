module Journal::Processors
  class Processor
    attr_writer :ctx, :output, :adapter, :opcode
    attr_reader :error

    class << self
      def required_keys
        []
      end
    end

    def initialize(ctx, output, adapter)
      self.ctx = ctx
      self.output = output
      self.adapter = adapter
      self.opcode = self.class.name.demodulize.underscore.to_sym
    end

    def preprocess(record, index)
    end

    def process(record)
    end

    protected

    def mark_dropped(cause)
      @error = cause
      @output.mark_dropped(@opcode, @ctx.entry['id'], cause, @ctx.path)

      return false
    end

    def mark_processed(value)
      @output.mark_processed(@opcode, value, @ctx.path)
    end

    def handler
      @adapter.handler_for(@ctx.current_collection_key, @opcode)
    end
  end
end