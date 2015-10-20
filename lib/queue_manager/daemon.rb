require 'fileutils'

module QueueManager
  class Daemon
    class << self
      def start
        if running?
          puts 'Queue manager is already running. To stop it, use rake queue_manager:stop'
          return false
        end

        fork do
          $running = true
          File.write(pid_file, Process.pid)
          puts 'Queue manager is running...'

          Signal.trap('TERM') do
            $running = false
            remove_pid_file
          end

          while $running do
            QueueManager::Task.handling_queue
            sleep config.wait
          end
        end
      ensure
        exit!(1)
      end

      def stop
        unless running?
          puts 'Queue manager is not running. To start it, use: rake queue_manager:start'
          return false
        end

        Process.kill('TERM', File.read(pid_file).to_i)
        remove_pid_file
        true
      rescue
        false
      end

      private

      def running?
        File.exist? pid_file
      end

      def remove_pid_file
        FileUtils.rm_rf(pid_file)
      end

      def pid_file
        config.pid_file
      end

      def config
        QueueManager.config
      end
    end
  end
end