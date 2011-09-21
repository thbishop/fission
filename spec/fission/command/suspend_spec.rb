require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Suspend do
  before do
    @vm_info = ['foo']
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @response_mock = mock('response')
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
      @response_mock.should_receive(:successful?).and_return(true)
      @vm_mock.should_receive(:suspend).and_return(@response_mock)

      command = Fission::Command::Suspend.new @vm_info
      command.execute

      @string_io.string.should match /Suspending '#{@vm_info.first}'/
      @string_io.string.should match /VM '#{@vm_info.first}' suspended/
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
          @response_mock.should_receive(:successful?).and_return(true)
          mock.should_receive(:suspend).and_return(@response_mock)
        end

        command = Fission::Command::Suspend.new ['--all']
        command.execute

        vm_items.keys.each do |vm|
          @string_io.string.should match /Suspending '#{vm}'/
          @string_io.string.should match /VM '#{vm}' suspended/
        end
      end
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Suspend.help

      output.should match /suspend \[vm \| --all\]/
    end
  end
end
