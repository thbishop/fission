require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Status do
  before do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @all_response_mock = mock('response')
    @all_running_response_mock = mock('response')
  end

  describe 'execute' do
    before do
      @all_response_mock.should_receive(:successful?).and_return(true)
      @all_response_mock.should_receive(:data).and_return(['foo', 'bar', 'baz'])
      Fission::VM.should_receive(:all).and_return(@all_response_mock)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
    end

    describe 'when successful' do
      before do
        @all_running_response_mock.should_receive(:successful?).and_return(true)
        @all_running_response_mock.should_receive(:data).and_return(['foo', 'baz'])
      end

      it 'should output the VMs which are running' do
        command = Fission::Command::Status.new
        command.execute

        @string_io.string.should match /foo.+[running]/
        @string_io.string.should match /baz.+[running]/
      end

      it 'should output the VMs which are not running' do
        command = Fission::Command::Status.new
        command.execute

        @string_io.string.should match /bar.+[not running]/
      end
    end

    describe 'when unsuccessful' do
      before do
        @all_running_response_mock.should_receive(:successful?).and_return(false)
        @all_running_response_mock.should_receive(:code).and_return(1)
        @all_running_response_mock.should_receive(:output).and_return('it blew up')
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
