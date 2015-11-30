require 'spec_helper'

describe Soapforce::SObject do

  describe 'empty object' do
    subject { Soapforce::SObject.new(id: [1, 1], name: "testing", stage_name: "Prospecting") }

    context "should have defaults" do
      it { expect(subject.Id).to eq 1 }
      it { expect(subject.Name).to eq "testing" }
      it { expect(subject.StageName).to eq "Prospecting" }
      it { expect(subject.InvalidField).to be_nil }

      it { expect(subject[:id]).to eq [1, 1] }
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

    context "respond to hash methods" do

      it "should has_key?" do
        expect(subject).to have_key(:name)
        expect(subject).to have_key(:stage_name)
        expect(subject).to_not have_key(:nothing)
      end

      it "should return keys" do
        expect(subject.keys).to eq [:id, :name, :stage_name]
      end
    end

  end

end
