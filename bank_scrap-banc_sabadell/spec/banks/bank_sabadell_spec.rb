require 'fake_bsmobil'
require 'rack'

RSpec.describe BankScrap::BancSabadell do
  let(:nie) { 'Y123456Y' }
  let(:pin) { 9876 }

  before do
    stub_request(:any, /www.bancsabadell.mobi/).to_rack(FakeBsmobil::Api)
  end

  subject(:bank) { described_class.new(nie, pin) }

  it { is_expected.to be }

  describe '#login' do
    subject(:login) { bank.login }
    after  { login }

    let(:session_id) { 'some-session-id' }

    around { |ex| FakeBsmobil.use_session(session_id, &ex) }

    it { is_expected.to be_an(Array) }

    it do
      new_session, _user = login
      expect(new_session).to eq(session_id)
    end
  end

  describe '#fetch_accounts' do
    subject(:fetch_accounts) { bank.fetch_accounts }
    after  { fetch_accounts }

    it { is_expected.to be_an(Array) }
    it { expect(fetch_accounts.size).to eq(1) }
    it { expect(fetch_accounts[0]).to be_a(BankScrap::Account) }

    let(:account) { FakeBsmobil.use_account(owner: 'John Doe') }

    # TODO: test build account
  end

  describe '#fetch_transactions_for' do
    let(:account) { BankScrap::Account.new(id: 'account-number') }

    subject(:transactions) { bank.fetch_transactions_for(account, start_date: Date.yesterday, end_date: Date.today) }

    it { is_expected.to be_an(Array) }
    it { expect(transactions.size).to eq(10) }

    context 'Transaction' do
      subject(:transaction) { transactions.sample }

      it { is_expected.to be_a(BankScrap::Transaction) }
    end
  end

  describe '#accounts' do
    subject(:accounts) { bank.accounts }


    it 'fetches accounts' do
      expect(bank).to receive(:fetch_accounts).and_return([]).once

      expect(accounts).to be(bank.accounts)
    end

  end

end
