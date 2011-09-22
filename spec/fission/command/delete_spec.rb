require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Delete do
  before do
    @target_vm = ['foo']
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @exists_response_mock = mock('exists_response')
    @all_running_response_mock = mock('all_running_response')
  end

  describe "execute" do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Delete.should_receive(:help)

      lambda {
        command = Fission::Command::Delete.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for delete command/
    end

    it "should output an error and exit if it can't find the target vm" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(false)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)

      lambda {
        command = Fission::Command::Delete.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find target vm #{@target_vm}/
    end

    it "should try to delete the vm if it exists" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::Fusion.should_receive(:is_running?).and_return(false)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::VM.should_receive(:delete).with(@target_vm.first)
      command = Fission::Command::Delete.new @target_vm
      command.execute
      @string_io.string.should match /Deletion complete/
    end

    it 'should output an error and exit if the VM is running' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return(['foo', 'bar'])
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      lambda {
        command = Fission::Command::Delete.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM is currently running/
      @string_io.string.should match /Either stop\/suspend the VM or use '--force' and try again/
    end

    it 'should output an error and exit if the fusion app is running' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::Fusion.should_receive(:is_running?).and_return(true)

      lambda {
        command = Fission::Command::Delete.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Fusion GUI is currently running/
      @string_io.string.should match /Either exit the Fusion GUI or use '--force' and try again/
      @string_io.string.should match /NOTE: Forcing a VM deletion with the Fusion GUI running may not clean up all of the VM metadata/
    end

    describe 'with --force' do
      before do
        @exists_response_mock.should_receive(:successful?).and_return(true)
        @exists_response_mock.should_receive(:data).and_return(true)
        Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                             and_return(@exists_response_mock)
      end

      it "should stop the VM if it's running and then delete it" do
        @stop_cmd_mock = mock('stop_cmd')
        @stop_cmd_mock.should_receive(:execute)
        @all_running_response_mock.should_receive(:successful?).and_return(true)
        @all_running_response_mock.should_receive(:data).and_return(['foo', 'bar'])
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
        Fission::Command::Stop.should_receive(:new).with(@target_vm).
                                                    and_return(@stop_cmd_mock)
        command = Fission::Command::Delete.new @target_vm << '--force'
        command.execute
        @string_io.string.should match /VM is currently running/
        @string_io.string.should match /Going to stop it/
        @string_io.string.should match /Deletion complete/
      end

      it 'should output a warning about fusion metadata issue and then delete the VM' do
        @all_running_response_mock.should_receive(:successful?).and_return(true)
        @all_running_response_mock.should_receive(:data).and_return(['bar'])
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
        Fission::Fusion.should_receive(:is_running?).and_return(true)
        command = Fission::Command::Delete.new @target_vm << '--force'
        command.execute
        @string_io.string.should match /Fusion GUI is currently running/
        @string_io.string.should match /metadata for the VM may not be removed completely/
        @string_io.string.should match /Deletion complete/
      end

    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Delete.help

      output.should match /delete target_vm \[--force\]/
      output.should match /--force/
    end
  end
end
