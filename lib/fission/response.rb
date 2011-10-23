module Fission
  class Response

    # Public: Gets/Sets the code (Integer).
    attr_accessor :code

    # Public: Gets/Sets the message (String).
    attr_accessor :message

    # Public: Gets/Sets the data (can be any of type as needed).
    attr_accessor :data

    # Public: Initialize a Response object.
    #
    # args - Hash of arguments:
    #       :code    - Integer which denotes the code of the Response.  This is
    #                  similar in concept to command line exit codes.  The
    #                  convention is that 0 denotes success and any other value
    #                  is unsuccessful (default: 1).
    #       :message - String which denotes the message of the Response.  The
    #                  convention is that this should only be used when the
    #                  Response is unsuccessful (default: '').
    #       :data    - Any valid ruby object.  This is used to convey any
    #                  data that needs to be used by a caller.  The convention
    #                  is that this should only be used when the Response is
    #                  successful (default nil).
    #
    # Examples
    #
    #   Response.new :code => 0, :data => [1, 2, 3, 4]
    #
    #   Response.new :code => 0, :data => true
    #
    #   Response.new :code => 5, :message => 'Something went wrong'
    #
    # Returns a new Response instance.
    def initialize(args={})
      @code = args.fetch :code, 1
      @message = args.fetch :message, ''
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

    # Public: Helper method to create a new Response object when running a
    # command line tool.
    #
    # cmd_output - This should be the output of the command.
    #
    # Returns a Response.
    # The Response's code attribute will be set to the value of '$?'.  The
    # Response's message attribute will be set to the provided command output
    # if, and only if, the Response is unsuccessful.
    def self.from_command(cmd_output)
      response = new :code => $?.exitstatus
      response.message = cmd_output unless response.successful?
      response
    end

  end
end
