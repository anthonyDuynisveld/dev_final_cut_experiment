# frozen_string_literal: true

require 'net/http'
require 'json'

module DevFinalCutExperiment
  # Submits one guess to the scene's lock endpoint. The endpoint only allows a
  # limited number of calls, so nothing is sent until #run is called.
  class GuessExecutor
    BASE_URL = 'https://teamcraft.ncurwen.dev/api/scenes'
    TOKEN_ENV = 'TEAMCRAFT_TOKEN'
    # Git-ignored; holds the bearer token when TEAMCRAFT_TOKEN isn't set.
    TOKEN_FILE = File.expand_path('../../.teamcraft_token', __dir__)

    attr_reader :scene, :part, :guess

    def self.default_token
      ENV.fetch(TOKEN_ENV) do
        raise KeyError, "set #{TOKEN_ENV} or put the token in #{TOKEN_FILE}" unless File.exist?(TOKEN_FILE)

        File.read(TOKEN_FILE).strip
      end
    end

    def initialize(scene:, part:, guess:, token: self.class.default_token)
      @scene = scene
      @part = part
      @guess = guess
      @token = token
    end

    def run
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      { status: response.code.to_i, body: parse(response.body) }
    end

    def uri
      URI("#{BASE_URL}/#{scene}/guess")
    end

    private

    attr_reader :token

    def request
      Net::HTTP::Post.new(uri, 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json').tap do |post|
        post.body = { 'part' => part, 'guess' => guess }.to_json
      end
    end

    def parse(body)
      JSON.parse(body)
    rescue JSON::ParserError
      body
    end
  end
end
