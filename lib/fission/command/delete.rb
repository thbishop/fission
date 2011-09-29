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

        vm_name = @args.first

        exists_response = Fission::VM.exists? vm_name

        if exists_response.successful?
          unless exists_response.data
            Fission.ui.output_and_exit "Unable to find the VM '#{vm_name}' (#{Fission::VM.path(vm_name)})", 1
          end
        end

        response = Fission::VM.all_running

        if response.successful?
          if response.data.include? vm_name
            Fission.ui.output 'VM is currently running'
            if @options.force
              Fission.ui.output 'Going to stop it'
              Fission::Command::Stop.new([vm_name]).execute
            else
              Fission.ui.output_and_exit "Either stop/suspend the VM or use '--force' and try again.", 1
            end
          end
        else
          Fission.ui.output_and_exit "There was an error determining if the VM is running.  The error was:\n#{response.output}", response.code
        end

        fusion_running_response = Fission::Fusion.is_running?

        if fusion_running_response.successful?
          if fusion_running_response.data
            Fission.ui.output 'It looks like the Fusion GUI is currently running'

            if @options.force
              Fission.ui.output 'The Fusion metadata for the VM may not be removed completely'
            else
              Fission.ui.output "Either exit the Fusion GUI or use '--force' and try again"
              Fission.ui.output_and_exit "NOTE: Forcing a VM deletion with the Fusion GUI running may not clean up all of the VM metadata", 1
            end
          end
        end

        delete_response = Fission::VM.new(vm_name).delete

        if delete_response.successful?
          Fission.ui.output ''
          Fission.ui.output "Deletion complete!"
        else
          Fission.ui.output_and_exit "There was an error deleting the VM.  The error was:\n#{delete_response.output}", delete_response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\ndelete usage: fission delete vm_name [--force]"

          opts.on '--force', "Stop the VM if it's running and then delete it" do
            @options.force = true
          end
        end

        optparse
      end

    end
  end
end
