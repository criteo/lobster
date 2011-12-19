module Lobster
  class Job
    attr_accessor :next_run

    def initialize(name)
      @name = name
      Lobster.logger.info "Job #{name} created."
      @pid = nil
    end

    def reload(options)
      options[:delay] ||= 10

      if options[:command] != @command
        Lobster.logger.info "Job command updated for #{@name}, was \"#{@command}\", now \"#{options[:command]}\"" if @command
        @command = options.delete(:command)
      end
      
      if options[:delay] != @delay
        Lobster.logger.info "Job delay updated for #{@name}, was \"#{@delay}\", now \"#{options[:delay]}\"" if @delay
        @delay = options.delete(:delay)
        @next_run = nil unless running?
      end

      @name ||= "<unnamed_job_#{command.hash.abs}>"
      @next_run ||= Time.now + rand(@delay*60)
    end

    def running?
      return false if @pid.nil?
      if Process.wait @pid, Process::WNOHANG
        Lobster.logger.error "Job #{@name} Failed with status #{$?}" unless $?.success?
        @pid = nil
        @next_run = Time.now + @delay*60
        false
      else
        true
      end
    end

    def run(out,err,dir)
      Lobster.logger.info "Starting job #{@name} from directory #{dir}"
      begin
        @pid = spawn(@command, :out=>out, :err=>err, :chdir=>dir)
      rescue Exception => e
        Lobster.logger.error "#{e}: error when starting job #{@name}"
        @next_run = Time.now + 10
      end
    end
  end
end
