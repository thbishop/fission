require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotRevert do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    Fission::VM.stub!(:new).and_return(@vm_mock)

    @snap_list_response_mock = mock('snap_list_response')
    @snap_revert_response_mock = mock('snap_revert_response')

    @vm_mock.stub(:exists?).and_return(@exists_response_mock)
    @vm_mock.stub(:name).and_return(@target_vm.first)
  end

  describe 'execute' do
    subject { Fission::Command::SnapshotRevert }

    it_should_not_accept_arguments_of [], 'snapshot revert'

    it "should output an error and the help when no snapshot name is passed in" do
      Fission::Command::SnapshotRevert.should_receive(:help)

      command = Fission::Command::SnapshotRevert.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot revert command/
    end

    it "should output an error and exit if it can't find the target vm" do
      @exists_response_mock.stub_as_successful false

      command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@target_vm.first}'/
    end

    describe 'when the VM exists' do
      before do
        @exists_response_mock.stub_as_successful true
        Fission::Fusion.should_receive(:running?).and_return(@fusion_running_response_mock)
      end

      it 'should output an error and exit if the fusion app is running' do
        @fusion_running_response_mock.stub_as_successful true

        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Fusion GUI is currently running/
        @string_io.string.should match /Please exit the Fusion GUI and try again/
      end

      describe 'when the Fusion app is not running' do
        before do
          @fusion_running_response_mock.stub_as_successful false
          @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)
        end

        it "should output an error and exit if it can't find the snapshot" do
          @snap_list_response_mock.stub_as_successful []

          command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
          lambda { command.execute }.should raise_error SystemExit

          @string_io.string.should match /Unable to find the snapshot 'snap_1'/
        end

        it 'should revert to the snapshot with the provided name' do
          @snap_list_response_mock.stub_as_successful ['snap_1', 'snap_2']
          @snap_revert_response_mock.stub_as_successful

          @vm_mock.should_receive(:revert_to_snapshot).with('snap_1').
                                                       and_return(@snap_revert_response_mock)

          command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
          command.execute

          @string_io.string.should match /Reverting to snapshot 'snap_1'/
          @string_io.string.should match /Reverted to snapshot 'snap_1'/
        end

        it 'should output an error and exit if there was an error getting the list of snapshots' do
          @snap_list_response_mock.stub_as_unsuccessful

          command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
          lambda { command.execute }.should raise_error SystemExit

          @string_io.string.should match /There was an error getting the list of snapshots.+it blew up/m
        end

        it 'should output an error and exit if there was an error reverting to the snapshot' do
          @snap_list_response_mock.stub_as_successful ['snap_1', 'snap_2']
          @snap_revert_response_mock.stub_as_unsuccessful

          @vm_mock.should_receive(:revert_to_snapshot).with('snap_1').
                                                       and_return(@snap_revert_response_mock)

          command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
          lambda { command.execute }.should raise_error SystemExit

          @string_io.string.should match /Reverting to snapshot 'snap_1'/
          @string_io.string.should match /There was an error reverting to the snapshot.+it blew up.+/m
        end
      end
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotRevert.help

      output.should match /snapshot revert vm_name snapshot_1/
    end
  end
end
