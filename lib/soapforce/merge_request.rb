module Soapforce
  MergeRequest = Struct.new(:sobject_type,:master_id,:other_ids) do
    def master_record_hash
      {
        'Id' => self.master_id
      }
    end

    def request_hash
      {
        masterRecord: master_record_hash.merge(:'@xsi:type' => sobject_type),
        recordToMergeIds: self.other_ids
      }
    end
  end
end