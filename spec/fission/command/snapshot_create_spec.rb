require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotCreate do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @snap_create_response_mock = mock('snap_create_response')
    @snap_list_response_mock = mock('snap_list_response')
  end

  describe 'execute' do
    subject { Fission::Command::SnapshotCreate }

    it_should_not_accept_arguments_of [], 'snapshot create'

    it "should output an error and the help when no snapshot name is passed in" do
      Fission::Command::SnapshotCreate.should_receive(:help)

      command = Fission::Command::SnapshotCreate.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot create command/
    end

    it "should output an error and exit if it can't find the target vm" do
      @exists_response_mock.stub_as_successful false
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)

      command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@target_vm.first}'/
    end

    describe 'when the VM exists' do
      before do
        @exists_response_mock.stub_as_successful true
        Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                             and_return(@exists_response_mock)
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      end

      it 'should output an error and exit if the VM is not running' do
        @all_running_response_mock.stub_as_successful []

        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM 'foo' is not running/
        @string_io.string.should match /A snapshot cannot be created unless the VM is running/
      end

      it 'should output an error and exit if there is was an error getting the list of snapshots' do
        @all_running_response_mock.stub_as_successful [@target_vm.first]
        @snap_list_response_mock.stub_as_unsuccessful

        @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)

        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error getting the list of snapshots.+it blew up.+/m
      end

      it "should output an error and exit if there is already a snapshot with the provided name"  do
        @all_running_response_mock.stub_as_successful [@target_vm.first]
        @snap_list_response_mock.stub_as_successful ['snap_1']

        @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)

        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM 'foo' already has a snapshot named 'snap_1'/
      end

      it 'should output an error and exit if there is an error getting the list of running VMs' do
        @all_running_response_mock.stub_as_unsuccessful

        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error determining if this VM is running.+\n#{'it blew up'}/m
      end

      it 'should create a new snapshot with the provided name' do
        @all_running_response_mock.stub_as_successful [@target_vm.first]
        @snap_create_response_mock.stub_as_successful []
        @snap_list_response_mock.stub_as_successful []

        @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)
        @vm_mock.should_receive(:create_snapshot).with('snap_1').
                                                  and_return(@snap_create_response_mock)

        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute

        @string_io.string.should match /Creating snapshot/
        @string_io.string.should match /Snapshot 'snap_1' created/
      end

      it 'should output an error and exit if there was an error creating the snapshot' do
        @all_running_response_mock.stub_as_successful [@target_vm.first]
        @snap_create_response_mock.stub_as_unsuccessful
        @snap_list_response_mock.stub_as_successful []

        @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)
        @vm_mock.should_receive(:create_snapshot).with('snap_1').
                                                  and_return(@snap_create_response_mock)

        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Creating snapshot/
        @string_io.string.should match /There was an error creating the snapshot.+it blew up.+/m
      end
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotCreate.help

      output.should match /snapshot create vm_name snapshot_1/
    end
  end
end
