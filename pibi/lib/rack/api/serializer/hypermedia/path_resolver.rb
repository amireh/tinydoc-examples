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

# require 'active_model/serializer'
# require 'active_model/array_serializer'

class Rack::API::Serializer::Hypermedia::PathResolver
  attr_reader :serializer, :options

  def initialize(serializer, options)
    @serializer = serializer
    @options = options
    @objects = {}
  end

  def path_for_association(object, association)
    association.to_s.singularize == association.to_s ?
      path_for_has_one(object, association) :
      path_for_has_many(object, association)
  end

  def path_for_object(object)
    context = if context_name = options[:context]
      get_object(context_name)
    end

    [ context, get_polymorphic_object ]
  end

  def url_for(*path)
    path = path.flatten.compact

    if path.length == 1
      model = path.first
      model_name = model.class.model_name

      query = {}
      query[:action] = :show
      query[:controller] = model_name.route_key
      query[:"#{model_name.param_key}_id"] = model.id

      serializer.url_for(query)
    else
      serializer.polymorphic_url(path)
    end
  end

  private

  def path_for_has_one(object, name)
    associated_object = get_object(name)

    if associated_object.nil?
      return nil
    end

    # locate the context for the association, if any
    association_serializer = begin
      name = associated_object.class.name.singularize.underscore
      "#{name}_serializer".classify.constantize
    rescue
      nil
    end

    association_context = if association_serializer
      association_hypermedia = association_serializer.try(:_hypermedia)
      association_hypermedia && association_hypermedia[:context]
    end

    if association_context
      association_context = associated_object.send(association_context)
    end

    [ association_context, associated_object, { name: name } ]
  end

  def path_for_has_many(object, name)
    # in has_many relationships, the object itself is the context:
    [ get_polymorphic_object(object), name ]
  end

  def get_object(name)
    name = name.to_sym

    @objects[name.to_sym] ||= if serializer.respond_to?(name, true)
      serializer.send name
    else
      serializer.object.send(name)
    end
  end

  def get_polymorphic_object(object=serializer.object)
    @polymorphic_object ||= if polymorphic_base = options[:as]
      object.becomes(polymorphic_base)
    else
      object
    end
  end
end # class PathResolver