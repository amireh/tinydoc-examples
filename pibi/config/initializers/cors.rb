settings = Rails.application.config.cors

Rails.application.config.middleware.insert_after Rails::Rack::Logger,
Rack::Cors, :logger => Rails.logger do
  allow do
    origins settings[:origin]
    resource '*',
      headers: settings[:headers],
      methods: [ :get, :post, :put, :patch, :delete, :options ],
      expose:  settings[:exposed],
      max_age: settings[:preflight_age].to_i,
      credentials: true
  end
end