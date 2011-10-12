require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Status do
  include_context 'command_setup'

  before do
    @all_response_mock = mock('response')
    @vm_1 = Fission::VM.new 'foo'
    @vm_2 = Fission::VM.new 'bar'
    @vm_3 = Fission::VM.new 'baz'
    @vm_4 = Fission::VM.new 'blah'
  end

  describe 'execute' do
    before do
      @all_response_mock.stub_as_successful [@vm_1, @vm_2, @vm_3, @vm_4]

      Fission::VM.should_receive(:all).and_return(@all_response_mock)
      Fission::VM.stub(:all_running).and_return(@all_running_response_mock)
    end

    describe 'when successful' do
      before do
        @all_running_response_mock.stub_as_successful [@vm_1, @vm_3]
      end

      it 'should output the VMs which are running' do
        command = Fission::Command::Status.new
        command.execute

        @string_io.string.should match /foo.+\[running\]/
        @string_io.string.should match /baz.+\[running\]/
      end

      it 'should output the VMs which are not running' do
        @state_response_mock = mock('state')
        @state_response_mock.stub_as_successful 'not running'

        @vm_2.stub(:state).and_return(@state_response_mock)
        command = Fission::Command::Status.new
        command.execute

        @string_io.string.should match /bar.+\[not running\]/
      end

      it 'should output the VMs which are suspended' do
        @state_response_mock = mock('state')
        @state_response_mock.stub_as_successful 'suspended'

        @vm_4.stub(:state).and_return(@state_response_mock)
        command = Fission::Command::Status.new
        command.execute

        @string_io.string.should match /blah.+\[suspended\]/
      end

      it 'should output unknown and an error for VMs which had an error getting their state' do
        @state_response_mock = mock('state')
        @state_response_mock.stub_as_unsuccessful

        @vm_4.stub(:state).and_return(@state_response_mock)
        command = Fission::Command::Status.new
        command.execute

        @string_io.string.should match /blah.+\[unknown\] \(it blew up\)/
      end

    end

    describe 'when unsuccessful' do
      before do
        @all_running_response_mock.stub_as_unsuccessful
      end

      it 'should output an error and exit if there was an error getting the list of running VMs' do
        command = Fission::Command::Status.new
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /There was an error getting the list of running VMs.+it blew up/m
      end
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Status.help

      output.should match /status/
    end
  end
end
