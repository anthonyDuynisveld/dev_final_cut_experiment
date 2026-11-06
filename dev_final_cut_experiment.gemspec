# frozen_string_literal: true

require_relative 'lib/dev_final_cut_experiment/version'

Gem::Specification.new do |spec|
  spec.name = 'dev_final_cut_experiment'
  spec.version = DevFinalCutExperiment::VERSION
  spec.authors = ['Anthony Duynisveld']
  spec.summary = 'Hallway lights interview problem: parse instructions and execute them against a hallway.'
  spec.required_ruby_version = '>= 3.3'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
