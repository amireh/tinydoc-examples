class Journal::Adapters::ServiceAdapter < Journal::Adapter
  OperationAliases = {
    delete: [ :destroy ]
  }

  # Find out if the given operation is supported for the specified resource type.
  #
  # @param [ActiveRecord::Associations::CollectionProxy] collection
  # @param [Symbol] operation
  #
  # @return [Boolean]
  #   Whether the adapter can handle the operation or not.
  #
  # @note
  # In your service object, you can define a class method called
  # journal_operations that returns an array of the supported operations for
  # the resource type the service handles. Unless defined, the adapter assumes
  # the service provides all the journal operations (create, update, delete)
  #
  # Example: Do not let User resources be created or deleted through a Journal:
  #
  #   class UserService
  #     def self.journal_operations
  #       [ :update ]
  #     end
  #   end
  #
  def operable?(collection, operation)
    operation = operation.to_sym

    unless service = service_for(collection)
      return false
    end

    if service.respond_to?(:journal_operations)
      unless service.journal_operations.include?(operation)
        return false
      end
    end

    method_for(operation, service).present?
  end

  def handler_for(collection, operation)
    if service = service_for(collection)
      method_for(operation, service).bind(service.new)
    end
  end

  private

  def service_for(collection)
    begin
      (collection.singularize + '_service').classify.constantize
    rescue NameError
      nil
    end
  end

  def method_for(operation, service)
    methods = service.instance_methods
    operation = operation.to_sym
    operations = [ operation, OperationAliases[operation] ].flatten.compact

    supported_operation = operations.detect do |operation|
      methods.include?(operation.to_sym)
    end

    supported_operation.present? && service.instance_method(supported_operation)
  end
end