require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Stop do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    Fission::VM.stub(:new).and_return(@vm_mock)
    @stop_response_mock = mock('stop_response')

    @vm_mock.stub(:exists?).and_return(@exists_response_mock)
    @vm_mock.stub(:name).and_return(@target_vm.first)
    @vm_mock.stub(:state).and_return(@state_response_mock)
  end

  describe 'execute' do
    subject { Fission::Command::Stop }

    it_should_not_accept_arguments_of [], 'stop'

    it "should output an error and exit if it can't find the vm" do
      @exists_response_mock.stub_as_successful false

      command = Fission::Command::Stop.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@target_vm.first}'/
    end

    describe 'when the VM exists' do
      before do
        @exists_response_mock.stub_as_successful true
      end

      it "should output and exit if the vm is not running" do
        @state_response_mock.stub_as_successful 'not running'

        command = Fission::Command::Stop.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM '#{@target_vm.first}' is not running/
      end

      it 'should output an error and exit if there was an error getting the list of running VMs' do
        @state_response_mock.stub_as_unsuccessful

        command = Fission::Command::Stop.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error determining if the VM is already running.+it blew up.+/m
      end

      it 'should try to stop the vm if it is running' do
        @state_response_mock.stub_as_successful 'running'

        @stop_response_mock.should_receive(:successful?).and_return(true)
        @vm_mock.should_receive(:stop).and_return(@stop_response_mock)

        command = Fission::Command::Stop.new @target_vm
        command.execute

        @string_io.string.should match /Stopping '#{@target_vm.first}'/
        @string_io.string.should match /VM '#{@target_vm.first}' stopped/
      end

      it 'should output an error and exit if there was an error stopping the vm' do
        @state_response_mock.stub_as_successful 'running'
        @stop_response_mock.stub_as_unsuccessful

        @vm_mock.should_receive(:stop).and_return(@stop_response_mock)

        command = Fission::Command::Stop.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Stopping '#{@target_vm.first}'/
        @string_io.string.should match /There was an error stopping the VM.+it blew up.+/m
      end
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Stop.help

      output.should match /stop vm_name/
    end
  end
end
