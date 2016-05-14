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

# @API Exports
#
# A bunch of APIs for exporting your Pibi data to other formats, like CSV and
# Excel.
#
# All the data export APIs are asynchronous in that they will return a Progress
# object as their output which will eventually yield the exported data.
#
# See the Progress API to monitor the export operations.
class ExportsController < ApplicationController
  include Rack::API::Parameters

  before_filter :require_user

  # @API Export transactions to a CSV or Excel sheet.
  #
  # Export a selection of transactions across any number of accounts.
  #
  # @argument [Array<String>] account_ids
  #   IDs of the user accounts that contain the transactions.
  #
  # @argument [String] format (optional)
  #   The format of the exported data, which can be either CSV (default) or Excel (.xls).
  #   Accepted values: [ 'csv', 'xls' ]
  #
  # @argument [String] from (optional)
  #   Specifies the beginning of the date-range.
  #   Value can be a JSON timestamp, or a string following the format "MM/DD/YYYY".
  #
  #   *Note*:
  #   The value will be automatically mapped to mark the _beginning_ of the
  #   specified day, eg: `00:00:00`.
  #
  # @argument [String] to (optional)
  #   Specifies the end of the date-range.
  #   Value can be a JSON timestamp, or a string following the format "MM/DD/YYYY".
  #
  #   *Note*:
  #   The value will be automatically mapped to mark the _end_ of the
  #   specified day, e.g: `23:59:59`.
  #
  # @emits ClientMessage::ExportTransactions
  #
  # @example_request
  #  {
  #    "from": "2014-02-18T00:00:00Z",
  #    "to": "2014-02-24T00:00:00Z"
  #  }
  #
  # @returns Progress
  def transactions
    parameter :account_ids, type: :array, required: true
    parameter :format, type: :string, in: [ 'csv', 'xls' ], default: 'csv'
    parameter :from, type: :date
    parameter :to, type: :date

    api.get(:account_ids).compact.uniq.each do |id|
      unless current_user.accounts.find(id)
        halt! 403, "You do not have access to account##{id}."
      end
    end

    # discard older exports:
    current_user.data_exports.where(tag: ClientMessage::ExportTransactions).destroy_all

    attachment = current_user.data_exports.create!({
      tag: ClientMessage::ExportTransactions
    })

    attachment.create_progress!

    Pibi::Worker.enqueue(Workers::ExportTransactions, {
      client_id: current_client_id,
      user_id: current_user.id,
      attachment_id: attachment.id,
      format: params[:format] || 'csv'
    }.merge(api.parameters))

    expose attachment.progress
  end
end