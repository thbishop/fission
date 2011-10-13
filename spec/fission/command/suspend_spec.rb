require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Suspend do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    Fission::VM.stub(:new).and_return(@vm_mock)
    @suspend_response_mock = mock('suspend_response')

    @vm_mock.stub(:exists?).and_return(@exists_response_mock)
    @vm_mock.stub(:name).and_return(@target_vm.first)
    @vm_mock.stub(:state).and_return(@state_response_mock)
  end

  describe 'execute' do
    subject { Fission::Command::Suspend }

    it_should_not_accept_arguments_of [], 'suspend'

    it "should output an error and exit if it can't find the VM" do
      @exists_response_mock.stub_as_successful false

      command = Fission::Command::Suspend.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@target_vm.first}'/
    end

    describe 'when the VM exists' do
      before do
        @exists_response_mock.stub_as_successful true
      end

      it "should output and exit if the vm is not running" do
        @state_response_mock.stub_as_successful 'not running'

        command = Fission::Command::Suspend.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM '#{@target_vm.first}' is not running/
      end

      it 'should try to suspend the vm if it is running' do
        @state_response_mock.stub_as_successful 'running'
        @suspend_response_mock.stub_as_successful

        @vm_mock.should_receive(:suspend).and_return(@suspend_response_mock)

        command = Fission::Command::Suspend.new @target_vm
        command.execute

        @string_io.string.should match /Suspending '#{@target_vm.first}'/
        @string_io.string.should match /VM '#{@target_vm.first}' suspended/
      end

      it 'should print an error and exit if there was an error getting the list of running VMs' do
        @state_response_mock.stub_as_unsuccessful# 'running'

        command = Fission::Command::Suspend.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error getting the list of running VMs.+it blew up/m
      end
    end

    describe 'with --all' do
      before do
        @vm_mock_1 = mock('vm_mock_1')
        @vm_mock_2 = mock('vm_mock_2')
        @vm_1_state = mock('vm_1_state')
        @vm_2_state = mock('vm_2_state')

        @vm_mock_1.stub(:state).and_return(@vm_1_state)
        @vm_mock_1.stub(:name).and_return('vm_1')
        @vm_mock_2.stub(:state).and_return(@vm_2_state)
        @vm_mock_2.stub(:name).and_return('vm_2')

        @vm_items = {'vm_1' => @vm_mock_1,
                     'vm_2' => @vm_mock_2
        }
      end

      it 'should suspend all running VMs' do
        @vm_1_state.stub_as_successful 'running'
        @vm_2_state.stub_as_successful 'running'
        @all_running_response_mock.stub_as_successful @vm_items.values
        @suspend_response_mock.stub_as_successful

        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

        @vm_items.each_pair do |name, mock|
          mock.should_receive(:suspend).and_return(@suspend_response_mock)
        end

        command = Fission::Command::Suspend.new ['--all']
        command.execute

        @vm_items.keys.each do |vm|
          @string_io.string.should match /Suspending '#{vm}'/
          @string_io.string.should match /VM '#{vm}' suspended/
        end
      end
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Suspend.help

      output.should match /suspend \[vm_name \| --all\]/
    end
  end
end
