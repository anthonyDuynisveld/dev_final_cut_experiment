# frozen_string_literal: true

require 'active_model'

require_relative 'dev_final_cut_experiment/version'
require_relative 'dev_final_cut_experiment/greeter'
require_relative 'dev_final_cut_experiment/hallway'
require_relative 'dev_final_cut_experiment/command'
require_relative 'dev_final_cut_experiment/library'
require_relative 'dev_final_cut_experiment/book'
require_relative 'dev_final_cut_experiment/instruction_parser'
require_relative 'dev_final_cut_experiment/hallway_executor'
require_relative 'dev_final_cut_experiment/library_executor'
require_relative 'dev_final_cut_experiment/guess_executor'
require_relative 'dev_final_cut_experiment/lock'
require_relative 'dev_final_cut_experiment/password'
require_relative 'dev_final_cut_experiment/guess'

module DevFinalCutExperiment
  def self.run
    HallwayExecutor.from_file.run.lit_count
  end

  def self.run_library
    LibraryExecutor.from_file.run
  end

  # Solves the lock against the REAL endpoint (spends real guesses, about 14
  # on average, 17 at most). Needs TEAMCRAFT_TOKEN set. Returns the Lock so its
  # solution, guesses and password can be inspected, even if solving stopped
  # part way.
  def self.solve_lock(scene: 3, part: 1)
    lock = Lock.new(scene:, part:)
    lock.solve
    lock
  rescue StandardError => e
    raise unless lock

    warn "Lock not solved: #{e.class}: #{e.message} (#{lock.guesses.size} guesses sent, #{lock.guesses_left.inspect} left)"
    lock
  end
end
