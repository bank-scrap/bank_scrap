module BankScrap::Banks
  module Openbank
    class Account < BankScrap::Account
      attr_accessor :contract_id
    end
  end
end
