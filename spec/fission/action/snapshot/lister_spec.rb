require 'spec_helper'

describe Fission::Action::Snapshot::Lister do
  before do
    @vm                      = Fission::VM.new 'foo'
    @conf_file_path          = File.join @vm.path, 'foo.vmx'
    @vmrun_cmd               = Fission.config['vmrun_cmd']
    @conf_file_response_mock = mock 'conf_file_response'
    @vm.stub(:conf_file).and_return(@conf_file_response_mock)
  end

  describe 'snapshots' do
    before do
      @vm.stub(:exists?).and_return(true)
      @conf_file_response_mock.stub_as_successful @conf_file_path
      @lister = Fission::Action::Snapshot::Lister.new @vm
    end

    it "should return an unsuccessful repsonse when the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @lister.snapshots.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return a successful response with the list of snapshots' do
      $?.should_receive(:exitstatus).and_return(0)
      @lister.should_receive(:`).
              with("#{@vmrun_cmd} listSnapshots #{@conf_file_path.gsub ' ', '\ '} 2>&1").
              and_return("Total snapshots: 3\nsnap foo\nsnap bar\nsnap baz\n")

      response = @lister.snapshots
      response.should be_a_successful_response
      response.data.should == ['snap foo', 'snap bar', 'snap baz']
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @lister.snapshots.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if there was a problem getting the list of snapshots' do
      $?.should_receive(:exitstatus).and_return(1)
      @lister.should_receive(:`).
              with("#{@vmrun_cmd} listSnapshots #{@conf_file_path.gsub ' ', '\ '} 2>&1").
              and_return("it blew up")

      @lister.snapshots.should be_an_unsuccessful_response
    end
  end
end
