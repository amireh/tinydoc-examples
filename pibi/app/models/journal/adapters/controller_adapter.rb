class Journal::Adapters::ControllerAdapter < Journal::Adapter
  def initialize
    @dispatcher = ActionDispatch::Integration::Session.new(Rails.application)
    @headers = {
      'Accept' => 'application/json; charset=UTF-8',
      'Content-Type' => 'application/json; charset=UTF-8'
    }

    super()
  end

  def handler_for(controller, action)
    route = Rails.application.routes.set.detect do |route|
      route.requirements[:controller] == controller.to_s &&
      route.requirements[:action] == action.to_s
    end

    if route.present?
      url = route.optimized_path
      verb = route.verb.to_s.gsub(/.*\^|\$.*$/, '').downcase

      factory = lambda { |*args|
        scope = args.shift
        data = args.last || {}

        @dispatcher.send(verb.to_sym, url, data.to_json, @headers)
        @dispatcher.response
      }
    end
  end

end