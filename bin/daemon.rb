require 'bundler/setup'
require 'daemons'
require 'queue_manager'

options = {
    monitor:            true,
    log_output:         true,
    backtrace:          true,
    output_logfilename: 'custom_output.log',
    logfilename:        'custom_log.log'
}

Daemons.run('bin/queue_manager.rb', options)

# options = {
#   app_name: 'queue_manager',
#   # ontop: true,
#   monitor: true
# }
#
# Daemons.call(options) do
#   loop do
#     QueueManager::Task.handling_queue
#     sleep(QueueManager.config.wait)
#   end
# end