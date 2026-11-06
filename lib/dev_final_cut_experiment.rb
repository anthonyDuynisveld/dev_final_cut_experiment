# frozen_string_literal: true

require 'active_model'

require_relative 'dev_final_cut_experiment/version'
require_relative 'dev_final_cut_experiment/greeter'
require_relative 'dev_final_cut_experiment/hallway'
require_relative 'dev_final_cut_experiment/command'
require_relative 'dev_final_cut_experiment/instruction_parser'
require_relative 'dev_final_cut_experiment/executor'

module DevFinalCutExperiment
  DEFAULT_INPUT_PATH = File.expand_path('../data/scene-1-input.txt', __dir__)

  def self.run(path = DEFAULT_INPUT_PATH)
    Executor.from_file(path).run.lit_count
  end
end
