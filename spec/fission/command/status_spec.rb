require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Status do
  before :each do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    before :each do
      Fission::VM.stub!(:all).and_return(['foo', 'bar', 'baz'])
      Fission::VM.stub!(:all_running).and_return(['foo', 'baz'])
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

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Status.help

      output.should match /status/
    end
  end
end
