require_relative 'queue_manager/configuration'

module QueueManager

  def self.config
    @config ||= QueueManager::Configuration.new
  end

  def self.configure
    yield config
  end

end

require_relative 'queue_manager/daemon'
require_relative 'queue_manager/task'
require_relative 'queue_manager/version'