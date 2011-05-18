require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::VM do
  before :each do
    @string_io = StringIO.new
  end

  describe 'new' do
    it 'should set the vm name' do
      Fission::VM.new('foo').name.should == 'foo'
    end
  end

  describe 'start' do
    it 'should output that it was successful' do
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
      @vm = Fission::VM.new('foo')
      @vm.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} -T fusion start #{(File.join(Fission::VM.path('foo'), 'foo.vmx')).gsub ' ', '\ '} gui 2>&1").and_return("it's all good")
      @vm.start

      @string_io.string.should match /VM started/
    end

    it 'it should output that it was unsuccessful' do
      $?.should_receive(:exitstatus).and_return(1)
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
      @vm = Fission::VM.new('foo')
      @vm.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} -T fusion start #{(File.join(Fission::VM.path('foo'), 'foo.vmx')).gsub ' ', '\ '} gui 2>&1").and_return("it blew up")
      @vm.start

      @string_io.string.should match /There was a problem starting the VM.+it blew up.+/m
    end
  end

  describe 'conf_file' do
    it 'should return the path to the conf file' do
      Fission::VM.new('foo').conf_file.should == File.join(Fission.config.attributes['vm_dir'], 'foo.vmwarevm', 'foo.vmx')
    end
  end

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
    before :each do
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    end

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

        File.open(File.join(Fission::VM.path('foo'), 'foo.vmx'), 'w') { |f| f.write 'foo.vmdk'}

        Fission::VM.clone source_vm, target_vm

        File.directory?(Fission::VM.path('bar')).should == true

        vm_files.each do |file|
          File.file?(File.join(Fission::VM.path('bar'), "#{target_vm}#{file}")).should == true
        end

        conf_file = File.read File.join(Fission::VM.path('bar'), 'bar.vmx')
        conf_file.should == 'bar.vmdk'
      end

      @string_io.string.should match /Cloning #{source_vm} to #{target_vm}/
      @string_io.string.should match /Configuring #{target_vm}/
    end

  end

end
