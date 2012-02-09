require 'spec_helper'

describe Fission::Action::VMStarter do

  describe 'start' do
    before do
      @vm                      = Fission::VM.new 'foo'
      @vmrun_cmd               = Fission.config['vmrun_cmd']
      @conf_file_path          = File.join @vm.path, 'foo.vmx'
      @conf_file_response_mock = mock 'conf_file_response'
      @running_response_mock   = mock 'running?'

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @running_response_mock.stub_as_successful false
      @conf_file_response_mock.stub_as_successful @conf_file_path
      @starter = Fission::Action::VMStarter.new @vm
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @starter.start.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is already running' do
      @running_response_mock.stub_as_successful true
      @starter.start.should be_an_unsuccessful_response 'VM is already running'
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful
      @starter.start.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @starter.start.should be_an_unsuccessful_response
    end

    context 'when the fusion gui is not running' do
      before do
        Fission::Fusion.stub(:running?).and_return(false)
      end

      it 'should start the VM and return a successful response' do
        $?.should_receive(:exitstatus).and_return(0)
        @starter.should_receive(:`).
                 with("#{@vmrun_cmd} start #{@conf_file_path.gsub(' ', '\ ')} gui 2>&1").
                 and_return("it's all good")

        @starter.start.should be_a_successful_response
      end

      it 'should successfully start the vm headless' do
        $?.should_receive(:exitstatus).and_return(0)
        @starter.should_receive(:`).
                 with("#{@vmrun_cmd} start #{@conf_file_path.gsub(' ', '\ ')} nogui 2>&1").
                 and_return("it's all good")

        @starter.start(:headless => true).should be_a_successful_response
      end

      it 'should return an unsuccessful response if there was an error starting the VM' do
        $?.should_receive(:exitstatus).and_return(1)
        @starter.should_receive(:`).
                 with("#{@vmrun_cmd} start #{@conf_file_path.gsub(' ', '\ ')} gui 2>&1").
                 and_return("it blew up")

        @starter.start.should be_an_unsuccessful_response
      end
    end

    context 'when the fusion gui is running' do
      before do
        Fission::Fusion.stub(:running?).and_return(true)
      end

      it 'should return an unsuccessful response if starting headless' do
        response = @starter.start :headless => true

        error_string = 'It looks like the Fusion GUI is currently running.  '
        error_string << 'A VM cannot be started in headless mode when the Fusion GUI is running.  '
        error_string << 'Exit the Fusion GUI and try again.'

        response.should be_an_unsuccessful_response error_string
      end
    end

  end

end
