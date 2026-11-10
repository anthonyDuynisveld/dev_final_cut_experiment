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
require_relative 'dev_final_cut_experiment/order_book'
require_relative 'dev_final_cut_experiment/doll'
require_relative 'dev_final_cut_experiment/doll/part'
require_relative 'dev_final_cut_experiment/doll/pattern'
require_relative 'dev_final_cut_experiment/doll/head'
require_relative 'dev_final_cut_experiment/doll/eyes'
require_relative 'dev_final_cut_experiment/doll/hair'
require_relative 'dev_final_cut_experiment/doll/limbs'
require_relative 'dev_final_cut_experiment/doll/outfit'
require_relative 'dev_final_cut_experiment/doll/voice_box'
require_relative 'dev_final_cut_experiment/doll/haunting'
require_relative 'dev_final_cut_experiment/order_book_executor'

module DevFinalCutExperiment
  def self.run
    HallwayExecutor.from_file.run.lit_count
  end

  def self.run_library
    LibraryExecutor.from_file.run
  end

  # Total minutes to build every doll in the order book.
  def self.order_book_minutes
    OrderBookExecutor.from_file.run
  end

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
