module Journallable
  extend ActiveSupport::Concern

  included do |base|
    base.extend ClassMethods
    base.send :include, InstanceMethods

    base.journal_class.tap do |klass|
      klass.cattr_accessor :journal_scope_key, :journal_collection_key
      klass.acts_as_journallable({
        collection_key: klass.name.demodulize.underscore.pluralize
      })
    end

    Journal::Registry.register_scope base
  end

  module InstanceMethods
    def journal_path
      klass = self.class.journal_class
      scope = journal_scope
      path = [ '' ]

      # Is our scope journallable too? Use its journal path if so:
      if scope && scope.respond_to?(:journal_path)
        scope_path = scope.journal_path

        if scope_path[0] == '/'
          path.shift
        end

        path << [ scope_path, scope.id ]
      # infer the journal path based on the scope:
      elsif scope
        scope_key = klass.journal_scope_key.pluralize
        scope_id = scope.id

        path << [ scope_key, scope_id ]
      end

      path << klass.journal_collection_key
      path.join('/')
    end

    def journal_scope
      klass = self.class.journal_class
      if klass.journal_scope_key.present?
        self.send(klass.journal_scope_key.singularize)
      end
    end
  end

  module ClassMethods
    def acts_as_journallable(options)
      self.journal_scope_key = options.fetch(:scope_key, self.journal_scope_key).to_s
      self.journal_collection_key = options.fetch(:collection_key, self.journal_collection_key).to_s
    end

    # Override this if you're using STI or a similar situation where you're
    # mixing in Journallable only in the base class, but the descendants may
    # be journallable too.
    #
    # This should return an instance that directly extends Journallable.
    def journal_class
      base_class
    end
  end
end