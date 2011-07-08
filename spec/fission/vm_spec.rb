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
      $?.should_receive(:exitstatus).and_return(0)
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

  describe 'stop' do
    it 'should output that it was successful' do
      $?.should_receive(:exitstatus).and_return(0)
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
      @vm = Fission::VM.new('foo')
      @vm.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} -T fusion stop #{(File.join(Fission::VM.path('foo'), 'foo.vmx')).gsub ' ', '\ '} 2>&1").and_return("it's all good")
      @vm.stop

      @string_io.string.should match /VM stopped/
    end

    it 'it should output that it was unsuccessful' do
      $?.should_receive(:exitstatus).and_return(1)
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
      @vm = Fission::VM.new('foo')
      @vm.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} -T fusion stop #{(File.join(Fission::VM.path('foo'), 'foo.vmx')).gsub ' ', '\ '} 2>&1").and_return("it blew up")
      @vm.stop

      @string_io.string.should match /There was a problem stopping the VM.+it blew up.+/m
    end
  end

  describe 'suspend' do
    it 'should output that it was successful' do
      $?.should_receive(:exitstatus).and_return(0)
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
      @vm = Fission::VM.new('foo')
      @vm.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} -T fusion suspend #{(File.join(Fission::VM.path('foo'), 'foo.vmx')).gsub ' ', '\ '} 2>&1").and_return("it's all good")
      @vm.suspend

      @string_io.string.should match /VM suspended/
    end

    it 'it should output that it was unsuccessful' do
      $?.should_receive(:exitstatus).and_return(1)
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
      @vm = Fission::VM.new('foo')
      @vm.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} -T fusion suspend #{(File.join(Fission::VM.path('foo'), 'foo.vmx')).gsub ' ', '\ '} 2>&1").and_return("it blew up")
      @vm.suspend

      @string_io.string.should match /There was a problem suspending the VM.+it blew up.+/m
    end
  end

  describe 'conf_file' do
    it 'should return the path to the conf file' do
      Fission::VM.new('foo').conf_file.should == File.join(Fission.config.attributes['vm_dir'], 'foo.vmwarevm', 'foo.vmx')
    end
  end

  describe "self.all" do
    it "should return the list of VMs" do
      vm_root = Fission.config.attributes['vm_dir']
      Dir.should_receive(:[]).and_return(["#{File.join vm_root, 'foo.vmwarevm' }", "#{File.join vm_root, 'bar.vmwarevm' }"])

      vm_root = Fission.config.attributes['vm_dir']
      File.should_receive(:directory?).with("#{File.join vm_root, 'foo.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).with("#{File.join vm_root, 'bar.vmwarevm'}").and_return(true)
      Fission::VM.all.should == ['foo', 'bar']
    end

    it "should not return an item in the list if it isn't a directory" do
      vm_root = Fission.config.attributes['vm_dir']
      Dir.should_receive(:[]).and_return(["#{File.join vm_root, 'foo.vmwarevm'}", "#{File.join vm_root, 'bar.vmwarevm'}", "#{File.join vm_root, 'baz.vmwarevm'}"])
      File.should_receive(:directory?).with("#{File.join vm_root, 'foo.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).with("#{File.join vm_root, 'bar.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).with("#{File.join vm_root, 'baz.vmwarevm'}").and_return(false)
      Fission::VM.all.should == ['foo', 'bar']
    end

    it "should only query for items with an extension of .vmwarevm" do
      dir_arg = File.join Fission.config.attributes['vm_dir'], '*.vmwarevm'
      Dir.should_receive(:[]).with(dir_arg).and_return(['foo.vmwarevm', 'bar.vmwarevm'])
      Fission::VM.all
    end
  end

  describe 'self.all_running' do
    it 'should list the running vms' do
      list_output = "Total running VMs: 2\n/vm/foo.vmwarevm/foo.vmx
\n/vm/bar.vmwarevm/bar.vmx\n/vm/baz.vmwarevm/baz.vmx\n"

      $?.should_receive(:exitstatus).and_return(0)
      Fission::VM.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} list").and_return(list_output)
      [ 'foo', 'bar', 'baz'].each do |vm|
        File.should_receive(:exists?).with("/vm/#{vm}.vmwarevm/#{vm}.vmx").and_return(true)
      end

      Fission::VM.all_running.should == ['foo', 'bar', 'baz']
    end

    it 'should output an error and exit if unable to get the list of running vms' do
      $?.should_receive(:exitstatus).and_return(1)
      Fission::VM.should_receive(:`).with("#{Fission.config.attributes['vmrun_bin'].gsub ' ', '\ '} list").and_return("it blew up")
      Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))

      lambda {
        Fission::VM.all_running
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to determine the list of running VMs/
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
      @source_vm = 'foo'
      @target_vm = 'bar'
      @vm_files = ['.vmx', '.vmxf', '.vmdk', '-s001.vmdk', '-s002.vmdk', '.vmsd']

      FakeFS.activate!

      FileUtils.mkdir_p Fission::VM.path('foo')

      @vm_files.each do |file|
        FileUtils.touch File.join(Fission::VM.path('foo'), "#{@source_vm}#{file}")
      end

      ['.vmx', '.vmxf', '.vmdk'].each do |ext|
        File.open(File.join(Fission::VM.path('foo'), "foo#{ext}"), 'w') { |f| f.write 'foo.vmdk'}
      end
    end

    after :each do
      FakeFS.deactivate!
    end

    it 'should copy the vm files to the target' do
      Fission::VM.clone @source_vm, @target_vm

      File.directory?(Fission::VM.path('bar')).should == true

      @vm_files.each do |file|
        File.file?(File.join(Fission::VM.path('bar'), "#{@target_vm}#{file}")).should == true
      end
    end

    it 'should update the target vm config files' do
      Fission::VM.clone @source_vm, @target_vm

      ['.vmx', '.vmxf'].each do |ext|
        File.read(File.join(Fission::VM.path('bar'), "bar#{ext}")).should_not match /foo/
          File.read(File.join(Fission::VM.path('bar'), "bar#{ext}")).should match /bar/
      end
    end

    it 'should not try to update the vmdk file' do
      Fission::VM.clone @source_vm, @target_vm

      File.read(File.join(Fission::VM.path('bar'), 'bar.vmdk')).should match /foo/
    end

    it 'should output that the clone was successful' do
      Fission::VM.clone @source_vm, @target_vm

      @string_io.string.should match /Cloning #{@source_vm} to #{@target_vm}/
        @string_io.string.should match /Configuring #{@target_vm}/
    end

  end

end
