# @class Journal::Output
#
# The output of a committed journal, which can be broadcasted to clients and
# played back to simulate the journal.
class Journal::Output
  attr_accessor :processed, :dropped

  class << self
    attr_accessor :error_formatter
  end

  class RecordSet < ::Array
    def at(*fragments)
      path = mk_path(fragments)
      entry = detect { |e| e[:path] == path } || push({ path: path }).last

      yield(entry)
    end

    private

    def mk_path(*path)
      path.flatten.join('/').tap do |str|
        if str[0] != '/'
          str.replace('/' + str)
        end
      end
    end
  end

  def initialize
    # processed records
    self.processed = RecordSet.new

    # dropped (rejected) records
    self.dropped = RecordSet.new
  end

  def mark_processed(opcode, resource_record, *path)
    processed.at(path) do |entry|
      entry[:operations] ||= {}
      entry[:operations][opcode.to_sym] ||= []
      entry[:operations][opcode.to_sym] << resource_record
    end
  end

  def mark_dropped(opcode, record_id, error, *path)
    formatted_error = if self.class.error_formatter.present?
      self.class.error_formatter.call(error)
    else
      error
    end

    dropped.at(path) do |entry|
      entry[:operations] ||= {}
      entry[:operations][opcode.to_sym] ||= []
      entry[:operations][opcode.to_sym] << {
        id: "#{record_id}",
        error: formatted_error
      }
    end
  end
end