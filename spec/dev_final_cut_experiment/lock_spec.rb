# frozen_string_literal: true

RSpec.describe DevFinalCutExperiment::Lock do
  subject(:lock) { described_class.new(scene: 3, part: 1) }

  let(:secret_code) { 'SMORES' }
  let(:status) { 200 }
  let(:guesses_left) { 59 }
  let(:opens) { true }

  # Stands in for the real endpoint: scores each guess against secret_code the
  # same way the lock does, so no request ever leaves the test.
  def endpoint_reply(guess)
    right_place = secret_code.chars.zip(guess.chars).count { |code_symbol, guess_symbol| code_symbol == guess_symbol }
    in_common = secret_code.chars.uniq.sum { |symbol| [secret_code.count(symbol), guess.count(symbol)].min }

    {
      status:,
      body: {
        'right_place' => right_place,
        'wrong_place' => in_common - right_place,
        'open' => opens && guess == secret_code,
        'guesses_left' => guesses_left
      }
    }
  end

  # Replaces the scoring endpoint with one that gives the same reply every time,
  # to simulate replies that contradict each other.
  def reply_to_every_guess_with(right_place:)
    reply = { status: 200, body: { 'right_place' => right_place, 'wrong_place' => 0, 'open' => false, 'guesses_left' => 50 } }
    allow(DevFinalCutExperiment::GuessExecutor).to receive(:new)
      .and_return(instance_double(DevFinalCutExperiment::GuessExecutor, run: reply))
  end

  before do
    allow(DevFinalCutExperiment::GuessExecutor).to receive(:new) do |guess:, **|
      instance_double(DevFinalCutExperiment::GuessExecutor, run: endpoint_reply(guess))
    end
  end

  describe 'creating a lock' do
    context 'when the scene is not a positive number' do
      it 'is rejected' do
        expect { described_class.new(scene: 0, part: 1) }.to raise_error(ActiveModel::ValidationError, /Scene/)
      end
    end
  end

  describe 'determining the letters in the code' do
    it 'returns every letter in the code, grouped by symbol' do
      expect(lock.determine_letters).to eq('SSMORE')
    end

    it 'stops counting as soon as all six letters are found', :aggregate_failures do
      lock.determine_letters

      expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).exactly(5).times
      %w[SSSSSS MMMMMM OOOOOO RRRRRR EEEEEE].each do |guess|
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).with(scene: 3, part: 1, guess:)
      end
      expect(DevFinalCutExperiment::GuessExecutor).not_to have_received(:new).with(hash_including(guess: 'XXXXXX'))
    end

    it 'reports how many times each symbol appears' do
      lock.determine_letters

      expect(lock.symbol_counts).to eq('S' => 2, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1, 'X' => 0)
    end

    context 'when the code contains X' do
      let(:secret_code) { 'XROXMS' }

      it 'needs every counting guess, including X', :aggregate_failures do
        expect(lock.determine_letters).to eq('SMORXX')
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).with(hash_including(guess: 'XXXXXX'))
      end
    end

    context 'when the first symbols counted already make up the whole code' do
      let(:secret_code) { 'SSSMMM' }

      it 'skips counting the rest and treats them as absent', :aggregate_failures do
        expect(lock.determine_letters).to eq('SSSMMM')
        expect(lock.symbol_counts).to eq('S' => 3, 'M' => 3, 'O' => 0, 'R' => 0, 'E' => 0, 'X' => 0)
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).twice
      end
    end

    context 'when some of the single-symbol guesses were already made' do
      before do
        lock.submit('SSSSSS')
        lock.submit('MMMMMM')
      end

      it 'only spends calls on the guesses still missing', :aggregate_failures do
        letters = lock.determine_letters

        expect(letters).to eq('SSMORE')
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).exactly(5).times
      end
    end

    context 'when it is called a second time' do
      it 'spends no further calls' do
        lock.determine_letters
        lock.determine_letters

        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).exactly(5).times
      end
    end

    context 'when a single-symbol guess opens the lock' do
      let(:secret_code) { 'SSSSSS' }

      it 'stops guessing once the lock is open', :aggregate_failures do
        lock.determine_letters

        expect(lock).to be_open
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).once
      end
    end

    context 'when the replies count more letters than the code can hold' do
      before { reply_to_every_guess_with(right_place: 4) }

      it 'raises instead of returning letters' do
        expect { lock.determine_letters }
          .to raise_error(described_class::GuessError, /add up to 8, more than 6/)
      end
    end

    context 'when every symbol is counted but the replies fall short of the code' do
      before { reply_to_every_guess_with(right_place: 0) }

      it 'raises instead of returning letters' do
        expect { lock.determine_letters }
          .to raise_error(described_class::GuessError, /add up to 0, expected 6/)
      end
    end
  end

  describe 'submitting a guess' do
    it 'records what the lock replied', :aggregate_failures do
      lock.submit('SSSXXX')

      expect(lock.guesses.last).to have_attributes(
        code: 'SSSXXX', right_place: 1, wrong_place: 1, open: false, guesses_left: 59
      )
      expect(lock.guesses_left).to eq(59)
      expect(lock).not_to be_open
    end

    context 'when the guess is the code' do
      it 'opens the lock' do
        lock.submit('SMORES')

        expect(lock).to be_open
      end
    end

    context 'when the code is not six of the lock symbols' do
      it 'is refused without spending a call', :aggregate_failures do
        %w[ABCDEF SMORE smores SMORESS].each do |code|
          expect { lock.submit(code) }.to raise_error(described_class::GuessError, /must be 6 of/)
        end
        expect(DevFinalCutExperiment::GuessExecutor).not_to have_received(:new)
      end
    end

    context 'when the code has already been guessed' do
      before { lock.submit('SSSXXX') }

      it 'is refused without spending a call', :aggregate_failures do
        expect { lock.submit('SSSXXX') }.to raise_error(described_class::GuessError, /already been guessed/)
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).once
      end
    end

    context 'when the lock is already open' do
      before { lock.submit('SMORES') }

      it 'is refused without spending a call', :aggregate_failures do
        expect { lock.submit('SSSXXX') }.to raise_error(described_class::GuessError, /already open/)
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).once
      end
    end

    context 'when the lock has no guesses left' do
      let(:guesses_left) { 0 }

      before { lock.submit('SSSXXX') }

      it 'is refused without spending a call', :aggregate_failures do
        expect { lock.submit('MMMXXX') }.to raise_error(described_class::GuessError, /no guesses left/)
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).once
      end
    end

    context 'when the endpoint replies with an error status' do
      let(:status) { 500 }

      it 'raises and does not record the guess', :aggregate_failures do
        expect { lock.submit('SSSXXX') }.to raise_error(described_class::GuessError, /failed/)
        expect(lock.guesses).to be_empty
      end
    end
  end

  describe 'solving the lock' do
    it 'opens the lock and returns the code', :aggregate_failures do
      expect(lock.solve).to eq('SMORES')
      expect(lock).to be_open
    end

    it 'searches the first half of the open positions first, padded with an absent symbol' do
      lock.solve

      expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).with(scene: 3, part: 1, guess: 'SSSXXX')
    end

    it 'records the final letter totals and positions on the password', :aggregate_failures do
      lock.solve

      expect(lock.password.final_totals).to eq('S' => 2, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1, 'X' => 0)
      expect(lock.password.letter_positions).to eq('S' => [0, 5], 'M' => [1], 'O' => [2], 'R' => [3], 'E' => [4])
      expect(lock.password.code).to eq('SMORES')
    end

    it 'stays well inside the 60-call budget' do
      lock.solve

      # 17 is the worst case across all 46,656 possible codes.
      expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).at_most(17).times
    end

    context 'when X is in the code' do
      let(:secret_code) { 'XXSMXX' }

      it 'pads probes with the first symbol missing from the code instead', :aggregate_failures do
        expect(lock.solve).to eq('XXSMXX')
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).with(scene: 3, part: 1, guess: 'SSSOOO')
      end
    end

    context 'when a symbol fills an entire half' do
      let(:secret_code) { 'SSSMMM' }

      it 'stops searching that symbol after one probe', :aggregate_failures do
        expect(lock.solve).to eq('SSSMMM')
        # two letter counts (S and M fill the code) + one probe ("SSSOOO") + the final code
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).exactly(4).times
      end
    end

    context 'when every symbol appears exactly once' do
      let(:secret_code) { 'XEROMS' }

      it 'has no absent symbol to pad with, so only tries rearrangements of the letters', :aggregate_failures do
        expect(lock.solve).to eq('XEROMS')
        expect(lock.guesses.reject(&:single_symbol?).map { |guess| guess.code.chars.sort.join }).to all(eq('EMORSX'))
      end
    end

    context 'when a single symbol fills the code' do
      let(:secret_code) { 'MMMMMM' }

      it 'opens while counting letters and sends nothing more', :aggregate_failures do
        expect(lock.solve).to eq('MMMMMM')
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).twice
      end
    end

    context 'when a probe was already sent by hand' do
      before { lock.submit('SSSXXX') }

      it 'reuses that reply instead of spending another call', :aggregate_failures do
        expect(lock.solve).to eq('SMORES')
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).with(scene: 3, part: 1, guess: 'SSSXXX').once
      end
    end

    context 'when the lock never opens' do
      let(:opens) { false }

      it 'raises once the only code that fits has been tried' do
        expect { lock.solve }.to raise_error(described_class::GuessError, /"SMORES" fits every reply but did not open/)
      end

      context 'when every symbol appears exactly once' do
        let(:secret_code) { 'XEROMS' }

        it 'raises once no untried arrangement fits' do
          expect { lock.solve }.to raise_error(described_class::GuessError, /no arrangement of the letters fits/)
        end
      end
    end

    context 'when the guesses run out' do
      let(:guesses_left) { 0 }

      it 'raises without sending another guess', :aggregate_failures do
        expect { lock.solve }.to raise_error(described_class::GuessError, /no guesses left/)
        expect(DevFinalCutExperiment::GuessExecutor).to have_received(:new).once
      end
    end
  end
end
