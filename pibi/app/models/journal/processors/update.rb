module Journal::Processors
  class Update < Processor
    def self.required_keys
      %w[ id data ]
    end

    def process(record)
      unless resource = @ctx.collection.find_by_id(record[:id])
        return mark_dropped(Journal::EC_RESOURCE_NOT_FOUND)
      end

      unless @ctx.resource_accessible?(resource, :update)
        return mark_dropped(Journal::EC_UNAUTHORIZED)
      end

      data = (record[:data] || {}).with_indifferent_access
      data.delete(:id)

      response = begin
        response = handler.call(resource, data)
      rescue ActiveRecord::RecordNotFound => e
        return mark_dropped(Journal::EC_REFERENCE_NOT_FOUND)
      end

      unless response.successful?
        return mark_dropped response.error
      end

      mark_processed({ id: "#{resource.id}" })
    end
  end
end