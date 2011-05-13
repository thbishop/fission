require 'yaml'

require 'fission/config'
require 'fission/core_ext/object'

module Fission
  extend self

  def config
    @config ||= Fission::Config.new
  end
end
