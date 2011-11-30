module Fission
  class Command
    class Status < Command

      def execute
        response = VM.all_with_status
        unless response.successful?
          output_and_exit "There was an error getting the status of the VMs.  The error was:\n#{response.message}", response.code
        end

        vms_status = response.data
        longest_vm_name = vms_status.keys.max { |a,b| a.length <=> b.length }

        vms_status.each_pair do |vm_name, status|
          output_printf "%-#{longest_vm_name.length}s   [%s]\n", vm_name, status
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nstatus usage: fission status"
        end

        optparse
      end

    end
  end
end
