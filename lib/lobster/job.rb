module Lobster
  class Job
    attr_accessor :next_run

    OPTIONS = [:command, :delay, :max_duration, :user, :directory]

    def initialize(name)
      @name = name
      Lobster.logger.info "Job #{name} created."
      @pid = nil
    end

    def reload(options, lobster_dir)
      options[:delay] ||= 10
      options[:max_duration] ||= 0
      options[:directory] ||= lobster_dir

      OPTIONS.each do |opt|
        val = instance_variable_get "@#{opt}"
        if options[opt] != val
          Lobster.logger.info "Job #{opt} updated for #{@name}, was \"#{val}\", now \"#{options[opt]}\"" if val
          instance_variable_set "@#{opt}", options.delete(opt)
          # special case: reset @next_run if delay is updated
          @next_run = nil if opt == :delay and not running?
        end
      end
      
      @name ||= "<unnamed_job_#{@command.hash.abs}>"
      @next_run ||= Time.now + rand(@delay*60)
      @last_run ||= Time.now
    end

    def check_last_run
      if @max_duration > 0 and Time.now - @last_run >= (@max_duration + @delay)*60
        Lobster.logger.error(
          "Job #{@name} has not run since #{@last_run}"
        )
      end
    end

    def running?
      return false if @pid.nil?
      if Process.wait @pid, Process::WNOHANG
        if $?.success?
          @last_run = Time.now
        else
          Lobster.logger.error "Job #{@name} Failed with status #{$?}"
        end
        @pid = nil
        close_pipes
        @next_run = Time.now + @delay*60
        false
      else
        true
      end
    end

    def run
      create_pipes

      Lobster.logger.info "Starting job #{@name}"
      command_line = @user ? "sudo -nu #{@user} -- sh -lc 'cd #{@directory}; #{@command}'" : @command

      begin
        @pid = spawn(command_line, :out=>@wout, :err=>@werr, :chdir=> @directory)
      rescue Exception => e
        Lobster.logger.error "#{e}: error when starting job #{@name}"
        close_pipes
        @next_run = Time.now + 10
      end
    end
    
    def kill(sig)
      if @pid
        Lobster.logger.info "Killing job #{@name} with pid #{@pid}"
        if @user
          `sudo -inu #{@user} -- kill -s #{sig} #{@pid}`
        else
          Process.kill sig, @pid
        end
        Process.wait @pid
      end
    end

    def destroy
      Thread.new do
        Lobster.logger.info "Job #{name} being destroyed."
        destroy_time = Time.now
        while running?
          sleep 60
          if ((delay = Time.now - destroy_time) > 60*60)
            Lobster.logger.warn "Job #{name} has not been destroyed after #{delay} seconds."
          end
        end
      end
    end

    private

    def create_pipes
      @rout, @wout = IO.pipe
      @rerr, @werr = IO.pipe

      Thread.new do
        while (line = @rout.gets)
          Lobster.logger.info "#{@name}: #{line.chomp}"
        end
      end

      Thread.new do
        while (line = @rerr.gets)
          Lobster.logger.warn "#{@name}: #{line.chomp}"
        end
      end
    end

    def close_pipes
      @wout.close
      @rout.close
      @werr.close
      @rerr.close
    end
  end
end
