require 'csv'

module BankScrap
  module Exporter
    # Csv exporter
    class Csv
      HEADERS = %w(ID Date Description DescriptionDetail Amount).freeze

      def initialize(output = nil, account)
        @output = Csv.get_filename(output)
        @account = account
      end

      def self.get_filename(output)
        output || 'transactions.csv'
      end

      def write_to_file(data)
        CSV.open(@output, 'wb') do |csv|
          csv << HEADERS
          data.each { |line| csv << line.to_a }
        end
      end
    end
  end
end
