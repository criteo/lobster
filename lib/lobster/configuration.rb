require 'yaml'

module Lobster
  class Configuration
    def initialize(dir, env)
      @config = {
        :monitor => true,
        :log_dir => File.join(dir, 'log'),
        :pid_dir => File.join('/', 'var', 'run', 'lobster'),
	:schedule_file => File.join(dir, 'config', 'schedule.rb')
      }

      config_file_path = File.join(dir, 'config', 'lobster.yml')
      if File.exist? config_file_path
        config_file = YAML.load_file(config_file_path)
        @config.keys.each do |key|
          @config[key] = config_file[env][key] || config_file[key] || @config[key]
        end
      end

      @config[:lobster_dir] = dir
      @config[:environment] = env
    end
    
    def [](key)
      @config[key]
    end
    
    def to_s
      @config.to_s
    end
  end
end
