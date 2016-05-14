module Journal::Processors
  class << self
    # The operations that can be handled by the journal.
    def operations
      [ 'create', 'update', 'delete' ]
    end

    def can_process?(opcode)
      operations.include?(opcode.to_s)
    end

    # Retrieve an instance of an operation processor.
    def processor_for(opcode, *args)
      klass = begin
        "Journal::Processors::#{opcode.to_s.classify}".constantize
      rescue NameError
        raise "No processor registered for operation #{opcode}."
      end
    end
  end
end