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

module Rack
  module API
    extend Callbacks

    class << self
      # @!attribute logger
      # @return [ActiveSupport::Logger]
      # A Logger instance.
      attr_accessor :logger

      # @!attribute instance
      # @return [ActionController::Base]
      #   The application controller instance that is evaluating the current
      #   request.
      attr_accessor :instance
    end

    ParameterValidator.install(self)
  end
end