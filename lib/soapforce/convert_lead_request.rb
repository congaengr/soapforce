module Soapforce
  ConvertLeadRequest = Struct.new(:lead_id, :contact_id, :account_id, :convert_status) do
    def request_hash
      {
        leadId:self.lead_id,
        contactId:self.contact_id,
        accountId: self.account_id,
        convertedStatus: self.convert_status,
        doNotCreateOpportunity:true
      }
    end
  end
end