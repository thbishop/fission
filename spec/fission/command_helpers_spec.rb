require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CommandHelpers do
  include_context 'command_setup'

  before do
    @object = Object.new
    @object.extend Fission::CommandHelpers
  end

end
