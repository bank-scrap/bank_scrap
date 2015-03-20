require 'open-uri'
require 'nokogiri'
require_relative 'account.rb'

module BankScrap
  module Banks::Openbank
    class Bank < BankScrap::Bank
      BASE_ENDPOINT    = 'https://www.openbank.mobi'
      LOGIN_ENDPOINT   = '/OPBMOV_IPAD_NSeg_ENS/ws/QUIZ_Def_Listener'
      PRODUCTS_ENDPOINT = '/OPB_BAMOBI_WS_ENS/ws/BAMOBI_WS_Def_Listener'
      ACCOUNT_ENDPOINT = '/OPB_BAMOBI_WS_ENS/ws/BAMOBI_WS_Def_Listener'
      USER_AGENT       = 'Dalvik/1.6.0 (Linux; U; Android 4.4.4; XT1032 Build/KXB21.14-L1.40)'

      def initialize(user, password, log: false, debug: false, extra_args: nil)
        @user = format_user(user)
        @password = password
        @log = log
        @debug = debug
        @public_ip = public_ip

        initialize_connection

        default_headers

        login

        super
      end

      # Fetch all the accounts for the given user
      # Returns an array of BankScrap::Banks::Openbank::Account objects
      def fetch_accounts
        log 'fetch_accounts'

        response = post(BASE_ENDPOINT + PRODUCTS_ENDPOINT, xml_products)

        document = parse_context(response)

        document.xpath('//cuentas/cuenta').map { |data| build_account(data) }
      end

      # Fetch transactions for the given account.
      # By default it fetches transactions for the last month,
      #
      # Account should be a BankScrap::Banks::Openbank::Account object
      # Returns an array of BankScrap::Transaction objects
      def fetch_transactions_for(account, start_date: Date.today - 1.month, end_date: Date.today)

        transactions = []
        end_page = false
        repo = nil
        importe_cta = nil

        # Loop over pagination
        until end_page
          response = post(BASE_ENDPOINT + ACCOUNT_ENDPOINT, xml_account(account, start_date, end_date, repo, importe_cta))
          document = parse_context(response)

          transactions += document.xpath('//listadoMovimientos/movimiento').map { |data| build_transaction(data, account) }

          repo = document.at_xpath('//methodResult/repo')
          importe_cta = document.at_xpath('//methodResult/importeCta')
          end_page = !(value_at_xpath(document, '//methodResult/finLista') == 'N')
        end

        transactions
      end

      private

      def default_headers
        set_headers(
          'Content-Type'     => 'text/xml; charset=utf-8',
          'User-Agent'       => USER_AGENT,
          'Host'             => 'www.openbank.mobi',
          'Connection'       => 'Keep-Alive',
          'Accept-Encoding'  => 'gzip'
        )
      end

      def public_ip
        log 'getting public ip'
        ip = open("http://api.ipify.org").read
        log "public ip: [#{ip}]"
        ip
      end

      def format_user(user)
        user.upcase
      end

      def login
        log 'login'
        response = post(BASE_ENDPOINT + LOGIN_ENDPOINT, xml_login)
        parse_context(response)
      end

      def parse_context(xml)
        document = Nokogiri::XML(xml)
        @cookie_credential = value_at_xpath(document, '//cookieCredential', @cookie_credential)
        @token_credential = value_at_xpath(document, '//tokenCredential', @token_credential)
        @user_data = document.at_xpath('//methodResult/datosUsuario') || @user_data
        document
      end

      def xml_security_header
        <<-security
        <soapenv:Header>
          <wsse:Security SOAP-ENV:actor="http://www.isban.es/soap/actor/wssecurityB64" SOAP-ENV:mustUnderstand="1" S12:role="wsssecurity" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:S12="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
            <wsse:BinarySecurityToken xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="SSOToken" ValueType="esquema" EncodingType="hwsse:Base64Binary">#{@token_credential}</wsse:BinarySecurityToken>
          </wsse:Security>
        </soapenv:Header>
        security
      end

      def xml_datos_cabecera
        <<-datos
        <datosCabecera>
          <version>3.0.4</version>
          <terminalID>Android</terminalID>
          <idioma>es-ES</idioma>
        </datosCabecera>
        datos
      end

      def xml_products
        <<-products
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://www.isban.es/webservices/BAMOBI/Posglobal/F_bamobi_posicionglobal_lip/internet/BAMOBIPGL/v1">
        #{xml_security_header}
        <soapenv:Body>
          <v1:obtenerPosGlobal_LIP facade="BAMOBIPGL">
            <entrada>#{xml_datos_cabecera}</entrada>
          </v1:obtenerPosGlobal_LIP>
        </soapenv:Body>
      </soapenv:Envelope>
        products
      end

      def xml_login
        <<-login
      <v:Envelope xmlns:v="http://schemas.xmlsoap.org/soap/envelope/"  xmlns:c="http://schemas.xmlsoap.org/soap/encoding/"  xmlns:d="http://www.w3.org/2001/XMLSchema"  xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <v:Header />
        <v:Body>
          <n0:authenticateCredential xmlns:n0="http://www.isban.es/webservices/TECHNICAL_FACADES/Security/F_facseg_security/internet/loginServicesNSegWS/v1" facade="loginServicesNSegWS">
            <CB_AuthenticationData i:type=":CB_AuthenticationData">
              <documento i:type=":documento">
                <CODIGO_DOCUM_PERSONA_CORP i:type="d:string">#{@user}</CODIGO_DOCUM_PERSONA_CORP>
                <TIPO_DOCUM_PERSONA_CORP i:type="d:string">N</TIPO_DOCUM_PERSONA_CORP>
              </documento>
              <password i:type="d:string">#{@password}</password>
            </CB_AuthenticationData>
            <userAddress i:type="d:string">#{@public_ip}</userAddress>
          </n0:authenticateCredential>
        </v:Body>
      </v:Envelope>
        login
      end

      def xml_date(date)
        "<dia>#{date.day}</dia><mes>#{date.month}</mes><anyo>#{date.year}</anyo>"
      end

      def xml_account(account, from_date, to_date, repo, importe_cta)
        is_pagination = repo ? 'S' : 'N'
        xml_from_date = xml_date(from_date)
        xml_to_date = xml_date(to_date)
        <<-account
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"   xmlns:v1="http://www.isban.es/webservices/BAMOBI/Cuentas/F_bamobi_cuentas_lip/internet/BAMOBICTA/v1">
        #{xml_security_header}
        <soapenv:Body>
          <v1:listaMovCuentasFechas_LIP facade="BAMOBICTA">
            <entrada>
        #{xml_datos_cabecera}
              <datosConexion>#{@user_data.children.to_s}</datosConexion>
              <contratoID>#{account.contract_id.to_s}</contratoID>
              <fechaDesde>#{xml_from_date}</fechaDesde>
              <fechaHasta>#{xml_to_date}</fechaHasta>
        #{importe_cta}
              <esUnaPaginacion>#{is_pagination}</esUnaPaginacion>
        #{repo}
            </entrada>
          </v1:listaMovCuentasFechas_LIP>
        </soapenv:Body>
      </soapenv:Envelope>
        account
      end

      # Build an BankScrap::Banks::Openbank::Account object from API data
      def build_account(data)
        Openbank::Account.new(
          bank: self,
          id: value_at_xpath(data, 'comunes/contratoID/NUMERO_DE_CONTRATO'),
          name: value_at_xpath(data, 'comunes/descContrato'),
          available_balance: value_at_xpath(data, 'importeDispAut/IMPORTE'),
          balance: value_at_xpath(data, 'impSaldoActual/IMPORTE'),
          currency: value_at_xpath(data, 'impSaldoActual/DIVISA'),
          iban: value_at_xpath(data, 'IBAN').tr(' ', ''),
          description: value_at_xpath(data, 'comunes/alias') || value_at_xpath(data, 'comunes/descContrato'),
          contract_id: data.at_xpath('contratoIDViejo').children.to_s
        )
      end

      # Build a transaction object from API data
      def build_transaction(data, account)
        currency = value_at_xpath(data, 'importe/DIVISA')
        balance = money(value_at_xpath(data, 'importeSaldo/IMPORTE'), value_at_xpath(data, 'importeSaldo/DIVISA'))
        Transaction.new(
          account: account,
          id: value_at_xpath(data, 'numeroMovimiento'),
          amount: money(value_at_xpath(data, 'importe/IMPORTE'), currency),
          description: value_at_xpath(data, 'descripcion'),
          effective_date: Date.strptime(value_at_xpath(data, 'fechaValor'), "%Y-%m-%d"),
          # TODO Falta fecha operacion
          currency: currency,
          balance: balance
        )
      end

      def value_at_xpath(node, xpath, default = '')
        value = node.at_xpath(xpath)
        value ? value.content.strip : default
      end

      def money(data, currency)
        Money.new(data.gsub('.', ''), currency)
      end
    end
  end
end
