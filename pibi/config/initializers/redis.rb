require 'redis'

Rails.application.config.tap do |config|
  config.redis_instance = Redis.new(config.redis.symbolize_keys)
end