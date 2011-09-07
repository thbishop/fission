require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotCreate do
  before do
    @target_vm = ['foo']
    @vm_mock = mock('vm_mock')
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    it "should output an error and the help when no vm name is passed in" do
      Fission::Command::SnapshotCreate.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotCreate.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot create command/
    end

    it "should output an error and the help when no snapshot name is passed in" do
      Fission::Command::SnapshotCreate.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot create command/
    end

    it "should output an error and exit if it can't find the target vm" do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(false)

      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@target_vm.first}/
    end

    it 'should output an error and exit if the VM is not running' do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return([])
      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM 'foo' is not running/
      @string_io.string.should match /A snapshot cannot be created unless the VM is running/
    end

    it "should output an error and exit if there is already a snapshot with the provided name"  do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(['foo'])
      @vm_mock.should_receive(:snapshots).and_return(['snap_1'])
      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM 'foo' already has a snapshot named 'snap_1'/
    end

    it 'should create a new snapshot with the provided name' do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(['foo'])
      @vm_mock.should_receive(:snapshots).and_return([])
      @vm_mock.should_receive(:create_snapshot).with('snap_1')
      command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
      command.execute
      @string_io.string.should match /Creating snapshot/
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotCreate.help

      output.should match /snapshot create my_vm snapshot_1/
    end
  end
end
