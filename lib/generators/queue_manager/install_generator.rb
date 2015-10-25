module QueueManager
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_initializer_file
      filename = 'queue_manager.rb'
      copy_file filename, "config/initializers/#{filename}"
    end
  end
end
