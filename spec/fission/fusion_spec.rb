require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Fusion do
  describe 'self.is_running?' do
    before :each do
      @cmd = "ps -ef | grep -v grep | "
      @cmd << "grep -c #{Fission.config.attributes['gui_bin'].gsub(' ', '\ ')} 2>&1"
    end

    it 'should return true if the fusion app is running' do
      Fission::Fusion.should_receive(:`).with(@cmd).
                                         and_return("1\n")
      Fission::Fusion.is_running?.should == true
    end

    it 'should return false if the fusion app is not running' do
      Fission::Fusion.should_receive(:`).with(@cmd).
                                         and_return("0\n")
      Fission::Fusion.is_running?.should == false
    end
  end
end
