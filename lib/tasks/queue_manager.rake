namespace :queue_manager do
  desc 'Start queue manager daemon'
  task start: :environment do
    QueueManager::Daemon.start
  end

  desc 'Stop queue manager daemon'
  task stop: :environment do
    QueueManager::Daemon.stop
  end

end
