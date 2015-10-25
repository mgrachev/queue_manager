module QueueManager
  class TaskLocator
    def locate(gid)
      QueueManager::Task.new(gid.model_id, gid.params['score'])
    end
  end
end
