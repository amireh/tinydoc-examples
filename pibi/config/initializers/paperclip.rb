Pibi::Application.configure do
  Paperclip::Attachment.default_options[:path] =
    ":rails_root/public/static/:class/:id_partition/:filename"
  Paperclip::Attachment.default_options[:url] =
    "/static/:class/:id_partition/:filename"

  if Rails.env.test?
    Paperclip::Attachment.default_options[:path] =
      ":rails_root/tmp/test/files/:hash"
  end
end