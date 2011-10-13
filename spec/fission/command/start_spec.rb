require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Start do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    Fission::VM.stub(:new).and_return(@vm_mock)

    @start_response_mock = mock('start_response')

    @vm_mock.stub(:exists?).and_return(@exists_response_mock)
    @vm_mock.stub(:name).and_return(@target_vm.first)
    @vm_mock.stub(:state).and_return(@state_response_mock)
  end

  describe 'execute' do
    subject { Fission::Command::Start }

    it_should_not_accept_arguments_of [], 'start'

    it "should output an error and exit if it can't find the vm" do
      @exists_response_mock.stub_as_successful false

      command = Fission::Command::Start.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@target_vm.first}'/
    end

    describe 'when the VM exists' do
      before do
        @exists_response_mock.stub_as_successful true
      end

      it "should output and exit if the vm is already running" do
        @state_response_mock.stub_as_successful 'running'

        command = Fission::Command::Start.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM '#{@target_vm.first}' is already running/
      end

      it 'should output an error and exit if there was an error getting the list of running VMs' do
        @state_response_mock.stub_as_unsuccessful

        command = Fission::Command::Start.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error determining if the VM is already running.+it blew up.+/m
      end

      it 'should try to start the vm if it is not running' do
        @state_response_mock.stub_as_successful 'not running'
        @start_response_mock.stub_as_successful true

        @vm_mock.should_receive(:start).and_return(@start_response_mock)

        command = Fission::Command::Start.new @target_vm
        command.execute

        @string_io.string.should match /Starting '#{@target_vm.first}'/
        @string_io.string.should match /VM '#{@target_vm.first}' started/
      end

      it 'should output an error and exit if there was an error starting the vm' do
        @state_response_mock.stub_as_successful 'not running'
        @start_response_mock.stub_as_unsuccessful

        @vm_mock.should_receive(:start).and_return(@start_response_mock)

        command = Fission::Command::Start.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Starting '#{@target_vm.first}'/
        @string_io.string.should match /There was a problem starting the VM.+it blew up.+/m
      end

      describe 'with --headless' do
        before do
          Fission::Fusion.should_receive(:running?).and_return(@fusion_running_response_mock)
          @state_response_mock.stub_as_successful 'not running'
        end

        it 'should start the vm headless' do
          @fusion_running_response_mock.stub_as_successful false
          @start_response_mock.stub_as_successful

          @vm_mock.should_receive(:start).and_return(@start_response_mock)

          command = Fission::Command::Start.new @target_vm << '--headless'
          command.execute

          @string_io.string.should match /Starting '#{@target_vm.first}'/
          @string_io.string.should match /VM '#{@target_vm.first}' started/
        end

        it 'should output an error and exit if the fusion app is running' do
          @fusion_running_response_mock.stub_as_successful true

          @vm_mock.should_not_receive(:start)

          command = Fission::Command::Start.new @target_vm << '--headless'
          lambda { command.execute }.should raise_error SystemExit

          @string_io.string.should match /Fusion GUI is currently running/
          @string_io.string.should match /A VM cannot be started in headless mode when the Fusion GUI is running/
          @string_io.string.should match /Exit the Fusion GUI and try again/
        end
      end

    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Start.help

      output.should match /start vm_name \[options\]/
      output.should match /--headless/
    end
  end
end
