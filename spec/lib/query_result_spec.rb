require 'spec_helper'

describe Soapforce::QueryResult do

  describe 'empty object' do
    subject { Soapforce::QueryResult.new }
    
    context "should have defaults" do
      it { subject.size.should == 0 }
      it { subject.query_locator.should be_nil }
      it { subject.should be_done }
    end
    
  end

  describe 'result object' do

    context "single object" do

      subject {
        hash = {
          done: true,
          query_locator: nil,
          size: 1,
          records: {id: 1, name: "Opportunity 1", stage_name: "Prospecting"}
        }
        Soapforce::QueryResult.new(hash)
      }

      it { subject.size.should == 1 }
      it { subject.query_locator.should be_nil }
      it { subject.should be_done }
      
      it "#each" do
        count = 0
        subject.each do |obj|
          count +=1
          obj[:id].should == count
        end
        expect(count).to be(1)
      end
    end

    context "multiple records" do

      subject {
        hash = {
          done: true,
          query_locator: nil,
          size: 2,
          records: [
            {id: 1, name: "Opportunity 1", stage_name: "Prospecting"},
            {id: 2, name: "Opportunity 2", stage_name: "Closed Won"}
          ]
        }
        Soapforce::QueryResult.new(hash)
      }

      it { subject.size.should == 2 }
      it { subject.query_locator.should be_nil }
      it { subject.should be_done }
      
      it "#each" do
        count = 0
        subject.each do |obj|
          count +=1
          obj[:id].should == count
        end
        expect(count).to be(2)
      end
    end

  end

end
