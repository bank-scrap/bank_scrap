require 'bank_scrap/http_client'
require 'net/http'

module BankScrap
  class NetHttpClient < HttpClient

    def initialize(base_url)
      super

      initialize_net_http(@base_url)
    end

    private

    def initialize_net_http(uri)
      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = uri.is_a?(URI::HTTPS)
      @http.set_debug_output $stdout if ENV['DEBUG']
    end

    def request(method, path, options = {})
      uri = URI.join(@base_url, path)

      request = Net::HTTP.const_get(method.to_s.capitalize, false).new(uri)

      request.body = options[:body]

      options.fetch(:headers).merge(@headers).each_pair do |header, values|
        Array(values).each do |value|
          request[header] = value
        end
      end

      response = @http.request(request)

      response_class.new(response.code, response.to_hash, response.body)
    end

  end
end
