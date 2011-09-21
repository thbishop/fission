module Fission
  class Response
    attr_accessor :code, :output

    def initialize(args={})
      @code = args.fetch :code, 1
      @output = args.fetch :output, ''
    end

    def successful?
      @code == 0
    end

  end
end
