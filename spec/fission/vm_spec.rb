require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::VM do
  before do
    @vm = Fission::VM.new('foo')
    @vm.stub!(:conf_file).and_return(File.join(@vm.path, 'foo.vmx'))
    @conf_file_path = File.join(@vm.path, 'foo.vmx')
    @vmrun_cmd = Fission.config['vmrun_cmd']
    @conf_file_response_mock = mock('conf_file_response')
  end

  describe 'new' do
    it 'should set the vm name' do
      Fission::VM.new('foo').name.should == 'foo'
    end
  end

  describe 'start' do
    before do
      @running_response_mock = mock('running?')

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @running_response_mock.stub_as_successful false
      @conf_file_response_mock.stub_as_successful @conf_file_path
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.start.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is already running' do
      @running_response_mock.stub_as_successful true
      @vm.start.should be_an_unsuccessful_response 'VM is already running'
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful
      @vm.start.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.start.should be_an_unsuccessful_response
    end

    describe 'when the fusion gui is not running' do
      before do
        Fission::Fusion.stub(:running?).and_return(false)
      end

      it 'should start the VM and return a successful response' do
        $?.should_receive(:exitstatus).and_return(0)
        @vm.should_receive(:`).
            with("#{@vmrun_cmd} start #{@conf_file_path.gsub(' ', '\ ')} gui 2>&1").
            and_return("it's all good")

        @vm.start.should be_a_successful_response
      end

      it 'should successfully start the vm headless' do
        $?.should_receive(:exitstatus).and_return(0)
        @vm.should_receive(:`).
            with("#{@vmrun_cmd} start #{@conf_file_path.gsub(' ', '\ ')} nogui 2>&1").
            and_return("it's all good")

        @vm.start(:headless => true).should be_a_successful_response
      end

      it 'should return an unsuccessful response if there was an error starting the VM' do
        $?.should_receive(:exitstatus).and_return(1)
        @vm.should_receive(:`).
            with("#{@vmrun_cmd} start #{@conf_file_path.gsub(' ', '\ ')} gui 2>&1").
            and_return("it blew up")

        @vm.start.should be_an_unsuccessful_response
      end
    end

    describe 'when the fusion gui is running' do
      before do
        Fission::Fusion.stub(:running?).and_return(true)
      end

      it 'should return an unsuccessful response if starting headless' do
        response = @vm.start :headless => true

        error_string = 'It looks like the Fusion GUI is currently running.  '
        error_string << 'A VM cannot be started in headless mode when the Fusion GUI is running.  '
        error_string << 'Exit the Fusion GUI and try again.'

        response.should be_an_unsuccessful_response error_string
      end
    end

  end

  describe 'stop' do
    before do
      @running_response_mock = mock('running?')

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @running_response_mock.stub_as_successful true
      @conf_file_response_mock.stub_as_successful @conf_file_path
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.stop.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is not running' do
      @running_response_mock.stub_as_successful false
      @vm.stop.should be_an_unsuccessful_response 'VM is not running'
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful
      @vm.stop.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.stop.should be_an_unsuccessful_response
    end

    it 'should return a successful response and stop the vm' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} stop #{@conf_file_path.gsub ' ', '\ '} 2>&1").
          and_return("it's all good")

      @vm.stop.should be_a_successful_response
    end

    it 'should return a suscessful response and hard stop the vm' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} stop #{@conf_file_path.gsub ' ', '\ '} hard 2>&1").
          and_return("it's all good")

      @vm.stop(:hard => true).should be_a_successful_response
    end

    it 'it should return an unsuccessful response if unable to stop the vm' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} stop #{@conf_file_path.gsub ' ', '\ '} 2>&1").
          and_return("it blew up")

      @vm.stop.should be_an_unsuccessful_response
    end
  end

  describe 'suspend' do
    before do
      @running_response_mock = mock('running?')

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @running_response_mock.stub_as_successful true
      @conf_file_response_mock.stub_as_successful @conf_file_path
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.suspend.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is not running' do
      @running_response_mock.stub_as_successful false
      @vm.suspend.should be_an_unsuccessful_response 'VM is not running'
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful
      @vm.suspend.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.suspend.should be_an_unsuccessful_response
    end

    it 'should return a successful response' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} suspend #{@conf_file_path.gsub ' ', '\ '} 2>&1").
          and_return("it's all good")

      @vm.suspend.should be_a_successful_response
    end

    it 'it should return an unsuccessful response if unable to suspend the vm' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} suspend #{@conf_file_path.gsub ' ', '\ '} 2>&1").
          and_return("it blew up")

      @vm.suspend.should be_an_unsuccessful_response
    end
  end

  describe 'snapshots' do
    before do
      @vm.stub(:exists?).and_return(true)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      @conf_file_response_mock.stub_as_successful @conf_file_path
    end

    it "should return an unsuccessful repsonse when the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.snapshots.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return a successful response with the list of snapshots' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} listSnapshots #{@conf_file_path.gsub ' ', '\ '} 2>&1").
          and_return("Total snapshots: 3\nsnap foo\nsnap bar\nsnap baz\n")

      response = @vm.snapshots
      response.should be_a_successful_response
      response.data.should == ['snap foo', 'snap bar', 'snap baz']
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.snapshots.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if there was a problem getting the list of snapshots' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} listSnapshots #{@conf_file_path.gsub ' ', '\ '} 2>&1").
          and_return("it blew up")

      @vm.snapshots.should be_an_unsuccessful_response
    end
  end

  describe 'create_snapshot' do
    before do
      @snapshots_response_mock = mock('snapshots')
      @running_response_mock = mock('running?')

      @running_response_mock.stub_as_successful true
      @conf_file_response_mock.stub_as_successful @conf_file_path
      @snapshots_response_mock.stub_as_successful []

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:snapshots).and_return(@snapshots_response_mock)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.create_snapshot('snap_1').should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is not running' do
      @running_response_mock.stub_as_successful false

      response = @vm.create_snapshot 'snap_1'
      error_message = 'The VM must be running in order to take a snapshot.'
      response.should be_an_unsuccessful_response error_message
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful
      @vm.create_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.create_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return a successful response and create a snapshot' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} snapshot #{@conf_file_path.gsub ' ', '\ '} \"bar\" 2>&1").
          and_return("")

      @vm.create_snapshot('bar').should be_a_successful_response
    end

    it 'should return an unsuccessful response if the snapshot name is a duplicate' do
      @snapshots_response_mock.stub_as_successful ['snap_1']
      response = @vm.create_snapshot 'snap_1'
      response.should be_an_unsuccessful_response "There is already a snapshot named 'snap_1'."
    end

    it 'should return an unsuccessful response if there was a problem listing the existing snapshots' do
      @snapshots_response_mock.stub_as_unsuccessful
      @vm.create_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return and unsuccessful response if there was a problem creating the snapshot' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} snapshot #{@conf_file_path.gsub ' ', '\ '} \"bar\" 2>&1").
          and_return("it blew up")

      @vm.create_snapshot('bar').should be_an_unsuccessful_response
    end
  end

  describe 'delete_snapshot' do
    before do
      @snapshots_response_mock = mock('snapshots')
      @running_response_mock = mock('running?')

      @running_response_mock.stub_as_successful true
      @conf_file_response_mock.stub_as_successful @conf_file_path
      @snapshots_response_mock.stub_as_successful ['snap_1']

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:snapshots).and_return(@snapshots_response_mock)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      Fission::Fusion.stub(:running?).and_return(false)
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.delete_snapshot('snap_1').should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.delete_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if the snapshot does not exist' do
      @snapshots_response_mock.stub_as_successful []

      response = @vm.delete_snapshot 'snap_1'
      response.should be_an_unsuccessful_response "Unable to find a snapshot named 'snap_1'."
    end

    it 'should return an unsuccessful response if there was a problem listing the existing snapshots' do
      @snapshots_response_mock.stub_as_unsuccessful
      @vm.delete_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return a successful response and delete the snapshot' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
        with("#{@vmrun_cmd} deleteSnapshot #{@conf_file_path.gsub ' ', '\ '} \"snap_1\" 2>&1").
        and_return("")

      @vm.delete_snapshot('snap_1').should be_a_successful_response
    end

    it 'should return an unsuccessful response if there was a problem deleting the snapshot' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} deleteSnapshot #{@conf_file_path.gsub ' ', '\ '} \"snap_1\" 2>&1").
          and_return("it blew up")

      @vm.delete_snapshot('snap_1').should be_an_unsuccessful_response
    end

    context 'when the gui is running' do
      before do
        Fission::Fusion.stub(:running?).and_return(true)
      end

      it 'should return an unsuccessful response if the vm is not running' do
        @running_response_mock.stub_as_successful false
        response = @vm.delete_snapshot 'snap_1'
        error_message = 'A snapshot cannot be deleted when the GUI is running and the VM is not running.'
        response.should be_an_unsuccessful_response error_message
      end

      it 'should return an unsuccessful response if unable to determine if running' do
        @running_response_mock.stub_as_unsuccessful
        @vm.delete_snapshot('snap_1').should be_an_unsuccessful_response
      end
    end

  end

  describe 'revert_to_snapshot' do
    before do
      @snapshots_response_mock = mock('snapshots')

      @conf_file_response_mock.stub_as_successful @conf_file_path
      @snapshots_response_mock.stub_as_successful ['snap_1']

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:snapshots).and_return(@snapshots_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)
      Fission::Fusion.stub(:running?).and_return(false)
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)
      @vm.revert_to_snapshot('snap_1').should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the Fusion GUI is running' do
      Fission::Fusion.stub(:running?).and_return(true)

      response = @vm.revert_to_snapshot 'snap_1'

      error_string = 'It looks like the Fusion GUI is currently running.  '
      error_string << 'A VM cannot be reverted to a snapshot when the Fusion GUI is running.  '
      error_string << 'Exit the Fusion GUI and try again.'

      response.should be_an_unsuccessful_response error_string
    end

    it 'should return an unsuccessful response if unable to figure out the conf file' do
      @conf_file_response_mock.stub_as_unsuccessful
      @vm.revert_to_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return a successful response and revert to the provided snapshot' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} revertToSnapshot #{@conf_file_path.gsub ' ', '\ '} \"snap_1\" 2>&1").
          and_return("")

      @vm.revert_to_snapshot('snap_1').should be_a_successful_response
    end

    it 'should return an unsuccessful response if the snapshot cannot be found' do
      @snapshots_response_mock.stub_as_successful []
      response = @vm.revert_to_snapshot 'snap_1'
      response.should be_an_unsuccessful_response "Unable to find a snapshot named 'snap_1'."
    end

    it 'should return an unsuccessful response if unable to list the existing snapshots' do
      @snapshots_response_mock.stub_as_unsuccessful
      @vm.revert_to_snapshot('snap_1').should be_an_unsuccessful_response
    end

    it 'should return and unsuccessful response if unable to revert to the snapshot' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} revertToSnapshot #{@conf_file_path.gsub ' ', '\ '} \"snap_1\" 2>&1").
          and_return("it blew up")

      @vm.revert_to_snapshot('snap_1').should be_an_unsuccessful_response
    end

  end

  describe 'exists?' do
    before do
      @conf_file_response = mock('exists')
      @vm.stub(:conf_file).and_return(@conf_file_response)
    end

    it 'should return true if the VM exists' do
      @conf_file_response.stub_as_successful '/vms/foo/foo.vmx'
      @vm.exists?.should == true
    end

    it 'should return false if the VM does not exist' do
      @conf_file_response.stub_as_unsuccessful
      @vm.exists?.should == false
    end
  end

  describe 'hardware_info' do
    before do
      @vm_config_data_response_mock = mock 'vm config data response'
      @vm.stub(:conf_file_data).and_return(@vm_config_data_response_mock)
      @config_data = { 'numvcpus'         => '2',
                       'replay.supported' => "TRUE",
                       'replay.filename'  => '',
                       'memsize'          => '2048',
                       'scsi0:0.redo'     => '' }
    end

    context 'when successful getting the vm config data' do
      before do
        @vm_config_data_response_mock.stub_as_successful @config_data
      end

      context 'when the number of cpus is not specified in the conf file' do
        before do
         @config_data.delete 'numvcpus'
        end

        it 'should return a successful response with a single cpu' do
          response = @vm.hardware_info

          response.should be_a_successful_response
          response.data.should have_key 'cpus'
          response.data['cpus'].should == 1
        end
      end

      it 'should return a successful response with the number of cpus' do
        response = @vm.hardware_info

        response.should be_a_successful_response
        response.data.should have_key 'cpus'
        response.data['cpus'].should == 2
      end

      it 'should return a successful response with the amount of memory' do
        response = @vm.hardware_info

        response.should be_a_successful_response
        response.data.should have_key 'memory'
        response.data['memory'].should == 2048
      end
    end

    context 'when unsuccessfully getting the vm config data' do
      it 'should return an unsuccessful response' do
        @vm_config_data_response_mock.stub_as_unsuccessful
        @vm.hardware_info.should be_an_unsuccessful_response
      end
    end

  end

  describe 'mac_addresses' do
    before do
      @network_info_mock = mock('network_info')
      @vm.should_receive(:network_info).and_return(@network_info_mock)
    end

    it 'should return a successful response with the list of mac addresses' do
      network_data = { 'ethernet0' => { 'mac_address' => '00:0c:29:1d:6a:64',
                                        'ip_address'  => '127.0.0.1' },
                       'ethernet1' => { 'mac_address' => '00:0c:29:1d:6a:75',
                                        'ip_address'  => '127.0.0.2' } }
      @network_info_mock.stub_as_successful network_data

      response = @vm.mac_addresses

      response.should be_a_successful_response
      response.data.should == ['00:0c:29:1d:6a:64', '00:0c:29:1d:6a:75']
    end

    it 'should return a successful response with an empty list if no mac addresses were found' do
      @network_info_mock.stub_as_successful Hash.new

      response = @vm.mac_addresses

      response.should be_a_successful_response
      response.data.should == []
    end

    it 'should return an unsuccessful response if there was an error getting the mac addresses' do
      @network_info_mock.stub_as_unsuccessful

      response = @vm.mac_addresses

      response.should be_an_unsuccessful_response
      response.data.should be_nil
    end

  end

  describe 'network_info' do
    before do
      @conf_file_response_mock.stub_as_successful @conf_file_path

      @vm.should_receive(:conf_file).and_return(@conf_file_response_mock)
      @conf_file_io = StringIO.new
      @lease_1_response_mock = mock('lease_1_response')
      @lease_2_response_mock = mock('lease_1_response')
    end

    it 'should return a successful response with the list of interfaces, macs, and ips' do
      @conf_file_response_mock.stub_as_successful @conf_file_path

      @lease_1 = Fission::Lease.new :ip_address  => '127.0.0.1',
                                    :mac_address => '00:0c:29:1d:6a:64'
      @lease_1_response_mock.stub_as_successful @lease_1

      @lease_2 = Fission::Lease.new :ip_address  => '127.0.0.2',
                                    :mac_address => '00:0c:29:1d:6a:75'
      @lease_2_response_mock.stub_as_successful @lease_2

      vmx_content = 'ide1:0.deviceType = "cdrom-image"
ethernet0.present = "TRUE"
ethernet1.address = "00:0c:29:1d:6a:75"
ethernet0.connectionType = "nat"
ethernet0.generatedAddress = "00:0c:29:1d:6a:64"
ethernet0.virtualDev = "e1000"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"
ethernet0.linkStatePropagation.enable = "TRUE"
ethernet0.generatedAddressenable = "TRUE"
ethernet1.generatedAddressenable = "TRUE"'

      @conf_file_io.string = vmx_content

      File.should_receive(:open).with(@conf_file_path, 'r').
                                 and_yield(@conf_file_io)

      Fission::Lease.should_receive(:find_by_mac_address).
                     with('00:0c:29:1d:6a:64').
                     and_return(@lease_1_response_mock)
      Fission::Lease.should_receive(:find_by_mac_address).
                     with('00:0c:29:1d:6a:75').
                     and_return(@lease_2_response_mock)

      response = @vm.network_info
      response.should be_a_successful_response
      response.data.should == { 'ethernet0' => { 'mac_address'  => '00:0c:29:1d:6a:64',
                                                 'ip_address'   => '127.0.0.1' },
                                'ethernet1' => { 'mac_address'  => '00:0c:29:1d:6a:75',
                                                 'ip_address'   => '127.0.0.2' } }
    end

    it 'should return a successful response with an empty list if there are no macs' do

      vmx_content = 'ide1:0.deviceType = "cdrom-image"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
vmci0.present = "TRUE"
roamingVM.exitBehavior = "go"
tools.syncTime = "TRUE"'

      @conf_file_io.string = vmx_content

      File.should_receive(:open).with(@conf_file_path, 'r').
                                 and_yield(@conf_file_io)

      response = @vm.network_info
      response.should be_a_successful_response
      response.data.should == {}
    end

    it 'should return a successful response without ip addresses if none were found' do
      @lease_1_response_mock.stub_as_successful nil
      @lease_2_response_mock.stub_as_successful nil

      vmx_content = 'ide1:0.deviceType = "cdrom-image"
ethernet0.present = "TRUE"
ethernet1.address = "00:0c:29:1d:6a:75"
ethernet0.connectionType = "nat"
ethernet0.generatedAddress = "00:0c:29:1d:6a:64"
ethernet0.virtualDev = "e1000"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"
ethernet0.linkStatePropagation.enable = "TRUE"
ethernet0.generatedAddressenable = "TRUE"
ethernet1.generatedAddressenable = "TRUE"'

      @conf_file_io.string = vmx_content

      File.should_receive(:open).with(@conf_file_path, 'r').
                                 and_yield(@conf_file_io)

      Fission::Lease.should_receive(:find_by_mac_address).
                     with('00:0c:29:1d:6a:64').
                     and_return(@lease_1_response_mock)
      Fission::Lease.should_receive(:find_by_mac_address).
                     with('00:0c:29:1d:6a:75').
                     and_return(@lease_2_response_mock)

      response = @vm.network_info
      response.should be_a_successful_response
      response.data.should == { 'ethernet0' => { 'mac_address'  => '00:0c:29:1d:6a:64',
                                                 'ip_address'   => nil },
                                'ethernet1' => { 'mac_address'  => '00:0c:29:1d:6a:75',
                                                 'ip_address'   => nil } }
    end

    it 'should return an unsuccessful response with an error if no conf file was found' do
      @conf_file_response_mock.stub_as_unsuccessful

      File.should_not_receive(:open)

      @vm.network_info.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful response if there was an error getting the ip information' do
      @lease_1_response_mock.stub_as_unsuccessful
      @lease_2_response_mock.stub_as_successful nil

      vmx_content = 'ide1:0.deviceType = "cdrom-image"
ethernet0.present = "TRUE"
ethernet1.address = "00:0c:29:1d:6a:75"
ethernet0.connectionType = "nat"
ethernet0.generatedAddress = "00:0c:29:1d:6a:64"
ethernet0.virtualDev = "e1000"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"
ethernet0.linkStatePropagation.enable = "TRUE"
ethernet0.generatedAddressenable = "TRUE"
ethernet1.generatedAddressenable = "TRUE"'

      @conf_file_io.string = vmx_content

      File.should_receive(:open).with(@conf_file_path, 'r').
                                 and_yield(@conf_file_io)

      Fission::Lease.should_receive(:find_by_mac_address).
                     with('00:0c:29:1d:6a:64').
                     and_return(@lease_1_response_mock)
      Fission::Lease.should_receive(:find_by_mac_address).
                     with('00:0c:29:1d:6a:75').
                     and_return(@lease_2_response_mock)

      @vm.network_info.should be_an_unsuccessful_response
    end
  end

  describe 'guestos' do
    before do
      @conf_file_response_mock.stub_as_successful @conf_file_path

      @vm.should_receive(:conf_file).and_return(@conf_file_response_mock)
      @conf_file_io = StringIO.new
    end

    it 'should return a successful response with a string when a guestos is defined' do
      @conf_file_response_mock.stub_as_successful @conf_file_path

      vmx_content = 'vmci0.present = "TRUE"
roamingVM.exitBehavior = "go"
tools.syncTime = "TRUE"
displayName = "sample-debian"
guestOS = "debian5"
nvram = "sample-debian.nvram"
virtualHW.productCompatibility = "hosted"
printers.enabled = "FALSE"
proxyApps.publishToHost = "FALSE"
tools.upgrade.policy = "upgradeAtPowerCycle"'

      @conf_file_io.string = vmx_content

      File.should_receive(:open).with(@conf_file_path, 'r').and_yield(@conf_file_io)

      response = @vm.guestos
      response.should be_a_successful_response
      response.data.should == 'debian5'
    end

    it 'should return a successful response with no data if no guestos defined' do

      vmx_content = 'vmci0.present = "TRUE"
roamingVM.exitBehavior = "go"
tools.syncTime = "TRUE"
nvram = "sample-debian.nvram"
virtualHW.productCompatibility = "hosted"
printers.enabled = "FALSE"
proxyApps.publishToHost = "FALSE"
tools.upgrade.policy = "upgradeAtPowerCycle"'

      @conf_file_io.string = vmx_content

      File.should_receive(:open).with(@conf_file_path, 'r').and_yield(@conf_file_io)

      response = @vm.guestos
      response.should be_a_successful_response
      response.data.should == ''
    end
  end

  describe 'uuids' do
    before do
      @conf_file_response_mock.stub_as_successful @conf_file_path

      @vm.should_receive(:conf_file).and_return(@conf_file_response_mock)
      @vm_config_mock = mock 'vm config'
      @vm_config_data_response_mock = mock 'vm config data response'
      @vm_config_mock.should_receive(:config_data).
                      and_return(@vm_config_data_response_mock)
      Fission::VMConfiguration.stub(:new).and_return(@vm_config_mock)

      @config_data = { 'uuid.location' => '56 4d d8 9c f8 ec 95 73-2e ea a0 f3 7a 1d 6f c8',
                       'uuid.bios' => '56 4d d8 9c f8 ec 95 73-2e ea a0 f3 7a 1d 6f c8',
                       'checkpoint.vmState' => '',
                       'cleanShutdown' => 'TRUE',
                       'replay.supported' => "TRUE",
                       'replay.filename' => '',
                       'scsi0:0.redo' =>'' }
    end

    context 'when successful getting the vm config data' do
      it 'should return a successful response with a hash when uuids are defined' do
        @vm_config_data_response_mock.stub_as_successful @config_data

        response = @vm.uuids
        response.should be_a_successful_response
        response.data.should == { 'bios'     => '56 4d d8 9c f8 ec 95 73-2e ea a0 f3 7a 1d 6f c8',
                                  'location' => '56 4d d8 9c f8 ec 95 73-2e ea a0 f3 7a 1d 6f c8' }
      end

      it 'should return a successful response with empty hash if no uuids are defined' do
        ['location', 'bios'].each { |i| @config_data.delete "uuid.#{i}" }
        @vm_config_data_response_mock.stub_as_successful @config_data

        response = @vm.uuids
        response.should be_a_successful_response
        response.data.should == {}
      end
    end

    context 'when unsuccessfully getting the vm config data' do
      it 'should return an unsuccessful response' do
        @vm_config_data_response_mock.stub_as_unsuccessful
        @vm.uuids.should be_an_unsuccessful_response
      end
    end

  end

  describe 'path' do
    it 'should return the path of the VM' do
      vm_path = File.join(Fission.config['vm_dir'], 'foo.vmwarevm').gsub '\\', ''
      Fission::VM.new('foo').path.should == vm_path
    end
  end

  describe 'state' do
    before do
      @vm_1 = Fission::VM.new 'foo'
      @vm_2 = Fission::VM.new 'bar'

      @all_running_response_mock = mock('all_running')
      @suspended_response_mock = mock('suspended')

      Fission::VM.stub(:all_running).and_return(@all_running_response_mock)
      @all_running_response_mock.stub_as_successful [@vm_2]
    end

    it "should return a successful response and 'not running' when the VM is off" do
      response = @vm.state
      response.should be_a_successful_response
      response.data.should == 'not running'
    end

    it "should return a successful resopnse and 'running' when the VM is running" do
      @all_running_response_mock.stub_as_successful [@vm_1, @vm_2]

      response = @vm.state
      response.should be_a_successful_response
      response.data.should == 'running'
    end

    it "should return a successful response and 'suspended' when the VM is suspended" do
      @suspended_response_mock.stub_as_successful true

      @vm.stub(:suspended?).and_return(@suspended_response_mock)

      response = @vm.state
      response.should be_a_successful_response
      response.data.should == 'suspended'
    end

    it 'should return an unsuccessful response if there was an error getting the running VMs' do
      @all_running_response_mock.stub_as_unsuccessful
      @vm.state.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful repsonse if there was an error determining if the VM is suspended' do
      @suspended_response_mock.stub_as_unsuccessful
      @vm.stub(:suspended?).and_return(@suspended_response_mock)
      @vm.state.should be_an_unsuccessful_response
    end
  end

  describe 'running?' do
    before do
      @all_running_response_mock = mock('all_running')

      Fission::VM.stub(:all_running).and_return(@all_running_response_mock)
    end

    it 'should return a successful response and false when the vm is not running' do
      @all_running_response_mock.stub_as_successful []
      response = @vm.running?
      response.should be_a_successful_response
      response.data.should == false
    end

    it 'should return a successful response and true if the vm is running' do
      @all_running_response_mock.stub_as_successful [Fission::VM.new('foo')]

      response = @vm.running?
      response.should be_a_successful_response
      response.data.should == true
    end

    it 'should return an unsuccessful repsponse if there is an error getting the list of running vms' do
      @all_running_response_mock.stub_as_unsuccessful
      @vm.running?.should be_an_unsuccessful_response
    end

  end

  describe 'suspend_file_exists?' do
    before do
      FakeFS.activate!
      FileUtils.mkdir_p @vm.path
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    it 'should return true if the suspend file exists' do
      FileUtils.touch(File.join(@vm.path, "#{@vm.name}.vmem"))
      @vm.suspend_file_exists?.should == true
    end

    it 'should return false if the suspend file does not exist' do
      @vm.suspend_file_exists?.should == false
    end

  end

  describe 'suspended?' do
    before do
      @running_response_mock = mock('running?')
      @vm.stub(:running?).and_return(@running_response_mock)
    end

    describe 'when the vm is not running' do
      before do
        @running_response_mock.stub_as_successful false
      end

      it 'should return a successful response and true if a .vmem file exists in the vm dir' do
        @vm.stub(:suspend_file_exists?).and_return(true)

        response = @vm.suspended?
        response.should be_a_successful_response
        response.data.should == true
      end

      it 'should return a successful response and false if a .vmem file is not found in the vm dir' do
        @vm.stub(:suspend_file_exists?).and_return(false)

        response = @vm.suspended?
        response.should be_a_successful_response
        response.data.should == false
      end
    end

    it 'should return a successful response and false if the vm is running' do
      @running_response_mock.stub_as_successful true

      response = @vm.suspended?
      response.should be_a_successful_response
      response.data.should == false
    end

    it 'should return an unsuccessful repsponse if there is an error getting the list of running vms' do
      @running_response_mock.stub_as_unsuccessful
      @vm.suspended?.should be_an_unsuccessful_response
    end

  end

  describe 'conf_file_data' do
    before do
      @vm_config_mock          = mock 'vm config'
      @vm_config_response_mock = mock 'vm config response'

      Fission::VMConfiguration.should_receive(:new).with(@vm).
                                                    and_return(@vm_config_mock)
    end

    it 'should return a successful response with the data' do
      @vm_config_response_mock.stub_as_successful({ 'numvcpus' => '2' })

      @vm_config_mock.should_receive(:config_data).
                      and_return(@vm_config_response_mock)
      config_data = @vm.conf_file_data
      config_data.should be_a_successful_response
      config_data.data.should == { 'numvcpus' => '2' }
    end

    it 'should return an unsuccessful response' do
      @vm_config_mock.should_receive(:config_data).
                      and_return(@vm_config_response_mock)
      @vm_config_response_mock.stub_as_unsuccessful
      @vm.conf_file_data.should be_an_unsuccessful_response
    end
  end

  describe 'conf_file' do
    before do
      FakeFS.activate!
      @vm_root_dir = Fission::VM.new('foo').path
      FileUtils.mkdir_p(@vm_root_dir)
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    it 'should return a successful response with the path to the conf file' do
      file_path = File.join(@vm_root_dir, 'foo.vmx')
      FileUtils.touch(file_path)

      response = Fission::VM.new('foo').conf_file
      response.should be_a_successful_response
      response.data.should == file_path
    end

    it 'should return an unsuccessful response with an error if no vmx file was found' do
      response = Fission::VM.new('foo').conf_file
      response.successful?.should == false
      response.message.should match /Unable to find a config file for VM 'foo' \(in '#{File.join(@vm_root_dir, '\*\.vmx')}'\)/m
    end

    describe 'when the VM name and conf file name do not match' do
      it 'should return the path to the conf file' do
        file_path = File.join(@vm_root_dir, 'bar.vmx')
        FileUtils.touch(file_path)

        response = Fission::VM.new('foo').conf_file
        response.should be_a_successful_response
        response.data.should == file_path
      end
    end

    describe 'if multiple vmx files are found' do
      it 'should use return a successful response with the conf file which matches the VM name if it exists' do
        ['foo.vmx', 'bar.vmx'].each do |file|
          FileUtils.touch(File.join(@vm_root_dir, file))
        end

        response = Fission::VM.new('foo').conf_file
        response.should be_a_successful_response
        response.data.should == File.join(@vm_root_dir, 'foo.vmx')
      end

      it 'should return an unsuccessful object if none of the conf files matches the VM name' do
        ['bar.vmx', 'baz.vmx'].each do |file|
          FileUtils.touch(File.join(@vm_root_dir, file))
        end
        Fission::VM.new('foo').conf_file

        response = Fission::VM.new('foo').conf_file
        response.successful?.should == false
        error_regex = /Multiple config files found for VM 'foo' \('bar\.vmx', 'baz\.vmx' in '#{@vm_root_dir}'/m
        response.message.should match error_regex
      end
    end

  end

  describe "self.all" do
    before do
      @vm_1_mock = mock('vm_1')
      @vm_2_mock = mock('vm_2')
    end

    it "should return a successful object with the list of VM objects" do
      vm_root = Fission.config['vm_dir']
      Dir.should_receive(:[]).
          and_return(["#{File.join vm_root, 'foo.vmwarevm' }", "#{File.join vm_root, 'bar.vmwarevm' }"])

      vm_root = Fission.config['vm_dir']
      File.should_receive(:directory?).with("#{File.join vm_root, 'foo.vmwarevm'}").
                                       and_return(true)
      File.should_receive(:directory?).with("#{File.join vm_root, 'bar.vmwarevm'}").
                                       and_return(true)

      Fission::VM.should_receive(:new).with('foo').and_return(@vm_1_mock)
      Fission::VM.should_receive(:new).with('bar').and_return(@vm_2_mock)

      response = Fission::VM.all
      response.should be_a_successful_response
      response.data.should == [@vm_1_mock, @vm_2_mock]
    end

    it "should return a successful object and not return an item in the list if it isn't a directory" do
      vm_root = Fission.config['vm_dir']
      Dir.should_receive(:[]).
          and_return((['foo', 'bar', 'baz'].map { |i| File.join vm_root, "#{i}.vmwarevm"}))
      File.should_receive(:directory?).
           with("#{File.join vm_root, 'foo.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).
           with("#{File.join vm_root, 'bar.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).
           with("#{File.join vm_root, 'baz.vmwarevm'}").and_return(false)

      Fission::VM.should_receive(:new).with('foo').and_return(@vm_1_mock)
      Fission::VM.should_receive(:new).with('bar').and_return(@vm_2_mock)

      response = Fission::VM.all
      response.should be_a_successful_response
      response.data.should == [@vm_1_mock, @vm_2_mock]
    end

    it "should only query for items with an extension of .vmwarevm" do
      dir_arg = File.join Fission.config['vm_dir'], '*.vmwarevm'
      Dir.should_receive(:[]).with(dir_arg).
                              and_return(['foo.vmwarevm', 'bar.vmwarevm'])
      Fission::VM.all
    end
  end

  describe 'self.all_running' do
    before do
      @vm_1 = Fission::VM.new 'foo'
      @vm_2 = Fission::VM.new 'bar'
      @vm_3 = Fission::VM.new 'baz'
      @vm_names_and_objs = { 'foo' => @vm_1, 'bar' => @vm_2, 'baz' => @vm_3 }
    end

    it 'should return a successful response with the list of running vms' do
      list_output = "Total running VMs: 2\n/vm/foo.vmwarevm/foo.vmx\n"
      list_output << "/vm/bar.vmwarevm/bar.vmx\n/vm/baz.vmwarevm/baz.vmx\n"

      $?.should_receive(:exitstatus).and_return(0)
      Fission::VM.should_receive(:`).
                  with("#{@vmrun_cmd} list").
                  and_return(list_output)
      [ 'foo', 'bar', 'baz'].each do |vm|
        File.should_receive(:exists?).with("/vm/#{vm}.vmwarevm/#{vm}.vmx").
                                      and_return(true)

        Fission::VM.should_receive(:new).with(vm).
                                         and_return(@vm_names_and_objs[vm])
      end

      response = Fission::VM.all_running
      response.should be_a_successful_response
      response.data.should == [@vm_1, @vm_2, @vm_3]
    end

    it 'should return a successful response with the VM dir name if it differs from the .vmx file name' do
      vm_dir_file = { 'foo' => 'foo', 'bar' => 'diff', 'baz' => 'baz'}
      list_output = "Total running VMs: 3\n"
      vm_dir_file.each_pair do |dir, file|
        list_output << "/vm/#{dir}.vmwarevm/#{file}.vmx\n"
        File.should_receive(:exists?).with("/vm/#{dir}.vmwarevm/#{file}.vmx").
                                      and_return(true)
        Fission::VM.should_receive(:new).with(dir).
                                         and_return(@vm_names_and_objs[dir])
      end

      $?.should_receive(:exitstatus).and_return(0)
      Fission::VM.should_receive(:`).
                  with("#{@vmrun_cmd} list").
                  and_return(list_output)

      response = Fission::VM.all_running
      response.should be_a_successful_response
      response.data.should == [@vm_1, @vm_2, @vm_3]
    end

    it 'should return an unsuccessful response if unable to get the list of running vms' do
      $?.should_receive(:exitstatus).and_return(1)
      Fission::VM.should_receive(:`).
                  with("#{@vmrun_cmd} list").
                  and_return("it blew up")
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))

      Fission::VM.all_running.should be_an_unsuccessful_response
    end
  end

  describe "self.clone" do
    before do
      @source_vm = Fission::VM.new 'foo'
      @target_vm = Fission::VM.new 'bar'
      @source_path = @source_vm.path
      @target_path = @target_vm.path

      @clone_response_mock = mock('clone_response')
      @vm_files = ['.vmx', '.vmxf', '.vmdk', '-s001.vmdk', '-s002.vmdk', '.vmsd']

      FakeFS.activate!

      FileUtils.mkdir_p @source_path

      @vm_files.each do |file|
        FileUtils.touch "#{@source_path}/#{@source_vm.name}#{file}"
      end

      ['.vmx', '.vmxf', '.vmdk'].each do |ext|
        File.open("#{@source_path}/foo#{ext}", 'w') { |f| f.write 'foo.vmdk'}
      end

      @source_vm.stub(:exists?).and_return(true)
      @target_vm.stub(:exists?).and_return(false)

      Fission::VM.stub(:new).with(@source_vm.name).
                             and_return(@source_vm)
      Fission::VM.stub(:new).with(@target_vm.name).
                             and_return(@target_vm)

      vmx_content = 'ide1:0.deviceType = "cdrom-image"
