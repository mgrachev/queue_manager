require 'fileutils'

module QueueManager
  class Daemon
    class << self

      PID_FILE = Rails.root.join('tmp', 'pids', 'queue_manager.pid')

      def start
        if running?
          puts 'Queue manager is already running. Use: QueueManager::Daemon.stop'
          return false
        end

        fork do
          $running = true
          File.write(PID_FILE, Process.pid)
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

        Process.kill('TERM', File.read(PID_FILE).to_i)
        FileUtils.rm_rf(PID_FILE)
        true
      rescue
        false
      end

      private

      def running?
        File.exist? PID_FILE
      end

    end
  end
end