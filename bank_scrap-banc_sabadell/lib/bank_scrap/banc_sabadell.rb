require 'json'
require 'bank_scrap/core'

module BankScrap
  class BancSabadell
    class InvalidCredentialsError < StandardError; end
    class InvalidResponseError < StandardError; end

    API_URL = URI('https://www.bancsabadell.mobi/bsmobil/api/').freeze

    LOGIN_INFO = {
        deviceInfo: 'iOSNative iPhone 8.2 NATIVE_APP 15.2.0',
        password: nil,
        userName: nil,
        newDevice: false,
        contract: '',
        brand: 'SAB',
        devicePrint: '',
        requestId: 'SDK',
        geolocationData: JSON.generate(
            DeviceSystemVersion: '8.2',
            HardwareID: 'FAB70832-3893-4471-BC3C-3C984A852E49',
            ScreenSize: '320 x 568',
            Languages: 'en',
            MultitaskingSupported: true,
            DeviceModel: 'iPhone',
            RSA_ApplicationKey: '42D7D0F93CE15214780F4DED46BAD347',
            TIMESTAMP: '2015-04-06T10:10:34Z',
            Emulator: 0,
            OS_ID: '46CC0D94-5F6F-44B7-B25D-055A8B093D81',
            Compromised: 0,
            DeviceSystemName: 'iPhone OS',
            DeviceName: 'bank_scrap',
            SDK_VERSION: '2.0.0'
        ).freeze,
        loginType: 5
    }.freeze

    def initialize(nie, pin, **options)
      @http_client = BankScrap.http_client.new(API_URL)
      @http_client.response_class = HttpResponse

      @http_client.headers.merge!(
          'Accept' => 'application/vnd.idk.bsmobil-v2+json',
          'Content-Type' => 'application/json'
      )

      @session = Session.new(self)

      @nie = nie or raise InvalidCredentialsError, "NIE can't be #{nie.inspect}"
      @pin = pin or raise InvalidCredentialsError, "NIE can't be #{nie.inspect}"
    end

    def login
      response = post('session', LOGIN_INFO.merge(userName: @nie.to_s, password: @pin.to_s))
      @user = response.body.fetch('user') { fail InvalidResponseError, response }

      [response.session_id, Time.now + 60]
    end

    def fetch_accounts
      response = get('accounts')
      response.body.fetch('accounts').map(&method(:build_account))
    end

    # @param account [Account]
    # @param start_date [Date]
    # @param end_date [Date]
    # @return Array<Transaction>
    def fetch_transactions_for(account, start_date: Date.today - 1.month, end_date: Date.today)
      build_transaction = method(:build_transaction).curry.call(account)

      response = post('accounts/movements',
                      {
                          moreRequest: false, account: { number: account.number },
                          dateFrom: start_date.strftime('%d-%m-%Y'),
                          dateTo: end_date.strftime('%d-%m-%Y')
                      })

      response.body.fetch('accountMovements').map(&build_transaction)
    end

    def accounts
      @accounts ||= fetch_accounts
    end
    protected

    InvalidMoneyError = Class.new(KeyError)

    def build_money(money)
      Money.new(money.fetch('value') * 100, money.fetch('currency'))
    rescue KeyError
      raise InvalidMoneyError, "#{money} is not valid money format"
    end

    def build_transaction(account, transaction)
      attributes = Utils.map_hash(transaction,
                                  'date' => :effective_date,
                                  'referencor' => :id,
                                  'amount' => :amount,
                                  'conceptDetail' => :description,
                                  'balance' => :balance)

      attributes = Utils.transform_hash(attributes,
                                        effective_date: ->(str){ Date.strptime(str, '%d-%m-%y') },
                                        balance: method(:build_money),
                                        amount: method(:build_money))

      Transaction.new(attributes.merge(account: account))
    end

    def build_account(account)
      attributes = Utils.map_hash(account,
                                  'number' => :id,
                                  'description' => :description,
                                  'iban' => :iban,
                                  'bic' => :bic,
                                  'amount' => { 'currency' => :currency, 'value' => :balance })

      Account.new(attributes.merge(bank: self))
    end

    class HttpResponse < Struct.new(:status, :headers, :body)
      def session_id
        cookies['JSESSIONID']
      end

      def cookies
        headers['set-cookie'].map do |cookie|
          cookie, * = cookie.split(/[;]\s?/)
          cookie.split('=')
        end.to_h
      end

      def body
        JSON.parse(super)
      end
    end

    def post(path, object)
      @http_client.post(path, JSON(object), authentication)
    end

    def get(path)
      @http_client.get(path, {}, authentication)
    end

    def authentication
      { 'Cookie' => "JSESSIONID=#{@session.id};" }
    end

    class Session
      attr_writer :session_id

      def initialize(bank)
        @bank = bank
        @session_id = nil
        @expires_at = nil
        @locked = false
      end

      def session_id
        @session_id = nil if expired?
        @session_id ||= new_session_id
      end

      alias id session_id

      def expired?
        @expires_at && @expires_at >= Time.now
      end

      protected

      def new_session_id
        _locked = @locked
        return if _locked
        @locked = !@locked

        @session_id, @expires_at = @bank.login
        @session_id
      ensure
        @locked = _locked
      end
    end

  end
end
