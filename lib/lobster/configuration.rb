require 'yaml'

module Lobster
  class Configuration
    def initialize(dir, env)
      reload(dir,env)
    end

    def reload(dir, env)
      @config = {
        :monitor => true,
        :log_dir => 'log',
        :pid_dir => 'pids',
        :schedule_file => File.join('config', 'schedule.rb')
      }

      config_file_path = File.join(dir, 'config', 'lobster.yml')
      if File.exist? config_file_path
        config_file = YAML.load_file(config_file_path)
        @config.keys.each do |key|
          val = config_file[env][key.to_s] # environment-specific override
          val = config_file[key.to_s] if val.nil?
          @config[key] = val unless val.nil? # keep default if no config
        end
      end

      # these keys cannot be set by the config file
      @config[:lobster_dir] = dir
      @config[:environment] = env

      # make paths absolute
      [:log_dir, :pid_dir, :schedule_file].each do |k|
        @config[k] = File.absolute_path(@config[k], dir)
      end
    end
    
    def [](key)
      @config[key]
    end
    
    def to_s
      @config.to_s
    end
  end
end
