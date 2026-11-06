# frozen_string_literal: true

module DevFinalCutExperiment
  class Book
    include ActiveModel::Model
    include ActiveModel::Attributes

    TABLE = Library::TABLE
    DROP_LINES = Library::DROP_LINES
    PATTERN = /\A(?<title>[a-z]+(?:-[a-z]+)*)-(?<shelf>\d+)\[(?<fake_checksum>[a-z]{5})\]\z/
    CHECKSUM_LENGTH = 5

    attribute :title, :string
    attribute :shelf, :integer
    attribute :fake_checksum, :string

    attr_accessor :library

    validates :title, format: { with: /\A[a-z]+(?:-[a-z]+)*\z/ }
    validates :shelf, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :fake_checksum, format: { with: /\A[a-z]{#{CHECKSUM_LENGTH}}\z/ }
    validates :library, presence: true

    def initialize(...)
      super
      validate!
    end

    def real_checksum
      title.delete('-').chars.tally
           .sort_by { |letter, count| [-count, letter] }
           .first(CHECKSUM_LENGTH)
           .map(&:first)
           .join
    end

    def genuine?
      fake_checksum == real_checksum
    end
  end
end
