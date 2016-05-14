Journal::Output.error_formatter = lambda do |error|
  status, message = nil, nil

  if error.is_a?(String)
    code = error
    status, message = case code
    when Journal::EC_RESOURCE_GONE
      [404, 'Resource no longer exists.']
    when Journal::EC_RESOURCE_OVERWRITTEN
      [407, 'That resource had already been created.']
    when Journal::EC_RESOURCE_NOT_FOUND
      [404, 'Resource could not be found.']
    when Journal::EC_REFERENCE_NOT_FOUND
      [404, 'An associated resource could not be found.']
    when Journal::EC_UNAUTHORIZED
      [403, 'You are not authorized to perform this action.']
    when Journal::EC_INTERNAL_ERROR
      [500, 'An internal error has occurred.']
    else
      [500, code ]
    end

    message = "[#{code}] #{message}"
  else
    status = 400
    message = error
  end

  Rack::API::Error.new(status, message).as_json
end