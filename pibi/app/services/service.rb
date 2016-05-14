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

class Service
  class Result
    attr_accessor :output, :error

    def valid?
      error.blank?
    end
    alias_method :successful?, :valid?
    alias_method :success?, :valid?

    def accept(output)
      self.output = output
      self
    end

    def reject(error)
      self.error = error
      self
    end
  end

  protected

  def logger
    Rails.logger
  end

  def reject_with(error)
    Result.new.reject(error)
  end

  def accept_with(output)
    Result.new.accept(output)
  end
end