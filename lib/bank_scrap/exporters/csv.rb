require 'csv'

module BankScrap
  module Exporter

    class Csv

      attr_accessor :output_path, :separator, :headers

      def initialize(output_path = nil, separator = nil)
        @output_path  = !output_path.nil? ? output_path : "#{Dir.pwd}/transactions.csv"
        @separator    = !separator.nil? ? separator : ','
        @headers      = ["Date", "Description", "Amount"]
      end

      def write_to_file(transactions)
        CSV.open(@output_path, 'wb', {col_sep: @separator}) do |csv|
          csv << @headers
          transactions.each do |transaction|
            csv << transaction.to_a
          end
        end
      end

    end
  end
end
