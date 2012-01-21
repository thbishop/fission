require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  before do
    @string_io = StringIO.new
    Fission::CLI.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @command_list = ['clone', 'delete', 'info',
                     'snapshot create', 'snapshot list',
                     'snapshot revert', 'start', 'status',
                     'stop', 'suspend']
  end

  describe 'self.commands' do
    it 'should return the list of commands' do
      Fission::CLI.commands.should == @command_list
    end
  end

  describe 'self.commands_banner' do
    it 'should output help for each command' do
      Fission::CLI.commands_banner
      @command_list.each do |cmd|
        @string_io.string.should match /#{cmd}\s+\w+/
      end
    end
  end

  describe 'self.command_names_and_summaries' do
    it 'should return the list of commands and summaries' do
      cmd_names_summaries = Fission::CLI.command_names_and_summaries

      cmd_names_summaries.keys.sort.should == @command_list
      cmd_names_summaries.values.each do |summary|
        summary.should match /\w+/
      end
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
        @cmd_mock.stub(:summary)
      end

      describe 'clone' do
        before do
          @cmd_mock.stub(:command_name).and_return('clone')
          Fission::Command::Clone.should_receive(:new).and_return(@cmd_mock)
          Fission::Command::Clone.stub(:help)
        end

        it "should try to clone the vm" do
          Fission::Command::Clone.should_receive(:new).with(['foo', 'bar']).
                                                       and_return(@cmd_mock)
          Fission::CLI.execute ['clone', 'foo', 'bar']
        end

        it 'should try to clone the vm and start it' do
          Fission::Command::Clone.should_receive(:new).
                                  with(['foo', 'bar', '--start']).
                                  and_return(@cmd_mock)
          Fission::CLI.execute ['clone', 'foo', 'bar', '--start']
        end
      end

      describe 'snapshot create' do
        before do
          @cmd_mock.stub(:command_name).and_return('snapshot create')
          Fission::Command::SnapshotCreate.should_receive(:new).
                                           twice.
                                           and_return(@cmd_mock)
          Fission::Command::SnapshotCreate.stub(:help)
        end

        it "should create a snapshot" do
          Fission::Command::SnapshotCreate.should_receive(:new).
                                           with(['foo', 'snap1']).
                                           and_return(@cmd_mock)
          Fission::CLI.execute ['snapshot', 'create', 'foo', 'snap1']
        end
      end

      describe 'snapshot list' do
        before do
          @cmd_mock.stub(:command_name).and_return('snapshot list')
          Fission::Command::SnapshotList.should_receive(:new).
                                         twice.
                                         and_return(@cmd_mock)
          Fission::Command::SnapshotList.stub(:help)
        end

        it "should list the snapshots" do
          Fission::Command::SnapshotList.should_receive(:new).
                                         with([]).
                                         and_return(@cmd_mock)
          Fission::CLI.execute ['snapshot', 'list']
        end
      end

      describe 'snapshot revert' do
        before do
          @cmd_mock.stub(:command_name).and_return('snapshot revert')
          Fission::Command::SnapshotRevert.should_receive(:new).
                                           twice.
                                           and_return(@cmd_mock)
          Fission::Command::SnapshotRevert.stub(:help)
        end

        it "should revert to the snapshots" do
          Fission::Command::SnapshotRevert.should_receive(:new).
                                           with(['foo', 'snap1']).
                                           and_return(@cmd_mock)
          Fission::CLI.execute ['snapshot', 'revert', 'foo', 'snap1']
        end
      end

      describe 'start' do
        before do
          @cmd_mock.stub(:command_name).and_return('start')
          Fission::Command::Start.should_receive(:new).
                                  and_return(@cmd_mock)
          Fission::Command::Start.stub(:help)
        end

        it "should try to start the vm" do
          Fission::Command::Start.should_receive(:new).
                                  with(['foo']).
                                  and_return(@cmd_mock)
          Fission::CLI.execute ['start', 'foo']
        end

        it 'should try to start the vm headless' do
          Fission::Command::Start.should_receive(:new).
                                  with(['foo', '--headless']).
                                  and_return(@cmd_mock)
          Fission::CLI.execute ['start', 'foo', '--headless']
        end
      end

      describe 'status' do
        before do
          @cmd_mock.stub(:command_name).and_return('status')
          Fission::Command::Status.should_receive(:new).and_return(@cmd_mock)
          Fission::Command::Status.stub(:help)
        end

        it "should try to get the status for all VMs" do
          Fission::Command::Status.should_receive(:new).
                                   with([]).
                                   and_return(@cmd_mock)
          Fission::CLI.execute ['status']
        end
      end

      describe 'stop' do
        before do
          @cmd_mock.stub(:command_name).and_return('stop')
          Fission::Command::Stop.should_receive(:new).and_return(@cmd_mock)
          Fission::Command::Stop.stub(:help)
        end

        it "should try to stop the vm" do
          Fission::Command::Stop.should_receive(:new).
                                 with(['foo']).
                                 and_return(@cmd_mock)
          Fission::CLI.execute ['stop', 'foo']
        end
      end

      describe 'suspend' do
        before do
          @cmd_mock.stub(:command_name).and_return('suspend')
          Fission::Command::Suspend.should_receive(:new).and_return(@cmd_mock)
          Fission::Command::Suspend.stub(:help)
        end

        it "should try to suspend the vm" do
          Fission::Command::Suspend.should_receive(:new).
                                    with(['foo']).
                                    and_return(@cmd_mock)
          Fission::CLI.execute ['suspend', 'foo']
        end

        it 'should try to suspend all of vms' do
          Fission::Command::Suspend.should_receive(:new).
                                    with(['--all']).
                                    and_return(@cmd_mock)
          Fission::CLI.execute ['suspend', '--all']
        end
      end

      describe 'delete' do
        before do
          @cmd_mock.stub(:command_name).and_return('delete')
          Fission::Command::Delete.should_receive(:new).and_return(@cmd_mock)
          Fission::Command::Delete.stub(:help)
        end

        it "should try to delete the vm" do
          Fission::Command::Delete.should_receive(:new).
                                   with(['foo']).
                                   and_return(@cmd_mock)
          Fission::CLI.execute ['delete', 'foo']
        end

        it 'should try to force delete the vm' do
          Fission::Command::Delete.should_receive(:new).
                                   with(['foo', '--force']).
                                   and_return(@cmd_mock)
          Fission::CLI.execute ['delete', 'foo', '--force']
        end
      end
    end

  end
end
