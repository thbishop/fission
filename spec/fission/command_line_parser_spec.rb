require 'spec_helper'

describe Fission::CommandLineParser do
  before do
    @string_io = StringIO.new
    Fission::CommandLineParser.any_instance.
                               stub(:ui).
                               and_return(Fission::UI.new(@string_io))
  end

  describe 'initialize' do

    context 'with no arguments' do
      it 'should output the usage info' do
        lambda {
          Fission::CommandLineParser.new([]).parse
        }.should raise_error SystemExit
        @string_io.string.should match /Usage/
      end
    end

    context 'with -v or --version argumetns' do
      ['-v', '--version'].each do |arg|
        it "should output the version with #{arg}" do
          lambda {
            Fission::CommandLineParser.new([arg]).parse
          }.should raise_error SystemExit

          @string_io.string.should match /#{Fission::VERSION}/
        end
      end
    end

    context 'with -h or --help argument' do
      ['-h', '--help'].each do |arg|
        it "should output the usage info with #{arg}" do
          lambda {
            Fission::CommandLineParser.new([arg]).parse
          }.should raise_error SystemExit

          @string_io.string.should match /Usage/
        end
      end
    end

    context 'with an invalid sub command' do
      it 'should display the help' do
        lambda {
          Fission::CommandLineParser.new(['foo', 'bar']).parse
        }.should raise_error SystemExit

        @string_io.string.should match /Usage/
      end
    end

    context 'with a valid sub command' do

      [ ['clone'],
        ['delete'],
        ['delete', 'foo'],
        ['snapshot', 'create'],
        ['snapshot', 'list'],
        ['snapshot', 'revert'],
        ['start'],
        ['stop'],
        ['suspend']
      ].each do |command|
        it "should accept #{command}" do
          Fission::CommandLineParser.new(command).parse
        end
      end

    end

  end

end
