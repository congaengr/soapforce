require 'spec_helper'

describe Soapforce::SObject do

  describe 'empty object' do
    subject { Soapforce::SObject.new(id: [1, 1], name: "testing", stage_name: "Prospecting") }

    context "should have defaults" do
      it { subject.Id.should == 1 }
      it { subject.Name.should == "testing" }
      it { subject.StageName.should == "Prospecting" }
      it { subject.InvalidField.should be_nil }

      it { subject[:id].should == [1, 1] }
      it { subject[:name].should == "testing" }
      it { subject[:stage_name].should == "Prospecting" }
      it { subject[:no_field].should be_nil }
    end

    context "assignment" do
      it "should assign through hash index" do
        subject[:nothing].should be_nil
        subject[:nothing] = "New Value"
        subject[:nothing].should == "New Value"
        subject.Nothing.should == "New Value"
      end
    end
  end

end
