require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Stop do
  before do
    @vm_info = ['foo']
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @all_running_response_mock = mock('all_running_response')
    @start_response_mock = mock('start_response')
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Stop.should_receive(:help)

      lambda {
        command = Fission::Command::Stop.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for stop command/
    end

    it "should output an error and exit if it can't find the vm" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(false)

      lambda {
        command = Fission::Command::Stop.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@vm_info.first}/
    end


    it "should output and exit if the vm is not running" do
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      lambda {
        command = Fission::Command::Stop.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM '#{@vm_info.first}' is not running/
    end

    it 'should output an error and exit if there was an error getting the list of running VMs' do
      @all_running_response_mock.should_receive(:successful?).and_return(false)
      @all_running_response_mock.should_receive(:code).and_return(1)
      @all_running_response_mock.should_receive(:output).and_return('it blew up')
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      command = Fission::Command::Start.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /There was an error determining if the VM is already running.+it blew up.+/m
    end

    it 'should try to stop the vm if it is running' do
      @vm_mock = mock('vm_mock')
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([@vm_info.first])
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @stop_response_mock.should_receive(:successful?).and_return(true)
      @vm_mock.should_receive(:stop).and_return(@stop_response_mock)

      command = Fission::Command::Stop.new @vm_info
      command.execute

      @string_io.string.should match /Stopping '#{@vm_info.first}'/
      @string_io.string.should match /VM '#{@vm_info.first}' stopped/
    end

    it 'should output an error and exit if there was an error stopping the vm' do
      @vm_mock = mock('vm_mock')
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([@vm_info.first])
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @stop_response_mock.should_receive(:successful?).and_return(false)
      @stop_response_mock.should_receive(:code).and_return(1)
      @stop_response_mock.should_receive(:output).and_return('it blew up')
      @vm_mock.should_receive(:stop).and_return(@stop_response_mock)

      command = Fission::Command::Stop.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Stopping '#{@vm_info.first}'/
      @string_io.string.should match /There was an error stopping the VM.+it blew up.+/m
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Stop.help

      output.should match /stop vm/
    end
  end
end
