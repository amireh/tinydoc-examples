module Journal::Processors
  class Delete < Processor
    def self.required_keys
      %w[ id ]
    end

    def process(record)
      unless resource = @ctx.collection.find_by_id(record[:id])
        return mark_dropped(Journal::EC_RESOURCE_NOT_FOUND)
      end

      unless @ctx.resource_accessible?(resource, :delete)
        return mark_dropped(Journal::EC_UNAUTHORIZED)
      end

      response = handler.call(resource)

      unless response.successful?
        return mark_dropped response.error
      end

      # delete any create or update records that are operating on this resource
      purge_relevant record[:id], :create
      purge_relevant record[:id], :update

      @output.mark_processed :delete, { id: "#{record[:id]}" }, *@ctx.current_path
    end

    protected

    def purge_relevant(record_id, operation)
      entries = @ctx.operations[operation]

      unless entries.blank?
        entry_id = "#{entry_id}"
        entry = entries.detect { |entry| entry_id == "#{entry[:id]}" }

        if entry.present?
          @output.mark_dropped(operation, entry[:id], Journal::EC_RESOURCE_GONE)
        end
      end
    end # purge_relevant
  end
end