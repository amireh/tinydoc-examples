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
# @API Attachments
#
# Certain resources can have files attached to them, which is particularly
# helpful for storing receipts, invoices, order confirmations, etc.
#
# You may upload images, text files, PDF files, or HTML files. The following
# file types (MIME types / extensions) are accepted:
#
#   - `image/jpg` (.jpg, .jpeg)
#   - `image/png` (.png)
#   - `application/pdf` (.pdf)
#   - `text/plain` (.txt)
#   - `application/html` (.html, .htm)
#
# Uploaded file size must **not exceed 2 megabytes**.
#
# @note
#   In the object synopsis, certain fields are keyed by `[attachable]`; this is
#   only because more than one resource provides the Attachments interface.
#   So, when you're actually performing the requests, you will have to substitute
#   `[attachable]` occurrences with the actual resource type you're interfacing
#   with, like `transaction` or `recurring`.
#
# @object Attachment
#  {
#    // The unique id of the attachment.
#    "id": 1,
#
#    // The attached file name.
#    "file_name": "my-file.txt",
#
#    // The attached file size, in bytes.
#    "file_size": 12,
#
#    // Time at which the attachment was uploaded.
#    "created_at": "2014-02-21T18:38:02.846Z",
#
#    // Path to this attachment, "attachables" would be substituted by the
#    // resource type you're attaching to, e.g: "transactions" or "recurrings"
#    "href": "/attachments/1",
#
#    "links": {
#      // Public download URL
#      "item": "/attachments/ea3775d09c4add39a18af496a5b4b751730170af.txt?1393007882"
#    }
#  }
class AttachmentsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_json_format, except: [ :serve_item ]
  before_filter :require_attachable
  before_filter :require_attachment, except: [ :index, :create ]
  before_filter :prepare_service, only: [ :create, :destroy ]

  def index
    expose @attachable.attachments
  end

  # @API Uploading files
  #
  # ...
  #
  # @argument [File] item
  #   The uploaded file.
  #
  # @returns Attachment
  def create
    parameter :item, required: true

    if @attachable.attachments.length > 3
      halt! 422, "[ATMT_MAX_FILE_COUNT] You can not upload more than 3 files for the same resource."
    end

    with_service @service.create(@attachable, api.parameters) do |attachment|
      playback :update, @attachable

      expose attachment
    end
  end

  def show
    expose @attachment
  end

  def destroy
    with_service @service.destroy(@attachment) do |rc|
      playback :update, @attachable

      no_content!
    end
  end

  def serve_item
    send_file @attachment.item.path, {
      filename: @attachment.item_file_name,
      type: @attachment.item_content_type
    }
  end

  private

  def prepare_service
    @service = AttachmentService.new
  end

  def require_attachable
    id_keys = params.keys.select { |key| key =~ /_id$/ }
    id_keys.reject! { |id_key| id_key.to_s == 'attachment_id' }

    if id_keys.any?
      scope = id_keys.first.sub(/_id$/, '').classify.constantize
      @attachable = scope.find(params[id_keys.first])
    end
  end

  def require_attachment
    @attachment = Attachment.find(params[:attachment_id].to_i)
  end
end