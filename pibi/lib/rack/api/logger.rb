module Rack::API::Logger
  def log(*args)
    Rails.logger.debug(args.unshift('[Rack::API] ').join)
  end
end