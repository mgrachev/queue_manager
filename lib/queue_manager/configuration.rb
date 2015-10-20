module QueueManager
  class Configuration

    IDENTIFIER = 'queue-manager'.freeze

    DEFAULT_CONFIG = {
      wait:                     1,
      delay:                    5,
      timeout:                  15,
      queue:                    'default_queue',
      redis_connection_string:  'redis://localhost:6379/0',
      pid_file:                 File.join('/tmp', 'queue_manager.pid'),
      log_output:               STDOUT
    }

    DEFAULT_CONFIG.each_key do |key|
      attr_writer key                                           # attr_writer :wait

      define_method key do                                      # def wait
        instance_variable_get("@#{key}") || DEFAULT_CONFIG[key] #   @wait || DEFAULT_CONFIG[:wait]
      end                                                       # end
    end

    def identifier
      IDENTIFIER
    end

  end
end