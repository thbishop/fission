module Fission
  class Command
    class SnapshotCreate < Command
      include Fission::CommandHelpers

      def execute
        unless @args.count == 2
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for snapshot create command', 1
        end

        vm_name, snap_name = @args.take 2

        ensure_vm_exists vm_name

        response = VM.all_running

        if response.successful?
          unless response.data.include? vm_name
            output "VM '#{vm_name}' is not running"
            output_and_exit 'A snapshot cannot be created unless the VM is running', 1
          end
        else
          output_and_exit "There was an error determining if this VM is running.  The error was:\n#{response.output}", response.code
        end

        vm = VM.new vm_name

        snaps_response = vm.snapshots
        if snaps_response.successful?
          if snaps_response.data.include? snap_name
            output_and_exit "VM '#{vm_name}' already has a snapshot named '#{snap_name}'", 1
          end
        else
          output_and_exit "There was an error getting the list of snapshots.  The error was:\n#{snaps_response.output}", snaps_response.code
        end

        output "Creating snapshot"
        response = vm.create_snapshot(snap_name)

        if response.successful?
          output "Snapshot '#{snap_name}' created"
        else
          output_and_exit "There was an error creating the snapshot.  The error was:\n#{response.output}", response.code
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
