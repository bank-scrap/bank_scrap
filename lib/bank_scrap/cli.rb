require 'thor'
require 'active_support/core_ext/string'

module BankScrap
  class Cli < Thor
    def self.shared_options
      option :user,     default: ENV['BANK_SCRAP_USER']
      option :password, default: ENV['BANK_SCRAP_PASSWORD']
      option :log,      default: false
      option :debug,    default: false

      # Some bank needs more input, like birthday, this would go here
      # Usage:
      # bank_scrap balance BANK_NAME --extra=birthday:01/12/1980
      option :extra, type: :hash, default: {}
      option :iban, type: :string, default: nil
      option :from, type: :string, default: nil
      option :to, type: :string, default: nil
    end

    desc "balance BANK", "get accounts' balance"
    shared_options
    def balance(bank)
      assign_shared_options
      initialize_client_for(bank)

      @client.accounts.each do |account|
        say "Account: #{account.description} (#{account.iban})", :cyan
        say "Balance: #{account.balance}", :green
      end
    end

    desc "transactions BANK", "get account's transactions"
    shared_options
    def transactions(bank)
      assign_shared_options
      initialize_client_for(bank)

      account = @iban ? @client.account_with_iban(@iban) : @client.accounts.first
      transactions = account.fetch_transactions(start_date: @from, end_date: @to)

      say "Transactions for: #{account.description} (#{account.iban})", :cyan

      transactions.each do |transaction|
        say transaction.to_s, (transaction.amount > Money.new(0) ? :green : :red)
      end
    end

    private

    def assign_shared_options
      @user       = options[:user]
      @password   = options[:password]
      @log        = options[:log]
      @debug      = options[:debug]
      @extra_args = options[:extra]
      @iban       = options[:iban]
      begin
        @from = options[:from] ? Date.strptime(options[:from], '%d-%m-%Y') : Date.today - 1.month
        @to = options[:to] ? Date.strptime(options[:to], '%d-%m-%Y') : Date.today
        if @from > @to
          say "From date must be lower than to date", :red
          exit
        end
      rescue ArgumentError
        say "Invalid date format. Correct format d-m-Y", :red
        exit
      end
    end

    def initialize_client_for(bank_name)
      bank_class = find_bank_class_for(bank_name)
      @client = bank_class.new(@user, @password, log: @log, debug: @debug, extra_args: @extra_args)
    end

    def find_bank_class_for(bank_name)
      Object.const_get("BankScrap::" + bank_name.classify)
    rescue NameError
      raise ArgumentError.new('Invalid bank name')
    end

  end
end
