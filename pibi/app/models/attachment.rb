class Attachment < ActiveRecord::Base
  belongs_to :attachable, polymorphic: true

  has_one :progress, dependent: :destroy

  # PaperClip will not remove the file after getting destroyed, at least
  # in tests (in console it worked...) no matter what I did. Tried with versions
  # 4.0.1 and 3.5.2, so anyway, we're removing the file by hand:
  #
  # Do NOT move this callback anywhere as the callback must be called before
  # any of paperclip's.
  before_destroy :remove_item_file

  has_attached_file :item, {
    # url: "/static/attachments/:hash.:extension",
    hash_secret: Pibi::Application.config.secret_key_base
  }

  validates_attachment :item, {
    size: {
      in: 0..2.megabytes,
      message: "[ATMT_TOO_BIG] Uploaded file size must not exceed 2 megabytes."
    },
    content_type: {
      content_type: /
        image\/(png|jpe?g)
        |application\/(pdf|html|vnd.ms-excel)
        |application\/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        |application\/vnd.google-apps.spreadsheet
        |text\/(plain|html|csv)
      /x,
      message: "[ATMT_BAD_TYPE] Uploaded files can only be of type png, jp(e)g, pdf, html, text, .xslx, or csv."
    }
  }

  def absolute_item_url
    Pibi::Util.encode_url(ActionController::Base.asset_host + item.url)
  end

  private

  def remove_item_file
    if self.item && self.item.path.present?
      begin
        FileUtils.rm(self.item.path)
      rescue Errno::ENOENT
      end
    end
  end
end
