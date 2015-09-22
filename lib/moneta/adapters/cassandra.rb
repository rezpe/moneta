require 'cassandra'

module Moneta
  module Adapters
    # Cassandra backend
    # @api public
    # @author Sebastien Perez Vasseur
    class Cassandra
      include Defaults
      include ExpiresSupport

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :keyspace ('moneta') Cassandra keyspace
      # @option options [String] :table ('moneta') Cassandra column family
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (9160) Server port
      # @option options [Integer] :expires Default expiration time
      # @option options [::Cassandra] :backend Use existing backend instance
      # @option options Other options passed to `Cassandra#new`
      def initialize(options = {})

        self.default_expires = options[:expires]
        @table = options[:table] || 'moneta'
        if options[:backend]
          @backend = options[:backend]
        else
          @cluster  = Cassandra.cluster(hosts: options[:host] || '127.0.0.1',
                                      port: options[:port] || 9160,
                                      connect_timeout: options[:connect_timeout] || 10,
                                      timeout: options[:timeout] || 10)

          keyspace = options[:keyspace] || 'moneta'

          unless @cluster.keyspace_exists?(keyspace)
            @cluster.create_keyspace(keyspace)
            session = cluster.connect(keyspace)
            session.execute("CREATE TABLE #{@table} ( key ascii PRIMARY KEY, value text ) ")
          end

          @backend = cluster.connect(keyspace)

        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        if @backend.exists?(@cf, key)
          load(key, options) if options.include?(:expires)
          true
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        if value = @backend.get(@cf, key)
          expires = expires_value(options, nil)
          @backend.insert(@cf, key, {'value' => value['value'] }, ttl: expires || nil) if expires != nil
          value['value']
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.insert(@cf, key, {'value' => value}, ttl: expires_value(options) || nil)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @backend.remove(@cf, key)
          value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.clear_column_family!(@cf)
        self
      end

      # (see Proxy#close)
      def close
        @backend.disconnect!
        nil
      end
    end
  end
end
