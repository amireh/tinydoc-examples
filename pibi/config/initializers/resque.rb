redis_settings = Rails.application.config.redis.symbolize_keys
# Resque 1.x
if Resque::VERSION.to_i == 1
  Resque.redis = Redis.new(redis_settings)

# Resque 2.x
elsif Resque::VERSION.to_i == 2
  Resque.configure do |config|
    # Set the redis connection. Takes any of:
    #   String - a redis url string (e.g., 'redis://host:port')
    #   String - 'hostname:port[:db][/namespace]'
    #   Redis - a redis connection that will be namespaced :resque
    #   Redis::Namespace - a namespaced redis connection that will be used as-is
    #   Redis::Distributed - a distributed redis connection that will be used as-is
    #   Hash - a redis connection hash (e.g. {:host => 'localhost', :port => 6379, :db => 0})
    config.redis = Rails.application.config.redis
  end
end