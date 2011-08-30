require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Delete do
  before :all do
    @target_vm = ['foo']
  end

  before :each do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe "execute" do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Delete.should_receive(:help)

      lambda {
        command = Fission::Command::Delete.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for delete command/
    end

    it "should output an error and exit if it can't find the target vm" do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(false)

      lambda {
        command = Fission::Command::Delete.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find target vm #{@target_vm}/
    end

    it "should try to delete the vm if it exists" do
      Fission::VM.should_receive(:exists?).with(@target_vm.first).and_return(true)
      Fission::VM.should_receive(:delete).with(@target_vm.first)
      command = Fission::Command::Delete.new @target_vm
      command.execute
      @string_io.string.should match /Deletion complete/
    end
  end
end
