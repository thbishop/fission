require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CommandHelpers do
  include_context 'command_setup'

  before do
    @object = Object.new
    @object.extend Fission::CommandHelpers
  end

  describe 'ensure_vm_exists' do
    it 'should output and exit if the VM does not exist' do
      @exists_response_mock.stub_as_successful false

      Fission::VM.should_receive(:exists?).with('foo').and_return(@exists_response_mock)

      @object.should_receive(:output_and_exit).
              with("Unable to find the VM 'foo' (#{Fission::VM.path('foo')})", 1)
      @object.ensure_vm_exists 'foo'
    end
  end

end