nvram = "foo.nvram"
ethernet0.present = "TRUE"
ethernet1.address = "00:0c:29:1d:6a:75"
ethernet0.connectionType = "nat"
ethernet0.generatedAddress = "00:0c:29:1d:6a:64"
ethernet0.virtualDev = "e1000"
tools.remindInstall = "TRUE"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"
uuid.action = "keep"
ethernet0.linkStatePropagation.enable = "TRUE"
ethernet0.generatedAddressenable = "TRUE"
ethernet1.generatedAddressenable = "TRUE"'

      File.open("#{@source_path}/#{@source_vm.name}.vmx", 'w') do |f|
        f.write vmx_content
      end

      ['.vmx', '.vmxf'].each do |ext|
        File.stub(:binary?).
             with("#{@target_path}/#{@target_vm.name}#{ext}").
             and_return(false)
      end

      File.stub(:binary?).
           with("#{@target_path}/#{@target_vm.name}.vmdk").
           and_return(true)
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    it "should return an unsuccessful response if the source vm doesn't exist" do
      @source_vm.stub(:exists?).and_return(false)
      response = Fission::VM.clone @source_vm.name, @target_vm.name
      response.should be_an_unsuccessful_response 'VM does not exist'
    end

    it "should return an unsuccessful response if the target vm exists" do
      @target_vm.stub(:exists?).and_return(true)
      response = Fission::VM.clone @source_vm.name, @target_vm.name
      response.should be_an_unsuccessful_response 'VM already exists'
    end

    it 'should copy the vm files to the target' do
      Fission::VM.clone @source_vm.name, @target_vm.name

      File.directory?(@target_path).should == true

      @vm_files.each do |file|
        File.file?("#{@target_path}/bar#{file}").should == true
      end
    end

    it "should copy the vm files to the target if a file name doesn't match the directory" do
      FileUtils.touch "#{@source_path}/other_name.nvram"

      Fission::VM.clone @source_vm.name, @target_vm.name

      File.directory?(@target_path).should == true

      @vm_files.each do |file|
        File.file?("#{@target_path}/#{@target_vm.name}#{file}").should == true
      end

      File.file?("#{@target_path}/bar.nvram").should == true
    end

    it "should copy the vm files to the target if a sparse disk file name doesn't match the directory" do
      FileUtils.touch "#{@source_path}/other_name-s003.vmdk"

      Fission::VM.clone @source_vm.name, @target_vm.name

      File.directory?(@target_path).should == true

      @vm_files.each do |file|
        File.file?("#{@target_path}/#{@target_vm.name}#{file}").should == true
      end

      File.file?("#{@target_path}/bar-s003.vmdk").should == true
    end

    it 'should update the target vm config files' do
      Fission::VM.clone @source_vm.name, @target_vm.name

      ['.vmx', '.vmxf'].each do |ext|
        File.read("#{@target_path}/bar#{ext}").should_not match /foo/
        File.read("#{@target_path}/bar#{ext}").should match /bar/
      end
    end

    it 'should disable VMware tools warning in the conf file' do
      Fission::VM.clone @source_vm.name, @target_vm.name

      pattern = /^tools\.remindInstall = "FALSE"/

      File.read("#{@target_path}/bar.vmx").should match pattern
    end

    it 'should remove auto generated MAC addresses from the conf file' do
      Fission::VM.clone @source_vm.name, @target_vm.name

      pattern = /^ethernet\.+generatedAddress.+/

      File.read("#{@target_path}/bar.vmx").should_not match pattern
    end

    it 'should setup the conf file to generate a new uuid' do
      Fission::VM.clone @source_vm.name, @target_vm.name

      pattern = /^uuid\.action = "create"/

      File.read("#{@target_path}/bar.vmx").should match pattern
    end

    it "should not try to update the vmdk file if it's not a sparse disk" do
      Fission::VM.clone @source_vm.name, @target_vm.name

      File.read("#{@target_path}/bar.vmdk").should match /foo/
    end

    it 'should return a successful response if clone was successful' do
      Fission::VM.clone(@source_vm.name, @target_vm.name).should be_a_successful_response
    end

    describe 'when a sparse disk is found' do
      it "should update the vmdk" do
        File.rspec_reset
        File.stub(:binary?).and_return(false)

        Fission::VM.clone @source_vm.name, @target_vm.name

        File.read("#{@target_path}/bar.vmdk").should match /bar/
      end
    end

  end

  describe 'self.all_with_status' do
    before do
      @vm_1 = Fission::VM.new 'foo'
      @vm_2 = Fission::VM.new 'bar'
      @vm_2.stub(:suspend_file_exists?).and_return('true')
      @vm_3 = Fission::VM.new 'baz'

      @all_vms_response_mock = mock('all_vms_mock')
      @all_vms_response_mock.stub_as_successful [@vm_1, @vm_2, @vm_3]

      @all_running_response_mock = mock('all_running_mock')
      @all_running_response_mock.stub_as_successful [@vm_1]

      Fission::VM.stub(:all).and_return(@all_vms_response_mock)
      Fission::VM.stub(:all_running).and_return(@all_running_response_mock)
    end

    it 'should return a sucessful response with the VMs and their status' do
      response = Fission::VM.all_with_status
      response.should be_a_successful_response
      response.data.should == { 'foo' => 'running',
                                'bar' => 'suspended',
                                'baz' => 'not running' }

    end

    it 'should return an unsuccessful response if unable to get all of the VMs' do
      @all_vms_response_mock.stub_as_unsuccessful
      Fission::VM.all_with_status.should be_an_unsuccessful_response
    end

    it 'should return an unsuccessful repsonse if unable to get the running VMs' do
      @all_running_response_mock.stub_as_unsuccessful
      Fission::VM.all_with_status.should be_an_unsuccessful_response
    end

  end

  describe 'delete' do
    before do
      @running_response_mock = mock('running?')
      @running_response_mock.stub_as_successful false

      @vm.stub(:exists?).and_return(true)
      @vm.stub(:running?).and_return(@running_response_mock)
      @vm.stub(:conf_file).and_return(@conf_file_response_mock)

      @target_vm = 'foo'
      @vm_files = %w{ .vmx .vmxf .vmdk -s001.vmdk -s002.vmdk .vmsd }
      FakeFS.activate!

      FileUtils.mkdir_p Fission::VM.new(@target_vm).path

      @vm_files.each do |file|
        FileUtils.touch File.join(Fission::VM.new(@target_vm).path, "#{@target_vm}#{file}")
      end
    end

    after do
      FakeFS.deactivate!
    end

    it "should return an unsuccessful response if the vm doesn't exist" do
      @vm.stub(:exists?).and_return(false)

      response = @vm.delete
      response.should be_an_unsuccessful_response 'VM does not exist'
    end

    it 'should return an unsuccessful response if the vm is running' do
      @running_response_mock.stub_as_successful true

      response = @vm.delete
      response.should be_an_unsuccessful_response 'The VM must not be running in order to delete it.'
    end

    it 'should return an unsuccessful response if unable to determine if running' do
      @running_response_mock.stub_as_unsuccessful

      response = @vm.delete
      response.should be_an_unsuccessful_response
    end

    it "should delete the target vm files" do
      Fission::Metadata.stub!(:delete_vm_info)

      @vm.delete

      @vm_files.each do |file|
        File.exists?(File.join(Fission::VM.new(@target_vm).path, "#{@target_vm}#{file}")).should == false
      end
    end

    it 'should delete the target vm metadata' do
      Fission::Metadata.should_receive(:delete_vm_info)
      @vm.delete
    end

    it 'should return a successful reponsse object' do
      Fission::Metadata.stub!(:delete_vm_info)
      @vm.delete.should be_a_successful_response
    end

  end
end
