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

        vm = VM.new @args[0]
        snap_name = @args[1]

        ensure_vm_exists vm

        state_response = vm.state

        if state_response.successful?
          if state_response.data != 'running'
            output "VM '#{vm.name}' is not running"
            output_and_exit 'A snapshot cannot be created unless the VM is running', 1
          end
        else
          output_and_exit "There was an error determining if this VM is running.  The error was:\n#{state_response.message}", state_response.code
        end

        snaps_response = vm.snapshots
        if snaps_response.successful?
          if snaps_response.data.include? snap_name
            output_and_exit "VM '#{vm.name}' already has a snapshot named '#{snap_name}'", 1
          end
        else
          output_and_exit "There was an error getting the list of snapshots.  The error was:\n#{snaps_response.message}", snaps_response.code
        end

        output "Creating snapshot"
        response = vm.create_snapshot(snap_name)

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
