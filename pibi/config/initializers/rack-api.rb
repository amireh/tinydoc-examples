ActiveSupport.on_load(:action_controller) do |controller|
  controller.before_filter do
    Rack::API.instance = self
  end

  # controller.rescue_from Rack::API::Error, with: :render_error
end