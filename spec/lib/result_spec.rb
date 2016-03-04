require 'spec_helper'

describe Soapforce::Result do

  describe 'symbol keys' do
    subject { Soapforce::Result.new({new_workitem_ids: 12345, success: true}) }

    it { expect(subject[:new_workitem_ids]).to eq 12345 }
    it { expect(subject["newWorkitemIds"]).to eq 12345 }
    it { expect(subject[:success]).to eq true }
    it { expect(subject["success"]).to eq true }
  end

  describe 'string keys' do
    subject { Soapforce::Result.new({"newWorkitemIds" => 12345, "success" => true}) }

    it { expect(subject[:new_workitem_ids]).to eq 12345 }
    it { expect(subject["newWorkitemIds"]).to eq 12345 }
    it { expect(subject[:success]).to eq true }
    it { expect(subject["success"]).to eq true }
  end


end
