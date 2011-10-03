require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Clone do
  include_context 'command_setup'

  before do
    @vm_info = ['foo', 'bar']
    @source_exists_response_mock = mock('source_exists_response')
    @target_exists_response_mock = mock('target_exists_response')
    @clone_response_mock = mock('clone_reponse')
    @start_response_mock = mock('start_reponse')
    @vm_mocks = { 'foo' => @source_exists_response_mock,
                  'bar' => @target_exists_response_mock }
  end

  describe 'execute' do
    subject { Fission::Command::Clone }
    [ [], ['foo'] ].each do |args|
      it_should_not_accept_arguments_of args, 'clone'
    end

    it "should output an error and exit if it can't find the source vm" do
      @source_exists_response_mock.stub_as_successful false
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@source_exists_response_mock)
      Fission::VM.should_not_receive(:exists?).with(@vm_info[1])

      command = Fission::Command::Clone.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM '#{@vm_info.first}'/
    end

    describe 'when the source VM exists' do
      before do
        @source_exists_response_mock.stub_as_successful true
        Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                             and_return(@source_exists_response_mock)
      end

      it "should output an error and exit if the target vm already exists" do
        @target_exists_response_mock.stub_as_successful true
        Fission::VM.should_receive(:exists?).with(@vm_info[1]).
                                             and_return(@target_exists_response_mock)

        command = Fission::Command::Clone.new @vm_info
        lambda { command.execute }.should raise_error SystemExit

        @string_io.string.should match /The target VM '#{@vm_info[1]}' already exists/
      end

      describe 'and the target VM does not exist' do
        before do
          @target_exists_response_mock.stub_as_successful false
          Fission::VM.should_receive(:exists?).with(@vm_info[1]).
                                               and_return(@target_exists_response_mock)
          Fission::VM.should_receive(:clone).with(@vm_info.first, @vm_info[1]).
                                             and_return(@clone_response_mock)
        end

        it 'should try to clone the vm if the source vm exists and the target vm does not' do
          @clone_response_mock.stub_as_successful true

          command = Fission::Command::Clone.new @vm_info
          command.execute

          @string_io.string.should match /Clone complete/
        end

        it 'should output an error and exit if there is an error cloning' do
          @clone_response_mock.stub_as_unsuccessful

          command = Fission::Command::Clone.new @vm_info
          lambda { command.execute }.should raise_error SystemExit

          @string_io.string.should match /There was an error cloning the VM.+it blew up/m
        end

        describe 'with --start' do
          before do
            @clone_response_mock.stub_as_successful true
            @vm_mock.should_receive(:start).and_return(@start_response_mock)
            Fission::VM.should_receive(:new).with(@vm_info[1]).and_return(@vm_mock)
          end

          it 'should try to clone the vm and start it' do
            @start_response_mock.stub_as_successful

            command = Fission::Command::Clone.new @vm_info << '--start'
            command.execute

            @string_io.string.should match /Clone complete/
            @string_io.string.should match /Starting '#{@vm_info[1]}'/
            @string_io.string.should match /VM '#{@vm_info[1]}' started/
          end

          it 'should output an error and exit if there is an error starting the VM after cloning it' do
            @start_response_mock.stub_as_unsuccessful

            command = Fission::Command::Clone.new @vm_info << '--start'
            lambda { command.execute }.should raise_error SystemExit

            @string_io.string.should match /Clone complete/
            @string_io.string.should match /Starting '#{@vm_info[1]}'/
            @string_io.string.should match /There was an error starting the VM.+it blew up/m
          end
        end
      end
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Clone.help

      output.should match /clone source_vm target_vm.+--start/m
    end
  end
end
