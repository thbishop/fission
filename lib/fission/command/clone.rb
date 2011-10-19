module Fission
  class Command
    class Clone < Command
      include Fission::CommandHelpers

      def initialize(args=[])
        super
        @options.start = false
      end

      def execute
        option_parser.parse! @args

        unless @args.count > 1
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for clone command', 1
        end

        source_vm = Fission::VM.new @args.first
        target_vm = Fission::VM.new @args[1]

        ensure_vm_exists source_vm

        exists_response = target_vm.exists?

        if target_vm.exists?
          output_and_exit "The target VM '#{target_vm.name}' already exists", 1
        end

        clone_response = VM.clone source_vm.name, target_vm.name

        if clone_response.successful?
          output ''
          output 'Clone complete!'

          if @options.start
            output "Starting '#{target_vm.name}'"

            start_response = target_vm.start

            if start_response.successful?
              output "VM '#{target_vm.name}' started"
            else
              output_and_exit "There was an error starting the VM.  The error was:\n#{start_response.output}", start_response.code
            end
          end
        else
          output_and_exit "There was an error cloning the VM.  The error was:\n#{clone_response.output}", clone_response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nclone usage: fission clone source_vm target_vm [options]"

          opts.on '--start', 'Start the VM after cloning' do
            @options.start = true
          end
        end

        optparse
      end

    end
  end
end
