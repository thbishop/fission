require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::UI do
  describe 'output' do
    it 'should show the desired text' do
      output = capturing_output do
        Fission::UI.new.output "foo bar\nbaz blah"
      end

      output.should == "foo bar\nbaz blah\n"
    end
  end

  describe 'output_and_exit' do
    it 'should show the desired text and exit with the desired exit code' do
      Fission::UI.any_instance.should_receive(:exit).and_return(1)

      output = capturing_output do
        Fission::UI.new.output_and_exit "foo bar\nbaz blah", 1
      end

      output.should == "foo bar\nbaz blah\n"
    end

  end
end
