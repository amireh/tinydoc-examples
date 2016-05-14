Resque::Mailer.default_queue_name = 'pibi_mailer'
Resque::Mailer.error_handler = lambda { |mailer, message, error, action, args|
  # Necessary to re-enqueue jobs that receieve the SIGTERM signal
  if error.is_a?(Resque::TermException)
    Resque.enqueue(mailer, action, *args)
  else
    raise error
  end
}

Resque::Mailer.excluded_environments = [:test]