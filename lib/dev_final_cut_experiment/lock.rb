# frozen_string_literal: true

module DevFinalCutExperiment
  class Lock
    include ActiveModel::Model
    include ActiveModel::Attributes

    class GuessError < StandardError; end

    SYMBOLS = %w[S M O R E X].freeze
    CODE_LENGTH = 6

    attribute :scene, :integer
    attribute :part, :integer

    attr_accessor :client
    attr_reader :guesses, :password

    validates :scene, :part, numericality: { only_integer: true, greater_than: 0 }

    def initialize(client: GuessExecutor, **)
      super(client:, **)
      validate!
      @guesses = []
      @password = Password.new(lock: self)
    end

    def code_pattern
      /\A[#{SYMBOLS.join}]{#{CODE_LENGTH}}\z/
    end

    # One guess per symbol ("SSSSSS", "MMMMMM", ...). Each one's right_place is
    # exactly how many times that symbol appears in the code.
    def initial_guesses
      SYMBOLS.map { |symbol| symbol * CODE_LENGTH }
    end

    # Sends whichever initial guesses haven't been made yet, stopping as soon as
    # all six letters are found, then returns the code's letters, e.g. "SSMORE".
    def determine_letters
      (initial_guesses - guesses.map(&:code)).each do |code|
        break if open? || password.totals_known?

        submit(code)
      end

      letters
    end

    # How many times each symbol appears; symbols never guessed count as 0
    # once all six letters are found.
    def symbol_counts
      password.final_totals || password.totals
    end

    def letters
      password.letters
    end

    # Finds the letters, then each letter's positions, then opens the lock.
    # Returns the code that opened it.
    def solve
      catch(:opened) do
        determine_letters
        throw :opened if open?

        filler ? locate_by_halving : guess_consistent_codes
      end

      password.reveal(solution) if solution
      solution
    end

    def solution
      guesses.find(&:open)&.code
    end

    # A symbol that is not in the code. Probes are padded with it so every
    # right_place in a probe comes from the symbol being searched for.
    def filler
      password.filler
    end

    # Every arrangement of the known letters that agrees with every reply so far.
    def candidates
      letters.chars.permutation.map(&:join).uniq.select do |code|
        guesses.all? { |guess| self.class.score(code, guess.code) == [guess.right_place, guess.wrong_place] }
      end
    end

    # What the lock replies with when `guess` is tried against `code`.
    def self.score(code, guess)
      right_place = code.chars.zip(guess.chars).count { |code_symbol, guess_symbol| code_symbol == guess_symbol }
      in_common = SYMBOLS.sum { |symbol| [code.count(symbol), guess.count(symbol)].min }
      [right_place, in_common - right_place]
    end

    def submit(code)
      raise GuessError, "#{code.inspect} must be #{CODE_LENGTH} of #{SYMBOLS.join(', ')}" unless code_pattern.match?(code)
      raise GuessError, "#{code.inspect} has already been guessed" if guesses.any? { |guess| guess.code == code }
      raise GuessError, 'lock is already open' if open?
      raise GuessError, 'no guesses left' if guesses_left&.zero?

      response = client.new(scene:, part:, guess: code).run
      raise GuessError, "guess #{code.inspect} failed: #{response.inspect}" unless (200..299).cover?(response[:status])

      record(code, response[:body])
    end

    def open?
      guesses.any?(&:open)
    end

    def guesses_left
      guesses.last&.guesses_left
    end

    private

    def locate_by_halving
      *searched, last = password.present_symbols

      searched.each do |symbol|
        password.place(symbol, halve(symbol, password.open_positions, symbol_counts[symbol]))
      end
      password.place(last, password.open_positions)

      guess_for(password.code)
      raise GuessError, "#{password.code.inspect} fits every reply but did not open the lock" unless open?
    end

    def halve(symbol, positions, count)
      return [] if count.zero?
      return positions if count == positions.size

      first_half, second_half = positions.each_slice((positions.size / 2.0).ceil).to_a
      found = probe(symbol, first_half)

      halve(symbol, first_half, found) + halve(symbol, second_half, count - found)
    end

    # How many of `positions` hold `symbol`, e.g. probe("S", [0, 1, 2]) sends "SSSXXX".
    def probe(symbol, positions)
      code = Array.new(CODE_LENGTH, filler)
      positions.each { |index| code[index] = symbol }

      guess_for(code.join).right_place
    end

    # No absent symbol to pad probes with (every symbol appears once), so keep
    # trying a code that agrees with every reply until one opens the lock.
    def guess_consistent_codes
      until open?
        code = (candidates - guesses.map(&:code)).first
        raise GuessError, 'no arrangement of the letters fits every reply' unless code

        guess_for(code)
      end
    end

    # Reuses an earlier reply for the same code instead of spending a call.
    def guess_for(code)
      guess = guesses.find { |earlier| earlier.code == code } || submit(code)
      throw :opened if guess.open

      guess
    end

    def record(code, body)
      guess = Guess.new(code:, lock: self, **body.slice('right_place', 'wrong_place', 'open', 'guesses_left').symbolize_keys)
      guesses << guess
      password.record_total(code[0], guess.right_place) if guess.single_symbol?
      guess
    rescue ActiveModel::ValidationError => e
      raise GuessError, e.message
    end
  end
end
