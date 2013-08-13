module Soapforce
  class SObject
    attr_reader :raw_hash

    def initialize(hash)
      @raw_hash = hash || {}
    end

    # For some reason the Id field is coming back twice and stored in an array.
    def Id
      @raw_hash[:id].is_a?(Array) ? @raw_hash[:id].first : @raw_hash[:id]
    end

    def [](index)
      @raw_hash[index.to_sym]
    end

    # Allows method-like access to the hash using camelcase field names.
    def method_missing(method, *args, &block)

      string_method = method.to_s
      if string_method =~ /[A-Z+]/
        string_method = underscore(string_method)
      end

      index = string_method.downcase.to_sym
      return raw_hash.has_key?(index) ? raw_hash[index] : nil
    end

    protected

    def underscore(str)
      str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

  end
end
