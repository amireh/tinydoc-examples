# Totally shamelessly stolen from:
# http://robots.thoughtbot.com/catching-json-parse-errors-with-custom-middleware
class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      if env['HTTP_ACCEPT'] =~ /application\/json/
        error_output = "There was a problem in the JSON you submitted: #{error}"
        return [
          400,
          { "Content-Type" => "application/json" },
          [ { status: 400, error: error_output }.to_json ]
        ]
      else
        return [
          400,
          { "Content-Type" => "text/plain" },
          [ "Only JSON is accepted as an input format." ]
        ]
      end
    end
  end
end