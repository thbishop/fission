require 'spec_helper'

describe Fission::Action::VMStopper do

  describe 'stop' do
    before do
      @vm                      = Fission::VM.new 'foo'
      @vmrun_cmd               = Fission.config['vmrun_cmd']
      @conf_file_path          = File.join @vm.path, 'foo.vmx'
      @conf_file_response_mock = mock 'conf_file_response'
      @running_response_mock   = mock 'running?'

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @running_response_mock.stub_as_successful true
      @conf_file_response_mock.stub_as_successful @conf_file_path
      @stopper = Fission::Action::VMStopper.new @vm
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @stopper.stop.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is not running' do
      @running_response_mock.stub_as_successful false
      @stopper.stop.should be_an_unsuccessful_response 'VM is not running'
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful
      @stopper.stop.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @stopper.stop.should be_an_unsuccessful_response
    end

    it 'should return a successful response and stop the vm' do
      $?.should_receive(:exitstatus).and_return(0)
      @stopper.should_receive(:`).
               with("#{@vmrun_cmd} stop #{@conf_file_path.gsub ' ', '\ '} 2>&1").
               and_return("it's all good")

      @stopper.stop.should be_a_successful_response
    end

    it 'should return a suscessful response and hard stop the vm' do
      $?.should_receive(:exitstatus).and_return(0)
      @stopper.should_receive(:`).
               with("#{@vmrun_cmd} stop #{@conf_file_path.gsub ' ', '\ '} hard 2>&1").
               and_return("it's all good")

      @stopper.stop(:hard => true).should be_a_successful_response
    end

    it 'it should return an unsuccessful response if unable to stop the vm' do
      $?.should_receive(:exitstatus).and_return(1)
      @stopper.should_receive(:`).
               with("#{@vmrun_cmd} stop #{@conf_file_path.gsub ' ', '\ '} 2>&1").
               and_return("it blew up")

      @stopper.stop.should be_an_unsuccessful_response
    end

  end

end
