module Soapforce
  class QueryResult
    include Enumerable

    attr_reader :raw_result

    def initialize(result_hash={})
      @raw_result = result_hash
      @result_records = [] # Default for 0 size response.
      if @raw_result[:size].to_i == 1
        @result_records = [@raw_result[:records]]
      elsif @raw_result[:records]
        @result_records = @raw_result[:records]
      end
    end

    # Implmentation for Enumerable mix-in.
    def each(&block)
      @result_records.each(&block)
    end

    def first
      @result_records.first
    end

    def last
      @result_records.last
    end

    def size
      @raw_result[:size] || 0
    end

    def done?
      @raw_result[:done] || true
    end

    def query_locator
      @raw_result[:query_locator]
    end
  end

end