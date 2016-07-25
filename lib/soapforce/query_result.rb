module Soapforce
  class QueryResult
    include Enumerable

    attr_reader :raw_result

    def initialize(result={})
      if result.is_a?(Soapforce::Result)
        @raw_result = result.to_hash
      else
        @raw_result = result
      end

      @result_records = [] # Default for 0 size response.
      @key_type = @raw_result.key?(:size) ? :symbol : :string

      records_key = key_name("records")

      if @raw_result[records_key]
        @result_records = @raw_result[records_key]
        # Single records come back as a Hash. Wrap in array.
        if @result_records.is_a?(Hash)
          @result_records = [@result_records]
        end
      end

      # Convert to SObject type.
      @result_records.map! {|hash| SObject.new(hash) }
    end

    def records
      @result_records
    end

    # Implmentation for Enumerable mix-in.
    def each(&block)
      @result_records.each(&block)
    end

    def map(&block)
      @result_records.map(&block)
    end

    def size
      @raw_result[key_name("size")].to_i || 0
    end

    def done?
      @raw_result[key_name("done")] || true
    end

    def query_locator
      @raw_result[key_name("queryLocator")]
    end

    def method_missing(method, *args, &block)
      if @result_records.respond_to?(method)
        @result_records.send(method, *args, &block)
      end
    end

    def key_name(key)
      if @key_type == :symbol
        key.is_a?(String) ? key.snakecase.to_sym : key
      else
        key.to_s
      end
    end
  end

end
