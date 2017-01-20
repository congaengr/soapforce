module Soapforce
  class Result
    extend Forwardable

    attr_reader :raw_hash

    def_delegators :@raw_hash, :key?, :has_key?, :each, :map, :to_hash

    def initialize(result_hash = {})
      @raw_hash = result_hash
    end

    def [](index)
      # If index is a symbol, try :field_name, "fieldName", "field_name"
      if index.is_a?(Symbol)
        if @raw_hash.key?(index)
          @raw_hash[index]
        elsif index.to_s.include?('_')
          camel_key = index.to_s.gsub(/\_(\w{1})/) { |cap| cap[1].upcase }
          @raw_hash[camel_key]
        else
          @raw_hash[index.to_s]
        end
      elsif index.is_a?(String)
        # If index is a String, try fieldName, :fieldName, :field_name
        if @raw_hash.key?(index)
          @raw_hash[index]
        elsif @raw_hash.key?(index.to_sym)
          @raw_hash[index.to_sym]
        else
          @raw_hash[index.snakecase.to_sym]
        end
      end
    end
  end
end
