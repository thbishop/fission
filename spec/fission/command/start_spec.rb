require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Start do
  before do
    @vm_info = ['foo']
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @vm_mock = mock('vm_mock')
    @all_running_response_mock = mock('all_running_response')
    @exists_response_mock = mock('exists_response')
    @fusion_running_response_mock = mock('fusion_running_response_mock')
    @start_response_mock = mock('start_response')
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Start.should_receive(:help)

      command = Fission::Command::Start.new
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for start command/
    end

    it "should output an error and exit if it can't find the vm" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(false)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)

      command = Fission::Command::Start.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@vm_info.first}/
    end


    it "should output and exit if the vm is already running" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return(@vm_info)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      command = Fission::Command::Start.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /VM '#{@vm_info.first}' is already running/
    end

    it 'should output an error and exit if there was an error getting the list of running VMs' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(false)
      @all_running_response_mock.should_receive(:code).and_return(1)
      @all_running_response_mock.should_receive(:output).and_return('it blew up')
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      command = Fission::Command::Start.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /There was an error determining if the VM is already running.+it blew up.+/m
    end

    it 'should try to start the vm if it is not running' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @start_response_mock.should_receive(:successful?).and_return(true)
      @vm_mock.should_receive(:start).and_return(@start_response_mock)

      command = Fission::Command::Start.new @vm_info
      command.execute

      @string_io.string.should match /Starting '#{@vm_info.first}'/
      @string_io.string.should match /VM '#{@vm_info.first}' started/
    end

    it 'should out an error and exit if there was an error starting the vm' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @start_response_mock.should_receive(:successful?).and_return(false)
      @start_response_mock.should_receive(:code).and_return(1)
      @start_response_mock.should_receive(:output).and_return('it blew up')
      @vm_mock.should_receive(:start).and_return(@start_response_mock)

      command = Fission::Command::Start.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Starting '#{@vm_info.first}'/
      @string_io.string.should match /There was a problem starting the VM.+it blew up.+/m
    end

    describe 'with --headless' do
      it 'should start the vm headless' do
        @exists_response_mock.should_receive(:successful?).and_return(true)
        @exists_response_mock.should_receive(:data).and_return(true)
        Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                             and_return(@exists_response_mock)
        @all_running_response_mock.should_receive(:successful?).and_return(true)
        @all_running_response_mock.should_receive(:data).and_return([])
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
        @fusion_running_response_mock.should_receive(:successful?).and_return(true)
        @fusion_running_response_mock.should_receive(:data).and_return(false)
        Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)
        Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
        @start_response_mock.should_receive(:successful?).and_return(true)
        @vm_mock.should_receive(:start).and_return(@start_response_mock)

        command = Fission::Command::Start.new @vm_info << '--headless'
        command.execute

        @string_io.string.should match /Starting '#{@vm_info.first}'/
        @string_io.string.should match /VM '#{@vm_info.first}' started/
      end

      it 'should output an error and exit if the fusion app is running' do
        @exists_response_mock.should_receive(:successful?).and_return(true)
        @exists_response_mock.should_receive(:data).and_return(true)
        Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                             and_return(@exists_response_mock)
        @all_running_response_mock.should_receive(:successful?).and_return(true)
        @all_running_response_mock.should_receive(:data).and_return([])
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
        @fusion_running_response_mock.should_receive(:successful?).and_return(true)
        @fusion_running_response_mock.should_receive(:data).and_return(true)
        Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)
        Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
        @vm_mock.should_not_receive(:start)

        command = Fission::Command::Start.new @vm_info << '--headless'
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Fusion GUI is currently running/
        @string_io.string.should match /A VM cannot be started in headless mode when the Fusion GUI is running/
        @string_io.string.should match /Exit the Fusion GUI and try again/
      end
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Start.help

      output.should match /start vm \[options\]/
      output.should match /--headless/
    end
  end
end
