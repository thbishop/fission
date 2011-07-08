require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  before :each do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
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

    describe 'clone' do
      before :each do
        @clone_mock = mock('clone_mock')
        Fission::Command::Clone.stub!(:help).and_return('')
      end

      it "should try to clone the vm" do
        @clone_mock.should_receive(:execute)
        Fission::Command::Clone.should_receive(:new).with(['foo', 'bar']).and_return(@clone_mock)

        Fission::CLI.execute ['clone', 'foo', 'bar']
      end
    end

    describe 'start' do
      before :each do
        @start_mock = mock('start_mock')
        Fission::Command::Start.stub!(:help).and_return('')
      end

      it "should try to start the vm" do
        @start_mock.should_receive(:execute)
        Fission::Command::Start.should_receive(:new).with(['foo']).and_return(@start_mock)

        Fission::CLI.execute ['start', 'foo']
      end
    end

    describe 'status' do
      before :each do
        @status_mock = mock('status_mock')
        Fission::Command::Status.stub!(:help).and_return('')
      end

      it "should try to get the status for all VMs" do
        @status_mock.should_receive(:execute)
        Fission::Command::Status.should_receive(:new).and_return(@status_mock)

        Fission::CLI.execute ['status']
      end
    end

    describe 'stop' do
      before :each do
        @stop_mock = mock('stop_mock')
        Fission::Command::Stop.stub!(:help).and_return('')
      end

      it "should try to stop the vm" do
        @stop_mock.should_receive(:execute)
        Fission::Command::Stop.should_receive(:new).with(['foo']).and_return(@stop_mock)

        Fission::CLI.execute ['stop', 'foo']
      end
    end

    describe 'suspend' do
      before :each do
        @suspend_mock = mock('suspend_mock')
        Fission::Command::Suspend.stub!(:help).and_return('')
      end

      it "should try to suspend the vm" do
        @suspend_mock.should_receive(:execute)
        Fission::Command::Suspend.should_receive(:new).with(['foo']).and_return(@suspend_mock)

        Fission::CLI.execute ['suspend', 'foo']
      end
    end

  end
end
