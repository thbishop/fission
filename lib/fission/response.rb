module Fission
  class Response
    attr_accessor :code, :output, :data

    def initialize(args={})
      @code = args.fetch :code, 1
      @output = args.fetch :output, ''
      @data = args.fetch :data, nil
    end

    def successful?
      @code == 0
    end

    def self.from_command(output)
      response = new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

  end
end
