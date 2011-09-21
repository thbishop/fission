module Fission
  class Command
    class Delete < Command

      def initialize(args=[])
        super
        @options.force = false
      end

      def execute
        option_parser.parse! @args

        if @args.count < 1
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for delete command", 1
        end

        target_vm = @args.first

        unless Fission::VM.exists? target_vm
          Fission.ui.output_and_exit "Unable to find target vm #{target_vm} (#{Fission::VM.path(target_vm)})", 1
        end

        response = Fission::VM.all_running

        if response.successful?
          if response.data.include? target_vm
            Fission.ui.output 'VM is currently running'
            if @options.force
              Fission.ui.output 'Going to stop it'
              Fission::Command::Stop.new([target_vm]).execute
            else
              Fission.ui.output_and_exit "Either stop/suspend the VM or use '--force' and try again.", 1
            end
          end
        end

        if Fission::Fusion.is_running?
          Fission.ui.output 'It looks like the Fusion GUI is currently running'
          if @options.force
            Fission.ui.output 'The Fusion metadata for the VM may not be removed completely'
          else
            Fission.ui.output "Either exit the Fusion GUI or use '--force' and try again"
            Fission.ui.output_and_exit "NOTE: Forcing a VM deletion with the Fusion GUI running may not clean up all of the VM metadata", 1
          end
        end

        Fission::VM.delete target_vm

        Fission.ui.output ''
        Fission.ui.output "Deletion complete!"
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\ndelete usage: fission delete target_vm [--force]"

          opts.on '--force', "Stop the VM if it's running and then delete it" do
            @options.force = true
          end
        end

        optparse
      end

    end
  end
end
