module Fission
  module CommandHelpers

    # Internal: Outputs the help text for a command and exits.
    #
    # command_name - The name of the command to use in the output text.
    #
    # Examples
    #
    #   incorrect_arguments 'delete'
    #
    # Returns nothing.
    # This will call the help class method for the help text.  This will exit
    # with the exit code 1.
    def incorrect_arguments(command_name)
      output "#{self.class.help}\n"
      output_and_exit "Incorrect arguments for #{command_name} command", 1
    end

    # Internal: Parses the command line arguments.
    #
    # Examples:
    #
    #   parse_arguments
    #
    # Returns nothing.
    # If there is an invalid argument, an error will be output and this will
    # exit with exit code 1.
    def parse_arguments
      option_parser.parse! @args
    rescue OptionParser::InvalidOption => e
      output e
      output ''
      output_and_exit"#{self.class.help}", 1
    end

  end
end
