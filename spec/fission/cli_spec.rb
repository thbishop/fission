require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  describe 'execute' do

    describe '-v or --version' do
      ['-v', '--version'].each do |arg|
        it "should output the version with #{arg}" do
          output = capturing_output do
            lambda {
              Fission::CLI.execute [arg]
            }.should raise_error SystemExit
          end

          output.strip.should == Fission::VERSION

        end
      end

    end

    describe '-h or --help' do
      ['-h', '--help'].each do |arg|
        it "should output the usage info with #{arg}" do
          output = capturing_output do
            lambda {
              Fission::CLI.execute [arg]
            }.should raise_error SystemExit
          end

          output.should match(/Usage/)
        end
      end

    end

    describe 'clone' do
      it "should try to clone the vm" do
        Fission::Command::Clone.should_receive(:execute).with(['foo', 'bar'])
        Fission::CLI.execute ['clone', 'foo', 'bar']
      end
    end

  end
end
