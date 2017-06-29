require 'json'

module BankScrap
  module Exporter
    # Json exporter
    class Json
      def initialize(output = nil)
        @output = Json.get_filename(output)
      end

      def self.get_filename(output)
        output || 'transactions.json'
      end

      def write_to_file(data)
        json_array = []
        data.each do |line|
          array = line.to_a
          hash = { date: array[0], description: array[1], amount: array[2] }
          json_array << hash
        end
        File.open(@output, 'w') do |f|
          f.write(json_array.to_json)
        end
      end
    end
  end
end
