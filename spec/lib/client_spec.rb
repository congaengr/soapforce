require 'spec_helper'

describe Soapforce::Client do
  let(:endpoint) { 'https://na15.salesforce.com' }

  describe "#operations" do
    it "should return list of operations from the wsdl" do
      subject.operations.should be_a(Array)
      subject.operations.should include(:login, :logout, :query, :create)
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

      user_info[:user_email].should == "johndoe@email.com"
      user_info[:user_full_name].should == "John Doe"
    end

    it "should raise arugment error when no parameters are passed" do
      expect { subject.login(session_id: 'something') }.to raise_error(ArgumentError)
    end
  end

  describe "list_sobjects" do
    it "should return array of object names" do

      body = "<tns:describeGlobal></tns:describeGlobal>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_global_response'})

      subject.list_sobjects.should == ['Account', 'AccountContactRole']
    end
  end

  describe "org_id" do
    it "should return organization id" do

      body = "<tns:query><tns:queryString>select id from Organization</tns:queryString></tns:query>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'org_id_response'})

      subject.org_id.should == "00DA0000000YpZ4MAK"
    end
  end

  describe "#descibeSObject" do

    it "supports single sobject name" do

      body = "<tns:describeSObject><tns:sObjectType>Opportunity</tns:sObjectType></tns:describeSObject>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_s_object_response'})

      subject.describe("Opportunity")

      # Hit cache.
      subject.describe("Opportunity")
    end

    it "supports array of sobject names" do

      body = "<tns:describeSObjects><tns:sObjectType>Account</tns:sObjectType><tns:sObjectType>Opportunity</tns:sObjectType></tns:describeSObjects>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_s_objects_response'})

      subject.describe(["Account", "Opportunity"])
    end
  end

  describe "#descibeLayout" do

    it "gets layouts for an sobject type" do

      body = %Q{<tns:describeLayout><tns:sObjectType>Account</tns:sObjectType><tns:recordTypeIds xsi:nil="true"/></tns:describeLayout>}
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_layout_response'})

      subject.describe_layout("Account")

      # Hit cache.
      subject.describe_layout("Account")
    end

    it "get the details for a specific layout" do

      body = %Q{<tns:describeLayout><tns:sObjectType>Account</tns:sObjectType><tns:recordTypeIds>012000000000000AAA</tns:recordTypeIds></tns:describeLayout>}
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_layout_response'})

      subject.describe_layout('Account', '012000000000000AAA')
    end
  end

  describe "#retrieve" do

    it "should retrieve object by id" do
      fields = {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "StageName"}]}
      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).with("Opportunity").and_return(fields)

      body = "<tns:retrieve><tns:fieldList>Id,Name,Description,StageName</tns:fieldList><tns:sObjectType>Opportunity</tns:sObjectType><tns:ids>006A000000LbkT5IAJ</tns:ids></tns:retrieve>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'retrieve_response'})

      sobject = subject.retrieve("Opportunity", "006A000000LbkT5IAJ")

      sobject.should be_a(Soapforce::SObject)
      sobject.type.should == "Opportunity"
      sobject.Id.should == "006A000000LbkT5IAJ"
      sobject.Name.should == "SOAPForce Opportunity"
      sobject.Description.should be_nil
      sobject.StageName.should == "Prospecting"
    end
  end

  describe "#find" do
    it "should retrieve object by id" do

      fields = {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "StageName"}]}
      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).with("Opportunity").and_return(fields)

      body = "<tns:retrieve><tns:fieldList>Id,Name,Description,StageName</tns:fieldList><tns:sObjectType>Opportunity</tns:sObjectType><tns:ids>006A000000LbkT5IAJ</tns:ids></tns:retrieve>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'retrieve_response'})

      sobject = subject.find("Opportunity", "006A000000LbkT5IAJ")

      sobject.should be_a(Soapforce::SObject)
      sobject.type.should == "Opportunity"
      sobject.Id.should == "006A000000LbkT5IAJ"
      sobject.Name.should == "SOAPForce Opportunity"
      sobject.Description.should be_nil
      sobject.StageName.should == "Prospecting"
    end

  end

  describe "#find_by_field" do

    it "should retrieve object by string field" do
      fields = {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "StageName"}]}
      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).exactly(2).with("Opportunity").and_return(fields)

      body = "<tns:query><tns:queryString>Select Id, Name, Description, StageName From Opportunity Where StageName = 'Prospecting'</tns:queryString></tns:query>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      subject.find_by_field("Opportunity", "Prospecting", "StageName")
    end

    it "should retrieve object by number field" do
      fields = {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "Amount", :type => "double"}]}
      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).exactly(2).with("Opportunity").and_return(fields)

      body = "<tns:query><tns:queryString>Select Id, Name, Description, Amount From Opportunity Where Amount = 0.0</tns:queryString></tns:query>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      subject.find_by_field("Opportunity", 0.0, "Amount")
    end

  end

  describe "#find_where" do

    let(:fields) { {:fields => [{:name => "Id"},{:name => "Name"},{:name => "Description"},{:name => "StageName"}]} }
    let(:body) { "<tns:query><tns:queryString>Select Id, Name, Description, StageName From Opportunity Where Id = '006A000000LbkT5IAJ' AND Amount = 0.0</tns:queryString></tns:query>" }

    after(:each) do
      @result.should be_a(Soapforce::QueryResult)
      @result.size.should == 2
      @result.first.Name == "Opportunity 1"
      @result.last.Name == "Opportunity 2"
    end

    it "should retrieve records from hash conditions" do
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})
      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).with("Opportunity").and_return(fields)

      @result = subject.find_where("Opportunity", {Id: "006A000000LbkT5IAJ", Amount: 0.0})
    end

    it "should retrieve records from hash condition using IN clause" do
      body = "<tns:query><tns:queryString>Select Id, Name, Description, StageName From Opportunity Where Id IN ('006A000000LbkT5IAJ', '006A000000AbkTcIAQ')</tns:queryString></tns:query>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).with("Opportunity").and_return(fields)

      @result = subject.find_where("Opportunity", {Id: ["006A000000LbkT5IAJ", "006A000000AbkTcIAQ"]})
    end

    it "should retrieve records from string condition" do
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})
      # retrieve calls describe to get the list of available fields.
      subject.should_receive(:describe).with("Opportunity").and_return(fields)

      @result = subject.find_where("Opportunity", "Id = '006A000000LbkT5IAJ' AND Amount = 0.0")
    end

    it "should retrieve records from string condition and specify fields" do
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})
      subject.should_not_receive(:describe)

      @result = subject.find_where("Opportunity", "Id = '006A000000LbkT5IAJ' AND Amount = 0.0", ["Id", "Name", "Description", "StageName"])
    end

  end

  describe "query methods" do

    after(:each) do
      @result.should be_a(Soapforce::QueryResult)
      @result.size.should == 2
      @result.first.Name == "Opportunity 1"
      @result.last.Name == "Opportunity 2"
    end

    it "#query" do
      body = "<tns:query><tns:queryString>Select Id, Name, StageName from Opportunity</tns:queryString></tns:query>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      @result = subject.query("Select Id, Name, StageName from Opportunity")
    end

    it "#query_all" do
      body = "<tns:queryAll><tns:queryString>Select Id, Name, StageName from Opportunity</tns:queryString></tns:queryAll>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_all_response'})

      @result = subject.query_all("Select Id, Name, StageName from Opportunity")
    end

    it "#query_more" do
      body = "<tns:queryMore><tns:queryLocator>some_locator_string</tns:queryLocator></tns:queryMore>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_more_response'})

      @result = subject.query_more("some_locator_string")
    end

  end

  describe "#search" do

    it "should return search results" do

      sosl = "FIND 'Name*' IN ALL FIELDS RETURNING Account (Id, Name), Contact, Opportunity, Lead"

      body = "<tns:search><tns:searchString>#{sosl}</tns:searchString></tns:search>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'search_response'})

      subject.search(sosl)
    end

  end

  describe "#create" do
    before(:each) do
      @body = "<tns:create><tns:sObjects><ins0:type>Opportunity</ins0:type><tns:Name>SOAPForce Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Prospecting</tns:StageName></tns:sObjects></tns:create>"
      @params = { Name: "SOAPForce Opportunity", CloseDate: '2013-08-12', StageName: 'Prospecting' }
    end

    it "should create new object" do

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'create_response'})
      response = subject.create("Opportunity", @params)

      response[:success].should be_true
      response[:id].should == "006A000000LbiizIAB"
    end

    it "should return false if object not created" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'create_response_failure'})
      response = subject.create("Opportunity", @params)
      response.should be_false
    end

    it "creates! new object" do

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'create_response'})
      response = subject.create!("Opportunity", @params)

      response[:success].should be_true
      response[:id].should == "006A000000LbiizIAB"
    end

    it "raises exception when create! fails" do

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'create_response_failure'})
      expect {
        response = subject.create!("Opportunity", @params)
      }.to raise_error(Savon::Error)

    end
  end

  describe "#update" do
    before(:each) do
      @body = "<tns:update><tns:sObjects><ins0:type>Opportunity</ins0:type><ins0:Id>003ABCDE</ins0:Id><tns:Name>SOAPForce Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Closed Won</tns:StageName></tns:sObjects></tns:update>"
      @params = { Id: '003ABCDE', Name: "SOAPForce Opportunity", CloseDate: '2013-08-12', StageName: 'Closed Won' }
    end

    it "updates existing object" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'update_response'})
      response = subject.update("Opportunity", @params)

      response[:success].should be_true
      response[:id].should == "006A000000LbiizIAB"
    end

    it "updates! existing object" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'update_response'})
      response = subject.update!("Opportunity", @params)

      response[:success].should be_true
      response[:id].should == "006A000000LbiizIAB"
    end

    it "returns false when update fails" do

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'update_response_failure'})
      response = subject.update("Opportunity", @params)
      response.should be_false
    end

    it "raises exception when update fails" do

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'update_response_failure'})
      expect {
        response = subject.update!("Opportunity", @params)
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
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'upsert_response'})
      subject.upsert("Opportunity", "External_Id__c", @objects)
    end

  end

  describe "#delete" do
    before(:each) do
      @body = "<tns:delete><tns:ids>006A000000LbiizIAB</tns:ids></tns:delete>"
      @id = "006A000000LbiizIAB"
    end

    it "deletes existing object" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response'})
      response = subject.delete(@id)

      response[:success].should be_true
      response[:id].should == @id
    end

    it "returns false if delete fails" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response_failure'})
      response = subject.delete(@id)

      response.should be_false
    end

    it "deletes existing object with a bang" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response'})
      response = subject.delete!(@id)

      response[:success].should be_true
      response[:id].should == @id
    end

    it "raises an exception if delete fails" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'delete_response_failure'})
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
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response'})
      response = subject.merge("Account", @object, @to_merge)

      response[:success].should be_true
      response[:id].should == @object[:id]
      response[:merged_record_ids].sort.should == @to_merge
    end

    it "returns false if merge fails" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response_failure'})
      response = subject.merge("Account", @object, @to_merge)

      response.should be_false
    end

    it "merges objects with a bang" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response'})
      response = subject.merge!("Account", @object, @to_merge)

      response[:success].should be_true
      response[:id].should == @object[:id]
      response[:merged_record_ids].sort.should == @to_merge
    end

    it "raises an exception if merge fails" do
      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'merge_response_failure'})
      expect {
        subject.merge!('Account', @object, @to_merge)
      }.to raise_error(Savon::Error)
    end
  end

  describe "process" do

    it "process submit request without approvers" do

      @body = '<tns:process><tns:actions xsi:type="tns:ProcessSubmitRequest"><tns:objectId>a00i0000007JBLJAA4</tns:objectId><tns:comments>Submitting for Approval</tns:comments></tns:actions></tns:process>'

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'process_submit_request_response'})
      response = subject.process({objectId: "a00i0000007JBLJAA4", comments: "Submitting for Approval"})

      response[:success].should be_true
      response[:new_workitem_ids].should == "04ii000000098uLAAQ"
    end

    it "process submit request with approvers" do

      @body = '<tns:process><tns:actions xsi:type="tns:ProcessSubmitRequest"><tns:objectId>a00i0000007JBLJAA4</tns:objectId><tns:comments>Submitting for Approval</tns:comments><tns:nextApproverIds>abcde12345</tns:nextApproverIds></tns:actions></tns:process>'

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'process_submit_request_response'})
      response = subject.process({objectId: "a00i0000007JBLJAA4", comments: "Submitting for Approval", approverIds: "abcde12345"})

      response[:success].should be_true
      response[:new_workitem_ids].should == "04ii000000098uLAAQ"
    end

    it "process workitem request" do
      @body = '<tns:process><tns:actions xsi:type="tns:ProcessWorkitemRequest"><tns:action>Removed</tns:action><tns:workitemId>a00i0000007JBLJAA4</tns:workitemId><tns:comments>Recalling Request</tns:comments></tns:actions></tns:process>'

      stub = stub_api_request(endpoint, {with_body: @body, fixture: 'process_workitem_request_response'})
      response = subject.process({action: "Removed", workitemId: "a00i0000007JBLJAA4", comments: "Recalling Request"})

      response[:success].should be_true
      response[:instance_status].should == "Removed"
    end
  end

end
