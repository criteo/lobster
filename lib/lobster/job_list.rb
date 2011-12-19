module Lobster
  class JobList
    attr_accessor :jobs

    def initialize(file)
      @file = file
      #@options = {}
      @current_options = nil
      @jobs = {}
    end

    def reload
      @new_jobs = {}
      #@new_options = {}

      instance_eval(File.read(@file),@file)

      # purely for logging
      @jobs.each do |name, job|
        Lobster.logger.info "Job #{name} deleted." unless @new_jobs[name]
      end
      #@options.each do |key, value|
      #  Lobster.logger.info "#{key} unset." unless @new_options[key]
      #end

      @jobs = @new_jobs
      #@options = @new_options
    end

    def job(name)
      @current_options = {}
      yield
      @new_jobs[name] ||= @jobs[name] || Job.new(name)
      @new_jobs[name].reload(@current_options)
      @current_options = nil
    end

    def cmd(command)
      @current_options[:command] = command
    end

    def delay(delay)
      @current_options[:delay] = delay
    end

#    def set(option, value)
#      Lobster.logger.info "set #{option}=#{value}" if value != @options[option]
#      @new_options[option] = value
#    end
#
#    def get(option)
#      @options[option]
#    end
  end
end
