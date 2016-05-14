# Be sure to restart your server when you modify this file.

require 'action_dispatch/middleware/session/moneta_store'
require 'redis'

redis_settings = Rails.application.config.redis.symbolize_keys
cookie_settings = {
  key: 'pibi.session',
  expire_after: 2.weeks.to_i,
  secure: false
}.merge(Rails.application.config.cookies.symbolize_keys)

Pibi::Application.config.session_store :moneta_store, {
  key: cookie_settings[:key],
  domain: cookie_settings[:domain],
  path: cookie_settings[:path],
  secret: cookie_settings[:secret],
  secure: cookie_settings[:secure],
  expire_after: cookie_settings[:expire_after],
  store: Moneta.new(:Redis, redis_settings)
}
