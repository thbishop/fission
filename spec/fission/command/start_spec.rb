require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Start do
  before :all do
    @vm_info = ['foo']
  end

  before :each do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Start.should_receive(:help)

      lambda {
        command = Fission::Command::Start.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for start command/
    end

    it "should output an error and exit if it can't find the vm" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(false)

      lambda {
        command = Fission::Command::Start.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@vm_info.first}/
    end


    it "should output and exit if the vm is already running" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@vm_info)

      lambda {
        command = Fission::Command::Start.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM '#{@vm_info.first}' is already running/
    end

    it 'should try to start the vm if it is not running' do
      @vm_mock = mock('vm_mock')
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return([])
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @vm_mock.should_receive(:start)

      command = Fission::Command::Start.new @vm_info
      command.execute

      @string_io.string.should match /Starting '#{@vm_info.first}'/
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Start.help

      output.should match /start vm/
    end
  end
end
