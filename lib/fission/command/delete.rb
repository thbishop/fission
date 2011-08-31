module Fission
  class Command
    class Delete < Command

      def initialize(args=[])
        super
      end

      def execute
        unless args.count == 1
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for delete command", 1
        end

        target_vm = @args.first

        unless Fission::VM.exists? target_vm
          Fission.ui.output_and_exit "Unable to find target vm #{target_vm} (#{Fission::VM.path(target_vm)})", 1
        end

        Fission::VM.delete target_vm

        Fission.ui.output ''
        Fission.ui.output "Deletion complete!"
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\ndelete usage: fission delete target_vm"
        end

        optparse
      end

    end
  end
end
