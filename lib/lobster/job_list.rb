module Lobster
  class JobList
    attr_accessor :jobs, :environment

    def initialize(file, env)
      @file = file
      @current_options = nil
      @jobs = {}
      @environment = env
    end

    def reload
      @new_jobs = {}

      instance_eval(File.read(@file),@file)

      # purely for logging
      @jobs.each do |name, job|
        Lobster.logger.info "Job #{name} deleted." unless @new_jobs[name]
      end

      @jobs = @new_jobs
    end

    def job(name)
      @current_options = {}
      yield
      @new_jobs[name] ||= @jobs[name] || Job.new(name)
      @new_jobs[name].reload(@current_options)
      @current_options = nil
    end

    [:command, :delay, :user].each do |opt|
      define_method opt do |value|
        @current_options[opt] = value
      end
    end

    # backward compatibility
    def cmd(command)
      @current_options[:command] = command
    end
  end
end
