# Shared context between the processors and the journal itself.
class Journal::Context
  attr_accessor *[
    # @!attribute [r] scope
    # @return [ActiveRecord::Base]
    #   The current scope being evaluated.
    :scope,

    # @!attribute [r] collection
    # @return [ActiveRecord::Association]
    #   The current scope collection being evaluated.
    :collection,

    # @!attribute [r] operations
    # @return [Array<Hash>]
    #   The set of operations to be performed on the collection.
    :operations,

    # @!attribute [r] entries
    # @return [Array<Hash>]
    #   The current set of resource operation entries that will be processed.
    :entries,

    # @!attribute [r] entry
    # @return [Hash]
    #   The current entry being processed.
    :entry,

    # @!attribute [r] processsor
    # @return [Journal::Processor]
    #   The processor handling the current operation.
    :processor,

    :shadows,
    :path
  ]

  def initialize(ability)
    @ability = ability
    self.shadows = []
  end

  # @return [String]
  #   The key to identify the collection in the output.
  #
  # @example Building a path for the current collection, an Account container:
  #   current_collection_key #=> "accounts"
  def current_collection_key
    self.collection.name.demodulize.pluralize.underscore
  end

  # @return [String]
  #   A path to the current collection.
  #
  # @example Path to the current collection Accounts in the User#1 scope:
  #   current_path #=> [ "users", 1, "accounts" ]
  def current_path
    path
  end

  def track_shadow(shadow_id, resource_id)
    self.shadows << {
      token: "\"#{shadow_id}\"",
      substitution: "\"#{resource_id}\""
    }
  end

  def resource_accessible?(resource, opcode)
    @ability.can?(opcode, resource)
  end
end