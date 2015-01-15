module QueueManager
  class Configuration

    DEFAULT_CONFIG = {
        wait:                     1,
        delay:                    5,
        timeout:                  15,
        queue:                    'default_queue',
        redis_connection_string:  'redis://localhost:6379/0',
        worker:                   nil,
        pid_file:                 File.join('/tmp', 'queue_manager.pid')
    }

    DEFAULT_CONFIG.each_key do |key|
      attr_writer key.to_sym

      define_method key do
        instance_variable_get("@#{key}") || DEFAULT_CONFIG[key]
      end
    end

  end
end