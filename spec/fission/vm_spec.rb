require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Vm do

  describe "self.path" do
    it "should return the path of the vm" do
      vm_path = File.join(Fission.config.attributes['vm_dir'], 'foo.vmwarevm').gsub '\\', ''
      Fission::Vm.path('foo').should == vm_path
    end
  end

  describe "self.exists?" do
    it "should return true if the vm exists" do
      FakeFS do
        FileUtils.mkdir_p(Fission::Vm.path('foo'))
        Fission::Vm.exists?('foo').should == true
      end
    end

    it 'should return false if the vm does not exist' do
      FakeFS do
        FileUtils.rm_r(Fission::Vm.path('foo'))
        Fission::Vm.exists?('foo').should == false
      end
    end
  end


  describe "self.clone" do
    it 'should clone the vm to the target' do
      source_vm = 'foo'
      target_vm = 'bar'
      vm_files = [ '.vmx',
                   '.vmxf',
                   '.vmdk',
                   '-s001.vmdk',
                   '-s002.vmdk',
                   '.vmsd' ]
      FakeFS do
        FileUtils.mkdir_p Fission::Vm.path('foo')

        vm_files.each do |file|
          FileUtils.touch File.join(Fission::Vm.path('foo'), "#{source_vm}#{file}")
        end

        Fission::Vm.clone source_vm, target_vm

        File.directory?(Fission::Vm.path('bar')).should == true

        vm_files.each do |file|
          File.file?(File.join(Fission::Vm.path('bar'), "#{target_vm}#{file}")).should == true
        end
      end
    end

  end

end
