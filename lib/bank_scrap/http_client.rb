module BankScrap
  class HttpClient

    module AbstractHttpClient
      attr_accessor :response_class, :headers

      def initialize(base_url)
        @base_url = URI(base_url).freeze
        @response_class = HttpResponse
        @headers = {}
      end

      def post(path, body, headers = {})
        request(:post, path, body: body, headers: headers)
      end

      def get(path, query = {}, headers = {})
        request(:get, path, query: query, headers: headers)
      end

      private

      def request(method, path, options = {})

      end

      class HttpResponse < Struct.new(:status, :headers, :body)
      end
    end

    include AbstractHttpClient

  end
end
