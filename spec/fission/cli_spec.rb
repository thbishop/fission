require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  before do
    @string_io = StringIO.new
    Fission::CLI.any_instance.stub(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'initialize' do
    describe 'with no arguments' do
      it 'should output the usage info' do
        lambda { Fission::CLI.new }.should raise_error SystemExit
        @string_io.string.should match /Usage/
      end
    end

    describe 'with -v or --version arguments' do
      ['-v', '--version'].each do |arg|
        it "should output the version with #{arg}" do
          lambda { Fission::CLI.new [arg] }.should raise_error SystemExit

          @string_io.string.should match /#{Fission::VERSION}/
        end
      end
    end

    describe '-h or --help argument' do
      ['-h', '--help'].each do |arg|
        it "should output the usage info with #{arg}" do
          lambda { Fission::CLI.new [arg] }.should raise_error SystemExit

          @string_io.string.should match /Usage/
        end
      end
    end

    describe 'with an invalid sub command' do
      it 'should display the help' do
        lambda {
          Fission::CLI.new(['foo', 'bar']).execute
        }.should raise_error SystemExit

        @string_io.string.should match /Usage/
      end
    end

    describe 'with a valid sub command' do
      before do
        @cmd_mock = mock('cmd')
        @cmd_mock.should_receive(:execute)
        @cmd_mock.stub(:summary)
      end

      describe 'clone' do
        before do
          @cmd_mock.stub(:command_name).and_return('clone')
          Fission::Command::Clone.should_receive(:new).and_return(@cmd_mock)
        end

        it "should try to clone the vm" do
          Fission::Command::Clone.should_receive(:new).with(['foo', 'bar']).
                                                       and_return(@cmd_mock)
          Fission::CLI.new(['clone', 'foo', 'bar']).execute

        end

        it 'should try to clone the vm and start it' do
          Fission::Command::Clone.should_receive(:new).
                                  with(['foo', 'bar', '--start']).
                                  and_return(@cmd_mock)
          Fission::CLI.new(['clone', 'foo', 'bar', '--start']).execute
        end
      end

      describe 'snapshot create' do
        before do
          @cmd_mock.stub(:command_name).and_return('snapshot create')
          Fission::Command::SnapshotCreate.should_receive(:new).
                                           and_return(@cmd_mock)
        end

        it "should create a snapshot" do
          Fission::Command::SnapshotCreate.should_receive(:new).
                                           with(['foo', 'snap1']).
                                           and_return(@cmd_mock)
          Fission::CLI.new(['snapshot', 'create', 'foo', 'snap1']).execute
        end
      end

      describe 'snapshot list' do
        before do
          @cmd_mock.stub(:command_name).and_return('snapshot list')
          Fission::Command::SnapshotList.should_receive(:new).
                                         and_return(@cmd_mock)
        end

        it "should list the snapshots" do
          Fission::Command::SnapshotList.should_receive(:new).
                                         with([]).
                                         and_return(@cmd_mock)
          Fission::CLI.new(['snapshot', 'list']).execute
        end
      end

      describe 'snapshot revert' do
        before do
          @cmd_mock.stub(:command_name).and_return('snapshot revert')
          Fission::Command::SnapshotRevert.should_receive(:new).
                                           and_return(@cmd_mock)
        end

        it "should revert to the snapshots" do
          Fission::Command::SnapshotRevert.should_receive(:new).
                                           with(['foo', 'snap1']).
                                           and_return(@cmd_mock)
          Fission::CLI.new(['snapshot', 'revert', 'foo', 'snap1']).execute
        end
      end

      describe 'start' do
        before do
          @cmd_mock.stub(:command_name).and_return('start')
          Fission::Command::Start.should_receive(:new).
                                  and_return(@cmd_mock)
        end

        it "should try to start the vm" do
          Fission::Command::Start.should_receive(:new).
                                  with(['foo']).
                                  and_return(@cmd_mock)
          Fission::CLI.new(['start', 'foo']).execute
        end

        it 'should try to start the vm headless' do
          Fission::Command::Start.should_receive(:new).
                                  with(['foo', '--headless']).
                                  and_return(@cmd_mock)
          Fission::CLI.new(['start', 'foo', '--headless']).execute
        end
      end

      describe 'status' do
        before do
          @cmd_mock.stub(:command_name).and_return('status')
          Fission::Command::Status.should_receive(:new).and_return(@cmd_mock)
        end

        it "should try to get the status for all VMs" do
          Fission::Command::Status.should_receive(:new).
                                   with([]).
                                   and_return(@cmd_mock)
          Fission::CLI.new(['status']).execute
        end
      end

      describe 'stop' do
        before do
          @cmd_mock.stub(:command_name).and_return('stop')
          Fission::Command::Stop.should_receive(:new).and_return(@cmd_mock)
        end

        it "should try to stop the vm" do
          Fission::Command::Stop.should_receive(:new).
                                 with(['foo']).
                                 and_return(@cmd_mock)
          Fission::CLI.new(['stop', 'foo']).execute
        end
      end

      describe 'suspend' do
        before do
          @cmd_mock.stub(:command_name).and_return('suspend')
          Fission::Command::Suspend.should_receive(:new).and_return(@cmd_mock)
        end

        it "should try to suspend the vm" do
          Fission::Command::Suspend.should_receive(:new).
                                    with(['foo']).
                                    and_return(@cmd_mock)
          Fission::CLI.new(['suspend', 'foo']).execute
        end

        it 'should try to suspend all of vms' do
          Fission::Command::Suspend.should_receive(:new).
                                    with(['--all']).
                                    and_return(@cmd_mock)
          Fission::CLI.new(['suspend', '--all']).execute
        end
      end

      describe 'delete' do
        before do
          @cmd_mock.stub(:command_name).and_return('delete')
          Fission::Command::Delete.should_receive(:new).and_return(@cmd_mock)
        end

        it "should try to delete the vm" do
          Fission::Command::Delete.should_receive(:new).
                                   with(['foo']).
                                   and_return(@cmd_mock)
          Fission::CLI.new(['delete', 'foo']).execute
        end

        it 'should try to force delete the vm' do
          Fission::Command::Delete.should_receive(:new).
                                   with(['foo', '--force']).
                                   and_return(@cmd_mock)
          Fission::CLI.new(['delete', 'foo', '--force']).execute
        end
      end
    end

  end
end
