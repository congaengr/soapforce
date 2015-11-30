module FixtureHelpers
  module InstanceMethods

    def stub_api_request(endpoint, options={})
      options = {
        :method => :post,
        :status => 200,
      }.merge(options)

      instance_url = options[:instance_url] || "https://login.salesforce.com/services/Soap/u/28.0"
      stub = stub_request(options[:method], instance_url)
      stub = stub.with(:body => soap_envelope(options[:headers], options[:with_body]))
      stub = stub.to_return(:status => options[:status], :body => fixture(options[:fixture]), :headers => { 'Content-Type' => 'text/xml;charset=UTF-8'}) if options[:fixture]
      stub
    end

    def stub_login_request(options={})
      server_url = options[:server_url] || "https://login.salesforce.com/services/Soap/u/28.0"
      stub = stub_request(:post, server_url)
      stub = stub.with(:body => soap_envelope(options[:headers], options[:with_body]))
      stub
    end

    def fixture(f)
      File.read(File.expand_path("../../fixtures/#{f}.xml", __FILE__))
    end

    def soap_envelope(headers, body)
envelope = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xmlns:tns="urn:partner.soap.sforce.com"
 xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
 xmlns:ins0="urn:sobject.partner.soap.sforce.com"
 xmlns:ins1="urn:fault.partner.soap.sforce.com">
#{soap_headers(headers)}
<env:Body>#{body}</env:Body>
</env:Envelope>
EOF
      envelope.gsub("\n", "")
    end

    def soap_headers(params={})
      return '' if params.nil? || params.empty?
      headers = "<env:Header>"
      headers << "<tns:CallOptions><tns:client>#{params[:client_id]}</tns:client></tns:CallOptions>" if params[:client_id]
      headers << "<tns:SessionHeader><tns:sessionId>#{params[:session_id]}</tns:sessionId></tns:SessionHeader>" if params[:session_id]
      headers << "</env:Header>"
    end

  end

end

RSpec.configure do |config|
  config.include FixtureHelpers::InstanceMethods
end
