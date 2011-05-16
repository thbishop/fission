require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Clone do
  before :all do
    @vm_info = ['foo', 'bar']
    @string_io = StringIO.new
  end

  before :each do
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    [ [], ['foo'], ['foo', 'bar', 'baz'] ].each do |args|
      it "should output an error and the help when #{args.count} arguments are passed in" do
        Fission::Command::Clone.should_receive(:help)

        lambda {
          Fission::Command::Clone.execute args
        }.should raise_error SystemExit

        @string_io.string.should match /Incorrect arguments for clone command/
      end
    end

    it "should output an error and exit if it can't find the source vm" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(false)
      Fission::VM.should_not_receive(:exists?).with(@vm_info[1])

      lambda {
        Fission::Command::Clone.execute @vm_info
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the source vm #{@vm_info.first}/
    end


    it "should output an error and exit if the target vm already exists" do
      @vm_info.each do |vm|
        Fission::VM.should_receive(:exists?).with(vm).and_return(true)
      end

      lambda {
        Fission::Command::Clone.execute @vm_info
      }.should raise_error SystemExit

      @string_io.string.should match /The target vm #{@vm_info[1]} already exists/
    end

    it 'should try to clone the vm if the source vm exists and the target vm does not' do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info[1]).and_return(false)
      Fission::VM.should_receive(:clone).with(@vm_info.first, @vm_info[1])
      Fission::Command::Clone.execute @vm_info

      @string_io.string.should match /Clone complete/
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Clone.help

      output.should match /clone source_vm target_vm/
    end
  end
end
