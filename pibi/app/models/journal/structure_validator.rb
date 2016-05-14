class Journal::StructureValidator < ActiveModel::Validator
  def validate(journal)
    error = run journal.records

    if error.is_a?(String)
      journal.errors.add :records, error
    end

    error.is_a?(String)
  end

  private

  # Current structure:
  #
  # {
  #   "records": [{
  #     "scope": "string",
  #     "scope_id": number,
  #     "collection": "string",
  #     "operations": {
  #       "create": [],
  #       "update": [],
  #       "delete": []
  #     }
  #   }]
  # }
  #
  # OPERATION VALIDATIONS
  # --------- -----------
  #
  # Validates operation records for structure validity,
  # by going through the records and validating that the specified required
  # keys are existent and valid within the record.
  #
  # Current operation structure:
  #
  # {
  #   "operations": {
  #     "create": [{
  #       "id": number, // shadow id
  #       "data": {}
  #     }],
  #     "update": [{
  #       "id": number,
  #       "data": {}
  #     }],
  #     "delete": [{
  #       "id": number
  #     }]
  #   }
  # }
  #
  # @error if record listing is not an array
  # @error record is not a Hash
  # @error missing a required key
  # @error 'data' is a required key and record['data'] is not a Hash
  #
  def run(records)
    unless records.is_a?(Array)
      return 'Record listing must be of type Array, got ' + records.class.name
    end

    if records.any? { |record| !record.is_a?(Hash) }
      return 'Record must be of type Hash.'
    end

    records.each do |record|
      record = record.with_indifferent_access

      unless record.has_key?(:path)
        return "Missing required record key 'path'"
      end

      operations = record[:operations] ||= {}

      unless operations.is_a?(Hash)
        return 'Operations must be of type Hash.'
      end

      operations.each_pair do |opcode, entries|
        unless Journal::Processors.can_process?(opcode)
          return "Unrecognized operation #{opcode}."
        end

        unless entries.is_a?(Array)
          return "Operation entries must be of type Array."
        end

        processor = Journal::Processors.processor_for(opcode)

        entries.each do |entry|
          unless entry.is_a?(Hash)
            return "Operation entry must be of type Hash."
          end

          processor.required_keys.each do |key|
            unless entry.has_key?(key)
              return "Operation entry is missing required key: #{key}"
            end
          end

          # Validate 'data' key integrity
          if processor.required_keys.include?('data')
            unless entry['data'].is_a?(Hash)
              return "Operation entry data must be of type Hash."
            end
          end
        end
      end # collection operations
    end # records
  end
end