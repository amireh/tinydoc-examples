Pibi::Application.configure do
  settings = config.mailer

  config.action_mailer.delivery_method = settings[:delivery_method].to_sym

  case settings[:delivery_method].to_sym
  when :sendmail
    config.action_mailer.sendmail_settings = settings[:sendmail_settings].symbolize_keys
  when :smtp
    config.action_mailer.smtp_settings = settings[:smtp_settings].symbolize_keys
  end

  if settings.has_key? :perform_deliveries
    config.action_mailer.perform_deliveries = settings[:perform_deliveries]
  end

  if settings.has_key? :raise_delivery_errors
    config.action_mailer.raise_delivery_errors = settings[:raise_delivery_errors]
  end

  config.action_mailer.default_options = settings[:default_options].symbolize_keys
  config.action_mailer.default_url_options = { host: settings[:host] }
end