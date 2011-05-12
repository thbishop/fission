# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fission/version"

Gem::Specification.new do |s|
  s.name        = "fission"
  s.version     = Fission::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Tommy Bishop']
  s.email       = ['bishop.thomas@gmail.com']
  s.homepage    = "http://github.com/thbishop/fission"
  s.summary     = %q{Tool to clone VMware fusion VMs}
  s.description = %q{A simple utility to create VMware Fusion VM clones}

  s.rubyforge_project = "fission"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency 'rspec', '~> 2.6.0'
  s.add_development_dependency 'fakefs', '~> 0.3.2'
end
