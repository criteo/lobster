module Lobster
  autoload :JobList,  'lobster/job_list'
  autoload :Job,      'lobster/job'
  autoload :Service,  'lobster/service'

  class << self
    attr_accessor :logger
  end
end
