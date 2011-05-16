module Fission
  class CLI
    def self.execute(args=ARGV)
      optparse = OptionParser.new do |opts|
        opts.banner = "\nUsage: fission [options] COMMAND [parameters]"

        opts.on_head('-v', '--version', 'Output the version of fission') do
          Fission.ui.output Fission::VERSION
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
        optparse.parse! args
      rescue OptionParser::InvalidOption => e
        Fission.ui.output e
        show_all_help(optparse)
        exit(1)
      end

      case args.first
      when 'clone'
        Fission::Command::Clone.execute args.drop 1
      end

    end

    private
    def self.commands_banner
      text = "\nCommands:\n"
      Fission::Command.descendants.each do |command_klass|
        text << (command_klass.send :help)
        text << "\n\n"
      end

      text
    end

    def self.show_all_help(options)
      Fission.ui.output options
      Fission.ui.output commands_banner
    end

  end
end
