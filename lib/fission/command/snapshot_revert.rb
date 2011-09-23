module Fission
  class Command
    class SnapshotRevert < Command

      def execute
        unless @args.count == 2
          Fission.ui.output self.class.help
          Fission.ui.output ''
          Fission.ui.output_and_exit 'Incorrect arguments for snapshot revert command', 1
        end

        vm_name, snap_name = @args.take 2

        exists_response = Fission::VM.exists? vm_name

        if exists_response.successful?
          unless exists_response.data
            Fission.ui.output_and_exit "Unable to find the VM #{vm_name} (#{Fission::VM.path(vm_name)})", 1 
          end
        end

        fusion_running_response = Fission::Fusion.is_running?

        if fusion_running_response.successful?
          if fusion_running_response.data
            Fission.ui.output 'It looks like the Fusion GUI is currently running'
            Fission.ui.output_and_exit 'Please exit the Fusion GUI and try again', 1
          end
        end

        vm = Fission::VM.new vm_name

        snapshots_response = vm.snapshots

        if snapshots_response.successful?
          snaps = snapshots_response.data

          unless snaps.include? snap_name
            Fission.ui.output_and_exit "Unable to find the snapshot '#{snap_name}'", 1
          end
        else
          Fission.ui.output_and_exit "There was an error getting the list of snapshots.  The error was:\n#{snapshots_response.output}", snapshots_response.code
        end

        Fission.ui.output "Reverting to snapshot '#{snap_name}'"
        response = vm.revert_to_snapshot snap_name

        if response.successful?
          Fission.ui.output "Reverted to snapshot '#{snap_name}'"
        else
          Fission.ui.output_and_exit "There was an error reverting to the snapshot.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsnapshot revert: fission snapshot revert my_vm snapshot_1"
        end

        optparse
      end

    end
  end
end
