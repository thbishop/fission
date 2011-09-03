require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Config do
  describe "init" do
    it "should use the fusion default dir for vm_dir" do
      FakeFS do
        @config = Fission::Config.new
        @config.attributes['vm_dir'].should == File.expand_path('~/Documents/Virtual Machines.localized/')
      end
    end

    it 'should use the fusion default for vmrun_bin' do
      FakeFS do
        @config = Fission::Config.new
        @config.attributes['vmrun_bin'].should == '/Library/Application Support/VMware Fusion/vmrun'
      end
    end

    it 'should use the fusion default for plist_file' do
      @config = Fission::Config.new
      @config.attributes['plist_file'].should == File.expand_path('~/Library/Preferences/com.vmware.fusion.plist')
    end

    it 'should use the fusion default for the gui bin' do
      @config = Fission::Config.new
      @config.attributes['gui_bin'].should == File.expand_path('/Applications/VMware Fusion.app/Contents/MacOS/vmware')
    end

    it "should use the user specified dir in ~/.fissionrc" do
      FakeFS do
        File.open('~/.fissionrc', 'w') { |f| f.puts YAML.dump({ 'vm_dir' => '/var/tmp/foo' })}

        @config = Fission::Config.new
        @config.attributes['vm_dir'].should == '/var/tmp/foo'
      end
    end

    it 'should set vmrun_cmd' do
      FakeFS do
        @config = Fission::Config.new
        @config.attributes['vmrun_cmd'].should == '/Library/Application\ Support/VMware\ Fusion/vmrun -T fusion'
      end
    end

  end

end
