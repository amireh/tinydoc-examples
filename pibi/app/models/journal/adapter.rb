# @class Journal::Adapter
#
# An adapter for handling journal operation entries, like creating, updating,
# or deleting resources.
#
# The adapter is normally not expected to handle the processing of operations
# in itself, but would instead proxy the requests to the modules that do, like
# Rails controllers, or Service objects.
class Journal::Adapter
  # Locate a resource handler for handling an operation on a specific resource
  # collection.
  #
  # @param [ActiveRecord::Base] collection
  # The resource collection, like User, Account, or Category.
  #
  # @param [String] operation
  # The operation identifier, like "create", or "delete". See
  # Journal::Processors for the available operations.
  #
  # @return [#call]
  # The handler. If you return nil, the journal will abort.
  def handler_for(collection, operation)
  end

  # @return [Boolean]
  # Whether the adapter can handle the specified operation on the given
  # collection.
  def operable?(collection, operation)
    false
  end
end