require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Info do
  include_context 'command_setup'

  before do
    @target_vm = ['foo']
    Fission::VM.stub!(:new).and_return(@vm_mock)

    @network_info_response_mock = mock('network_info_response')

    @vm_mock.stub(:name).and_return(@target_vm.first)
  end

  describe 'execute' do
    before do
      @vm_mock.stub(:network_info).and_return(@network_info_response_mock)
      @network_info = { 'ethernet0' => { 'mac_address'  => '00:11:22:33:AA:BB',
                                         'ip_address'   => '192.168.1.10' },
                        'ethernet1' => { 'mac_address'  => '00:11:22:33:AA:BB',
                                         'ip_address'   => '192.168.1.10' } }
    end

    subject { Fission::Command::Info }

    it_should_not_accept_arguments_of [], 'info'

    it 'should output the vm name' do
      @network_info_response_mock.stub_as_successful Hash.new

      command = Fission::Command::Info.new @target_vm
      command.execute

      @string_io.string.should match /foo/
    end

    it 'should output the network info' do
      @network_info_response_mock.stub_as_successful @network_info

      command = Fission::Command::Info.new @target_vm
      command.execute

      @string_io.string.should match /ethernet0/
      @string_io.string.should match /00:11:22:33:AA:BB/
      @string_io.string.should match /192\.168\.1\.10/
    end

    it 'should output an error and exit if there was an error getting the network info' do
      @network_info_response_mock.stub_as_unsuccessful

      command = Fission::Command::Info.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /There was an error getting the network info.+it blew up.+/m
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Info.help

      output.should match /info vm_name/
    end
  end
end
