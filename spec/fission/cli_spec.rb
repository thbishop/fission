require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  before :each do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'self.commands' do
    it 'should return the list of commands' do
      Fission::CLI.commands.should == ['clone', 'delete', 'start', 'status', 'stop', 'suspend']
    end
  end

  describe 'execute' do

    describe 'with no arguments' do
      it 'should output the usage info' do
        lambda {
          Fission::CLI.execute []
        }.should raise_error SystemExit

        @string_io.string.should match /Usage/
      end
    end

    describe '-v or --version' do
      ['-v', '--version'].each do |arg|
        it "should output the version with #{arg}" do
          lambda {
            Fission::CLI.execute [arg]
          }.should raise_error SystemExit

          @string_io.string.should match /#{Fission::VERSION}/

        end
      end

    end

    describe '-h or --help' do
      ['-h', '--help'].each do |arg|
        it "should output the usage info with #{arg}" do
          lambda {
            Fission::CLI.execute [arg]
          }.should raise_error SystemExit

          @string_io.string.should match /Usage/
        end
      end

    end

    describe 'with the sub command' do
      before :each do
        @cmd_mock = mock('cmd')
        @cmd_mock.should_receive(:execute)
      end

      describe 'clone' do
        it "should try to clone the vm" do
          Fission::Command::Clone.stub!(:help).and_return('')
          Fission::Command::Clone.should_receive(:new).with(['foo', 'bar']).and_return(@cmd_mock)
          Fission::CLI.execute ['clone', 'foo', 'bar']
        end
      end

      describe 'start' do
        it "should try to start the vm" do
          Fission::Command::Start.stub!(:help).and_return('')
          Fission::Command::Start.should_receive(:new).with(['foo']).and_return(@cmd_mock)
          Fission::CLI.execute ['start', 'foo']
        end
      end

      describe 'status' do
        it "should try to get the status for all VMs" do
          Fission::Command::Status.stub!(:help).and_return('')
          Fission::Command::Status.should_receive(:new).and_return(@cmd_mock)
          Fission::CLI.execute ['status']
        end
      end

      describe 'stop' do
        it "should try to stop the vm" do
          Fission::Command::Stop.stub!(:help).and_return('')
          Fission::Command::Stop.should_receive(:new).with(['foo']).and_return(@cmd_mock)
          Fission::CLI.execute ['stop', 'foo']
        end
      end

      describe 'suspend' do
        it "should try to suspend the vm" do
          Fission::Command::Suspend.stub!(:help).and_return('')
          Fission::Command::Suspend.should_receive(:new).with(['foo']).and_return(@cmd_mock)
          Fission::CLI.execute ['suspend', 'foo']
        end
      end

      describe 'delete' do
        it "should try to delete the vm" do
          Fission::Command::Delete.stub!(:help).and_return('')
          Fission::Command::Delete.should_receive(:new).with(['foo']).and_return(@cmd_mock)
          Fission::CLI.execute ['delete', 'foo']
        end
      end
    end

  end
end
