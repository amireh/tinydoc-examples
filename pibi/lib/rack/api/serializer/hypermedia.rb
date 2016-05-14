module Rack::API::Serializer::Hypermedia
  def self.included(base)
    base.class_attribute :_hypermedia
    base.extend ClassMethods
  end

  module ClassMethods
    # Enable Hypermedia links for this serializer.
    #
    # @param [Hash] options
    #
    # @param [Array<Symbol>] options.only
    #   Only the associations found in this array will be handled. When blank,
    #   the serializer's associations are probed instead.
    #
    # @param [Array<Symbol>] options.except
    #   Associations in this array will not be handled.
    #
    # @param [Array<Symbol>] options.extra
    #   Extra associations to link. This is useful when you'd like to provide
    #   a URL for a resource association, but you're not including it in the
    #   serializer using something like `has_many`.
    def hypermedia(options={})
      self._hypermedia = options.merge({ enabled: true })
    end
  end

  private

  def assign_hypermedia_urls(hsh)
    options = self.class._hypermedia
    resolver = PathResolver.new(self, options)

    hsh[:href] = resolver.url_for(resolver.path_for_object(object))
    hsh[:links] ||= {}

    # links for associations:
    whitelist = options[:only] || []
    blacklist = options[:except] || []

    if options.has_key?(:links)
      options[:links].each_pair do |id, link|
        hsh[:links][id] = instance_exec(&link)
      end
    end

    associations = if whitelist.any?
      whitelist
    else
      self.class._associations.map(&:first)
    end

    if blacklist.any?
      associations = associations - blacklist
    end

    if options[:extra].present?
      associations += options[:extra]
    end

    associations.each_with_object(hsh[:links]) do |name, out|
      if path = resolver.path_for_association(object, name)
        if path.last.is_a?(Hash)
          name = path.pop[:name]
        end

        out[name] = resolver.url_for(path)
      end
    end

    hsh.delete(:links) if hsh[:links].empty?
  end # method assign_hypermedia_urls
end