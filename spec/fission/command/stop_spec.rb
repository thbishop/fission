require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Stop do
  include_context 'command_setup'

  before do
    @vm_info = ['foo']
    @stop_response_mock = mock('stop_response')
  end

  describe 'execute' do
    subject { Fission::Command::Stop }

    it_should_not_accept_arguments_of [], 'stop'

    it "should output an error and exit if it can't find the vm" do
      @exists_response_mock.stub_as_successful false

      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)

      command = Fission::Command::Stop.new @vm_info
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

      it "should output and exit if the vm is not running" do
        @all_running_response_mock.stub_as_successful []

        command = Fission::Command::Stop.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /VM '#{@vm_info.first}' is not running/
      end

      it 'should output an error and exit if there was an error getting the list of running VMs' do
        @all_running_response_mock.stub_as_unsuccessful

        command = Fission::Command::Stop.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error determining if the VM is already running.+it blew up.+/m
      end

      it 'should try to stop the vm if it is running' do
        @all_running_response_mock.stub_as_successful [@vm_info.first]

        @stop_response_mock.should_receive(:successful?).and_return(true)
        @vm_mock.should_receive(:stop).and_return(@stop_response_mock)

        Fission::VM.should_receive(:new).with(@vm_info.first).
                                         and_return(@vm_mock)

        command = Fission::Command::Stop.new @vm_info
        command.execute

        @string_io.string.should match /Stopping '#{@vm_info.first}'/
        @string_io.string.should match /VM '#{@vm_info.first}' stopped/
      end

      it 'should output an error and exit if there was an error stopping the vm' do
        @all_running_response_mock.stub_as_successful [@vm_info.first]
        @stop_response_mock.stub_as_unsuccessful

        @vm_mock.should_receive(:stop).and_return(@stop_response_mock)

        Fission::VM.should_receive(:new).with(@vm_info.first).
                                         and_return(@vm_mock)

        command = Fission::Command::Stop.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /Stopping '#{@vm_info.first}'/
        @string_io.string.should match /There was an error stopping the VM.+it blew up.+/m
      end
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Stop.help

      output.should match /stop vm_name/
    end
  end
end
