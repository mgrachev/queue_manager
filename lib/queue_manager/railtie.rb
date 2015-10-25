module QueueManager
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/queue_manager.rake', __FILE__)
    end
  end
end
