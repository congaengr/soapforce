require 'spec_helper'

describe Soapforce do

  after do
    Soapforce.instance_variable_set :@configuration, nil
  end

  describe '#configuration' do
    subject { Soapforce.configuration }

    it { should be_a Soapforce::Configuration }
    it { subject.client_id.should be_nil }

  end

  describe '#configure' do
    [:client_id].each do |attr|
      it "allows #{attr} to be set" do
        Soapforce.configure do |config|
          config.send("#{attr}=", 'foobar')
        end
        expect(Soapforce.configuration.send(attr)).to eq 'foobar'
      end
    end
  end

end
