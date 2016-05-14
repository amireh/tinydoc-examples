rails: bin/rails server -p 9122
resque: bin/rake resque:work QUEUE=* PIDFILE=./tmp/pids/resque.pid INTERVAL=1
scheduler: bin/rake resque:scheduler DYNAMIC_SCHEDULE=1 RESQUE_SCHEDULER_INTERVAL=5 PIDFILE=./tmp/pids/resque-scheduler.pid VERBOSE=1