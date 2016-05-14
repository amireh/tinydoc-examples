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
# @API Journals
#
# TODO
#
# @object Journal
#  {
#  }
class JournalsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user
  before_filter :require_journal, only: [ :show ]
  before_filter :prepare_service, only: [ :create ]

  # @API Create a new journal.
  #
  # @returns Journal
  def create
    parameter :records, type: :array, required: true
    parameter :graceful, type: :boolean

    with_service @service.create(current_user, api.get(:records)) do |journal|
      # so it gets picked up by the broadcast after_filter
      @journal_output = journal.output

      expose journal
    end
  end

  def index
    expose current_user.journals
  end

  def show
    expose @journal
  end

  private

  def prepare_service
    @service = JournalService.new
  end

  def require_journal
    with :user, :journal
  end
end