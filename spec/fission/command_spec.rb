require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Command do
  describe 'new' do
    it 'should set options variable as an open struct' do
      @command = Fission::Command.new
      @command.options.should be_kind_of OpenStruct
    end

    it 'should set the args variable' do
      @command = Fission::Command.new ['foo', 'bar']
      @command.args.should == ['foo', 'bar']
    end
  end

  describe 'help' do
    it 'should call option_parser on a new instance' do
      @new_instance_mock = mock('new_instance')
      @new_instance_mock.should_receive(:option_parser).and_return('foo')
      Fission::Command.should_receive(:new).and_return(@new_instance_mock)
      Fission::Command.help.should == 'foo'
    end
  end

end
