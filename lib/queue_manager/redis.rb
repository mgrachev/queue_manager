module QueueManager
  module Redis
    def self.included(base)
      base.extend self
    end

    private

    def redis
      $redis ||= Redis.new(url: config.redis_connection_string)
    end

    def timestamp
      redis.time[0].to_i
    end

    def transaction(&block)
      redis.watch(config.queue)
      block.call
      redis.unwatch
    end

    def config
      QueueManager.config
    end
  end
end