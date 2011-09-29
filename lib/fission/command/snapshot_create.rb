module Fission
  class Command
    class SnapshotCreate < Command

      def execute
        unless @args.count == 2
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for snapshot create command", 1
        end

        vm_name, snap_name = @args.take 2

        exists_response = Fission::VM.exists? vm_name

        if exists_response.successful?
          unless exists_response.data
            Fission.ui.output_and_exit "Unable to find the VM '#{vm_name}' (#{Fission::VM.path(vm_name)})", 1 
          end
        end

        response = Fission::VM.all_running

        if response.successful?
          unless response.data.include? vm_name
            Fission.ui.output "VM '#{vm_name}' is not running"
            Fission.ui.output_and_exit 'A snapshot cannot be created unless the VM is running', 1
          end
        else
          Fission.ui.output_and_exit "There was an error determining if this VM is running.  The error was:\n#{response.output}", response.code
        end

        vm = Fission::VM.new vm_name

        snaps_response = vm.snapshots
        if snaps_response.successful?
          if snaps_response.data.include? snap_name
            Fission.ui.output_and_exit "VM '#{vm_name}' already has a snapshot named '#{snap_name}'", 1
          end
        else
          Fission.ui.output_and_exit "There was an error getting the list of snapshots.  The error was:\n#{snaps_response.output}", snaps_response.code
        end

        Fission.ui.output "Creating snapshot"
        response = vm.create_snapshot(snap_name)

        if response.successful?
          Fission.ui.output "Snapshot '#{snap_name}' created"
        else
          Fission.ui.output_and_exit "There was an error creating the snapshot.  The error was:\n#{response.output}", response.code
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
