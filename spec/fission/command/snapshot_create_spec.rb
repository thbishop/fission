require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotCreate do
  before do
    @target_vm = ['foo']
    @vm_mock = mock('vm_mock')
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @all_running_response_mock = mock('all_running')
    @snap_create_response_mock = mock('response')
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
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM 'foo' is not running/
      @string_io.string.should match /A snapshot cannot be created unless the VM is running/
    end

    it "should output an error and exit if there is already a snapshot with the provided name"  do
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([@target_vm.first])
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      @vm_mock.should_receive(:snapshots).and_return(['snap_1'])
      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM 'foo' already has a snapshot named 'snap_1'/
    end

    it 'should output an error and exit if there is an error getting the list of running VMs' do
      @all_running_response_mock.should_receive(:successful?).and_return(false)
      @all_running_response_mock.should_receive(:code).and_return(1)
      @all_running_response_mock.should_receive(:output).and_return('it blew up')
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      lambda {
        command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /There was an error determining if this VM is running.+\n#{'it blew up'}/m
    end

    it 'should create a new snapshot with the provided name' do
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([@target_vm.first])
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      @snap_create_response_mock.should_receive(:successful?).and_return(true)
      @vm_mock.should_receive(:snapshots).and_return([])
      @vm_mock.should_receive(:create_snapshot).with('snap_1').and_return(@snap_create_response_mock)

      command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
      command.execute

      @string_io.string.should match /Creating snapshot/
      @string_io.string.should match /Snapshot 'snap_1' created/
    end

    it 'should output an error and exit if there was an error creating the snapshot' do
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([@target_vm.first])
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      @snap_create_response_mock.should_receive(:successful?).and_return(false)
      @snap_create_response_mock.should_receive(:code).and_return(1)
      @snap_create_response_mock.should_receive(:output).and_return('it blew up')
      @vm_mock.should_receive(:snapshots).and_return([])
      @vm_mock.should_receive(:create_snapshot).with('snap_1').and_return(@snap_create_response_mock)

      command = Fission::Command::SnapshotCreate.new @target_vm << 'snap_1'
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Creating snapshot/
      @string_io.string.should match /There was an error creating the snapshot.+it blew up.+/m
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotCreate.help

      output.should match /snapshot create my_vm snapshot_1/
    end
  end
end
