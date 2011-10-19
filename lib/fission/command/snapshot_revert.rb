module Fission
  class Command
    class SnapshotRevert < Command
      include Fission::CommandHelpers

      def execute
        unless @args.count == 2
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for snapshot revert command', 1
        end

        vm = VM.new @args[0]
        snap_name = @args[1]

        ensure_vm_exists vm

        if Fusion.running?
          output 'It looks like the Fusion GUI is currently running'
          output_and_exit 'Please exit the Fusion GUI and try again', 1
        end

        snapshots_response = vm.snapshots

        if snapshots_response.successful?
          snaps = snapshots_response.data

          unless snaps.include? snap_name
            output_and_exit "Unable to find the snapshot '#{snap_name}'", 1
          end
        else
          output_and_exit "There was an error getting the list of snapshots.  The error was:\n#{snapshots_response.output}", snapshots_response.code
        end

        output "Reverting to snapshot '#{snap_name}'"
        response = vm.revert_to_snapshot snap_name

        if response.successful?
          output "Reverted to snapshot '#{snap_name}'"
        else
          output_and_exit "There was an error reverting to the snapshot.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsnapshot revert: fission snapshot revert vm_name snapshot_1"
        end

        optparse
      end

    end
  end
end
