require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/object/json'

module QueueManager
  class Task
    include QueueManager::Util
    include GlobalID::Identification

    MARKER = '*'
    MARKED_REGEXP = Regexp.new("^#{92.chr}#{MARKER}") # /^\*/

    #
    # Add a new task to the queue
    #
    # @param id [String] The unique identifier of the task
    # @param job [Symbol] Job class name
    # @param options [Hash] Hash of additional options
    #
    # @return [QueueManager::Task] Instance of QueueManager::Task
    #
    def self.add(id, job:, **options)
      fail ArgumentError, 'Job should be present' unless job

      transaction do
        time = redis.zscore(config.queue, "#{MARKER}#{id}") || timestamp
        score = time + config.delay

        task = new(id, score)
        task.job = job
        task.options = options.to_json

        redis.multi do
          redis.zadd(config.queue, score, id)
        end

        logger.info "Add new task \"#{id}\" with job: \"#{job}\""
        return task
      end
    end

    #
    # Check the queue and run tasks
    #
    def self.handling_queue
      # Return the first element from range
      id, score = redis.zrange(config.queue, 0, 0, with_scores: true).flatten

      return false if id.blank? && score.blank?
      return false if score > timestamp

      new_score = timestamp + config.timeout

      if MARKED_REGEXP =~ id
        redis.zadd(config.queue, new_score, id)
        logger.info "Time is over for the task \"#{id}\". Updated time"
      else
        redis.zrem(config.queue, id)
        redis.zadd(config.queue, new_score, "#{MARKER}#{id}")
        logger.info "Task \"#{id}\" is taken into work"
      end

      original_id = id.tr('*', '')
      task = new(original_id, score.to_i)
      task.update_score(new_score)
      options = JSON.load(task.options).symbolize_keys

      task.job.constantize.public_send(:perform_later, task, original_id, **options)
      logger.info "Launched job: #{task.job}.perform_later(task, \"#{original_id}\", #{options})"
    end

    # Instance of QueueManager::Task provides detailed information about the task
    # and allows you to manage it. You can change a job of the task, pass additional
    # parameters or delete the task.

    attr_reader :id, :score

    #
    # @param id [String] The unique identifier of the task
    # @param score [Fixnum] Timestamp of the task
    #
    def initialize(id, score)
      @id = id
      @score = score
    end

    def update_score(value)
      transaction do
        old_job = job
        old_options = options

        redis.multi do
          clear_task
          @score = value
          self.job = old_job
          self.options = old_options
        end
      end
    end

    %w(job options).each do |name|
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

        return false unless score.to_i == redis_score.to_i

        redis.multi do
          clear_task
          redis.zrem(config.queue, marked_id)
        end

        logger.info "The task \"#{id}\" is removed from the queue"
      end
      true
    end
    alias_method :done, :remove
    alias_method :delete, :remove

    #
    # Convert task to global id
    #
    # @return [GlobalID] Instance of GlobalID
    #
    def to_global_id
      GlobalID.create(self, app: config.identifier, score: score)
    end

    private

    def clear_task
      %w(job options).each do |name|
        redis.del("#{key}/#{name}")
      end
    end

    def key
      "#{config.queue}/#{id}/#{score}"
    end
  end
end
