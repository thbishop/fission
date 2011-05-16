require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::CLI do
  before :all do
    @string_io = StringIO.new
  end

  before :each do
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
  end

  describe 'execute' do

    describe 'with no arguments' do
      it 'should output the usage info' do
        lambda {
          Fission::CLI.execute []
        }.should raise_error SystemExit

        @string_io.string.should match /Usage/
      end
    end

    describe '-v or --version' do
      ['-v', '--version'].each do |arg|
        it "should output the version with #{arg}" do
          lambda {
            Fission::CLI.execute [arg]
          }.should raise_error SystemExit

          @string_io.string.should match /#{Fission::VERSION}/

        end
      end

    end

    describe '-h or --help' do
      ['-h', '--help'].each do |arg|
        it "should output the usage info with #{arg}" do
          lambda {
            Fission::CLI.execute [arg]
          }.should raise_error SystemExit

          @string_io.string.should match /Usage/
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
