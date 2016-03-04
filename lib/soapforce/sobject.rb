module Soapforce
  class SObject
    attr_reader :raw_hash

    def initialize(hash)
      @raw_hash = hash || {}
      id_key = @raw_hash.key?(:id) ? :id : 'Id'

      # For some reason the Id field is coming back twice and stored in an array.
      if @raw_hash[id_key].is_a?(Array)
        @raw_hash[id_key] = @raw_hash[id_key].compact.uniq
        # Remove empty id array if nothing exists.
        if @raw_hash[id_key].empty?
          @raw_hash.delete(id_key)
        elsif @raw_hash[id_key].size == 1
          @raw_hash[id_key] = @raw_hash[id_key].first
        end
      end
    end

    def Id
      @raw_hash[:id] || @raw_hash['Id']
    end

    def [](index)
      val = @raw_hash[index]

      # When fetching a child relationship, wrap it in QueryResult
      if val.is_a?(Hash) && (val.has_key?(:records) || val.has_key?("records"))
        val = QueryResult.new(val)
      end
      val
    end

    def []=(index, value)
      @raw_hash[index] = value
    end

    def has_key?(key)
      @raw_hash.has_key?(key)
    end

    # Allows method-like access to the hash using camelcase field names.
    def method_missing(method, *args, &block)
      # Check string keys first, original and downcase
      string_method = method.to_s

      if raw_hash.key?(string_method)
        return self[string_method]
      elsif raw_hash.key?(string_method.downcase)
        return self[string_method.downcase]
      end

      if string_method =~ /[A-Z+]/
        string_method = string_method.snakecase
      end

      index = string_method.downcase.to_sym
      # Check symbol key and return local hash entry.
      return self[index] if raw_hash.has_key?(index)
      # Then delegate to hash object.
      if raw_hash.respond_to?(method)
        return raw_hash.send(method, *args)
      end
      # Finally return nil.
      nil
    end

  end
end
