require 'spec_helper'

describe Soapforce::QueryResult do

  describe 'empty object' do
    subject { Soapforce::QueryResult.new }

    context "should have defaults" do
      it { expect(subject.size).to eq 0 }
      it { expect(subject.query_locator).to be_nil }
      it { expect(subject.first).to be_nil }
      it { expect(subject.last).to be_nil }
      it { expect(subject).to be_done }
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

      it { expect(subject.size).to eq 1 }
      it { expect(subject.query_locator).to be_nil }
      it { expect(subject).to be_done }

      it "#each" do
        count = 0
        subject.each do |obj|
          count +=1
          expect(obj[:id]).to eq count
          expect(obj.Id).to eq count
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

      it { expect(subject.size).to eq 2 }
      it { expect(subject.records).to be_an(Array) }
      it { expect(subject.query_locator).to be_nil }
      it { expect(subject).to be_done }

      it "#each" do
        count = 0
        subject.each do |obj|
          count +=1
          expect(obj[:id]).to eq count
          expect(obj.Id).to eq count
        end
        expect(count).to be(2)
      end

      it "#map" do
        count = 0
        subject.map do |obj|
          count +=1
          expect(obj[:id]).to eq count
          expect(obj.Id).to eq count
        end
        expect(count).to be(2)
      end

    end

    context "not done" do

      subject {
        hash = {
          done: false,
          query_locator: nil,
          size: 1,
          records: {id: 1, name: "Opportunity 1", stage_name: "Prospecting"}
        }
        Soapforce::QueryResult.new(hash)
      }

      it "#done?" do
        expect(subject.done?).to eq false
      end

    end

  end

end
