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

##
# @API Progresses
#
# Progress objects are tied to Attachments and operations that may take a while
# to complete. They provide means to track the progress of such operations.
#
# @object Progress
#  {
#    // The unique id of the progress.
#    "id": 1,
#
#    "completion": 0,
#
#    "workflow_state": "active",
#
#    // Time at which the progress was started.
#    "created_at": "2014-02-21T18:38:02.846Z",
#
#    // Path to this progress.
#    "href": "/progresses/1",
#
#    "links": {
#      "attachment": "/attachments/1"
#    }
#  }
class ProgressesController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_progress, only: [ :show ]

  def show
    expose @progress
  end

  private

  def require_progress
    @progress = Progress.find(params[:progress_id])
  end
end