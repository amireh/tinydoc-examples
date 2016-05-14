settings = Rails.application.config.application[:user]

[ :default_payment_methods, :default_categories ].any? do |required_key|
  unless settings.has_key?(required_key)
    raise "Missing configuration parameter: application[:user][:#{required_key}]"
  end
end

User.default_payment_methods = settings[:default_payment_methods]
User.default_categories = settings[:default_categories]