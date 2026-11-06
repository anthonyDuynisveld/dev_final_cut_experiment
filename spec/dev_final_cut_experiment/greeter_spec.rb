# frozen_string_literal: true

RSpec.describe DevFinalCutExperiment::Greeter do
  describe '#greet' do
    it 'greets the given name' do
      expect(described_class.new('Ada').greet).to eq('Hello, Ada!')
    end
  end
end
