# frozen_string_literal: true

module DevFinalCutExperiment
  # Runs the Lock's solving process against a StubEndpoint and reports how many
  # guesses it took. Never calls the real endpoint.
  class SimulationExecutor
    attr_reader :endpoint, :lock

    # Solves every password given (default: 100 random ones) and summarises the guess counts.
    def self.benchmark(passwords = Array.new(100) { StubEndpoint.random_password })
      results = passwords.map { |password| new(password:).run }
      counts = results.map { |result| result[:guesses] }

      {
        runs: results.size,
        solved: results.count { |result| result[:solved] },
        average_guesses: (counts.sum.to_f / counts.size).round(2),
        fewest_guesses: counts.min,
        most_guesses: counts.max,
        hardest_password: results.max_by { |result| result[:guesses] }[:password]
      }
    end

    def initialize(password: StubEndpoint.random_password)
      @endpoint = StubEndpoint.new(password:)
      @lock = Lock.new(scene: 3, part: 1, client: endpoint)
    end

    def run
      solution = lock.solve

      {
        password: endpoint.password,
        solved: solution == endpoint.password,
        guesses: endpoint.received.size,
        sequence: endpoint.received,
        letter_totals: lock.password.final_totals,
        letter_positions: lock.password.letter_positions
      }
    end
  end
end
