require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Start do
  include_context 'command_setup'

  before do
    @vm_info = ['foo']
    @start_response_mock = mock('start_response')
  end

  describe 'execute' do
    subject { Fission::Command::Start }

    it_should_not_accept_arguments_of [], 'start'

    it "should output an error and exit if it can't find the vm" do
      @exists_response_mock.stub_as_successful false
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)

      command = Fission::Command::Start.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@vm_info.first}'/
    end

    describe 'when the VM exists' do
      before do
        @exists_response_mock.stub_as_successful true
        Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                             and_return(@exists_response_mock)
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      end

      it "should output and exit if the vm is already running" do
        @all_running_response_mock.stub_as_successful @vm_info


        command = Fission::Command::Start.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM '#{@vm_info.first}' is already running/
      end

      it 'should output an error and exit if there was an error getting the list of running VMs' do
        @all_running_response_mock.stub_as_unsuccessful

        command = Fission::Command::Start.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error determining if the VM is already running.+it blew up.+/m
      end

      it 'should try to start the vm if it is not running' do
        @all_running_response_mock.stub_as_successful []
        @start_response_mock.stub_as_successful true

        @vm_mock.should_receive(:start).and_return(@start_response_mock)

        Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)

        command = Fission::Command::Start.new @vm_info
        command.execute

        @string_io.string.should match /Starting '#{@vm_info.first}'/
        @string_io.string.should match /VM '#{@vm_info.first}' started/
      end

      it 'should output an error and exit if there was an error starting the vm' do
        @all_running_response_mock.stub_as_successful []
        @start_response_mock.stub_as_unsuccessful

        @vm_mock.should_receive(:start).and_return(@start_response_mock)

        Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)

        command = Fission::Command::Start.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Starting '#{@vm_info.first}'/
        @string_io.string.should match /There was a problem starting the VM.+it blew up.+/m
      end

      describe 'with --headless' do
        before do
          Fission::Fusion.should_receive(:is_running?).and_return(@fusion_running_response_mock)
          Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
        end

        it 'should start the vm headless' do
          @all_running_response_mock.stub_as_successful []
          @fusion_running_response_mock.stub_as_successful false
          @start_response_mock.stub_as_successful

          @vm_mock.should_receive(:start).and_return(@start_response_mock)

          command = Fission::Command::Start.new @vm_info << '--headless'
          command.execute

          @string_io.string.should match /Starting '#{@vm_info.first}'/
          @string_io.string.should match /VM '#{@vm_info.first}' started/
        end

        it 'should output an error and exit if the fusion app is running' do
          @all_running_response_mock.stub_as_successful []
          @fusion_running_response_mock.stub_as_successful true

          @vm_mock.should_not_receive(:start)

          command = Fission::Command::Start.new @vm_info << '--headless'
          lambda { command.execute }.should raise_error SystemExit

          @string_io.string.should match /Fusion GUI is currently running/
          @string_io.string.should match /A VM cannot be started in headless mode when the Fusion GUI is running/
          @string_io.string.should match /Exit the Fusion GUI and try again/
        end
      end

    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Start.help

      output.should match /start vm_name \[options\]/
      output.should match /--headless/
    end
  end
end
