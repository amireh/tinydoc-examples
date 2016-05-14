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

class Rack::API::Serializer < ActiveModel::Serializer
  include Hypermedia

  class_attribute :_stringifiables

  # @override
  # Attach Hypermedia links to the serializer output.
  def serializable_hash
    super.tap do |hsh|
      stringify_ids(hsh, self.class._associations)

      if self.class._hypermedia.present?
        assign_hypermedia_urls(hsh)
      end
    end
  end

  # Mark certain attributes as optional, which will be omitted if the user is
  # requesting a compact version of the output, e.g by passing ?compact=true
  # as a request parameter.
  def self.optional_attributes(*fields)
    fields.flatten.each do |field|
      method = "include_#{field}?".to_sym

      unless method_defined?(method)
        define_method method do
          !compact?
        end
      end
    end
  end

  # Explicitly mark certain attributes to be stringified. These attributes
  # can either be scalars (numbers), or arrays of scalars. Both will be handled.
  def self.stringify_attributes(*fields)
    self._stringifiables ||= []
    self._stringifiables.concat(Array.wrap(fields))
  end

  # Tell whether the user is requesting a compact version of the output.
  #
  # You can use this flag inside your attribute serializers.
  def compact?
    scope && scope[:params] && scope[:params][:compact].present?
  end

  private

  def stringify_ids(hsh, associations)
    hsh[:id] = "#{hsh[:id]}" if hsh[:id]

    attrs = []
    attrs << associations.keys.map do |name|
      singular = name.to_s.singularize
      singular == name.to_s ? "#{name}_id" : "#{singular}_ids"
    end

    if self.class._stringifiables.present?
      attrs << self.class._stringifiables.to_a
    end

    attrs.flatten.map(&:to_sym).uniq.select { |k| hsh.has_key?(k) }.each do |key|
      hsh[key] = hsh[key].is_a?(Array) ? hsh[key].map(&:to_s) : "#{hsh[key]}"
    end
  end
end