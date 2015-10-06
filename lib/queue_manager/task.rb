require 'active_support/core_ext/object/blank'

module QueueManager
  class Task

    MARKER = '*'
    MARKED_REGEXP = Regexp.new("^#{92.chr}#{MARKER}") # /^\*/

    class << self

      #
      # Add task in redis
      #
      # @param id [String] Unique identifier of task
      #
      # @return [Fixnum] Score
      #
      def add(id)
        transaction do
          time = redis.zscore(config.queue, "#{MARKER}#{id}") || timestamp
          score = time + config.delay

          redis.multi do
            redis.zadd(config.queue, score, id)
          end
          return score
        end
      end

      #
      # Remove task from redis by score
      #
      # @param id [String] Unique identifier of task
      # @param score [String] Score of task
      #
      def remove(id, score)
        transaction do
          marked_id = "#{MARKER}#{id}"
          redis_score = redis.zscore(config.queue, marked_id)

          if score.to_i == redis_score.to_i
            redis.multi do
              redis.zrem(config.queue, marked_id)
            end
          end
        end
      end

      #
      # Check queue and run tasks
      #
      def handling_queue
        transaction do
          # Return the first element from range
          id, score = redis.zrange(config.queue, 0, 0, with_scores: true).flatten

          return false if id.blank? && score.blank?
          return false if score > timestamp

          new_score = timestamp + config.timeout

          redis.multi do
            if MARKED_REGEXP =~ id
              redis.zadd(config.queue, new_score, id)
            else
              redis.zrem(config.queue, id)
              redis.zadd(config.queue, new_score, "#{MARKER}#{id}")
            end
          end

          if config.worker.present?
            config.worker.constantize.perform_async id.gsub(MARKED_REGEXP, '')
          end
        end
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
end
