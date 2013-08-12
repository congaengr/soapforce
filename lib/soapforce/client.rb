module Soapforce
  class Client

    attr_reader :client
    attr_reader :headers

    # The partner.wsdl is used by default but can be changed by passing in a new :wsdl option.
    # A client_id can be 
    def initialize(options={})
      @headers = {}
      @wsdl = options[:wsdl] || File.dirname(__FILE__) + "/../../resources/partner.wsdl.xml"

      # If a client_id is provided then it needs to be included 
      # in the header for every request.  This allows ISV Partners
      # to make SOAP calls in Professional/Group Edition organizations.

      client_id = options[:client_id] || Soapforce.configuration.client_id
      @headers = {"tns:CallOptions" => {"tns:client" => client_id}} if client_id

      @client = Savon.client(
        wsdl: @wsdl,
        soap_header: @headers,
        convert_request_keys_to: :none,
        pretty_print_xml: true
        )
    end

    # List all available operations from the partner.wsdl
    def operations
      @client.operations
    end

    # Supports a username/password (with token) combination or session_id/server_url pair.
    def login(options={})
      result = nil
      if options[:username] && options[:password]
        response = @client.call(:login) do |locals|
          locals.message :username => options[:username], :password => options[:password]
        end

        result = response.to_hash[:login_response][:result]
        returned_endpoint = result[:server_url]

        @session_id = result[:session_id]
        @server_url = result[:server_url]
      elsif options[:session_id] && options[:server_url]
        @session_id = options[:session_id]
        @server_url = options[:server_url]
      else
        raise ArgumentError.new("Must provide username/password or session_id/server_url.")
      end

      @headers = @headers.merge({"tns:SessionHeader" => {"tns:sessionId" => @session_id}})

      @client = Savon.client(
        wsdl: @wsdl,
        soap_header: @headers,
        convert_request_keys_to: :none,
        endpoint: @server_url
      )

      # If a session_id/server_url were passed in then invoke get_user_info for confirmation.
      # Method missing to call_soap_api
      result = self.get_user_info if options[:session_id]

      result
    end

    def describe(sobject_type)
      if sobject_type.is_a?(Array)
        list = sobject_type.map do |type|
          {:sObjectType => type} 
        end
        call_soap_api(:describe_s_objects, :sObjectType => sobject_type)
      else
        call_soap_api(:describe_s_object, :sObjectType => sobject_type)
      end
    end

    def query(soql)
      result = call_soap_api(:query, {:queryString => soql})
      QueryResult.new(result)
    end

    # Includes deleted (isDeleted) or archived (isArchived) records
    def query_all(soql)
      result = call_soap_api(:query_all, {:queryString => soql})
      QueryResult.new(result)
    end

    def query_more(locator)
      result = call_soap_api(:query_more, {:queryLocator => locator})
      QueryResult.new(result)
    end

    def search(sosl)
      call_soap_api(:search, {:searchString => sosl})
    end

    def create(sobject_type, properties)
      call_soap_api(:create, sobjects_hash(sobject_type, properties))
    end

    def update(sobject_type, properties)
      call_soap_api(:update, sobjects_hash(sobject_type, properties))
    end

    def upsert(external_id_field_name, sobject_type, objects)
      message = {externalIDFieldName: external_id_field_name}.merge(sobjects_hash(sobject_type, objects))
      call_soap_api(:upsert, message)
    end

    def delete(id)
      ids = id.is_a?(Array) ? id : [id]
      call_soap_api(:delete, {:ids => ids})
    end

    # Supports the following No Argument methods:
    #   get_user_info
    #   describe_global
    #   describe_softphone_layout
    #   describe_tabs
    #   logout
    #   get_server_timestamp
    def method_missing(method, *args)
      call_soap_api(method, *args)
    end

    def call_soap_api(method, message_hash={})

      response = @client.call(method.to_sym) do |locals|
        locals.message message_hash
      end
      response = response.to_hash
      result = response["#{method}_response".to_sym][:result]
      return result
    end

    def sobjects_hash(sobject_type, sobject_hash)

      if sobject_hash.is_a?(Array)
        sobjects = sobject_hash
      else
        sobjects = [sobject_hash]
      end

      sobjects.map! do |obj|
        {"ins0:type" => sobject_type}.merge(obj)
      end

      {sObjects: sobjects}
    end
  end
end