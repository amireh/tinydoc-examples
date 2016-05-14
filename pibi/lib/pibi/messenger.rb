module Pibi::Messenger
  # Send a targeted message to a user via Faye.
  #
  # @param [String] user_id
  # @param [String] code
  #   Unique message identifier. This must be properly documented so that
  #   Pibi.js can identify and listen to this message.
  #
  # @param [Hash] params (optional)
  #   Any message-specific parameters you'd like to pass along.
  def self.publish(user_id, code, params, options={})
    config = Rails.application.config.redis
    redis = Redis.new(config)
    redis.publish(config[:channel], {
      user_id: user_id,
      client_id: options[:client_id],
      code: code,
      params: params
    }.to_json)
  end
end