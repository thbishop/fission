require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Delete do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    @delete_response_mock = mock('delete_response')
  end

  describe "execute" do
    subject { Fission::Command::Delete }

    it_should_not_accept_arguments_of [], 'delete'

    it "should output an error and exit if it can't find the target vm" do
      @exists_response_mock.stub_as_successful false
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)

      command = Fission::Command::Delete.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@target_vm.first}'/
    end

    describe 'when the VM exits' do
      before do
        @exists_response_mock.stub_as_successful true
        Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                             and_return(@exists_response_mock)
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      end

      it "should try to delete the vm if it exists" do
        @delete_response_mock.stub_as_successful
        @all_running_response_mock.stub_as_successful []
        @fusion_running_response_mock.stub_as_successful false
        @vm_mock.should_receive(:delete).and_return(@delete_response_mock)

        Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)
        Fission::VM.should_receive(:new).with(@target_vm.first).and_return(@vm_mock)

        command = Fission::Command::Delete.new @target_vm
        command.execute

        @string_io.string.should match /Deletion complete/
      end

      it 'should output an error and exit if there was an error getting the list of running VMs' do
        @all_running_response_mock.stub_as_unsuccessful

        command = Fission::Command::Delete.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error determining if the VM is running.+it blew up.+/m
      end

      it 'should output an error and exit if there was an error deleting the VM' do
        @delete_response_mock.stub_as_unsuccessful
        @all_running_response_mock.stub_as_successful []
        @fusion_running_response_mock.stub_as_successful false
        @vm_mock.should_receive(:delete).and_return(@delete_response_mock)

        Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)
        Fission::VM.should_receive(:new).with(@target_vm.first).and_return(@vm_mock)

        command = Fission::Command::Delete.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error deleting the VM.+it blew up/m
      end

      it 'should output an error and exit if the VM is running' do
        @all_running_response_mock.stub_as_successful ['foo', 'bar']

        command = Fission::Command::Delete.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM is currently running/
        @string_io.string.should match /Either stop\/suspend the VM or use '--force' and try again/
      end

      it 'should output an error and exit if the fusion app is running' do
        @all_running_response_mock.stub_as_successful []
        @fusion_running_response_mock.stub_as_successful true

        Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)

        command = Fission::Command::Delete.new @target_vm
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Fusion GUI is currently running/
        @string_io.string.should match /Either exit the Fusion GUI or use '--force' and try again/
        @string_io.string.should match /NOTE: Forcing a VM deletion with the Fusion GUI running may not clean up all of the VM metadata/
      end

      describe 'with --force' do
        before do
          @vm_mock.should_receive(:delete).and_return(@delete_response_mock)
          Fission::VM.should_receive(:new).with(@target_vm.first).and_return(@vm_mock)
          @delete_response_mock.stub_as_successful true
        end

        it "should stop the VM if it's running and then delete it" do
          @stop_cmd_mock = mock('stop_cmd')

          @stop_cmd_mock.should_receive(:execute)
          @all_running_response_mock.stub_as_successful ['foo', 'bar']

          Fission::Command::Stop.should_receive(:new).with(@target_vm).
                                                      and_return(@stop_cmd_mock)
          command = Fission::Command::Delete.new @target_vm << '--force'
          command.execute

          @string_io.string.should match /VM is currently running/
          @string_io.string.should match /Going to stop it/
          @string_io.string.should match /Deletion complete/
        end

        it 'should output a warning about fusion metadata issue and then delete the VM' do
          @all_running_response_mock.stub_as_successful ['bar']
          @fusion_running_response_mock.stub_as_successful true

          Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)
          command = Fission::Command::Delete.new @target_vm << '--force'
          command.execute

          @string_io.string.should match /Fusion GUI is currently running/
          @string_io.string.should match /metadata for the VM may not be removed completely/
          @string_io.string.should match /Deletion complete/
        end
      end

    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Delete.help

      output.should match /delete vm_name \[--force\]/
      output.should match /--force/
    end
  end
end
