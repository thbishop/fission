require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Fusion do
  describe 'self.is_running?' do
    before do
      @cmd = "ps -ef | grep -v grep | "
      @cmd << "grep -c #{Fission.config['gui_bin'].gsub(' ', '\ ')} 2>&1"
    end

    it 'should return a successful response and true if the fusion app is running' do
      Fission::Fusion.should_receive(:`).with(@cmd).
                                         and_return("1\n")
      response = Fission::Fusion.is_running?
      response.successful?.should == true
      response.data.should == true
    end

    it 'should return a successful response and false if the fusion app is not running' do
      Fission::Fusion.should_receive(:`).with(@cmd).
                                         and_return("0\n")
      response = Fission::Fusion.is_running?
      response.successful?.should == true
      response.data.should == false
    end
  end
end
