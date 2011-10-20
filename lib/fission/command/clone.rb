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

        incorrect_arguments 'clone' unless @args.count > 1

        source_vm = Fission::VM.new @args.first
        target_vm = Fission::VM.new @args[1]

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
              output_and_exit "There was an error starting the VM.  The error was:\n#{start_response.message}", start_response.code
            end
          end
        else
          output_and_exit "There was an error cloning the VM.  The error was:\n#{clone_response.message}", clone_response.code
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
