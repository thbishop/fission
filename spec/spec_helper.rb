require 'rspec'
require 'fission'
require 'fakefs/safe'
Dir[File.expand_path(File.join(File.dirname(__FILE__),'matchers','*.rb'))].each {|f| require f}
