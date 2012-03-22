module Lobster
  class Job
    attr_accessor :next_run

    def initialize(name)
      @name = name
      Lobster.logger.info "Job #{name} created."
      @pid = nil
    end

    def reload(options, lobster_dir)
      options[:delay] ||= 10
      options[:directory] ||= lobster_dir

      [:command, :delay, :user, :directory].each do |opt|
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

    def run(out,err)
      Lobster.logger.info "Starting job #{@name}"
      command_line = @user ? "sudo -snu #{@user} '#{@command}'" : @command

      begin
        @pid = spawn(command_line, :out=>out, :err=>err, :chdir=> @directory)
      rescue Exception => e
        Lobster.logger.error "#{e}: error when starting job #{@name}"
        @next_run = Time.now + 10
      end
    end
    
    def kill(sig)
      if @pid
        Lobster.logger.info "Killing job #{@name} with pid #{@pid} and all its children"
        kill_tree sig, @pid
      end
    end

    private

    def kill_tree(sig, pid)
      child_parent_processes = `ps -eo pid,ppid | grep #{pid}`
      child_parent_processes = child_parent_processes.split("\n").map do |child_and_parent|
        child_and_parent.strip.split(/\s+/).map(&:to_i)
      end
      child_parent_processes.each do |child, parent|
        if parent == pid
          kill_tree(sig, child)
        end
      end
      
      Lobster.logger.info "Killing pid #{pid}"
      if @user
        `sudo -inu #{@user} "kill -s #{sig} #{pid}"`
      else
        begin
          Process.kill sig, pid
        rescue Errno::ESRCH
          # Process already got killed somehow
        rescue Exception => e
          Lobster.logger.warn "Process #{pid} exception: #{e}"
        end
      end
    end
  end
end
