require 'spec_helper'

describe Fission::Fusion do
  describe 'self.running?' do
    before do
      @cmd = "ps -ef | grep -v grep | "
      @cmd << "grep -c #{Fission.config['gui_bin'].gsub(' ', '\ ')} 2>&1"
    end

    it 'should return a successful response and true if the fusion app is running' do
      Fission::Fusion.should_receive(:`).with(@cmd).
                                         and_return("1\n")
      Fission::Fusion.running?.should == true
    end

    it 'should return a successful response and false if the fusion app is not running' do
      Fission::Fusion.should_receive(:`).with(@cmd).
                                         and_return("0\n")
      Fission::Fusion.running?.should == false
    end
  end
end
