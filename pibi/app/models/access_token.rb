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

class AccessToken < ActiveRecord::Base
  class << self
    attr_accessor :salt
  end

  belongs_to :user

  before_save :set_defaults

  validates_uniqueness_of :digest
  validates_uniqueness_of :udid, scope: :user_id,
    message: 'UDID is already bound to an access token.'

  def set_defaults
    self.digest ||= Digest::SHA1.hexdigest([
      self.udid,
      self.class.salt,
      self.user.id
    ].join('_'))
  end
end
