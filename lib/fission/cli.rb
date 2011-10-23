module Fission
  class CLI

    # Internal: Starts the command line parsing logic and hands off to the
    # requested commands.  If there are invalid arguments or errors then the
    # help text will be displayed.
    #
    # args - The list of arguments for the Fission command line app.  This
    #        should be the raw command line arguments.
    #
    # Examples
    #
    #   Fission::CLI.execute
    #
    # Returns nothing.
    def self.execute(args=ARGV)
      optparse = OptionParser.new do |opts|
        opts.banner = "\nUsage: fission [options] COMMAND [arguments]"

        opts.on_head('-v', '--version', 'Output the version of fission') do
          ui.output VERSION
          exit(0)
        end

        opts.on_head('-h', '--help', 'Displays this message') do
          show_all_help(optparse)
          exit(0)
        end

        opts.define_tail do
          commands_banner
        end

      end

      begin
        optparse.order! args
      rescue OptionParser::InvalidOption => e
        ui.output e
        show_all_help(optparse)
        exit(1)
      end

      if commands.include?(args.first)
        @cmd = Command.const_get(args.first.capitalize).new args.drop 1
      elsif is_snapshot_command?(args)
        klass = args.take(2).map {|c| c.capitalize}.join('')
        @cmd = Command.const_get(klass).new args.drop 2
      else
        show_all_help(optparse)
        exit(1)
      end

      @cmd.execute
    end

    # Internal: Provides the list of Fission commands based on the files in the
    # command directory.
    #
    # Examples
    #
    #   Fission::CLI.commands
    #   # => ['clone', 'delete', 'snapshot create', 'snapshot list']
    #
    # Returns an Array of the commands (String).  Commands with underscores will
    # have them replaced with spaces.
    def self.commands
      cmds = Dir.entries(File.join(File.dirname(__FILE__), 'command')).select do |file|
        !File.directory? file
      end

      cmds.map { |cmd| File.basename(cmd, '.rb').gsub '_', ' ' }
    end

    private
    # Internal: Determines if the provided command is a snapshot related
    # command.
    #
    # args - The arguments (Array) to interrogate.  This should be the command
    #        line arguments.  Only the first two items in the Array will be
    #        used.
    #
    # Examples
    #
    #   Fission::CLI.is_snapshot_command? ['foo', 'bar']
    #   # => false
    #
    #   Fission::CLI.is_snapshot_command? ['snapshot', 'list']
    #   # => true
    #
    # Returns a Boolean of whether a snapshot command was given or not.
    def self.is_snapshot_command?(args)
      args.first == 'snapshot' && args.count > 1 && commands.include?(args.take(2).join(' '))
    end

    # Internal: Provides the help of all of the known commands.
    #
    # Examples
    #
    #   Fission::CLI.commands_banner
    #
    # Returns a String which is a concatenation of the help text for all known
    # commands.
    def self.commands_banner
      text = "\nCommands:\n"
      Command.descendants.each do |command_klass|
        text << (command_klass.send :help)
      end

      text
    end

    # Internal: Helper method to output the command line options and the help
    # for all known commands to the terminal.
    #
    # options - The options to display as a part of the output.  This can (and
    #           in almost all cases) should be the optparse object.
    #
    # Examples
    #
    #   Fission::CLI.show_all_help my_opt_parse
    #   # => 'fission options command arguments ....' (concatenated)
    #
    # Returns nothing.
    def self.show_all_help(options)
      ui.output options
      ui.output commands_banner
    end

    # Internal: Helper method for outputting text to the ui
    #
    # Examples
    #
    #   CLI.ui.output 'foo'
    #
    # Returns a UI instance.
    def self.ui
      @ui ||= UI.new
    end

  end
end
