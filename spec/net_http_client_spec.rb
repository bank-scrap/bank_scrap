
RSpec.describe  do

  let(:net_http) { BankScrap::NetHttpClient.new('http://localhost') }

  it 'should send headers' do
    stub_request(:post, 'http://localhost/path').
        with(body: 'body',
             headers: {'Accept' => 'some-accept', 'Content-Type' => 'content'}).
        to_return(status: 200, body: '', headers: {})
    net_http.post('path', 'body', 'Accept' => 'some-accept', 'Content-Type' => 'content')
  end

  context '#response' do
    before do
      stub_request(:any, %r{http://localhost/}).
          to_return(status: 201, body: 'body', headers: {'Content-Type' => 'content'})
    end

    let(:response) { net_http.get('path') }

    it do
      expect(response.body).to eq('body')
    end

    it do
      expect(response.headers).to eq('content-type' => ['content'])
    end
  end

end
