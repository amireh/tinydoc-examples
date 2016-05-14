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

module Rack::API
  # API for defining parameters an endpoint requires or accepts, their types,
  # and optional validators.
  #
  module Resources
    private

    def api_resources(*list)
      required_resources(*list)
    end
    alias_method :with, :api_resources

    def required_resources(*required)
      parent_resource = nil

      required.each do |resource|
        parent_resource = api_locate_resource(resource.to_s, parent_resource)
      end
    end

    # Attempt to locate a resource based on an ID supplied in a request parameter.
    #
    # If the param map contains a resource id (ie, :folder_id),
    # we attempt to locate and expose it to the route.
    #
    # A 404 is raised if:
    #
    #   1. the scope is missing
    #   2. the resource couldn't be found in its scope
    #
    # If the resources were located, they're accessible using @folder or @page.
    #
    # The route can be halted using the :requires => [] condition when it expects
    # a resource.
    #
    # @example using :requires to reject a request with an invalid @page
    #
    #   get '/folders/:folder_id/pages/:page_id', :requires => [ :page ] do
    #     @page.show    # page is good
    #     @folder.show  # so is its folder
    #   end
    #
    def api_locate_resource(r, container = nil)
      resource_id = params[r + '_id'].to_i
      klass = r.camelize

      if instance_variable_defined?("@#{r}")
        logger.warn "Rack::API::Resources: @#{r} is already defined, skipping resolution"
        return instance_variable_get("@#{r}")
      end

      collection = if container.nil?
        klass.constantize
      else
        container.send("#{r.pluralize}")
      end

      logger.debug "locating resource #{r} with id #{resource_id} " +
        "from #{collection} [#{container}]"

      resource = begin
        collection.find(resource_id)
      rescue ActiveRecord::RecordNotFound
        logger.debug "Rack::API::Resources: unable to find resource #{resource_id} in container #{collection}"
        nil
      end

      if !resource
        error = "No such resource: #{klass}##{resource_id}"

        if container
          error << " in #{container.class.name.to_s}##{container.id}"
        end

        raise Error.new(404, error)
      end

      if respond_to?(:can?)
        unless can? :access, resource
          raise Error.new(403, "You do not have access to this #{klass} resource.")
        end
      end

      instance_variable_set("@#{r}", resource)

      Rack::API.trigger :resource_located, resource, r

      resource
    end
  end
end