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

# @API Notices
#
# An interface for accepting notifications.
#
# @model Notification
#   {
#     "status": "success",
#     "message": "notice_accepted"
#   }
class NoticesController < ApplicationController
  include Rack::API::Parameters
  include Rack::API::Resources

  skip_before_filter :require_user, only: [ :accept ]

  def accept
    requires :token

    unless notice = Notice.find_by({ token: api.get(:token).to_s })
      halt! 404
    end

    notice.accept!

    respond_to do |format|
      format.html do
      end

      format.json do
        render json: { status: 'success', message: 'notice_accepted' }
      end
    end
  end

  private

  def require_json_format
  end
end