# frozen_string_literal: true

module DevFinalCutExperiment
  class InstructionParser
    class ParseError < StandardError; end

    def parse_start(model, **associations)
      build(model, rows(model).first, 1, **associations)
    end

    def parse_commands(model, **associations)
      rows(model).drop(1).each.with_index(2).map do |line, line_number|
        parse_command(model, line, line_number, **associations)
      end
    end

    private

    # Each model names its own TABLE (data file); read each table once.
    def rows(model)
      @rows ||= {}
      @rows[model::TABLE] ||= File.readlines(model::TABLE, chomp: true).map(&:strip).reject(&:empty?)
    end

    def parse_command(model, line, line_number, **associations)
      build(model, line, line_number, **associations)
    end

    def build(model, line, line_number, **associations)
      match = model::PATTERN.match(line.to_s)
      raise ParseError, "line #{line_number}: #{line.inspect} does not match #{model.name.demodulize}" unless match

      model.new(**match.named_captures.symbolize_keys, **associations)
    rescue ActiveModel::ValidationError => e
      raise ParseError, "line #{line_number}: #{e.message}"
    end
  end
end
