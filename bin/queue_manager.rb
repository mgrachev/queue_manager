require 'queue_manager'

loop do
  QueueManager::Task.handling_queue
  sleep(QueueManager.config.wait)
end