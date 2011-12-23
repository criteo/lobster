require 'logger'

module Lobster
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  autoload :Configuration, 'lobster/configuration'
  autoload :JobList,  'lobster/job_list'
  autoload :Job,      'lobster/job'
  autoload :Service,  'lobster/service'
end
