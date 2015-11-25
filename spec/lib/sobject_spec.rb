require 'spec_helper'

describe Soapforce::SObject do

  describe 'symbol snakecase keys' do
    subject {
      Soapforce::SObject.new({
        id: [1, 1],
        name: "testing",
        stage_name: "Prospecting",
        opportunity_line_items: {
          done: true,
          query_locator: nil,
          size: 2,
          records: [
            {id: 1, name: "Opportunity 1", stage_name: "Prospecting"},
            {id: 2, name: "Opportunity 2", stage_name: "Closed Won"}
          ]
        }
      })
    }

    context "should have defaults" do
      it { expect(subject.Id).to eq 1 }
      it { expect(subject.Name).to eq "testing" }
      it { expect(subject.StageName).to eq "Prospecting" }
      it { expect(subject.InvalidField).to be_nil }

      it { expect(subject[:id]).to eq 1 }
      it { expect(subject[:name]).to eq "testing" }
      it { expect(subject[:stage_name]).to eq "Prospecting" }
      it { expect(subject[:no_field]).to be_nil }
    end

    context "assignment" do
      it "should assign through hash index" do
        expect(subject[:nothing]).to be_nil
        subject[:nothing] = "New Value"
        expect(subject[:nothing]).to eq "New Value"
        expect(subject.Nothing).to eq "New Value"
      end
    end

    context "child relationship" do
      it "returns records as QueryResult" do
        items = subject.OpportunityLineItems

        expect(items).to be_an_instance_of(Soapforce::QueryResult)
        expect(items.size).to eq 2
        expect(items).to be_done

        number = 1
        subject.OpportunityLineItems.each do |sobject|
          expect(sobject.Id).to eq number
          expect(sobject.Name).to eq "Opportunity #{number}"
          number += 1
        end
      end
    end

    context "respond to hash methods" do

      it "should has_key?" do
        expect(subject).to have_key(:name)
        expect(subject).to have_key(:stage_name)
        expect(subject).to_not have_key(:nothing)
      end

      it "should return keys" do
        expect(subject.keys).to eq [:id, :name, :stage_name, :opportunity_line_items]
      end
    end

  end

  describe 'string keys' do
    subject {
      Soapforce::SObject.new(
        "Id" => [1, 1],
        "Name" => "testing",
        "StageName" => "Prospecting",
        "OpportunityLineItems" => {
          "done" => true,
          "queryLocator" => nil,
          "size" => 2,
          "records" => [
            {"Id" => 1, "Name" => "Opportunity 1", "StageName" => "Prospecting"},
            {"Id" => 2, "Name" => "Opportunity 2", "StageName" => "Closed Won"}
          ]
        }
      )
    }

    context "should have defaults" do
      it { expect(subject.Id).to eq 1 }
      it { expect(subject.Name).to eq "testing" }
      it { expect(subject.StageName).to eq "Prospecting" }
      it { expect(subject.InvalidField).to be_nil }

      it { expect(subject["Id"]).to eq 1 }
      it { expect(subject["Name"]).to eq "testing" }
      it { expect(subject["StageName"]).to eq "Prospecting" }
      it { expect(subject["NoField"]).to be_nil }
    end

    context "assignment" do
      it "should assign through hash index" do
        expect(subject["nothing"]).to be_nil
        subject["nothing"] = "New Value"
        expect(subject["nothing"]).to eq "New Value"
        expect(subject.Nothing).to eq "New Value"
      end
    end

    context "respond to hash methods" do

      it "should has_key?" do
        expect(subject).to have_key("Name")
        expect(subject).to have_key("StageName")
        expect(subject).to_not have_key("nothing")
      end

      it "should return keys" do
        expect(subject.keys).to eq ["Id", "Name", "StageName", "OpportunityLineItems"]
      end
    end

    context "child relationship" do
      it "returns records as QueryResult" do
        items = subject.OpportunityLineItems
        expect(items).to be_an_instance_of(Soapforce::QueryResult)
        expect(items.size).to eq 2
        expect(items).to be_done

        number = 1
        subject.OpportunityLineItems.each do |sobject|
          expect(sobject.Id).to eq number
          expect(sobject.Name).to eq "Opportunity #{number}"
          number += 1
        end
      end
    end

  end

  describe 'empty id field' do
    subject { Soapforce::SObject.new({ id: [nil, nil], name: "testing", stage_name: "Prospecting" }) }

    context "should have defaults" do
      it { expect(subject).to_not have_key(:id) }
      it { expect(subject.Name).to eq "testing" }
      it { expect(subject.StageName).to eq "Prospecting" }
      it { expect(subject.InvalidField).to be_nil }
      it { expect(subject.to_hash).to eq({:name=>"testing", :stage_name=>"Prospecting"}) }
    end
  end



end
