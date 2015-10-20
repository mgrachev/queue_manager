require 'redis'
require 'global_id'
require 'logger'

require_relative 'queue_manager/configuration'
require_relative 'queue_manager/daemon'
require_relative 'queue_manager/util'
require_relative 'queue_manager/task'
require_relative 'queue_manager/version'

module QueueManager
  def config
    @config ||= QueueManager::Configuration.new
  end

  def configure
    yield config
  end

  def add_task(*args)
    Task.add(*args)
  end

  def logger
    $logger ||= Logger.new(config.log_output, 'weekly')
  end

  module_function :config, :configure, :add_task, :logger
end

require_relative 'queue_manager/railtie' if defined? Rails

require_relative 'queue_manager/task_locator'
GlobalID::Locator.use QueueManager.config.identifier, QueueManager::TaskLocator