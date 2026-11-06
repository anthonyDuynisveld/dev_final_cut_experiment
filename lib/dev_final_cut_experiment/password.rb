# frozen_string_literal: true

module DevFinalCutExperiment
  # What is known so far about a lock's code: how many of each symbol it holds
  # (totals) and which symbol sits in each position (positions).
  class Password
    include ActiveModel::Model

    SYMBOLS = Lock::SYMBOLS
    LENGTH = Lock::CODE_LENGTH

    attr_accessor :lock
    attr_reader :totals, :positions

    validate :totals_fit_length
    validate :totals_fill_length_once_every_symbol_is_counted
    validate :positions_match_totals

    def initialize(...)
      super
      @totals = {}
      @positions = Array.new(LENGTH)
      validate!
    end

    def record_total(symbol, count)
      totals[symbol] = count
      validate!
    end

    def counted_total
      totals.values.sum
    end

    # Every letter is accounted for: either all six have been found, or every
    # symbol has been counted.
    def totals_known?
      counted_total == LENGTH || SYMBOLS.all? { |symbol| totals.key?(symbol) }
    end

    # Totals for every symbol, with uncounted symbols filled in as 0 once all
    # six letters are found, e.g. {"S"=>2, "M"=>1, ..., "X"=>0}.
    def final_totals
      return unless totals_known?

      SYMBOLS.to_h { |symbol| [symbol, totals.fetch(symbol, 0)] }
    end

    # The code's letters in SYMBOLS order, e.g. "SSMORE".
    def letters
      final_totals&.sum('') { |symbol, count| symbol * count }
    end

    def present_symbols
      final_totals&.select { |_symbol, count| count.positive? }&.keys
    end

    # A symbol that is not in the code.
    def filler
      final_totals&.key(0)
    end

    def place(symbol, indexes)
      indexes.each { |index| positions[index] = symbol }
      validate!
    end

    # Fills every position from a known code, e.g. the one that opened the lock.
    def reveal(code)
      @positions = code.chars
      validate!
    end

    def open_positions
      positions.each_index.select { |index| positions[index].nil? }
    end

    def solved?
      open_positions.empty?
    end

    def code
      positions.join if solved?
    end

    # Where each symbol sits, e.g. {"S"=>[0, 5], "M"=>[1], ...}.
    def letter_positions
      positions.each_with_index.each_with_object({}) do |(symbol, index), found|
        (found[symbol] ||= []) << index if symbol
      end
    end

    private

    def totals_fit_length
      return if counted_total <= LENGTH

      errors.add(:totals, "add up to #{counted_total}, more than #{LENGTH}")
    end

    def totals_fill_length_once_every_symbol_is_counted
      return unless SYMBOLS.all? { |symbol| totals.key?(symbol) }
      return if counted_total == LENGTH

      errors.add(:totals, "add up to #{counted_total}, expected #{LENGTH}")
    end

    def positions_match_totals
      return unless final_totals

      letter_positions.each do |symbol, indexes|
        next if indexes.size <= final_totals[symbol]

        errors.add(:positions, "place #{symbol} #{indexes.size} times, but the code has #{final_totals[symbol]}")
      end
    end
  end
end
