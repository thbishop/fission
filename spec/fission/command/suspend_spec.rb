require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Suspend do
  before :all do
    @vm_info = ['foo']
  end

  before :each do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Suspend.should_receive(:help)

      lambda {
        command = Fission::Command::Suspend.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for suspend command/
    end

    it "should output an error and exit if it can't find the vm" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(false)

      lambda {
        command = Fission::Command::Suspend.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@vm_info.first}/
    end


    it "should output and exit if the vm is not running" do
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return([])

      lambda {
        command = Fission::Command::Suspend.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM '#{@vm_info.first}' is not running/
    end

    it 'should try to suspend the vm if it is running' do
      @vm_mock = mock('vm_mock')
      Fission::VM.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::VM.should_receive(:all_running).and_return([@vm_info.first])
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @vm_mock.should_receive(:suspend)

      command = Fission::Command::Suspend.new @vm_info
      command.execute

      @string_io.string.should match /suspending '#{@vm_info.first}'/
    end

    describe 'with --all' do
      it 'should suspend all running VMs' do
        @vm_mock_1 = mock('vm_mock_1')
        @vm_mock_2 = mock('vm_mock_2')

        vm_items = {'vm_1' => @vm_mock_1,
                    'vm_2' => @vm_mock_2
        }

        Fission::VM.should_receive(:all_running).and_return(vm_items.keys)

        vm_items.each_pair do |name, mock|
          Fission::VM.should_receive(:new).with(name).and_return(mock)
          mock.should_receive(:suspend)
        end

        command = Fission::Command::Suspend.new ['--all']
        command.execute

        @string_io.string.should match /suspending 'vm_1'/
        @string_io.string.should match /suspending 'vm_2'/
      end
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Suspend.help

      output.should match /suspend vm/
      output.should match /--all/
    end
  end
end
