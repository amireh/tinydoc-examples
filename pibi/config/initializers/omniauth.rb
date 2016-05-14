Rails.application.config.middleware.use OmniAuth::Builder do |config|
  settings = Rails.application.config.oauth

  OmniAuth.config.on_failure = lambda { |env|
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  }

  OmniAuth.config.full_host = settings[:host]

  if Rails.env.test?
    OmniAuth.config.test_mode = true
  end

  unless Rails.env.production?
    provider :developer
  end

  provider :facebook,
    settings['facebook']['key'],
    settings['facebook']['secret']

  provider :google_oauth2,
    settings['google']['key'],
    settings['google']['secret'],
    { access_type: "offline", approval_prompt: "" }
end
