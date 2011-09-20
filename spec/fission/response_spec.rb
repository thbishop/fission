require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Response do
  describe 'initialize' do
    it 'should allow you to set the code' do
      Fission::Response.new(:code => 1).code.should == 1
    end

    it 'should set the code to 1 if not provided' do
      Fission::Response.new.code.should == 1
    end

    it 'should allow you to set the output' do
      Fission::Response.new(:output => 'foobar').output.should == 'foobar'
    end

    it 'should set the output to an empty string if not provided' do
      Fission::Response.new.output.should == ''
    end

  end

  describe 'code' do
    it 'should not allow you to set the code' do
      @response = Fission::Response.new
      lambda { @response.code = 4 }.should raise_error NoMethodError
    end
  end

  describe 'successful?' do
    it 'should return true if the code is 0' do
      Fission::Response.new(:code => 0).successful?.should == true
    end

    it 'should return false if the code is not 0' do
      Fission::Response.new(:code => 1).successful?.should == false
    end
  end

  describe 'output' do
    it 'should not allow you to set the output' do
      @response = Fission::Response.new
      lambda { @response.output = 'foobar' }.should raise_error NoMethodError
    end
  end
end
