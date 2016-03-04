require 'spec_helper'

describe Soapforce::Client do
  let(:endpoint) { 'https://na15.salesforce.com' }
  let(:subject) { Soapforce::Client.new(tag_style: :snakecase) }

  describe "#operations" do
    it "should return list of operations from the wsdl" do
      expect(subject.operations).to be_an(Array)
      expect(subject.operations).to include(:login, :logout, :query, :create)
    end
  end

  describe "#login" do
    it "authenticates with username and password_and_token" do

      body = "<tns:login><tns:username>testing</tns:username><tns:password>password_and_token</tns:password></tns:login>"
      stub = stub_login_request({with_body: body})
      stub.to_return(:status => 200, :body => fixture("login_response")) #, :headers => {})

      subject.login(username: 'testing', password: 'password_and_token')
    end

    it "authenticates with session_id and instance_url" do

      body = "<tns:getUserInfo></tns:getUserInfo>"
      stub = stub_login_request({
        server_url: 'https://na15.salesforce.com',
        headers: {session_id: 'abcde12345'},
        with_body: body}
        )
      stub.to_return(:status => 200, :body => fixture("get_user_info_response"))

      user_info = subject.login(session_id: 'abcde12345', server_url: 'https://na15.salesforce.com')

      expect(user_info[:user_email]).to eq "johndoe@email.com"
      expect(user_info[:user_full_name]).to eq "John Doe"
    end

    it "should raise arugment error when no parameters are passed" do
      expect { subject.login(session_id: 'something') }.to raise_error(ArgumentError)
    end
  end

  describe "list_sobjects" do
    it "should return array of object names" do

      body = "<tns:describeGlobal></tns:describeGlobal>"
      stub_api_request(endpoint, {with_body: body, fixture: 'describe_global_response'})

      expect(subject.list_sobjects).to eq ['Account', 'AccountContactRole']
    end
  end

  describe "org_id" do
    it "should return organization id" do

      body = "<tns:query><tns:queryString>SELECT Id FROM Organization</tns:queryString></tns:query>"
      stub_api_request(endpoint, {with_body: body, fixture: 'org_id_response'})

      expect(subject.org_id).to eq "00DA0000000YpZ4MAK"
    end
  end

  describe "#descibeSObject" do

    it "supports single sobject name" do

      body = "<tns:describeSObject><tns:sObjectType>Opportunity</tns:sObjectType></tns:describeSObject>"
      stub_api_request(endpoint, {with_body: body, fixture: 'describe_s_object_response'})

      subject.describe("Opportunity")

      # Hit cache.
      subject.describe("Opportunity")
    end

    it "supports array of sobject names" do

      body = "<tns:describeSObjects><tns:sObjectType>Account</tns:sObjectType><tns:sObjectType>Opportunity</tns:sObjectType></tns:describeSObjects>"
      stub_api_request(endpoint, {with_body: body, fixture: 'describe_s_objects_response'})

      subject.describe(["Account", "Opportunity"])
    end
  end

  describe "#descibeLayout" do

    it "gets layouts for an sobject type" do

      body = %Q{<tns:describeLayout><tns:sObjectType>Account</tns:sObjectType><tns:recordTypeIds xsi:nil="true"/></tns:describeLayout>}
      stub_api_request(endpoint, {with_body: body, fixture: 'describe_layout_response'})

      subject.describe_layout("Account")

      # Hit cache.
      subject.describe_layout("Account")
    end

    it "get the details for a specific layout" do

      body = %Q{<tns:describeLayout><tns:sObjectType>Account</tns:sObjectType><tns:recordTypeIds>012000000000000AAA</tns:recordTypeIds></tns:describeLayout>}
      stub_api_request(endpoint, {with_body: body, fixture: 'describe_layout_response'})

      subject.describe_layout('Account', '012000000000000AAA')
    end
  end

  describe "#retrieve" do

    it "should retrieve object by id" do
      fields = fields_hash

      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).with("Opportunity").and_return(fields)

      body = "<tns:retrieve><tns:fieldList>Id,Name,Description,StageName</tns:fieldList><tns:sObjectType>Opportunity</tns:sObjectType><tns:ids>006A000000LbkT5IAJ</tns:ids></tns:retrieve>"
      stub_api_request(endpoint, {with_body: body, fixture: 'retrieve_response'})

      sobject = subject.retrieve("Opportunity", "006A000000LbkT5IAJ")

      expect(sobject).to be_instance_of(Soapforce::SObject)
      expect(sobject.type).to eq "Opportunity"
      expect(sobject.Id).to eq "006A000000LbkT5IAJ"
      expect(sobject.Name).to eq "SOAPForce Opportunity"
      expect(sobject.Description).to be_nil
      expect(sobject.StageName).to eq "Prospecting"
    end
  end

  describe "#find" do
    it "should retrieve object by id" do
      fields = fields_hash

      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).with("Opportunity").and_return(fields)

      body = "<tns:retrieve><tns:fieldList>Id,Name,Description,StageName</tns:fieldList><tns:sObjectType>Opportunity</tns:sObjectType><tns:ids>006A000000LbkT5IAJ</tns:ids></tns:retrieve>"
      stub_api_request(endpoint, {with_body: body, fixture: 'retrieve_response'})

      sobject = subject.find("Opportunity", "006A000000LbkT5IAJ")

      expect(sobject).to be_instance_of(Soapforce::SObject)
      expect(sobject.type).to eq "Opportunity"
      expect(sobject.Id).to eq "006A000000LbkT5IAJ"
      expect(sobject.Name).to eq "SOAPForce Opportunity"
      expect(sobject.Description).to be_nil
      expect(sobject.StageName).to eq "Prospecting"
    end

  end

  describe "#find_by_field" do

    it "should retrieve object by string field" do
      fields = fields_hash

      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).exactly(2).with("Opportunity").and_return(fields)

      body = "<tns:query><tns:queryString>SELECT Id, Name, Description, StageName FROM Opportunity WHERE StageName = &#39;Prospecting&#39;</tns:queryString></tns:query>"
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      subject.find_by_field("Opportunity", "Prospecting", "StageName")
    end

    it "should retrieve object by number field" do
      if subject.tag_style == :raw
        fields = {"fields" => [{"name" => "Id"},{"name" => "Name"},{"name" => "Description"},{"name" => "Amount", "type" => "double"}]}
      else
        fields = {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "Amount", :type => "double"}]}
      end

      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).exactly(2).with("Opportunity").and_return(fields)

      body = "<tns:query><tns:queryString>SELECT Id, Name, Description, Amount FROM Opportunity WHERE Amount = 0.0</tns:queryString></tns:query>"
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      subject.find_by_field("Opportunity", 0.0, "Amount")
    end

  end

  describe "#find_where" do

    let(:fields) { fields_hash }
    let(:body) { "<tns:query><tns:queryString>SELECT Id, Name, Description, StageName FROM Opportunity WHERE Id = &#39;006A000000LbkT5IAJ&#39; AND Amount = 0.0</tns:queryString></tns:query>" }

    after(:each) do
      expect(@result).to be_instance_of(Soapforce::QueryResult)
      expect(@result.size).to eq 2
      expect(@result.first.Name).to eq "Opportunity 1"
      expect(@result.last.Name).to eq "Opportunity 2"
    end

    it "should retrieve records from hash conditions" do
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})
      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).with("Opportunity").and_return(fields)

      @result = subject.find_where("Opportunity", {Id: "006A000000LbkT5IAJ", Amount: 0.0})
    end

    it "should retrieve records from hash condition using IN clause" do
      body = "<tns:query><tns:queryString>SELECT Id, Name, Description, StageName FROM Opportunity WHERE Id IN (&#39;006A000000LbkT5IAJ&#39;, &#39;006A000000AbkTcIAQ&#39;)</tns:queryString></tns:query>"
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).with("Opportunity").and_return(fields)

      @result = subject.find_where("Opportunity", {Id: ["006A000000LbkT5IAJ", "006A000000AbkTcIAQ"]})
    end

    it "should retrieve records from string condition" do
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})
      # retrieve calls describe to get the list of available fields.
      expect(subject).to receive(:describe).with("Opportunity").and_return(fields)

      @result = subject.find_where("Opportunity", "Id = '006A000000LbkT5IAJ' AND Amount = 0.0")
    end

    it "should retrieve records from string condition and specify fields" do
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})
      expect(subject).to_not receive(:describe)

      @result = subject.find_where("Opportunity", "Id = '006A000000LbkT5IAJ' AND Amount = 0.0", ["Id", "Name", "Description", "StageName"])
    end

  end

  describe "query methods" do

    after(:each) do
      expect(@result).to be_instance_of(Soapforce::QueryResult)
      expect(@result.size).to eq 2
      expect(@result.first.Name).to eq "Opportunity 1"
      expect(@result.last.Name).to eq "Opportunity 2"
    end

    it "#query" do
      soql = "SELECT Id, Name, StageName FROM Opportunity"
      body = "<tns:query><tns:queryString>#{soql}</tns:queryString></tns:query>"
      stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      @result = subject.query(soql)
    end

    it "#query_all" do
      soql = "SELECT Id, Name, StageName FROM Opportunity"
      body = "<tns:queryAll><tns:queryString>#{soql}</tns:queryString></tns:queryAll>"
      stub_api_request(endpoint, {with_body: body, fixture: 'query_all_response'})

      @result = subject.query_all(soql)
    end

    it "#query_more" do
      body = "<tns:queryMore><tns:queryLocator>some_locator_string</tns:queryLocator></tns:queryMore>"
      stub_api_request(endpoint, {with_body: body, fixture: 'query_more_response'})

      @result = subject.query_more("some_locator_string")
    end

  end

  describe "#search" do

    it "should return search results" do

      sosl = "FIND 'Name*' IN ALL FIELDS RETURNING Account (Id, Name), Contact, Opportunity, Lead"
      # single quote encoding changed in ruby 2
      body = "<tns:search><tns:searchString>FIND &#39;Name*&#39; IN ALL FIELDS RETURNING Account (Id, Name), Contact, Opportunity, Lead</tns:searchString></tns:search>"
      stub_api_request(endpoint, {with_body: body, fixture: 'search_response'})

      subject.search(sosl)
    end

  end

  describe "#create" do
    before(:each) do
      @body = "<tns:create><tns:sObjects><ins0:type>Opportunity</ins0:type><tns:Name>SOAPForce Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Prospecting</tns:StageName></tns:sObjects></tns:create>"
      @params = { Name: "SOAPForce Opportunity", CloseDate: '2013-08-12', StageName: 'Prospecting' }
    end

    it "should create new object" do

      stub_api_request(endpoint, {with_body: @body, fixture: 'create_response'})
      response = subject.create("Opportunity", @params)

      expect(response[:success]).to eq true
      expect(response[:id]).to eq "006A000000LbiizIAB"
    end

    it "should return false if object not created" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'create_response_failure'})
      response = subject.create("Opportunity", @params)
      expect(response).to eq false
    end

    it "creates! new object" do

      stub_api_request(endpoint, {with_body: @body, fixture: 'create_response'})
      response = subject.create!("Opportunity", @params)

      expect(response[:success]).to eq true
      expect(response[:id]).to eq "006A000000LbiizIAB"
    end

    it "raises exception when create! fails" do

      stub_api_request(endpoint, {with_body: @body, fixture: 'create_response_failure'})
      expect {
        subject.create!("Opportunity", @params)
      }.to raise_error(Savon::Error)

    end
  end

  describe "#update" do
    before(:each) do
      @body = "<tns:update><tns:sObjects><ins0:type>Opportunity</ins0:type><ins0:Id>003ABCDE</ins0:Id><tns:Name>SOAPForce Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Closed Won</tns:StageName></tns:sObjects></tns:update>"
      @params = { Id: '003ABCDE', Name: "SOAPForce Opportunity", CloseDate: '2013-08-12', StageName: 'Closed Won' }
    end

    it "updates existing object" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'update_response'})
      response = subject.update("Opportunity", @params)

      expect(response[:success]).to eq true
      expect(response[:id]).to eq "006A000000LbiizIAB"
    end

    it "updates! existing object" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'update_response'})
      response = subject.update!("Opportunity", @params)

      expect(response[:success]).to eq true
      expect(response[:id]).to eq "006A000000LbiizIAB"
    end

    it "returns false when update fails" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'update_response_failure'})
      response = subject.update("Opportunity", @params)
      expect(response).to eq false
    end

    it "raises exception when update fails" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'update_response_failure'})
      expect {
        subject.update!("Opportunity", @params)
      }.to raise_error(Savon::Error)

    end
  end

  describe "#upsert" do
    before(:each) do
      @body = "<tns:upsert><tns:externalIDFieldName>External_Id__c</tns:externalIDFieldName><tns:sObjects><ins0:type>Opportunity</ins0:type><tns:Name>New Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Prospecting</tns:StageName></tns:sObjects><tns:sObjects><ins0:type>Opportunity</ins0:type><ins0:Id>003ABCDE</ins0:Id><tns:Name>Existing Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Closed Won</tns:StageName></tns:sObjects></tns:upsert>"
      @objects = [
        { Name: "New Opportunity", CloseDate: '2013-08-12', StageName: 'Prospecting' },
        { Id: '003ABCDE', Name: "Existing Opportunity", CloseDate: '2013-08-12', StageName: 'Closed Won' }
      ]
    end

    it "inserts new and updates existing objects" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'upsert_response'})
      subject.upsert("Opportunity", "External_Id__c", @objects)
    end

  end

  describe "#delete" do
    before(:each) do
      @body = "<tns:delete><tns:ids>006A000000LbiizIAB</tns:ids></tns:delete>"
      @id = "006A000000LbiizIAB"
    end

    it "deletes existing object" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response'})
      response = subject.delete(@id)

      expect(response[:success]).to eq true
      expect(response[:id]).to eq @id
    end

    it "returns false if delete fails" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response_failure'})
      response = subject.delete(@id)

      expect(response).to eq false
    end

    it "deletes existing object with a bang" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response'})
      response = subject.delete!(@id)

      expect(response).to be_an_instance_of Soapforce::Result
      expect(response[:success]).to eq true
      expect(response[:id]).to eq @id
    end

    it "raises an exception if delete fails" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response_failure'})
      expect {
        subject.delete!(@id)
      }.to raise_error(Savon::Error)
    end

  end

  describe "#merge" do
    before(:each) do
      @body = "<tns:merge><tns:request><tns:masterRecord xsi:type=\"Account\"><tns:id>001160000000000AAG</tns:id></tns:masterRecord><tns:recordToMergeIds>001140000000000AA4</tns:recordToMergeIds><tns:recordToMergeIds>001150000000000AAO</tns:recordToMergeIds></tns:request></tns:merge>"
      @object   = { id: "001160000000000AAG" }
      @to_merge = ['001140000000000AA4','001150000000000AAO']
    end

    it "merges objects together" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response'})
      response = subject.merge("Account", @object, @to_merge)

      expect(response).to be_an_instance_of Soapforce::Result
      expect(response[:success]).to eq true
      expect(response[:id]).to eq @object[:id]
      expect(response[:merged_record_ids]).to be_an(Array)
      expect(response[:merged_record_ids].sort).to eq @to_merge
    end

    it "returns false if merge fails" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response_failure'})
      response = subject.merge("Account", @object, @to_merge)

      expect(response).to eq false
    end

    it "merges objects with a bang" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response'})
      response = subject.merge!("Account", @object, @to_merge)

      expect(response[:success]).to eq true
      expect(response[:id]).to eq @object[:id]
      expect(response[:merged_record_ids].sort).to eq @to_merge
    end

    it "raises an exception if merge fails" do
      stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response_failure'})
      expect {
        subject.merge!('Account', @object, @to_merge)
      }.to raise_error(Savon::Error)
    end
  end

  describe "process" do

    it "process submit request without approvers" do

      @body = '<tns:process><tns:actions xsi:type="tns:ProcessSubmitRequest"><tns:objectId>a00i0000007JBLJAA4</tns:objectId><tns:comments>Submitting for Approval</tns:comments></tns:actions></tns:process>'

      stub_api_request(endpoint, {with_body: @body, fixture: 'process_submit_request_response'})
      response = subject.process({objectId: "a00i0000007JBLJAA4", comments: "Submitting for Approval"})

      expect(response).to be_an_instance_of(Soapforce::Result)
      expect(response[:success]).to eq true
      expect(response[:new_workitem_ids]).to eq "04ii000000098uLAAQ"
      expect(response["newWorkitemIds"]).to eq "04ii000000098uLAAQ"
    end

    it "process submit request with approvers" do

      @body = '<tns:process><tns:actions xsi:type="tns:ProcessSubmitRequest"><tns:objectId>a00i0000007JBLJAA4</tns:objectId><tns:comments>Submitting for Approval</tns:comments><tns:nextApproverIds>abcde12345</tns:nextApproverIds></tns:actions></tns:process>'

      stub_api_request(endpoint, {with_body: @body, fixture: 'process_submit_request_response'})
      response = subject.process({objectId: "a00i0000007JBLJAA4", comments: "Submitting for Approval", approverIds: "abcde12345"})

      expect(response[:success]).to eq true
      expect(response[:new_workitem_ids]).to eq "04ii000000098uLAAQ"
    end

    it "process workitem request" do
      @body = '<tns:process><tns:actions xsi:type="tns:ProcessWorkitemRequest"><tns:action>Removed</tns:action><tns:workitemId>a00i0000007JBLJAA4</tns:workitemId><tns:comments>Recalling Request</tns:comments></tns:actions></tns:process>'

      stub_api_request(endpoint, {with_body: @body, fixture: 'process_workitem_request_response'})
      response = subject.process({action: "Removed", workitemId: "a00i0000007JBLJAA4", comments: "Recalling Request"})

      expect(response[:success]).to eq true
      expect(response[:instance_status]).to eq "Removed"
    end
  end

  def fields_hash
    if subject.tag_style == :raw
      {"fields" => [{"name" => "Id"},{"name" => "Name"},{"name" => "Description"},{"name" => "StageName"}]}
    else
      {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "StageName"}]}
    end
  end

end
