# Pibi API - The official JSON API for Pibi, the personal financing software.
# Copyright (C) 2014 Ahmad Amireh <ahmad@algollabs.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Journal < ActiveRecord::Base
  include ActiveModel::Validations

  attr_accessor :records, :adapter
  attr_reader :registry, :output

  belongs_to :user

  EC_RESOURCE_GONE = 'JOURNAL_RESOURCE_GONE'
  EC_RESOURCE_OVERWRITTEN = 'JOURNAL_RESOURCE_OVERWRITTEN'
  EC_RESOURCE_NOT_FOUND = 'JOURNAL_RESOURCE_NOT_FOUND'
  EC_REFERENCE_NOT_FOUND = 'JOURNAL_REFERENCE_NOT_FOUND'
  EC_UNAUTHORIZED = 'JOURNAL_UNAUTHORIZED'
  EC_INTERNAL_ERROR = 'JOURNAL_INTERNAL_ERROR'

  validate :validate_records

  after_initialize do
    @ability = Ability.new(self.user)
    @ctx = Context.new(@ability)
    @registry = Registry.new
    @adapter ||= Adapters::ServiceAdapter.new
    @records ||= []
  end

  def commit(options = {})
    unless self.valid?
      return false
    end

    @output = Output.new

    @processors = [ :create, :update, :delete ].reduce({}) do |hsh, opcode|
      hsh[opcode.to_s] = Processors.processor_for(opcode).new(@ctx, @output, @adapter)
      hsh
    end

    reorder_operations

    # first pass: pre-process, this may fail
    if !preprocess
      return false
    end

    # second pass: actually commit the operations, this should not fail
    process

    @output
  end

  private

  PriorityList = [
    :users,
    :categories,
    :payment_methods,
    :accounts,
    :transactions,
    :recurrings
  ]

  def validate_records
    validate_structure
    validate_and_resolve_paths if self.errors.empty?
    validate_operations if self.errors.empty?

    self.errors.empty?
  end

  def validate_structure
    Journal::StructureValidator.new.validate(self)
  end

  def validate_and_resolve_paths
    @records.each do |record|
      begin
        info = @registry.resolve_path(record[:path])
        collection = info[:collection]
        collection_key = collection && collection.base_class.name.underscore.pluralize

        record[:scope] = info[:scope]
        record[:collection] = info[:collection]
        record[:collection_key] = collection_key
      rescue Registry::RegistryError => e
        self.errors.add :records, e.message
        break
      end
    end
  end

  def validate_operations
    @records.select { |record| record.has_key?(:operations) }.each do |record|
      record[:operations].each_pair do |opcode, entries|
        next if entries.blank?

        unless adapter.operable?(record[:collection_key], opcode)
          errors.add :records,
            "Resources of type #{record[:collection_key]} do not support the operation #{opcode}."
        end
      end
    end
  end

  def reorder_operations()
    @records.sort! { |a, b|
      a = a#.with_indifferent_access
      b = b#.with_indifferent_access

      PriorityList.index(a[:collection_key].to_sym) <=> PriorityList.index(b[:collection_key].to_sym)
    }
  end

  def traverse(handlers = {})
    @records.each do |record|
      record = record.with_indifferent_access

      handlers[:on_scope].call(record[:scope], record[:path]) if handlers[:on_scope]

      if handlers[:on_collection]
        handlers[:on_collection].call(*[
          record[:collection],
          record[:scope],
          record[:operations] || {}
        ])
      end
    end
  end

  def pass
    traverse({
      on_scope: lambda do |scope, path|
        @ctx.scope = scope
        @ctx.path = path
      end,

      on_collection: lambda do |collection, scope, operations|
        @ctx.collection = collection
        @ctx.operations = operations
        @ctx.scope = scope

        operations.each_pair do |operation, entries|
          @ctx.processor = @processors[operation.to_s]
          @ctx.entries = entries
          yield(operation, entries)
        end # collection operations
      end
    })
  end

  def preprocess
    pass do |opcode, entries|
      entries.each_with_index do |entry, index|
        @ctx.entry = entry
        @ctx.processor.preprocess entry, index

        if @ctx.processor.error.present?
          errors.add :records, @ctx.processor.error
          return false
        end
      end
    end

    true
  end

  def process
    pass do |opcode, entries|
      entries.each do |entry|
        begin
          entry_docstring = entry.to_json
          modified = false

          @ctx.shadows.each do |shadow|
            if entry_docstring.match(shadow[:token])
              entry_docstring.gsub!(shadow[:token], shadow[:substitution])
              modified = true
            end
          end

          if modified
            entry = JSON.parse(entry_docstring).with_indifferent_access
          end

          @ctx.entry = entry
          @ctx.processor.process(entry)
        rescue Exception => e
          puts "WARN: journal processor failure: #{e.class}: #{e.message}"
          puts e.backtrace

          @output.mark_dropped(opcode.to_sym, entry[:id], EC_INTERNAL_ERROR, @ctx.path)
        end
      end
    end
  end
end