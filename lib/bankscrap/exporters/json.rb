require 'json'

module BankScrap
  module Exporter
    # Json exporter
    class Json
      def initialize(output = nil, account)
        @output = Json.get_filename(output)
        @account = account
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
        json_hash = { account: { description: @account.description, iban: @account.iban }, transactions: json_array }
        File.open(@output, 'w') do |f|
            f.write(json_hash.to_json)
        end
      end
    end
  end
end
