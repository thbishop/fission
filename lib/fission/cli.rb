module Fission
  class CLI
    def self.execute(args=ARGV)
      optparse = OptionParser.new do |opts|
        opts.banner = "\nUsage: fission [options] COMMAND [parameters]\n\n"

        opts.on('-v', '--version', 'Output the version of fission') do
          puts Fission::VERSION
          exit(0)
        end

      end

      optparse.parse! args

      puts args.first
      case args.first
      when 'clone'
        Fission::Command::Clone.execute args.drop 1
      end

    end

  end
end
