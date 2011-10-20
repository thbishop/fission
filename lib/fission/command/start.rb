module Fission
  class Command
    class Start < Command
      include CommandHelpers

      def initialize(args=[])
        super
        @options.headless = false
      end

      def execute
        option_parser.parse! @args

        incorrect_arguments 'start' if @args.empty?

        vm = VM.new @args.first

        output "Starting '#{vm.name}'"
        start_args = {}

        start_args[:headless] = true if @options.headless

        response = vm.start start_args

        if response.successful?
          output "VM '#{vm.name}' started"
        else
          output_and_exit "There was a problem starting the VM.  The error was:\n#{response.message}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nstart usage: fission start vm_name [options]"

          opts.on '--headless', 'Start the VM in headless mode (i.e. no Fusion GUI console)' do
            @options.headless = true
          end
        end

        optparse
      end

    end
  end
end
