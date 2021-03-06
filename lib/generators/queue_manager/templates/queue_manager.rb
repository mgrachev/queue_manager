QueueManager.configure do |config|
  # Waiting between checking queue
  # config.wait = 5 # Default: 1 second

  # The delay between the addition of tasks in the queue and the start of its processing
  # config.delay = 3 # Default: 5 second

  # Timeout after which the task returns to the queue
  # config.timeout = 30 # Default: 15 seconds

  # Used queue in redis
  # config.queue = 'example' # Default: default_queue

  # URL for connection to redis
  # config.redis_connection_string = 'redis://example.com:6379/0' # Default: redis://localhost:6379/0

  # Path to pid file
  config.pid_file = Rails.root.join('tmp', 'pids', 'queue_manager.pid') # Default: /tmp/queue_manager.pid

  # Log output
  config.log_output = Rails.root.join('log', 'queue_manager.log') # Default: STDOUT
end
