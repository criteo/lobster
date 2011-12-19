require 'logger'
require 'lobster/version'

module Lobster
  class Service
    def self.start(dir)
      Lobster.logger = Logger.new(STDOUT)
      new(dir).run
    end

    def initialize(dir)
      @job_list = nil
      @directory = dir || '.'
      @file = File.join(@directory, 'config', 'schedule.rb')
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

      Signal.trap "INT" do
        Lobster.logger.info  "All jobs are getting killed."
        exit 0
      end
    end

    def run
      Lobster.logger.info "Lobster started version #{Lobster::VERSION}"
      Lobster.logger.info "Schedule file: #{@file}"
      Lobster.logger.info "Poll delay: #{@poll_delay}"
      
      loop do
        now = Time.now
        
        reload_config

        @job_list.jobs.each_value do |job|
          if not job.running? and now >= job.next_run
            job.run(@wout, @werr, @directory)
          end
        end
        sleep @poll_delay
      end
    end

    def reload_config
      @job_list ||= JobList.new(@file)
      begin
        @job_list.reload
      rescue Exception => e
        Lobster.logger.error "#{e}: error while reading config file in #{@file}, not updating"
      end
    end
  end
end
