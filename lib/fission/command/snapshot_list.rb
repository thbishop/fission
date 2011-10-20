module Fission
  class Command
    class SnapshotList < Command
      include Fission::CommandHelpers

      def execute
        incorrect_arguments 'snapshot list' unless @args.count == 1

        vm = VM.new @args.first

        response = vm.snapshots

        if response.successful?
          snaps = response.data

          if snaps.any?
            output snaps.join("\n")
          else
            output "No snapshots found for VM '#{vm.name}'"
          end
        else
          output_and_exit "There was an error listing the snapshots.  The error was:\n#{response.message}", response.code
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
