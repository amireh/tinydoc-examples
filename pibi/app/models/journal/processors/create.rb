module Journal::Processors
  class Create < Processor
    def initialize(*args)
      @dropped = []

      super(*args)
    end

    def self.required_keys
      %w[ id data ]
    end

    def preprocess(record, record_index)
      # has there been a CREATE record with the same shadow id in this collection?
      @ctx.entries.each_with_index do |sibling, index|
        if sibling['id'].to_s == record['id'].to_s && index != record_index
          # because this is so much easier and cleaner than trying to remove all
          # duplicates from the array, we'll simply test this flag in #process
          drop sibling
        end
      end

      # we process only the very last CREATE record for this resource
      undrop record
    end

    def process(record)
      if dropped?(record)
        return mark_dropped(Journal::EC_RESOURCE_OVERWRITTEN)
      end

      # TODO: find out what side-effects this is causing:
      #
      # this permission test is not really accurate as the only way we
      # can test if we can create resources in this *collection* is by testing
      # whether we can manage the parent scope
      unless @ctx.resource_accessible?(@ctx.scope, :create)
        return mark_dropped(Journal::EC_UNAUTHORIZED)
      end

      data = (record[:data] || {}).with_indifferent_access
      data.delete(:id)

      response = begin
        handler.call(@ctx.scope, data)
      rescue ActiveRecord::RecordNotFound => e
        return mark_dropped(Journal::EC_REFERENCE_NOT_FOUND)
      end

      unless response.successful?
        return mark_dropped response.error
      end

      resource = response.output

      # map the shadow id to the real resource id
      @ctx.track_shadow(record['id'], resource.id)

      mark_processed({
        id: "#{resource.id}",
        shadow_id: "#{record['id']}"
      })
    end

    protected

    def drop(record)
      @dropped << record.hash
    end

    def undrop(record)
      @dropped.delete(record.hash)
    end

    def dropped?(record)
      @dropped.include?(record.hash)
    end
  end
end