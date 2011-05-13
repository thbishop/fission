require 'rspec'
require 'fission'
require 'fakefs/safe'

# Helper to capture our stdout
# Example
#   output = capturing_output do
#     lambda {
#       Erector.new(["--version"])
#     }.should raise_error(SystemExit)
#   end
#   output.should == Erector::VERSION + "\n"
def capturing_output
  output = StringIO.new
  $stdout = output
  yield
  output.string
ensure
  $stdout = STDOUT
end
