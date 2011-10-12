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

        if @args.empty?
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for start command', 1
        end

        vm_name = @args.first

        ensure_vm_exists vm_name

        response = VM.all_running

        if response.successful?
          if response.data.include?(vm_name)
            output ''
            output_and_exit "VM '#{vm_name}' is already running", 0
          end
        else
          output_and_exit "There was an error determining if the VM is already running.  The error was:\n#{response.output}", response.code
        end

        output "Starting '#{vm_name}'"
        vm = VM.new vm_name
        start_args = {}

        if @options.headless
          fusion_running_response = Fusion.running?

          if fusion_running_response.successful?
            if fusion_running_response.data
              output 'It looks like the Fusion GUI is currently running'
              output 'A VM cannot be started in headless mode when the Fusion GUI is running'
              output_and_exit "Exit the Fusion GUI and try again", 1
            end
          else
            start_args[:headless] = true
          end
        end

        response = vm.start start_args

        if response.successful?
          output "VM '#{vm_name}' started"
        else
          output_and_exit "There was a problem starting the VM.  The error was:\n#{response.output}", response.code
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
