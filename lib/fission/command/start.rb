module Fission
  class Command
    class Start < Command

      def initialize(args=[])
        super
        @options.headless = false
      end

      def execute
        option_parser.parse! @args

        if @args.empty?
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for start command", 1
        end

        vm_name = @args.first

        exists_response = Fission::VM.exists? vm_name

        if exists_response.successful?
          unless exists_response.data
            Fission.ui.output_and_exit "Unable to find the VM #{vm_name} (#{Fission::VM.path(vm_name)})", 1 
          end
        end

        response = Fission::VM.all_running

        if response.successful?
          if response.data.include?(vm_name)
            Fission.ui.output ''
            Fission.ui.output_and_exit "VM '#{vm_name}' is already running", 0
          end
        else
          Fission.ui.output_and_exit "There was an error determining if the VM is already running.  The error was:\n#{response.output}", response.code
        end

        Fission.ui.output "Starting '#{vm_name}'"
        @vm = Fission::VM.new vm_name
        start_args = {}

        if @options.headless
          fusion_running_response = Fission::Fusion.is_running?

          if fusion_running_response.successful?
            if fusion_running_response.data
              Fission.ui.output 'It looks like the Fusion GUI is currently running'
              Fission.ui.output 'A VM cannot be started in headless mode when the Fusion GUI is running'
              Fission.ui.output_and_exit "Exit the Fusion GUI and try again", 1
            end
          else
            start_args[:headless] = true
          end
        end

        response = @vm.start start_args

        if response.successful?
          Fission.ui.output "VM '#{vm_name}' started"
        else
          Fission.ui.output_and_exit "There was a problem starting the VM.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nstart usage: fission start vm [options]"

          opts.on '--headless', 'Start the VM in headless mode (i.e. no Fusion GUI console)' do
            @options.headless = true
          end
        end

        optparse
      end

    end
  end
end
