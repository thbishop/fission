require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotRevert do
  before do
    @target_vm = ['foo']
    @vm_mock = mock('vm_mock')
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    it "should output an error and the help when no vm name is passed in" do
      Fission::Command::SnapshotRevert.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotRevert.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot revert command/
    end

    it "should output an error and the help when no snapshot name is passed in" do
      Fission::Command::SnapshotRevert.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot revert command/
    end

    it "should output an error and exit if it can't find the target vm" do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(false)

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@target_vm.first}/
    end

    it "should output an error and exit if it can't find the snapshot" do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::Fusion.should_receive(:is_running?).and_return(false)
      @vm_mock.should_receive(:snapshots).and_return([])

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the snapshot 'snap_1'/
    end

    it 'should output an error and exit if the fusion app is running' do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::Fusion.should_receive(:is_running?).and_return(true)

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Fusion GUI is currently running/
      @string_io.string.should match /Please exit the Fusion GUI and try again/
    end

    it 'should revert to the snapshot with the provided name' do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      @vm_mock.should_receive(:snapshots).and_return(['snap_1', 'snap_2'])
      @vm_mock.should_receive(:revert_to_snapshot).with('snap_1')
      command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
      command.execute
      @string_io.string.should match /Reverting to snapshot 'snap_1'/
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotRevert.help

      output.should match /snapshot revert my_vm snapshot_1/
    end
  end
end
