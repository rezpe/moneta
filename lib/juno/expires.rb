module Juno
  class Expires < Proxy
    def key?(key, options = {})
      !!self[key]
    end

    def fetch(key, value = nil, options = {}, &block)
      result = check_expired(key, super(key, value, options, &block))
      if result && options.include?(:expires)
        store(key, result, options)
      else
        result
      end
    end

    def [](key)
      check_expired(key, super(key))
    end

    def store(key, value, options = {})
      if expires = options.delete(:expires)
        super(key, [value, Time.now.to_i + expires].compact, options)
      else
        super(key, [value], options)
      end
      value
    end

    def delete(key, options = {})
      check_expired(key, super, false)
    end

    protected

    def check_expired(key, value, delete_expired = true)
      value, expires = value
      if expires && Time.now.to_i > expires
        delete(key) if delete_expired
        nil
      else
        value
      end
    end
  end
end