require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CommandHelpers do
  include_context 'command_setup'

  before do
    @object = Object.new
    @object.extend Fission::CommandHelpers
  end

  describe 'ensure_vm_exists' do
    before do
      @vm_mock.stub(:name).and_return('foo')
    end

    it 'should output and exit if the VM does not exist' do
      @vm_mock.should_receive(:exists?).and_return(false)
      @object.should_receive(:output_and_exit).
              with("Unable to find the VM 'foo' (#{Fission::VM.path('foo')})", 1)

      @object.ensure_vm_exists @vm_mock
    end

    it 'should do nothing if the VM exists' do
      @vm_mock.should_receive(:exists?).and_return(true)
      @object.should_not_receive(:output_and_exit)
      @object.should_not_receive(:output)

      @object.ensure_vm_exists @vm_mock
    end

  end

end
