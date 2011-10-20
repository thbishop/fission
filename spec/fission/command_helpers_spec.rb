require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CommandHelpers do
  include_context 'command_setup'

  before do
    @object = Object.new
    @object.extend Fission::CommandHelpers
  end

  describe 'incorrect_arguments' do
    before do
      @object.class.should_receive(:help).and_return('foo help')
      @object.stub(:output)
      @object.stub(:output_and_exit)
    end

    it "should output the command's help text" do
      @object.should_receive(:output).with("foo help\n")
      @object.incorrect_arguments 'delete'
    end

    it 'should output that the argumets are incorrect and exit' do
      @object.should_receive(:output_and_exit).
              with('Incorrect arguments for delete command', 1)
      @object.incorrect_arguments 'delete'
    end
  end

end
