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
  # An event pub/sub interface.
  module Callbacks
    attr_accessor :callbacks

    def self.extended(base)
      base.callbacks = {}
    end

    # Add a callback to a given event.
    #
    # @example Listening to :resource_located events
    #
    #     Sinatra::API.on :resource_located do |resource, name|
    #       if resource.is_a?(Monkey)
    #         resource.eat_banana
    #       end
    #     end
    #
    # @example A callback with an instance method
    #
    #   class Monkey
    #     def initialize
    #       # This means that the monkey will eat a banana everytime a resource
    #       # is located.
    #       Sinatra::API.on :resource_located, &method(:eat_banana)
    #     end
    #
    #     def eat_banana(*args)
    #     end
    #   end
    def on(event, &callback)
      (self.callbacks[event.to_sym] ||= []) << callback
    end

    # Broadcast an event to subscribed callbacks.
    #
    # @example Triggering an event with an argument
    #
    #     Sinatra::API.trigger :special_event, 'Special Argument'
    #
    def trigger(event, *args)
      callbacks = self.callbacks[event.to_sym] || []
      callbacks.each do |callback|
        callback.call(*args)
      end
    end
  end
end