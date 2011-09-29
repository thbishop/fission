require 'rspec'
require 'fission'
require 'fakefs/safe'

['matchers', 'helpers'].each do |dir|
  Dir[File.expand_path(File.join(File.dirname(__FILE__),dir,'*.rb'))].each {|f| require f}
end

include ResponseHelpers
