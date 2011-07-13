require 'fileutils'
require 'optparse'
require 'ostruct'
require 'yaml'

$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require 'fission/cli'
require 'fission/command'
require 'fission/command/clone'
require 'fission/command/start'
require 'fission/command/status'
require 'fission/command/stop'
require 'fission/command/suspend'
require 'fission/config'
require 'fission/core_ext/class'
require 'fission/core_ext/file'
require 'fission/core_ext/object'
require 'fission/ui'
require 'fission/vm'
require 'fission/version'

module Fission
  extend self

  def config
    @config ||= Fission::Config.new
  end

  def ui
    @ui ||= Fission::UI.new
  end
end
