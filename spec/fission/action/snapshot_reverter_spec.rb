require 'spec_helper'

describe Fission::Action::SnapshotReverter do

  describe 'revert_snapshot' do
    before do
      @vm                      = Fission::VM.new 'foo'
      @conf_file_path          = File.join @vm.path, 'foo.vmx'
      @vmrun_cmd               = Fission.config['vmrun_cmd']
      @conf_file_response_mock = mock 'conf_file_response'
      @snapshots_response_mock = mock 'snapshots'

      @conf_file_response_mock.stub_as_successful @conf_file_path
      @snapshots_response_mock.stub_as_successful []

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:snapshots).and_return(@snapshots_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @snapshots_response_mock.stub_as_successful ['snap_1']
      Fission::Fusion.stub(:running?).and_return(false)
      @reverter = Fission::Action::SnapshotReverter.new @vm
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @reverter.revert_to_snapshot('snap_1').should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the Fusion GUI is running' do
      Fission::Fusion.stub(:running?).and_return(true)

      response = @reverter.revert_to_snapshot 'snap_1'

      error_string = 'It looks like the Fusion GUI is currently running.  '
      error_string << 'A VM cannot be reverted to a snapshot when the Fusion GUI is running.'
      error_string << '  Exit the Fusion GUI and try again.'

      response.should be_an_unsuccessful_response error_string
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @reverter.revert_to_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return a successful response and revert to the provided snapshot' do
      $?.should_receive(:exitstatus).and_return(0)
      @reverter.should_receive(:`).
                with("#{@vmrun_cmd} revertToSnapshot #{@conf_file_path.gsub ' ', '\ '} \"snap_1\" 2>&1").
                and_return("")

      @reverter.revert_to_snapshot('snap_1').should be_a_successful_response
    end

    it 'should return an unsuccessful response if the snapshot cannot be found' do
      @snapshots_response_mock.stub_as_successful []
      response = @reverter.revert_to_snapshot 'snap_1'
      response.should be_an_unsuccessful_response "Unable to find a snapshot named 'snap_1'."
    end

    it 'should return an unsuccessful response if unable to list the existing snapshots' do
      @snapshots_response_mock.stub_as_unsuccessful
      @reverter.revert_to_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return and unsuccessful response if unable to revert to the snapshot' do
      $?.should_receive(:exitstatus).and_return(1)
      @reverter.should_receive(:`).
                with("#{@vmrun_cmd} revertToSnapshot #{@conf_file_path.gsub ' ', '\ '} \"snap_1\" 2>&1").
                and_return("it blew up")

      @reverter.revert_to_snapshot('snap_1').should be_an_unsuccessful_response
    end

  end

end
