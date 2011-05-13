require 'yaml'
require 'fileutils'
require 'optparse'

require 'fission/cli'
require 'fission/command'
require 'fission/command/clone'
require 'fission/config'
require 'fission/core_ext/object'
require 'fission/vm'
require 'fission/version'

module Fission
  extend self

  def config
    @config ||= Fission::Config.new
  end
end
