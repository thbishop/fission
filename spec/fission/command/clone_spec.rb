require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Clone do
  before :all do
    @vm_info = ['foo', 'bar']
  end

  describe 'execute' do
    it 'should check to see if the source and target vms exist' do
      @vm_info.each do |vm|
        Fission::Vm.should_receive(:exists?).with(vm)
      end

      Fission::Vm.stub!(:clone)

      Fission::Command::Clone.execute @vm_info
    end

    it "should output an error and exit if it can't find the source vm"

    it "should output an error and exit if it can't find the target vm"

    it 'should copy the source vm to the target vm' do
      Fission::Vm.stub!(:exists?).and_return(true)
      Fission::Vm.should_receive(:clone).with(@vm_info.first, @vm_info[1])
      Fission::Command::Clone.execute @vm_info
    end

  end
end
