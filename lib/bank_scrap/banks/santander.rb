require 'open-uri'
require 'nokogiri'
require_relative '../accounts/santander_account'

module BankScrap
  class Santander < Bank
    HOST              = 'www.bsan.mobi'
    BASE_ENDPOINT     = 'https://www.bsan.mobi'
    LOGIN_ENDPOINT    = '/SANMOV_IPAD_NSeg_ENS/ws/SANMOVNS_Def_Listener'
    PRODUCTS_ENDPOINT = '/SCH_BAMOBI_WS_ENS/ws/BAMOBI_WS_Def_Listener'
    ACCOUNT_ENDPOINT  = '/SCH_BAMOBI_WS_ENS/ws/BAMOBI_WS_Def_Listener'
    USER_AGENT        = 'ksoap2-android/2.6.0+'

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
    # Returns an array of BankScrap::Banks::Santander::Account objects
    def fetch_accounts
      log 'fetch_accounts'

      headers = { "SOAPAction" => "http://www.isban.es/webservices/BAMOBI/Posglobal/F_bamobi_posicionglobal_lip/internet/BAMOBIPGL/v1/obtenerPosGlobal_LIP" }

      response = with_headers(headers) { post(BASE_ENDPOINT + PRODUCTS_ENDPOINT, fields: xml_products) }

      document = parse_context(response)

      document.xpath('//cuentas/cuenta').map { |data| build_account(data) }
    end

    # Fetch transactions for the given account.
    # By default it fetches transactions for the last month.
    #
    # Account should be a BankScrap::Banks::Santander::Account object
    # Returns an array of BankScrap::Transaction objects
    def fetch_transactions_for(account, start_date: Date.today - 1.month, end_date: Date.today)

      headers = { "SOAPAction" => "http://www.isban.es/webservices/BAMOBI/Cuentas/F_bamobi_cuentas_lip/internet/BAMOBICTA/v1/listaMovCuentasFechas_LIP" }
      transactions = []
      end_page = false
      repo = nil
      importe_cta = nil

      # Loop over pagination
      until end_page
        response = with_headers(headers) { post(BASE_ENDPOINT + ACCOUNT_ENDPOINT, fields: xml_account(account, start_date, end_date, repo, importe_cta)) }
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
      add_headers(
        'Content-Type'    => 'text/xml; charset=utf-8',
        'User-Agent'      => USER_AGENT,
        'Host'            => HOST,
        'Connection'      => 'Keep-Alive',
        'Accept-Encoding' => 'gzip'
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
      headers = { "SOAPAction" => "http://www.isban.es/webservices/TECHNICAL_FACADES/Security/F_facseg_security/internet/loginServicesNSegSAN/v1/authenticateCredential" }
      response = with_headers(headers) { post(BASE_ENDPOINT + LOGIN_ENDPOINT, fields: xml_login) }
      parse_context(response)
    end

    def parse_context(xml)
      document = Nokogiri::XML(xml)
      @token_credential = value_at_xpath(document, '//tokenCredential', @token_credential)
      @user_data = document.at_xpath('//methodResult/datosUsuario') || @user_data
      document
    end

    def xml_security_header
      <<-security
        <v:Header>
          <n0:Security v:actor="http://www.isban.es/soap/actor/wssecurityB64" v:mustUnderstand="1" n1:role="wsssecurity" xmlns:n0="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:n1="http://www.w3.org/2003/05/soap-envelope">
            <n0:BinarySecurityToken n2:Id="SSOToken" ValueType="esquema" EncodingType="hwsse:Base64Binary" xmlns:n2="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">#{@token_credential}</n0:BinarySecurityToken>
          </n0:Security>
        </v:Header>
      security
    end

    def xml_datos_cabecera
      <<-datos
        <datosCabecera i:type=":datosCabecera">
          <version i:type="d:string">4.7.1</version>
          <terminalID i:type="d:string">Android</terminalID>
          <idioma i:type="d:string">es-ES</idioma>
        </datosCabecera>
      datos
    end

    def xml_products
      <<-products
        <v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:d="http://www.w3.org/2001/XMLSchema" xmlns:c="http://schemas.xmlsoap.org/soap/encoding/" xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
          #{xml_security_header}
          <v:Body>
            <n3:obtenerPosGlobal_LIP facade="BAMOBIPGL" xmlns:n3="http://www.isban.es/webservices/BAMOBI/Posglobal/F_bamobi_posicionglobal_lip/internet/BAMOBIPGL/v1/">
              <entrada i:type=":entrada">#{xml_datos_cabecera}</entrada>
            </n3:obtenerPosGlobal_LIP>
          </v:Body>
        </v:Envelope>
      products
    end

    def xml_login
      <<-login
      <v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:d="http://www.w3.org/2001/XMLSchema" xmlns:c="http://schemas.xmlsoap.org/soap/encoding/" xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
        <v:Header />
        <v:Body>
          <n0:authenticateCredential facade="loginServicesNSegSAN" xmlns:n0="http://www.isban.es/webservices/TECHNICAL_FACADES/Security/F_facseg_security/internet/loginServicesNSegSAN/v1">
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
      <<-date
      <dia i:type="d:int">#{date.day}</dia>
      <mes i:type="d:int">#{date.month}</mes>
      <anyo i:type="d:int">#{date.year}</anyo>
      date
    end

    def xml_account(account, from_date, to_date, repo, importe_cta)
      is_pagination = repo ? 'S' : 'N'
      xml_from_date = xml_date(from_date)
      xml_to_date = xml_date(to_date)
      <<-account
        <v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:d="http://www.w3.org/2001/XMLSchema" xmlns:c="http://schemas.xmlsoap.org/soap/encoding/" xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
          #{xml_security_header}
          <v:Body>
            <n3:listaMovCuentasFechas_LIP facade="BAMOBICTA" xmlns:n3="http://www.isban.es/webservices/BAMOBI/Cuentas/F_bamobi_cuentas_lip/internet/BAMOBICTA/v1/">
              <entrada i:type=":entrada">
                #{xml_datos_cabecera}
                <datosConexion i:type=":datosConexion">#{@user_data.children.to_s}</datosConexion>
                <contratoID i:type=":contratoID">#{account.contract_id.to_s}</contratoID>
                #{importe_cta}
                <fechaDesde i:type=":fechaDesde">#{xml_from_date}</fechaDesde>
                <fechaHasta i:type=":fechaHasta">#{xml_to_date}</fechaHasta>
                <esUnaPaginacion i:type="d:string">#{is_pagination}</esUnaPaginacion>
                #{repo}
              </entrada>
            </n3:listaMovCuentasFechas_LIP>
          </v:Body>
        </v:Envelope>
      account
    end

    # Build an BankScrap::SantanderAccount object from API data
    def build_account(data)
      SantanderAccount.new(
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
      BankScrap::Transaction.new(
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
