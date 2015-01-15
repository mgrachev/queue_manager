require 'fileutils'

module QueueManager
  class Daemon
    class << self

      def start
        if running?
          puts 'Queue manager is already running. Use: QueueManager::Daemon.stop'
          return false
        end

        fork do
          $running = true
          File.write(QueueManager.config.pid_file, Process.pid)
          puts 'Queue manager is running...'

          Signal.trap('TERM') { $running = false }
          while $running do
            QueueManager::Task.handling_queue
            sleep(QueueManager.config.wait)
          end
        end
      ensure
        exit!(1)
      end

      def stop
        unless running?
          puts 'Queue manager is not running. Use: QueueManager::Daemon.start'
          return false
        end

        Process.kill('TERM', File.read(QueueManager.config.pid_file).to_i)
        FileUtils.rm_rf(QueueManager.config.pid_file)
        true
      rescue
        false
      end

      private

      def running?
        File.exist? QueueManager.config.pid_file
      end

    end
  end
end