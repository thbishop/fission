require 'yaml'
require 'fileutils'

require 'fission/config'
require 'fission/core_ext/object'
require 'fission/vm'

module Fission
  extend self

  def config
    @config ||= Fission::Config.new
  end
end
