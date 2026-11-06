# frozen_string_literal: true

# Runs the full solving process against StubEndpoint (spec/support), a stand-in
# for the real lock with a password chosen here. No real guesses are spent.
RSpec.describe DevFinalCutExperiment::SimulationExecutor do
  # 17 is the worst case across all 46,656 possible passwords.
  let(:worst_case_guesses) { 17 }

  describe 'solving a chosen password' do
    {
      'SMORES' => 'the example password, with a repeated letter',
      'XROXMS' => 'X in the code, so another absent symbol pads the probes',
      'SSSMMM' => 'two letters that fill the code before the rest are counted',
      'XEROMS' => 'every symbol once, so there is no absent symbol to pad with',
      'ESMRSX' => 'one of the hardest passwords',
      'MMMMMM' => 'one letter everywhere, opened while counting',
      'XXXXXX' => 'one letter everywhere, and the last one counted'
    }.each do |password, why|
      context "when the password is #{password} (#{why})" do
        it 'opens the lock within the worst-case number of guesses', :aggregate_failures do
          result = described_class.new(password:).run

          expect(result[:solved]).to be(true)
          expect(result[:guesses]).to be <= worst_case_guesses
          expect(result[:letter_totals]).to eq(DevFinalCutExperiment::Lock::SYMBOLS.to_h { [_1, password.count(_1)] })

          RSpec.configuration.reporter.message("    #{password}: #{result[:guesses]} guesses #{result[:sequence].join(' ')}")
        end
      end
    end
  end

  describe 'a benchmark of random passwords' do
    it 'solves every one within the worst-case number of guesses', :aggregate_failures do
      summary = described_class.benchmark

      expect(summary[:solved]).to eq(summary[:runs])
      expect(summary[:most_guesses]).to be <= worst_case_guesses

      RSpec.configuration.reporter.message("    benchmark: #{summary}")
    end
  end

  describe 'running out of guesses' do
    it 'stops instead of spending more than the endpoint allows', :aggregate_failures do
      endpoint = DevFinalCutExperiment::StubEndpoint.new(password: 'SMORES', guess_limit: 3)
      lock = DevFinalCutExperiment::Lock.new(scene: 3, part: 1, client: endpoint)

      expect { lock.solve }.to raise_error(DevFinalCutExperiment::Lock::GuessError, /no guesses left/)
      expect(endpoint.received.size).to eq(3)
    end
  end
end
