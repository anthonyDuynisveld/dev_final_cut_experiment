# frozen_string_literal: true

module DevFinalCutExperiment
  class Executor
    attr_reader :hallway, :commands

    def self.from_file(path)
      new(InstructionParser.parse_file(path))
    end

    def initialize(parser)
      @hallway = parser.build_hallway
      @commands = parser.commands
    end

    def run
      commands.each { |command| execute(command) }
      hallway
    end

    def execute(command)
      command.apply(hallway)
    end
  end
end
