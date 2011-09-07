module Fission
  class Command
    class SnapshotRevert < Command

      def initialize(args=[])
        super
      end

      def execute
        unless @args.count == 2
          Fission.ui.output self.class.help
          Fission.ui.output ''
          Fission.ui.output_and_exit 'Incorrect arguments for snapshot revert command', 1
        end

        vm_name, snap_name = @args.take 2

        unless Fission::VM.exists? vm_name
          Fission.ui.output_and_exit "Unable to find the VM #{vm_name} (#{Fission::VM.path(vm_name)})", 1 
        end

        if Fission::Fusion.is_running?
          Fission.ui.output 'It looks like the Fusion GUI is currently running'
          Fission.ui.output_and_exit 'Please exit the Fusion GUI and try again', 1
        end

        @vm = Fission::VM.new vm_name

        unless @vm.snapshots.include? snap_name
          Fission.ui.output_and_exit "Unable to find the snapshot '#{snap_name}'", 1
        end

        Fission.ui.output "Reverting to snapshot '#{snap_name}'"
        @vm.revert_to_snapshot(snap_name)
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
