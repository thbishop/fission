module Fission
  class Command
    class Info < Command
      include Fission::CommandHelpers

      def execute
        incorrect_arguments 'info' unless @args.count == 1

        vm = VM.new @args.first

        output "name: #{vm.name}"

        hardware_response = vm.hardware_info

        if hardware_response.successful?
          hardware_response.data.each_pair do |k, v|
            output "#{k}: #{v}"
          end
        else
          output_and_exit "There was an error getting the hardware info.  The error was:\n#{hardware_response.message}", hardware_response.code
        end

        network_response = vm.network_info

        if network_response.successful?
          network_response.data.each_pair do |int, data|
            output "#{int}"
            data.each_pair do |k, v|
              output "  #{k}: #{v}"
            end
            output ""
          end
        else
          output_and_exit "There was an error getting the network info.  The error was:\n#{network_response.message}", network_response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\ninfo: fission info vm_name"
        end

        optparse
      end

    end
  end
end
