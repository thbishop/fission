module Fission
  class Command
    class Status < Command

      def execute
        response = VM.all
        if response.successful?
          all_vms = response.data
        end

        response = VM.all_running
        if response.successful?
          all_running_vm_names = response.data.collect { |v| v.name }
        else
          output_and_exit "There was an error getting the list of running VMs.  The error was:\n#{response.message}", response.code
        end

        vm_names = all_vms.collect { |v| v.name }

        longest_vm_name = vm_names.max { |a,b| a.length <=> b.length }

        all_vms.each do |vm|
          if all_running_vm_names.include? vm.name
            status = '[running]'
          else
            if vm.suspend_file_exists?
              status = '[suspended]'
            else
              state_response = vm.state

              if state_response.successful?
                status = "[#{state_response.data}]"
              else
                status = "[unknown] (#{state_response.message})"
              end
            end
          end

          output_printf "%-#{longest_vm_name.length}s   %s\n", vm.name, status
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
