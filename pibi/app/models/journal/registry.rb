# @class Journal::Registry
#
# The registry tracks the scopes available for journalling. Journalled scopes
# must provide an interface for setting and retrieving shadow resources.
#
# @see Journallable
class Journal::Registry
  attr_accessor :resolved_scopes

  class RegistryError < RuntimeError
  end

  class UnknownScopeError < RegistryError
    attr_accessor :scope_key

    def initialize(key)
      super("Unknown scope #{key}")
    end
  end

  class ScopeNotFoundError < RegistryError
    attr_accessor :scope_key, :scope_id

    def initialize(key, id)
      super("No such resource #{key}##{id}")
    end
  end

  class UnknownCollectionError < RegistryError
    attr_accessor :collection_key, :scope_key

    def initialize(collection_key, scope_key)
      super("No such collection #{collection_key} in scope #{scope_key}")
    end
  end

  def initialize
    self.resolved_scopes = {}
  end

  def resolve_path(path)
    fragments = path.to_s.split('/').reject { |s| s == '/' || s.empty? }
    key = fragments.pop
    rc = {}

    scopes = []
    ancestry = []
    cursor = nil
    root_scope = nil
    fragments.each_with_index do |fragment, i|
      next if i % 2 != 0

      scopes << {
        key: fragment.to_s.singularize,
        id: fragments[i+1]
      }
    end

    if scopes.empty?
      return {
        collection: locate_scope(key.to_s.singularize),
        ancestry: []
      }
    end

    scopes.shift.tap do |entry|
      unless self.class.scope_registered?(entry[:key])
        raise UnknownScopeError.new(entry[:key])
      end

      root_scope = resolve_scope(entry[:key], entry[:id])

      unless root_scope.present?
        raise ScopeNotFoundError.new(entry[:key], entry[:id])
      end
    end

    cursor = root_scope
    ancestry << root_scope

    while scopes.any?
      entry = scopes.shift
      scope_path = generate_scope_path(*entry.values)

      cursor = self.resolved_scopes[scope_path] ||= begin
        cursor.send(entry[:key].pluralize).find_by_id(entry[:id])
      end

      ancestry << cursor
    end

    if cursor
      unless cursor.respond_to?(key)
        raise UnknownCollectionError.new(key, cursor.class.name)
      end

      rc[:collection] = cursor.send(key)
    end

    rc.merge!({
      ancestry: ancestry,
      scope: ancestry.last
    })

    rc
  end

  class << self
    # Register a scope as available for journalling.
    #
    # @param [ActiveRecord::Base] klass
    # The scope.
    #
    # This is done automatically if a model mixes in the Journallable module.
    def register_scope(klass)
      scopes[klass.name.underscore] = klass
    end

    # Is the given scope identifier registered as a journallable scope?
    def scope_registered?(key)
      scopes.has_key?(key.to_s)
    end

    # The registered scopes.
    def scopes
      @@scopes ||= {}
    end
  end

  private

  def generate_scope_path(key, id)
    [ key, id ].map(&:to_s).map(&:underscore).join('_')
  end

  def locate_scope(key)
    self.class.scopes[key.to_s]
  end

  # Retrieve a specific record from a scope.
  #
  # @param [String] key
  # The scope identifier.
  #
  # @param [Integer] id
  # The resource identifier.
  #
  # @return [ActiveRecord::Base]
  # The model.
  def resolve_scope(key, id)
    path = generate_scope_path(key, id)
    self.resolved_scopes[path] ||= begin
      if self.class.scope_registered?(key) && id.present?
        locate_scope(key).find_by_id(id)
      end
    end
  end
end