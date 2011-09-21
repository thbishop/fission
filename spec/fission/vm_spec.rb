require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::VM do
  before do
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @vm = Fission::VM.new('foo')
    @vm.stub!(:conf_file).and_return(File.join(Fission::VM.path('foo'), 'foo.vmx'))
    @vmrun_cmd = Fission.config.attributes['vmrun_cmd']
  end

  describe 'new' do
    it 'should set the vm name' do
      Fission::VM.new('foo').name.should == 'foo'
    end
  end

  describe 'start' do
    it 'should return a successful response object' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} start #{@vm.conf_file.gsub(' ', '\ ')} gui 2>&1").
          and_return("it's all good")

      response = @vm.start
      response.successful?.should == true
      response.output.should == ''
    end

    it 'should successfully start the vm headless' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} start #{@vm.conf_file.gsub(' ', '\ ')} nogui 2>&1").
          and_return("it's all good")

      response = @vm.start(:headless => true)
      response.successful?.should == true
      response.output.should == ''
    end

    it 'should return an unsuccessful response' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} start #{@vm.conf_file.gsub(' ', '\ ')} gui 2>&1").
          and_return("it blew up")

      response = @vm.start
      response.successful?.should == false
      response.code.should == 1
      response.output.should == 'it blew up'
    end
  end

  describe 'stop' do
    it 'should output that it was successful' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} stop #{@vm.conf_file.gsub ' ', '\ '} 2>&1").
          and_return("it's all good")
      @vm.stop

      @string_io.string.should match /VM stopped/
    end

    it 'it should output that it was unsuccessful' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} stop #{@vm.conf_file.gsub ' ', '\ '} 2>&1").
          and_return("it blew up")
      @vm.stop

      @string_io.string.should match /There was a problem stopping the VM.+it blew up.+/m
    end
  end

  describe 'suspend' do
    it 'should output that it was successful' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} suspend #{@vm.conf_file.gsub ' ', '\ '} 2>&1").
          and_return("it's all good")
      @vm.suspend

      @string_io.string.should match /VM suspended/
    end

    it 'it should output that it was unsuccessful' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} suspend #{@vm.conf_file.gsub ' ', '\ '} 2>&1").
          and_return("it blew up")
      @vm.suspend

      @string_io.string.should match /There was a problem suspending the VM.+it blew up.+/m
    end
  end

  describe 'snapshots' do
    it 'should return the list of snapshots' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} listSnapshots #{@vm.conf_file.gsub ' ', '\ '} 2>&1").
          and_return("Total snapshots: 3\nsnap foo\nsnap bar\nsnap baz\n")
      @vm.snapshots.should == ['snap foo', 'snap bar', 'snap baz']
    end

    it 'should print an error and exit if there was a problem getting the list of snapshots' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} listSnapshots #{@vm.conf_file.gsub ' ', '\ '} 2>&1").
          and_return("it blew up\n")
      lambda { @vm.snapshots }.should raise_error SystemExit
      @string_io.string.should match /error getting the list of snapshots/
      @string_io.string.should match /error was.+it blew up/m
    end
  end

  describe 'create_snapshot' do
    it 'should create a snapshot' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} snapshot #{@vm.conf_file.gsub ' ', '\ '} \"bar\" 2>&1").
          and_return("")

      response = @vm.create_snapshot 'bar'
      response.successful?.should == true
      response.output.should == ''
    end

    it 'should print an error and exit if there was a problem creating the snapshot' do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} snapshot #{@vm.conf_file.gsub ' ', '\ '} \"bar\" 2>&1").
          and_return("it blew up")

      response = @vm.create_snapshot 'bar'
      response.successful?.should == false
      response.code.should == 1
      response.output.should == 'it blew up'
    end
  end

  describe 'revert_to_snapshot' do
    it 'should revert to the provided snapshot' do
      $?.should_receive(:exitstatus).and_return(0)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} revertToSnapshot #{@vm.conf_file.gsub ' ', '\ '} \"bar\" 2>&1").
          and_return("")

      response = @vm.revert_to_snapshot 'bar'
      response.successful?.should == true
      response.output.should == ''
    end

    it "should print an error and exit if the snapshot doesn't exist" do
      $?.should_receive(:exitstatus).and_return(1)
      @vm.should_receive(:`).
          with("#{@vmrun_cmd} revertToSnapshot #{@vm.conf_file.gsub ' ', '\ '} \"bar\" 2>&1").
          and_return("it blew up")

      response = @vm.revert_to_snapshot 'bar'
      response.successful?.should == false
      response.code.should == 1
      response.output.should == 'it blew up'
    end
  end

  describe 'conf_file' do
    before do
      FakeFS.activate!
      @vm_root_dir = Fission::VM.path('foo')
      FileUtils.mkdir_p(@vm_root_dir)
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    it 'should return the path to the conf file' do
      file_path = File.join(@vm_root_dir, 'foo.vmx')
      FileUtils.touch(file_path)
      Fission::VM.new('foo').conf_file.should == file_path
    end

    it 'should output an error and exit if no vmx file was found' do
      lambda {
        FileUtils.mkdir_p(@vm_root_dir)
        Fission::VM.new('foo').conf_file
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find a config file for VM 'foo' \(in '#{File.join(@vm_root_dir, '\*\.vmx')}'\)/m
    end

    describe 'when the VM name and conf file name do not match' do
      it 'should return the path to the conf file' do
        file_path = File.join(@vm_root_dir, 'bar.vmx')
        FileUtils.touch(file_path)
        Fission::VM.new('foo').conf_file.should == file_path
      end
    end

    describe 'if multiple vmx files are found' do
      before do
        FileUtils.mkdir_p(@vm_root_dir)
      end

      it 'should use the conf file which matches the VM name if it exists' do
        ['foo.vmx', 'bar.vmx'].each do |file|
          FileUtils.touch(File.join(@vm_root_dir, file))
        end
        Fission::VM.new('foo').conf_file.should == File.join(@vm_root_dir, 'foo.vmx')
      end

      it 'should output an error and exit' do
        lambda {
          ['bar.vmx', 'baz.vmx'].each do |file|
            FileUtils.touch(File.join(@vm_root_dir, file))
          end
          Fission::VM.new('foo').conf_file
        }.should raise_error SystemExit

        @string_io.string.should match /Multiple config files found for VM 'foo' \('bar\.vmx', 'baz\.vmx' in '#{@vm_root_dir}'/m
      end
    end

  end

  describe "self.all" do
    it "should return the list of VMs" do
      vm_root = Fission.config.attributes['vm_dir']
      Dir.should_receive(:[]).
          and_return(["#{File.join vm_root, 'foo.vmwarevm' }", "#{File.join vm_root, 'bar.vmwarevm' }"])

      vm_root = Fission.config.attributes['vm_dir']
      File.should_receive(:directory?).with("#{File.join vm_root, 'foo.vmwarevm'}").
                                       and_return(true)
      File.should_receive(:directory?).with("#{File.join vm_root, 'bar.vmwarevm'}").
                                       and_return(true)
      Fission::VM.all.should == ['foo', 'bar']
    end

    it "should not return an item in the list if it isn't a directory" do
      vm_root = Fission.config.attributes['vm_dir']
      Dir.should_receive(:[]).
          and_return((['foo', 'bar', 'baz'].map { |i| File.join vm_root, "#{i}.vmwarevm"}))
      File.should_receive(:directory?).
           with("#{File.join vm_root, 'foo.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).
           with("#{File.join vm_root, 'bar.vmwarevm'}").and_return(true)
      File.should_receive(:directory?).
           with("#{File.join vm_root, 'baz.vmwarevm'}").and_return(false)
      Fission::VM.all.should == ['foo', 'bar']
    end

    it "should only query for items with an extension of .vmwarevm" do
      dir_arg = File.join Fission.config.attributes['vm_dir'], '*.vmwarevm'
      Dir.should_receive(:[]).with(dir_arg).
                              and_return(['foo.vmwarevm', 'bar.vmwarevm'])
      Fission::VM.all
    end
  end

  describe 'self.all_running' do
    it 'should list the running vms' do
      list_output = "Total running VMs: 2\n/vm/foo.vmwarevm/foo.vmx\n"
      list_output << "/vm/bar.vmwarevm/bar.vmx\n/vm/baz.vmwarevm/baz.vmx\n"

      $?.should_receive(:exitstatus).and_return(0)
      Fission::VM.should_receive(:`).
                  with("#{@vmrun_cmd} list").
                  and_return(list_output)
      [ 'foo', 'bar', 'baz'].each do |vm|
        File.should_receive(:exists?).with("/vm/#{vm}.vmwarevm/#{vm}.vmx").
                                      and_return(true)
      end

      Fission::VM.all_running.should == ['foo', 'bar', 'baz']
    end

    it 'should output the VM dir name if it differs from the .vmx file name' do
      vm_dir_file = { 'foo' => 'foo', 'bar' => 'diff', 'baz' => 'baz'}
      list_output = "Total running VMs: 3\n"
      vm_dir_file.each_pair do |dir, file|
        list_output << "/vm/#{dir}.vmwarevm/#{file}.vmx\n"
        File.should_receive(:exists?).with("/vm/#{dir}.vmwarevm/#{file}.vmx").
                                      and_return(true)
      end

      $?.should_receive(:exitstatus).and_return(0)
      Fission::VM.should_receive(:`).
                  with("#{@vmrun_cmd} list").
                  and_return(list_output)

      Fission::VM.all_running.should == ['foo', 'bar', 'baz']
    end

    it 'should output an error and exit if unable to get the list of running vms' do
      $?.should_receive(:exitstatus).and_return(1)
      Fission::VM.should_receive(:`).
                  with("#{@vmrun_cmd} list").
                  and_return("it blew up")
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
    before do
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

      ['.vmx', '.vmxf'].each do |ext|
        File.should_receive(:binary?).
             with(File.join(Fission::VM.path('bar'), "bar#{ext}")).
             and_return(false)
      end
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    it 'should copy the vm files to the target' do
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).
           and_return(true)
      Fission::VM.clone @source_vm, @target_vm

      File.directory?(Fission::VM.path('bar')).should == true

      @vm_files.each do |file|
        File.file?(File.join(Fission::VM.path('bar'), "#{@target_vm}#{file}")).should == true
      end
    end

    it "should copy the vm files to the target if a file name doesn't match the directory" do
      FileUtils.touch File.join(Fission::VM.path('foo'), 'other_name.nvram')
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).
           and_return(true)
      Fission::VM.clone @source_vm, @target_vm

      File.directory?(Fission::VM.path('bar')).should == true

      @vm_files.each do |file|
        File.file?(File.join(Fission::VM.path('bar'), "#{@target_vm}#{file}")).should == true
      end

      File.file?(File.join(Fission::VM.path('bar'), "bar.nvram")).should == true
    end


    it "should copy the vm files to the target if a sparse disk file name doesn't match the directory" do
      FileUtils.touch File.join(Fission::VM.path('foo'), 'other_name-s003.vmdk')
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).
           and_return(true)
      Fission::VM.clone @source_vm, @target_vm

      File.directory?(Fission::VM.path('bar')).should == true

      @vm_files.each do |file|
        File.file?(File.join(Fission::VM.path('bar'), "#{@target_vm}#{file}")).should == true
      end

      File.file?(File.join(Fission::VM.path('bar'), "bar-s003.vmdk")).should == true
    end

    it 'should update the target vm config files' do
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).
           and_return(true)
      Fission::VM.clone @source_vm, @target_vm

      ['.vmx', '.vmxf'].each do |ext|
        File.read(File.join(Fission::VM.path('bar'), "bar#{ext}")).should_not match /foo/
        File.read(File.join(Fission::VM.path('bar'), "bar#{ext}")).should match /bar/
      end
    end

    it "should not try to update the vmdk file if it's not a sparse disk" do
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).and_return(true)
      Fission::VM.clone @source_vm, @target_vm

      File.read(File.join(Fission::VM.path('bar'), 'bar.vmdk')).should match /foo/
    end

    it "should update the vmdk when a sparse disk is found" do
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).and_return(false)
      Fission::VM.clone @source_vm, @target_vm

      File.read(File.join(Fission::VM.path('bar'), 'bar.vmdk')).should match /bar/
    end

    it 'should output that the clone was successful' do
      File.should_receive(:binary?).
           with(File.join(Fission::VM.path('bar'), "bar.vmdk")).and_return(true)
      Fission::VM.clone @source_vm, @target_vm

      @string_io.string.should match /Cloning #{@source_vm} to #{@target_vm}/
      @string_io.string.should match /Configuring #{@target_vm}/
    end
  end

  describe "self.delete" do
    before do
      @target_vm = 'foo'
      @vm_files = %w{ .vmx .vmxf .vmdk -s001.vmdk -s002.vmdk .vmsd }
      FakeFS.activate!

      FileUtils.mkdir_p Fission::VM.path(@target_vm)

      @vm_files.each do |file|
        FileUtils.touch File.join(Fission::VM.path(@target_vm), "#{@target_vm}#{file}")
      end
    end

    after do
      FakeFS.deactivate!
    end

    it "should delete the target vm files" do
      Fission::Metadata.stub!(:delete_vm_info)
      Fission::VM.delete @target_vm
      @vm_files.each do |file|
        File.exists?(File.join(Fission::VM.path(@target_vm), "#{@target_vm}#{file}")).should == false
      end
      @string_io.string.should match /Deleting vm #{@target_vm}/
    end

    it 'should delete the target vm metadata' do
      Fission::Metadata.should_receive(:delete_vm_info)
      Fission::VM.delete @target_vm
    end

  end
end
