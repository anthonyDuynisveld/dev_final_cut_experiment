# frozen_string_literal: true

module DevFinalCutExperiment
  # A stand-in for the lock endpoint with a password you choose. It answers
  # exactly like the real lock, so the Lock can be run against it without
  # spending real calls. Pass it to a Lock as its client:
  #
  #   endpoint = StubEndpoint.new(password: 'SMORES')
  #   Lock.new(scene: 3, part: 1, client: endpoint).solve
  class StubEndpoint
    GUESS_LIMIT = 60

    # One request, shaped like a GuessExecutor: built with new, sent with run.
    Request = Struct.new(:endpoint, :guess) do
      def run
        endpoint.reply(guess)
      end
    end

    attr_reader :password, :guess_limit, :received

    def self.random_password
      Array.new(Lock::CODE_LENGTH) { Lock::SYMBOLS.sample }.join
    end

    def initialize(password: self.class.random_password, guess_limit: GUESS_LIMIT)
      raise ArgumentError, "password #{password.inspect} must be 6 of #{Lock::SYMBOLS.join(', ')}" unless
        password.match?(/\A[#{Lock::SYMBOLS.join}]{#{Lock::CODE_LENGTH}}\z/)

      @password = password
      @guess_limit = guess_limit
      @received = []
    end

    # Matches GuessExecutor.new(scene:, part:, guess:) so a Lock can't tell the difference.
    def new(guess:, **)
      Request.new(self, guess)
    end

    def reply(guess)
      return { status: 429, body: { 'error' => 'no guesses left' } } if received.size >= guess_limit

      received << guess
      right_place, wrong_place = Lock.score(password, guess)

      {
        status: 200,
        body: {
          'right_place' => right_place,
          'wrong_place' => wrong_place,
          'open' => guess == password,
          'guesses_left' => guess_limit - received.size
        }
      }
    end
  end
end
