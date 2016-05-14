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

class AttachmentSerializer < Rack::API::Serializer
  attributes :id, :file_name, :file_size, :created_at, :href, :links

  has_one :progress, embed: :object

  def file_name
    object.item_file_name
  end

  def file_size
    object.item_file_size
  end

  def item_url
    object.absolute_item_url
  end

  def href
    attachment_url(object)
  end

  def links
    {}.tap do |links|
      links[:item] = item_url if object.item.present?
    end
  end
end
