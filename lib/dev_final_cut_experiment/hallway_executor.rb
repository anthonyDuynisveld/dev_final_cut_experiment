# frozen_string_literal: true

module DevFinalCutExperiment
  class HallwayExecutor
    attr_reader :hallway

    def self.from_file
      new(InstructionParser.new)
    end

    def initialize(parser)
      @parser = parser
      @hallway = build_hallway
    end

    def run
      hallway.commands.each { |command| execute(command) }
      hallway
    end

    def execute(command)
      command.apply
    end

    private

    attr_reader :parser

    def build_hallway
      hallway = parser.parse_start(Hallway)
      hallway.commands.concat(parser.parse_commands(Command, hallway:))
      hallway
    end
  end
end
