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

          #We check if the keyspace exists, if not, we create a new keyspace
          unless @cluster.keyspace_exists?(keyspace)
            @cluster.create_keyspace(keyspace)
            session = cluster.connect(keyspace)
            session.execute("CREATE TABLE #{@table} ( key ascii PRIMARY KEY, value text ) ")
          end

          #Connection to the cluster
          @backend = cluster.connect(keyspace)

        end
      end

      # (see Proxy#key?)
      #Check if the key is present in the table
      def key?(key, options = {})
        rows = @backend.execute("SELECT * FROM #{@table} WHERE key='#{key}' LIMIT 1")

        if rows.first
          true
        else
          false
        end

      end

      # (see Proxy#load)
      #Reads a value from the table
      def load(key, options = {})
        rows = @backend.execute("SELECT * FROM #{@table} WHERE key='#{key}' LIMIT 1")

        if rows.first
          rows.first['value']
        else
          nil
        end
      end

      # (see Proxy#store)
      #Stores a value
      def store(key, value, options = {})
        @backend.execute("INSERT INTO #{@table} (key, value) VALUES ('#{key}','#{value}')")
        value
      end

      # (see Proxy#delete)
      #deletes a value
      def delete(key, options = {})
        if value = load(key, options)
          @backend.execute("DELETE FROM #{@table} where key='#{key}'")
          value
        end
      end

      # (see Proxy#clear)
      #Clears the table
      def clear(options = {})
        @backend.execute("TRUNCATE #{@table}")
        self
      end

      # (see Proxy#close)
      #disconnection
      def close
        @backend.close
        nil
      end
    end
  end
end
