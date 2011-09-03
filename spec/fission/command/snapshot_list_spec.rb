require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotList do
  before :each do
    @target_vm = ['foo']
    @vm_mock = mock('vm_mock')
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::SnapshotList.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotList.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot list command/
    end

    it "should output an error and exit if it can't find the target vm" do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(false)

      lambda {
        command = Fission::Command::SnapshotList.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@target_vm.first}/
    end

    it 'should output the list of snapshots if any exist' do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      @vm_mock.should_receive(:snapshots).and_return(['snap 1', 'snap 2', 'snap 3'])
      command = Fission::Command::SnapshotList.new @target_vm
      command.execute

      @string_io.string.should match /snap 1\nsnap 2\nsnap 3\n/
    end

    it 'should output that it could not find any snapshots if none exist' do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      @vm_mock.should_receive(:snapshots).and_return([])
      command = Fission::Command::SnapshotList.new @target_vm
      command.execute

      @string_io.string.should match /No snapshots found for VM '#{@target_vm.first}'/
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotList.help

      output.should match /snapshot list/
    end
  end
end
