require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Clone do
  before :all do
    @vm_info = ['foo', 'bar']
    @string_io = StringIO.new
  end

  describe 'execute' do
    it "should output an error and exit if it can't find the source vm" do
      Fission.should_receive(:ui).and_return(Fission::UI.new(@string_io))
      Fission::Vm.should_receive(:exists?).with(@vm_info.first).and_return(false)
      Fission::Vm.should_not_receive(:exists?).with(@vm_info[1])

      lambda {
        Fission::Command::Clone.execute @vm_info
      }.should raise_error SystemExit

      @string_io.string.should match(/Unable to find the source vm #{@vm_info.first}/)
    end


    it "should output an error and exit if the target vm already exists" do
      Fission.should_receive(:ui).and_return(Fission::UI.new(@string_io))
      @vm_info.each do |vm|
        Fission::Vm.should_receive(:exists?).with(vm).and_return(true)
      end

      lambda {
        Fission::Command::Clone.execute @vm_info
      }.should raise_error SystemExit

      @string_io.string.should match(/The target vm #{@vm_info[1]} already exists/)
    end

    it 'should try to clone the vm if the source vm exists and the target vm does not' do
      Fission::Vm.should_receive(:exists?).with(@vm_info.first).and_return(true)
      Fission::Vm.should_receive(:exists?).with(@vm_info[1]).and_return(false)
      Fission::Vm.should_receive(:clone).with(@vm_info.first, @vm_info[1])
      Fission::Command::Clone.execute @vm_info
    end

  end
end
