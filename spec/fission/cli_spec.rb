require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  before do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'self.commands' do
    it 'should return the list of commands' do
      Fission::CLI.commands.should == ['clone', 'delete', 'snapshot create',
                                       'snapshot list', 'snapshot revert',
                                       'start', 'status', 'stop', 'suspend']
    end
  end

  describe 'execute' do
    describe 'with no arguments' do
      it 'should output the usage info' do
        lambda { Fission::CLI.execute [] }.should raise_error SystemExit

        @string_io.string.should match /Usage/
      end
    end

    describe '-v or --version' do
      ['-v', '--version'].each do |arg|
        it "should output the version with #{arg}" do
          lambda { Fission::CLI.execute [arg] }.should raise_error SystemExit

          @string_io.string.should match /#{Fission::VERSION}/
        end
      end
    end

    describe '-h or --help' do
      ['-h', '--help'].each do |arg|
        it "should output the usage info with #{arg}" do
          lambda { Fission::CLI.execute [arg] }.should raise_error SystemExit

          @string_io.string.should match /Usage/
        end
      end
    end

    describe 'with the sub command' do
      before do
        @cmd_mock = mock('cmd')
        @cmd_mock.should_receive(:execute)
      end

      describe 'clone' do
        it "should try to clone the vm" do
          Fission::Command::Clone.stub!(:help).and_return('')
          Fission::Command::Clone.should_receive(:new).with(['foo', 'bar']).
                                                       and_return(@cmd_mock)
          Fission::CLI.execute ['clone', 'foo', 'bar']
        end

        it 'should try to clone the vm and start it' do
          Fission::Command::Clone.stub!(:help).and_return('')
          Fission::Command::Clone.should_receive(:new).with(['foo', 'bar', '--start']).
                                                       and_return(@cmd_mock)
          Fission::CLI.execute ['clone', 'foo', 'bar', '--start']
        end
      end

      describe 'snapshot create' do
        it "should create a snapshot" do
          Fission::Command::SnapshotCreate.stub!(:help).and_return('')
          Fission::Command::SnapshotCreate.should_receive(:new).
                                           with(['foo', 'snap1']).
                                           and_return(@cmd_mock)
          Fission::CLI.execute ['snapshot', 'create', 'foo', 'snap1']
        end
      end

      describe 'snapshot list' do
        it "should list the snapshots" do
          Fission::Command::SnapshotList.stub!(:help).and_return('')
          Fission::Command::SnapshotList.should_receive(:new).
                                         with([]).
                                         and_return(@cmd_mock)
          Fission::CLI.execute ['snapshot', 'list']
        end
      end

      describe 'snapshot revert' do
        it "should revert to the snapshots" do
          Fission::Command::SnapshotRevert.stub!(:help).and_return('')
          Fission::Command::SnapshotRevert.should_receive(:new).
                                           with(['foo', 'snap1']).
                                           and_return(@cmd_mock)
          Fission::CLI.execute ['snapshot', 'revert', 'foo', 'snap1']
        end
      end

      describe 'start' do
        it "should try to start the vm" do
          Fission::Command::Start.stub!(:help).and_return('')
          Fission::Command::Start.should_receive(:new).
                                  with(['foo']).
                                  and_return(@cmd_mock)
          Fission::CLI.execute ['start', 'foo']
        end

        it 'should try to start the vm headless' do
          Fission::Command::Start.stub!(:help).and_return('')
          Fission::Command::Start.should_receive(:new).
                                  with(['foo', '--headless']).
                                  and_return(@cmd_mock)
          Fission::CLI.execute ['start', 'foo', '--headless']

        end
      end

      describe 'status' do
        it "should try to get the status for all VMs" do
          Fission::Command::Status.stub!(:help).and_return('')
          Fission::Command::Status.should_receive(:new).
                                   with([]).
                                   and_return(@cmd_mock)
          Fission::CLI.execute ['status']
        end
      end

      describe 'stop' do
        it "should try to stop the vm" do
          Fission::Command::Stop.stub!(:help).and_return('')
          Fission::Command::Stop.should_receive(:new).
                                 with(['foo']).
                                 and_return(@cmd_mock)
          Fission::CLI.execute ['stop', 'foo']
        end
      end

      describe 'suspend' do
        it "should try to suspend the vm" do
          Fission::Command::Suspend.stub!(:help).and_return('')
          Fission::Command::Suspend.should_receive(:new).
                                    with(['foo']).
                                    and_return(@cmd_mock)
          Fission::CLI.execute ['suspend', 'foo']
        end

        it 'should try to suspend all of vms' do
          Fission::Command::Suspend.stub!(:help).and_return('')
          Fission::Command::Suspend.should_receive(:new).
                                    with(['--all']).
                                    and_return(@cmd_mock)
          Fission::CLI.execute ['suspend', '--all']
        end
      end

      describe 'delete' do
        it "should try to delete the vm" do
          Fission::Command::Delete.stub!(:help).and_return('')
          Fission::Command::Delete.should_receive(:new).
                                   with(['foo']).
                                   and_return(@cmd_mock)
          Fission::CLI.execute ['delete', 'foo']
        end

        it 'should try to force delete the vm' do
          Fission::Command::Delete.stub!(:help).and_return('')
          Fission::Command::Delete.should_receive(:new).
                                   with(['foo', '--force']).
                                   and_return(@cmd_mock)
          Fission::CLI.execute ['delete', 'foo', '--force']
        end
      end
    end

  end
end
