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

class Category < ActiveRecord::Base
  include Journallable

  acts_as_journallable scope_key: "user"

  default_scope { order('name ASC') }

  paginates_per 50
  max_paginates_per 50

  belongs_to :user
  has_and_belongs_to_many :transactions

  validates_presence_of :name,
    message: '[CGRY_MISSING_NAME] You must provide a name for the category!'

  validates_uniqueness_of :name, :scope => [ :user_id ],
    message: '[CGRY_NAME_UNAVAILABLE] You already have such a category!',
    case_sensitive: false

  validates_length_of :name, minimum: 3,
    message: '[CGRY_NAME_TOO_SHORT] A category must be at least 3 characters long.'
end
