settings = Rails.application.config.application

DECIMAL_SCALE = 4
DECIMAL_PRECISION = 12
FUDGE_DATES_PRIOR_TO = Time.parse(settings[:fudge_dates_prior_to])
