# frozen_string_literal: true

RSpec.describe DevFinalCutExperiment::Password do
  subject(:password) { described_class.new }

  def record_totals(totals)
    totals.each { |symbol, count| password.record_total(symbol, count) }
  end

  describe 'a new password' do
    it 'knows nothing about the code yet', :aggregate_failures do
      expect(password.final_totals).to be_nil
      expect(password.letters).to be_nil
      expect(password.open_positions).to eq([0, 1, 2, 3, 4, 5])
      expect(password.code).to be_nil
    end
  end

  describe 'tracking letter totals' do
    context 'when the counted letters fill the code before every symbol is counted' do
      before { record_totals('S' => 2, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1) }

      it 'treats the symbols never counted as absent', :aggregate_failures do
        expect(password).to be_totals_known
        expect(password.final_totals).to eq('S' => 2, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1, 'X' => 0)
        expect(password.letters).to eq('SSMORE')
        expect(password.filler).to eq('X')
      end
    end

    context 'when the counted letters do not fill the code yet' do
      before { record_totals('S' => 2, 'M' => 1) }

      it 'does not report final totals', :aggregate_failures do
        expect(password).not_to be_totals_known
        expect(password.final_totals).to be_nil
        expect(password.letters).to be_nil
      end
    end

    context 'when every symbol appears exactly once' do
      before { record_totals('S' => 1, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1, 'X' => 1) }

      it 'has no absent symbol to use as filler' do
        expect(password.filler).to be_nil
      end
    end

    context 'when the totals add up to more than the code length' do
      it 'is rejected' do
        expect { record_totals('S' => 4, 'M' => 3) }
          .to raise_error(ActiveModel::ValidationError, /Totals add up to 7, more than 6/)
      end
    end

    context 'when every symbol is counted but the totals fall short of the code length' do
      it 'is rejected' do
        expect { record_totals('S' => 1, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1, 'X' => 0) }
          .to raise_error(ActiveModel::ValidationError, /Totals add up to 5, expected 6/)
      end
    end
  end

  describe 'tracking letter positions' do
    before { record_totals('S' => 2, 'M' => 1, 'O' => 1, 'R' => 1, 'E' => 1) }

    it 'records where each letter sits and which positions are still open', :aggregate_failures do
      password.place('S', [0, 5])

      expect(password.letter_positions).to eq('S' => [0, 5])
      expect(password.open_positions).to eq([1, 2, 3, 4])
      expect(password.code).to be_nil
    end

    context 'when every position is filled' do
      before { password.reveal('SMORES') }

      it 'reports the full code and every letter position', :aggregate_failures do
        expect(password).to be_solved
        expect(password.code).to eq('SMORES')
        expect(password.letter_positions).to eq('S' => [0, 5], 'M' => [1], 'O' => [2], 'R' => [3], 'E' => [4])
      end
    end

    context 'when a letter is placed more times than the code holds it' do
      it 'is rejected' do
        expect { password.place('M', [1, 2]) }
          .to raise_error(ActiveModel::ValidationError, /place M 2 times, but the code has 1/)
      end
    end
  end
end
