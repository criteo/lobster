# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lobster/version"

Gem::Specification.new do |s|
  s.name        = "lobster"
  s.version     = Lobster::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Maxime Brugidou"]
  s.email       = ["m.brugidou@criteo.com"]
  s.homepage    = ""
  s.summary     = %q{Simple loop job runner service.}
  s.description = %q{}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/{functional,unit}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "daemons", ">= 1.1.4"
  
  #s.add_development_dependency "shoulda", ">= 2.1.1"
end
