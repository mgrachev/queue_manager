module QueueManager
  class Task
    include QueueManager::Redis

    MARKER = '*'
    MARKED_REGEXP = Regexp.new("^#{92.chr}#{MARKER}") # /^\*/
    ENQUEUES = [:now, :later]

    #
    # Add a new task to the queue
    #
    # @param id [String] The unique identifier of the task
    # @param job [Symbol] Job class name
    # @param enqueue [Symbol] Now or later
    # @param options [Hash] Hash of additional options
    #
    # @return [QueueManager::Task] Instance of QueueManager::Task
    #
    def self.add(id, job:, enqueue: :now, **options)
      # TODO test
      raise ArgumentError, "Option enqueue should be #{ENQUEUES.join(' or ')}" unless ENQUEUES.include?(enqueue)

      transaction do
        time = redis.zscore(config.queue, "#{MARKER}#{id}") || timestamp
        score = time + config.delay

        task = new(id, score)
        task.job = job
        task.enqueue = enqueue
        task.options = options

        redis.multi do
          redis.zadd(config.queue, score, id)
        end

        # TODO: Test
        return task
      end
    end
    alias_method :create, :add

    #
    # Check the queue and run tasks
    #
    def self.handling_queue
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

        # TODO test
        task = new(id, score)
        task.score = new_score
        task.job.to_s.constantize.public_send("perform_#{task.enqueue}", task, id, **task.options)
      end
    end

    # Instance of QueueManager::Task provides detailed information about the task
    # and allows you to manage it. You can change a job of the task, pass additional
    # parameters or delete the task.

    attr_reader :id
    attr_accessor :score

    #
    # @param id [String] The unique identifier of the task
    # @param score [Fixnum] Timestamp of the task
    #
    def initialize(id, score)
      @id, @score = id, score
    end

    %w(job enqueue options).each do |name|
      define_method "#{name}=" do |value|   # def job=(value)
        redis.set("#{key}/#{name}", value)  #   redis.set("#{key}/job", value)
      end                                   # end

      define_method name do                 # def job
        redis.get("#{key}/#{name}")         #   redis.get("#{key}/job")
      end                                   # end
    end

    #
    # Remove task from the queue by score
    #
    # @return [Boolean] True or false
    #
    def remove
      transaction do
        marked_id = "#{MARKER}#{id}"
        redis_score = redis.zscore(config.queue, marked_id)

        if score.to_i == redis_score.to_i
          redis.multi do
            # TODO: Test
            %w(job enqueue options).each do |name|
              redis.del("#{key}/#{name}")
            end

            redis.zrem(config.queue, marked_id)
            # TODO: Test
            return true
          end
        else
          # TODO: Test
          return false
        end
      end
    end
    alias_method :done, :remove
    alias_method :delete, :remove

    private

    def key
      "#{config.queue}/#{id}/#{score}"
    end

  end
end