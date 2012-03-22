module Lobster
  class JobList
    attr_accessor :jobs

    def initialize(config)
      @config = config
      @current_options = nil
      @jobs = {}
    end

    def reload
      @new_jobs = {}

      file = @config[:schedule_file]
      instance_eval(File.read(file),file)

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
      @new_jobs[name].reload(@current_options, @config[:lobster_dir])
      @current_options = nil
    end

    [:command, :delay, :user, :directory].each do |opt|
      define_method opt do |value|
        @current_options[opt] = value
      end
    end

    # backward compatibility
    def cmd(command)
      @current_options[:command] = command
    end

    # config data
    def environment
      @config[:environment]
    end
  end
end
