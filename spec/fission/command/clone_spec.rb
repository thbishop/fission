require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Clone do
  before do
    @vm_info = ['foo', 'bar']
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    [ [], ['foo'] ].each do |args|
      it "should output an error and the help when #{args.count} arguments are passed in" do
        Fission::Command::Clone.should_receive(:help)

        lambda {
          command = Fission::Command::Clone.new args
          command.execute
        }.should raise_error SystemExit

        @string_io.string.should match /Incorrect arguments for clone command/
      end
    end

    it "should output an error and exit if it can't find the source vm" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(false)
      Fission::VM.should_not_receive(:exists?).with(@vm_info[1])

      lambda {
        command = Fission::Command::Clone.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the source vm #{@vm_info.first}/
    end


    it "should output an error and exit if the target vm already exists" do
      @vm_info.each do |vm|
        Fission::VM.should_receive(:exists?).with(vm).and_return(true)
      end

      lambda {
        command = Fission::Command::Clone.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /The target vm #{@vm_info[1]} already exists/
    end

    it 'should try to clone the vm if the source vm exists and the target vm does not' do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info[1]).and_return(false)
      Fission::VM.should_receive(:clone).with(@vm_info.first, @vm_info[1])
      command = Fission::Command::Clone.new @vm_info
      command.execute

      @string_io.string.should match /Clone complete/
    end

    describe 'with --start' do
      it 'should try to clone the vm and start it' do
        @vm_mock = mock('vm_mock')
        Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
        Fission::VM.should_receive(:exists?).with(@vm_info[1]).and_return(false)
        Fission::VM.should_receive(:clone).with(@vm_info.first, @vm_info[1])

        @vm_mock.should_receive(:start)
        Fission::VM.should_receive(:new).with(@vm_info[1]).and_return(@vm_mock)

        command = Fission::Command::Clone.new @vm_info << '--start'
        command.execute

        @string_io.string.should match /Clone complete/
        @string_io.string.should match /Starting '#{@vm_info[1]}'/
      end
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Clone.help

      output.should match /clone source_vm target_vm/
    end
  end
end
