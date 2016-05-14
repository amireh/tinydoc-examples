module TokenGenerator
  class << self
    def urlsafe_token
      Base64.urlsafe_encode64(SecureRandom.hex(16))
    end
  end
end