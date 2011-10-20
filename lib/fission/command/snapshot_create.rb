module Fission
  class Command
    class SnapshotCreate < Command
      include Fission::CommandHelpers

      def execute
        incorrect_arguments 'snapshot create' unless @args.count == 2

        vm = VM.new @args[0]
        snap_name = @args[1]

        output "Creating snapshot"
        response = vm.create_snapshot snap_name

        if response.successful?
          output "Snapshot '#{snap_name}' created"
        else
          output_and_exit "There was an error creating the snapshot.  The error was:\n#{response.message}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsnapshot create: fission snapshot create vm_name snapshot_1"
        end

        optparse
      end

    end
  end
end
