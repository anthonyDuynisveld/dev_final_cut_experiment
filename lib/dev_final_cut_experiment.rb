# frozen_string_literal: true

require 'active_model'

require_relative 'dev_final_cut_experiment/version'
require_relative 'dev_final_cut_experiment/greeter'
require_relative 'dev_final_cut_experiment/hallway'
require_relative 'dev_final_cut_experiment/command'
require_relative 'dev_final_cut_experiment/instruction_parser'
require_relative 'dev_final_cut_experiment/hallway_executor'

module DevFinalCutExperiment
  def self.run
    HallwayExecutor.from_file.run.lit_count
  end
end
