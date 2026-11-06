# frozen_string_literal: true

module DevFinalCutExperiment
  class InstructionParser
    class ParseError < StandardError; end

    START_PATTERN = /\Ahallway (?<size>\d+)\z/
    COMMAND_PATTERN = /\A(?<action>turn on|turn off|toggle) (?<from>\d+) through (?<to>\d+)\z/

    attr_reader :hallway_size, :commands

    def self.parse_file(path)
      new(File.readlines(path, chomp: true)).parse
    end

    def initialize(lines)
      @lines = lines
      @commands = []
    end

    def parse
      start_line, *command_lines = @lines.map(&:strip).reject(&:empty?)

      parse_start(start_line)
      command_lines.each.with_index(2) { |line, line_number| parse_command(line, line_number) }
      parse_finish

      self
    end

    def build_hallway
      Hallway.new(size: hallway_size)
    end

    private

    # The opening line: sets up the hallway everything else acts on.
    def parse_start(line)
      match = START_PATTERN.match(line.to_s)
      raise ParseError, "line 1: expected 'hallway <size>', got #{line.inspect}" unless match

      @hallway_size = match[:size].to_i
    end

    # A single instruction line: becomes one Command.
    def parse_command(line, line_number)
      match = COMMAND_PATTERN.match(line)
      raise ParseError, "line #{line_number}: unrecognised instruction #{line.inspect}" unless match

      command = Command.new(action: match[:action].tr(' ', '_'), from: match[:from], to: match[:to])
      raise ParseError, "line #{line_number}: #{command.errors.full_messages.to_sentence}" if command.invalid?

      @commands << command
    end

    # Runs once every line has been read: checks the result as a whole.
    def parse_finish
      out_of_range = @commands.find { |command| command.to >= hallway_size }
      return unless out_of_range

      raise ParseError, "command #{out_of_range.attributes} reaches past the end of a #{hallway_size}-light hallway"
    end
  end
end
