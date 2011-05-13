module Fission
  class CLI
    def self.execute(args=ARGV)
      optparse = OptionParser.new do |opts|
        opts.banner = "\nUsage: fission [options] source_vm target_vm\n\n"

        opts.on('-v', '--version', 'Output the version of fission') do
          puts Fission::VERSION
          exit(0)
        end

      end

      optparse.parse!(args)

    end

  end
end
