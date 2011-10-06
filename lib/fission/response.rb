module Fission
  class Response

    # Public: Gets/Sets the code (Integer).
    attr_accessor :code

    # Public: Gets/Sets the output (String).
    attr_accessor :output

    # Public: Gets/Sets the data (can be any of type as needed).
    attr_accessor :data

    # Public: Initialize a ResponseObject.
    #
    # args - Hash of arguments:
    #       :code   - Integer which denotes the code of the ResponseObject.
    #                 This is similar in concept to comman line exit codes.  The
    #                 convention is that 0 denotes success and any other value
    #                 is unsuccessful (default: 1).
    #       :output - String which denotes the output of the ResponseObject.
    #                 The convention is that this should only be used when the
    #                 ResponseObject is unsuccessful (default: '').
    #       :data   - Any valid ruby object type.  This is used to convey any
    #                 data that needs to be used by a caller.  The convention
    #                 is that this should only be used when the ResponseObject
    #                 is successful (default nil).
    #
    # Examples
    #
    #   ResponseObject.new :code => 0, :data => [1, 2, 3, 4]
    #
    #   ResponseObject.new :code => 0, :data => true
    #
    #   ResponseObject.new :code => 5, :output => 'Something went wrong'
    def initialize(args={})
      @code = args.fetch :code, 1
      @output = args.fetch :output, ''
      @data = args.fetch :data, nil
    end

    # Public: Helper method to determine if a response is successful or not.
    #
    # Examples
    #
    #   response.successful?
    #   # => true
    #
    #   response.successful?
    #   # => false
    #
    # Returns a Boolean.
    # Returns true if the code is 0.
    # Returns false if the code is any other value.
    def successful?
      @code == 0
    end

    # Public: Helper method to create a new response object when running a
    # command line tool.
    #
    # output - This should be the output of the command.
    #
    # Returns a ResponseObject.  The ResponseObject's code attribute will be set
    # to the value of '$?'.  The ResponseObjects's output will be set to the
    # provided output if, and only if, the ResponseObject is unsuccessful.
    def self.from_command(output)
      response = new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

  end
end
