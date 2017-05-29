module Soapforce
  class Client
    attr_reader :client
    attr_reader :headers
    attr_reader :tag_style
    attr_accessor :logger

    # The partner.wsdl is used by default but can be changed by passing in a new :wsdl option.
    # A client_id can be
    def initialize(options = {})
      @describe_cache = {}
      @describe_layout_cache = {}
			@headers = {}

      @wsdl = options[:wsdl] || File.dirname(__FILE__) + '/../../resources/partner.wsdl.xml'

      # If a client_id is provided then it needs to be included
      # in the header for every request.  This allows ISV Partners
      # to make SOAP calls in Professional/Group Edition organizations.

      client_id = options[:client_id] || Soapforce.configuration.client_id
			
			@headers = options[:headers] if options[:headers]
				
      @headers = { 'tns:CallOptions' => { 'tns:client' => client_id } } if client_id

      @version = options[:version] || Soapforce.configuration.version || 28.0
      @host = options[:host] || 'login.salesforce.com'
      @login_url = options[:login_url] || "https://#{@host}/services/Soap/u/#{@version}"

      @logger = options[:logger] || false
      # Due to SSLv3 POODLE vulnerabilty and disabling of TLSv1, use TLSv1_2
      @ssl_version = options[:ssl_version] || :TLSv1_2

      if options[:tag_style] == :raw
        @tag_style = :raw
        @response_tags = lambda { |key| key }
      else
        @tag_style = :snakecase
        @response_tags = lambda { |key| key.snakecase.to_sym }
      end

      # Override optional Savon attributes
      savon_options = {}
      %w(read_timeout open_timeout proxy raise_errors).each do |prop|
        key = prop.to_sym
        savon_options[key] = options[key] if options.key?(key)
      end

      @client = Savon.client({
        wsdl: @wsdl,
        soap_header: @headers,
        convert_request_keys_to: :none,
        convert_response_tags_to: @response_tags,
        pretty_print_xml: true,
        logger: @logger,
        log: (@logger != false),
        endpoint: @login_url,
        ssl_version: @ssl_version # Sets ssl_version for HTTPI adapter
      }.update(savon_options))
    end

    # Public: Get the names of all wsdl operations.
    # List all available operations from the partner.wsdl
    def operations
      @client.operations
    end

    # Public: Get the names of all wsdl operations.
    #
    # Supports a username/password (with token) combination or session_id/server_url pair.
    #
    # Examples
    #
    #   client.login(username: 'test', password: 'password_and_token')
    #   # => {...}
    #
    #   client.login(session_id: 'abcd1234', server_url: 'https://na1.salesforce.com/')
    #   # => {...}
    #
    # Returns Hash of login response and user info
    def login(options={})
      result = nil
      if options[:username] && options[:password]
        response = @client.call(:login) do |locals|
          locals.message :username => options[:username], :password => options[:password]
        end

        result = response.to_hash[key_name(:login_response)][key_name(:result)]
        @session_id = result[key_name(:session_id)]
        @server_url = result[key_name(:server_url)]

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
        convert_response_tags_to: @response_tags,
        logger: @logger,
        log: (@logger != false),
        endpoint: @server_url,
        ssl_version: @ssl_version # Sets ssl_version for HTTPI adapter
      )

      # If a session_id/server_url were passed in then invoke get_user_info for confirmation.
      # Method missing to call_soap_api
      result = self.get_user_info if options[:session_id]

      result
    end
    alias_method :authenticate, :login


    # Public: Get the names of all sobjects on the org.
    #
    # Examples
    #
    #   # get the names of all sobjects on the org
    #   client.list_sobjects
    #   # => ['Account', 'Lead', ... ]
    #
    # Returns an Array of String names for each SObject.
    def list_sobjects
      response = describe_global # method_missing
      response[key_name(:sobjects)].collect { |sobject| sobject[key_name(:name)] }
    end

    # Public: Get the current organization's Id.
    #
    # Examples
    #
    #   client.org_id
    #   # => '00Dx0000000BV7z'
    #
    # Returns the String organization Id
    def org_id
      object = query('SELECT Id FROM Organization').first
      object.Id if object
    end

    # Public: Returns a detailed describe result for the specified sobject
    #
    # sobject - String name of the sobject.
    #
    # Examples
    #
    #   # get the describe for the Account object
    #   client.describe('Account')
    #   # => { ... }
    #
    #   # get the describe for the Account object
    #   client.describe(['Account', 'Contact'])
    #   # => { ... }
    #
    # Returns the Hash representation of the describe call.
    def describe(sobject_type)
      if sobject_type.is_a?(Array)
        response = call_soap_api(:describe_s_objects, sObjectType: sobject_type)
      else
        # Cache objects to avoid repeat lookups.
        if @describe_cache[sobject_type].nil?
          response = call_soap_api(:describe_s_object, sObjectType: sobject_type)
          @describe_cache[sobject_type] = response
        else
          response = @describe_cache[sobject_type]
        end
      end

      response
    end

    # Public: Returns the layout for the specified object
    #
    # sobject - String name of the sobject.
    #
    # Examples
    #
    #   # get layouts for an sobject type
    #   client.describe_layout('Account')
    #   # => { ... }
    #
    #   # get layouts for an sobject type
    #   client.describe_layout('Account', '012000000000000AAA')
    #   # => { ... }
    #
    # Returns the Hash representation of the describe call.
    def describe_layout(sobject_type, layout_id=nil)
      # Cache objects to avoid repeat lookups.
      @describe_layout_cache[sobject_type] ||={}

      # nil key is for full object.
      if @describe_layout_cache[sobject_type][layout_id].nil?
        response = call_soap_api(:describe_layout, :sObjectType => sobject_type, :recordTypeIds => layout_id)
        @describe_layout_cache[sobject_type][layout_id] = response
      else
        response = @describe_layout_cache[sobject_type][layout_id]
      end

      response
    end

    def query(soql, header={})
      call_soap_api(:query, {:queryString => soql}, header)
    end

    # Includes deleted (isDeleted) or archived (isArchived) records
    def query_all(soql, header={})
      call_soap_api(:query_all, {:queryString => soql}, header)
    end

    def query_more(locator, header={})
      call_soap_api(:query_more, {:queryLocator => locator}, header)
    end

    def search(sosl, header={})
      call_soap_api(:search, {:searchString => sosl}, header)
    end

    # Public: Insert a new record.
    #
    # sobject - String name of the sobject.
    # attrs   - Hash of attributes to set on the new record.
    #
    # Examples
    #
    #   # Add a new account
    #   client.create('Account', Name: 'Foobar Inc.')
    #   # => '0016000000MRatd'
    #
    # Returns the String Id of the newly created sobject.
    # Returns false if something bad happens.
    def create(sobject_type, properties, header={})
      create!(sobject_type, properties, header)
    rescue
      false
    end

    # Public: Insert a new record.
    #
    # sobject - String name of the sobject.
    # attrs   - Hash of attributes to set on the new record.
    #
    # Examples
    #
    #   # Add a new account
    #   client.create('Account', Name: 'Foobar Inc.')
    #   # => '0016000000MRatd'
    #
    # Returns the String Id of the newly created sobject.
    # Raises exceptions if an error is returned from Salesforce.
    def create!(sobject_type, properties, header={})
      call_soap_api(:create, sobjects_hash(sobject_type, properties), header)
    end

    # Public: Update a record.
    #
    # sobject - String name of the sobject.
    # attrs   - Hash of attributes to set on the record.
    #
    # Examples
    #
    #   # Update the Account with Id '0016000000MRatd'
    #   client.update('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp')
    #
    # Returns Hash if the sobject was successfully updated.
    # Returns false if there was an error.
    def update(sobject_type, properties, header={})
      update!(sobject_type, properties, header)
    rescue
      false
    end

    # Public: Update a record.
    #
    # sobject - String name of the sobject.
    # attrs   - Hash of attributes to set on the record.
    #
    # Examples
    #
    #   # Update the Account with Id '0016000000MRatd'
    #   client.update!('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp')
    #
    # Returns Hash if the sobject was successfully updated.
    # Raises an exception if an error is returned from Salesforce
    def update!(sobject_type, properties, header={})
      call_soap_api(:update, sobjects_hash(sobject_type, properties), header)
    end

    # Public: Update or create a record based on an external ID
    #
    # sobject - The name of the sobject to created.
    # field   - The name of the external Id field to match against.
    # attrs   - Hash of attributes for the record.
    #
    # Examples
    #
    #   # Update the record with external ID of 12
    #   client.upsert('Account', 'External__c', External__c: 12, Name: 'Foobar')
    #
    # Returns Hash if the record was found and updated or newly created.
    # Raises an exception if an error is returned from Salesforce.
    def upsert(sobject_type, external_id_field_name, objects, header={})
      upsert!(sobject_type, external_id_field_name, objects, header)
    rescue
      false
    end

    # Public: Update or create a record based on an external ID
    #
    # sobject - The name of the sobject to created.
    # field   - The name of the external Id field to match against.
    # attrs   - Hash of attributes for the record.
    #
    # Examples
    #
    #   # Update the record with external ID of 12
    #   client.upsert!('Account', 'External__c', External__c: 12, Name: 'Foobar')
    #
    # Returns Hash if the record was found and updated or newly created.
    # Raises an exception if an error is returned from Salesforce.
    def upsert!(sobject_type, external_id_field_name, objects, header={})
      message = {externalIDFieldName: external_id_field_name}.merge(sobjects_hash(sobject_type, objects))
      call_soap_api(:upsert, message, header)
    end

    # Public: Delete a record.
    #
    # sobject - String name of the sobject.
    # id      - The Salesforce ID of the record.
    #
    # Examples
    #
    #   # Delete the Account with Id '0016000000MRatd'
    #   client.delete('Account', '0016000000MRatd')
    #
    # Returns true if the sobject was successfully deleted.
    # Returns false if an error is returned from Salesforce.
    def delete(id, header = {})
      delete!(id, header)
    rescue
      false
    end
    alias_method :destroy, :delete

    # Public: Delete a record.
    #
    # sobject - String name of the sobject.
    # id      - The Salesforce ID of the record.
    #
    # Examples
    #
    #   # Delete the Account with Id '0016000000MRatd'
    #   client.delete!('Account', '0016000000MRatd')
    #
    # Returns Hash if the sobject was successfully deleted.
    # Raises an exception if an error is returned from Salesforce.
    def delete!(id, header={})
      ids = id.is_a?(Array) ? id : [id]
      call_soap_api(:delete, {:ids => ids}, header)
    end
    alias_method :destroy!, :delete

    # Public: Convert Lead to Opportunity
    #
    # attrs   - Hash of attributes to set on the record.
    #
    # Example
    #
    #   client.convert_lead(leadId: '00Qi000001bMOtM',
    #     opportunityName: 'Opportunity from Lead',
    #     convertedStatus: 'Closed - Converted')
    #
    # Returns Soapforce::Result
    def convert_lead(attributes, header={})
      leads = attributes.is_a?(Array) ? attributes : [attributes]
      call_soap_api(:convert_lead, {leadConverts: leads}, header)
    end

    # Public: Merges records together
    #
    # sobject       - String name of the sobject
    # master_record - Hash of the master record that other records will be merged into
    # ids           - Array of Salesforce Ids that will be merged into the master record
    #
    # Examples
    #
    #   client.merge('Account', Id: '0016000000MRatd', ['012000000000000AAA'])
    #
    # Returns Hash if the records were merged successfully
    # Raises an exception if an error is returned from Salesforce.
    def merge!(sobject_type, master_record_hash, ids)
      call_soap_api(
        :merge,
        request: {
          masterRecord: master_record_hash.merge(:'@xsi:type' => sobject_type),
          recordToMergeIds: ids
        }
      )
    end
    # Public: Merges records together
    #
    # sobject       - String name of the sobject
    # master_record - Hash of the master record that other records will be merged into
    # ids           - Array of Salesforce Ids that will be merged into the master record
    #
    # Examples
    #
    #   client.merge('Account', Id: '0016000000MRatd', ['012000000000000AAA'])
    #
    # Returns Hash if the records were merged successfully
    # Raises an exception if an error is returned from Salesforce.
    def merge(sobject_type, master_record_hash, ids)
      merge!(sobject_type, master_record_hash, ids)
    rescue
      false
    end

    # Public: Finds a single record and returns all fields.
    #
    # sobject - The String name of the sobject.
    # id      - The id of the record. If field is specified, id should be the id
    #           of the external field.
    # field   - External ID field to use (default: nil).
    #
    # Returns Hash of sobject record.
    def find(sobject, id, field=nil)
      if field.nil? || field.downcase == "id"
        retrieve(sobject, id)
      else
        find_by_field(sobject, id, field)
      end
    end

    # Public: Finds record based on where condition and returns all fields.
    #
    # sobject - The String name of the sobject.
    # where   - String where clause or Hash made up of field => value pairs.
    # select  - Optional array of field names to return.
    #
    # Returns Hash of sobject record.
    def find_where(sobject, where={}, select_fields=[])

      if where.is_a?(String)
        where_clause = where
      elsif where.is_a?(Hash)
        conditions = []
        where.each {|k,v|
          # Wrap strings in single quotes.
          v = v.is_a?(String) ? "'#{v}'" : v
          v = 'NULL' if v.nil?

          # Handle IN clauses when value is an array.
          if v.is_a?(Array)
            # Wrap single quotes around String values.
            values = v.map {|s| s.is_a?(String) ? "'#{s}'" : s}.join(", ")
            conditions << "#{k} IN (#{values})"
          else
            conditions << "#{k} = #{v}"
          end
        }
        where_clause = conditions.join(" AND ")

      end

      # Get list of fields if none were specified.
      if select_fields.empty?
        field_names = field_list(sobject)
      else
        field_names = select_fields
      end

      soql = "SELECT #{field_names.join(", ")} FROM #{sobject} WHERE #{where_clause}"
      query(soql)
    end

    # Public: Finds a single record and returns all fields.
    #
    # sobject - The String name of the sobject.
    # id      - The id of the record. If field is specified, id should be the id
    #           of the external field.
    # field   - External ID field to use.
    #
    # Returns Hash of sobject record.
    def find_by_field(sobject, id, field_name)
      field_details = field_details(sobject, field_name)
      field_names = field_list(sobject).join(", ")

      if ["int", "currency", "double", "boolean", "percent"].include?(field_details[key_name(:type)])
        search_value = id
      else
        # default to quoted value
        search_value = "'#{id}'"
      end

      soql = "SELECT #{field_names} FROM #{sobject} WHERE #{field_name} = #{search_value}"
      result = query(soql)
      # Return first query result.
      result ? result.first : nil
    end

    # Public: Finds a single record and returns all fields.
    #
    # sobject - The String name of the sobject.
    # id      - The id of the record. If field is specified, id should be the id
    #           of the external field.
    #
    # Returns Hash of sobject record.
    def retrieve(sobject, id)
      ids = id.is_a?(Array) ? id : [id]
      call_soap_api(:retrieve, {fieldList: field_list(sobject).join(","), sObjectType: sobject, ids: ids})
    end

    # ProcessSubmitRequest
    #   request = {objectId: .., comments: ..., nextApproverIds: [...] }
    # ProcessWorkItemRequest
    #   request = {action: .., workitemId: .., comments: ..., nextApproverIds: [...] }
    #
    # Returns Hash of process status.
    def process(request)

      # approverIds is optional if Approval is configured to auto-assign the approver.
      # Ensure approver ids is an array.
      approver_ids = request[:approverIds] || []
      approver_ids = approver_ids.is_a?(Array) ? approver_ids : [approver_ids]

      request_type = request[:workitemId] ? "ProcessWorkitemRequest" : "ProcessSubmitRequest"

      # Unfortunately had to use XML since I could not figure out
      # how to get Savon2 to include the proper xsi:type attribute
      # on the actions element.
      xml = "<tns:actions xsi:type=\"tns:#{request_type}\">"
      # Account for Submit or Workitem Request
      if request[:objectId]
        xml << "<tns:objectId>#{request[:objectId]}</tns:objectId>"
      else
        xml << "<tns:action>#{request[:action]}</tns:action>"
        xml << "<tns:workitemId>#{request[:workitemId]}</tns:workitemId>"
      end

      xml << "<tns:comments>#{request[:comments]}</tns:comments>"
      approver_ids.each do |aid|
        xml <<  "<tns:nextApproverIds>#{aid}</tns:nextApproverIds>"
      end
      xml << "</tns:actions>"

      call_soap_api(:process, xml)
    end

    # Helpers

    def field_list(sobject)
      description = describe(sobject)
      name_key = key_name(:name)
      description[key_name(:fields)].collect {|c| c[name_key] }
    end

    def field_details(sobject, field_name)
      description = describe(sobject)
      fields = description[key_name(:fields)]
      name_key = key_name(:name)
      fields.find {|f| field_name.downcase == f[name_key].downcase }
    end

    # Supports the following No Argument methods:
    #   describe_global
    #   describe_softphone_layout
    #   describe_tabs
    #   get_server_timestamp
    #   get_user_info
    #   logout
    def method_missing(method, *args)
      call_soap_api(method, *args)
    end

    def key_name(key)
      if @tag_style == :snakecase
        key.is_a?(Symbol) ? key : key.snakecase.to_sym
      else
        if key.to_s.include?('_')
          camel_key = key.to_s.gsub(/\_(\w{1})/) {|cap| cap[1].upcase }
        else
          key.to_s
        end
      end
    end

		def header_hash(header)
			xml_header = header.map do |k,v|
				header_fields = v.map {|k,v| ["tns:#{k}",v]}.to_h
				header_name = "tns:#{k}"
				[header_name, header_fields]
			end
			xml_header.to_h
		end
				 
    def call_soap_api(method, message_hash={}, header={})
			
      response = @client.call(method.to_sym) do |locals|
        locals.message message_hash
				locals.soap_header header_hash(header) unless header.empty?
      end

      # Convert SOAP XML to Hash
      response = response.to_hash

      # Get Response Body
      key = key_name("#{method}Response")
      response_body = response[key]

      # Grab result section if exists.
      result = response_body ? response_body[key_name(:result)] : nil

      # Raise error when response contains errors
      if result.is_a?(Hash)
        xsi_type = result[key_name(:"@xsi:type")].to_s

        if result[key_name(:success)] == false && result[key_name(:errors)]
          errors = result[key_name(:errors)]
          raise Savon::Error.new("#{errors[key_name(:status_code)]}: #{errors[key_name(:message)]}")
        elsif xsi_type.include?("sObject")
          result = SObject.new(result)
        elsif xsi_type.include?("QueryResult")
          result = QueryResult.new(result)
        else
          result = Result.new(result)
        end
      end

      result
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
