require 'addressable/uri'

module Pibi::Util
  def self.parse_date(string, default=nil)
    date = Rack::API::ParameterValidators::DateValidator.new.coerce(string)
    date || default
  end

  def self.encode_url(url)
    Addressable::URI.parse(url).normalize.to_str
  end
end