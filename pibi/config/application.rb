require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"

Bundler.require(:default, Rails.env)

module Pibi
  class Application < Rails::Application
    config.time_zone = ENV['TZ'] = Time.zone = 'UTC'

    config.middleware.delete "Rack::Lock"
    config.middleware.delete "ActionDispatch::Flash"
    config.middleware.delete "Rack::MethodOverride"
    config.middleware.insert_before ActionDispatch::ParamsParser, "CatchJsonParseErrors"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    # Disable the asset pipeline.
    config.assets.enabled = false

    config.autoload_paths += Dir["#{config.root}/lib/"]
    config.eager_load_paths += ["#{Rails.root}/lib"]

    Dir["#{config.root}/config/*.yml"].each do |config_file|
      context = File.basename(config_file.gsub(/\.yml$/, ''))
      context_cfg = YAML.load_file(config_file).with_indifferent_access

      if context_cfg[Rails.env] && context_cfg[Rails.env][context]
        context_cfg = context_cfg[Rails.env][context]
      end

      config.send "#{context}=", context_cfg
    end
  end
end
