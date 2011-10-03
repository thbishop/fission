require 'forwardable'

module Fission
  class Command
    extend Forwardable

    def_delegators :@ui, :output, :output_and_exit, :output_printf

    attr_reader :options, :args, :ui

    def initialize(args=[])
      ui
      @options = OpenStruct.new
      @args = args
    end

    def ui
      @ui ||= Fission::UI.new
    end

    def self.help
      self.new.option_parser.to_s
    end

  end
end
