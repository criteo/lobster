require 'lobster/version'

module Lobster
  class Service
    def self.start(config)
      new(config).run
    end

    def initialize(config)
      @job_list = nil
      @running = true
      @sleeping = false
      @main_thread = Thread.current
      @config = config
      @poll_delay = 60

      rout, @wout = IO.pipe
      rerr, @werr = IO.pipe

      Thread.new do
        while (line = rout.gets)
          Lobster.logger.info line.chomp
        end
      end

      Thread.new do
        while (line = rerr.gets)
          Lobster.logger.error line.chomp
        end
      end

      trap 'HUP' do
        begin
          @config = Configuration.new(@config[:lobster_dir], @config[:environment])
        rescue Exception => e
          Lobster.logger.error "Cannot reload conf, Exception: #{e}"
          break
        end
        Lobster.logger.info "Lobster config reloaded: #{@config}"
      end

      at_exit do
        @running = false
        sleep 0.01 until @sleeping # make sure no new jobs are created
       
        Lobster.logger.info  "Exiting, all jobs are getting killed."
        @job_list.jobs.each_value do |job|
          job.kill 'INT'
        end if @job_list

        @main_thread.wakeup # stop sleeping and exit properly
      end
    end

    def run
      Lobster.logger.info "Lobster started version #{Lobster::VERSION}"
      Lobster.logger.info "Lobster config: #{@config}"
      
      while @running
        @sleeping = false
        now = Time.now
        
        reload_schedule

        @job_list.jobs.each_value do |job|
          if not job.running? and now >= job.next_run
            job.run(@wout, @werr, @config[:lobster_dir])
          end
        end
        @sleeping = true
        sleep @poll_delay
      end
    end

    def reload_schedule
      @job_list ||= JobList.new(@config[:schedule_file])
      begin
        @job_list.reload
      rescue Exception => e
        Lobster.logger.error "#{e}: error while reading config file in #{@config[:schedule_file]}, not updating"
      end
    end
  end
end
