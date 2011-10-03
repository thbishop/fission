module Fission
  class Command
    class SnapshotList < Command
      include Fission::CommandHelpers

      def execute
        unless @args.count == 1
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for snapshot list command', 1
        end

        vm_name = @args.first

        ensure_vm_exists vm_name

        vm = VM.new vm_name
        response = vm.snapshots

        if response.successful?
          snaps = response.data

          if snaps.any?
            output snaps.join("\n")
          else
            output "No snapshots found for VM '#{vm_name}'"
          end
        else
          output_and_exit "There was an error listing the snapshots.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsnapshot list: fission snapshot list vm_name"
        end

        optparse
      end

    end
  end
end
