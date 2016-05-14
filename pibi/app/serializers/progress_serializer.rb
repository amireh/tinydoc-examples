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

class ProgressSerializer < Rack::API::Serializer
  attributes :id,
    :attachment_id,
    :user_id,
    :tag,
    :completion,
    :workflow_state,
    :created_at,
    :updated_at,
    :href,
    :links

  stringify_attributes :attachment_id, :user_id

  def tag
    object.tag || object.attachment.tag
  end

  def href
    progress_url(object)
  end

  def links
    {}.tap do |links|
      links[:attachment] = attachment_url(object.attachment)
    end
  end
end
