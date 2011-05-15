require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::VM do

  describe "self.path" do
    it "should return the path of the vm" do
      vm_path = File.join(Fission.config.attributes['vm_dir'], 'foo.vmwarevm').gsub '\\', ''
      Fission::VM.path('foo').should == vm_path
    end
  end

  describe "self.exists?" do
    it "should return true if the vm exists" do
      FakeFS do
        FileUtils.mkdir_p(Fission::VM.path('foo'))
        Fission::VM.exists?('foo').should == true
      end
    end

    it 'should return false if the vm does not exist' do
      FakeFS do
        FileUtils.rm_r(Fission::VM.path('foo'))
        Fission::VM.exists?('foo').should == false
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
        FileUtils.mkdir_p Fission::VM.path('foo')

        vm_files.each do |file|
          FileUtils.touch File.join(Fission::VM.path('foo'), "#{source_vm}#{file}")
        end

        Fission::VM.clone source_vm, target_vm

        File.directory?(Fission::VM.path('bar')).should == true

        vm_files.each do |file|
          File.file?(File.join(Fission::VM.path('bar'), "#{target_vm}#{file}")).should == true
        end
      end
    end

  end

end
