require "ibm/bluemix/service_discovery/version"
require "logger"
require "unirest"

module IBM
  module Bluemix

    # ServiceDiscovery provides a simple interface to the IBM Bluemix Service
    # Discovery service.  The interface provides methods for all operations
    # provided by Service Discovery as well as some helpers to make working
    # with the service a little easier.
    class ServiceDiscovery
      # Your code goes here...

      # URL for the production Bluemix Service Discovery endpoint
      SERVICE_DISCOVERY_ENDPOINT = "https://servicediscovery.ng.bluemix.net/api/v1/services"

      # URL for the production Bluemix Service Registry endpoint
      SERVICE_REGISTRY_ENDPOINT = "https://servicediscovery.ng.bluemix.net/api/v1/instances"

      private_constant :SERVICE_DISCOVERY_ENDPOINT, :SERVICE_REGISTRY_ENDPOINT

      # cache of registered services
      @@services = {}

      # cache of threads running heartbeats
      @@heartbeats = {}

      # dummy logger that can be overridden
      class << self
        # logger attribute that can be overridden
        attr_writer :logger

        # Logger function that should be overridden.
        #
        # @example
        #   logger.debug 'this is a debug message'
        #
        def logger
          @logger ||= Logger.new($stdout).tap do |log|
            log.progname = self.name
          end
        end
      end

      # Create a new ServiceDiscovery instance.
      #
      # @example
      #   sd = ServiceDiscovery.new('token...')
      #
      # @param auth_token [String] Valid `auth_token` from the IBM Bluemix Service Discovery service
      #
      def initialize(auth_token)
        @auth_token = auth_token

        # defaults
        Unirest.default_header('Authorization', 'Bearer ' + @auth_token)
        Unirest.default_header('Accept','application/json')
        Unirest.default_header('Content-Type','application/json')

        Unirest.timeout(5) # 5s timeout
      end

      # Register a service with Service Discovery
      #
      # @example
      #   sd = ServiceDiscovery.new('token...')
      #   => sd.register('sample_service', '192.168.1.100:8080', { ttl: 60, heartbeat: true }, {})
      #
      # @param service_name [String] The name of the microservice
      # @param host [String] The host and port where the microservice can be reached at
      # @param options [Hash] Options to customize service discovery instance (see below)
      # @option options [Boolean] :heartbeat Enable or disable automated heartbeat for the service
      # @option options [Integer] :ttl Expire the service after this many seconds if a heartbeat has not been received.  Hearbeat is automatically set to 30% of this value
      # @param meta [Hash] Metadata to store with the service registration
      # @return [Hash] Resulting payload from the call to Service Discovery
      #
      def register(service_name, host, options = {}, meta = {})

        begin
          response = Unirest.post SERVICE_REGISTRY_ENDPOINT,
                          parameters: {
                            service_name: service_name,
                            endpoint: {
                              type: 'tcp',
                              value: host
                            },
                            status: "UP",
                            ttl: options[:ttl] || 60,
                            metadata: meta
                          }.to_json
        rescue Exception => e
          # TODO: raise custom exception
          ServiceDiscovery.logger.debug "Exception: #{e.class} #{e.message}"
          return nil
        end

        # ServiceDiscovery.logger.debug response

        if response.code != 201
          #
          ServiceDiscovery.logger.error response.code
        end

        # TODO: validate the response.body has the right keys

        @@services[service_name] = response.body

        # response.code # Status code
        # response.headers # Response headers
        # response.body # Parsed body
        # response.raw_body # Unparsed body



        # '{"service_name":"my_service", "endpoint": { "type":"tcp", "value": "host:port" }, "status":"UP", "ttl":25, "metadata":{"key":"value"}}'

        # {
        #    "id":"6ae425dd79f1962e",
        #    "ttl":30,
        #    "links":{
        #       "self": "https://servicediscovery.ng.bluemix.net/api/v1/instances/6ae425dd79f1962e",
        #       "heartbeat": "https://servicediscovery.ng.bluemix.net/api/v1/instances/6ae425dd79f1962e/heartbeat",
        #    }
        # }

        # check if we should enable a heartbeat
        if options[:heartbeat] == true
          heartbeat_ttl = (options[:ttl] * 0.75).round
          self.heartbeat(service_name, heartbeat_ttl)
        end

        return @@services[service_name]
      end

      # Send a heartbeat request to indicate the service is still alive and well
      #
      # @example
      #   sd.renew('sample_service')
      #
      # @param service_name [String] The name of the microservice
      # @return [Boolean] `true` if the service was renewed, `false` otherwise
      #
      def renew(service_name)

        # error, we didn't register the service yet
        return false unless @@services.has_key? service_name

        service = @@services[service_name]

        begin
          ServiceDiscovery.logger.debug 'calling heartbeat url: ' + service['links']['heartbeat']
          response = Unirest.put service['links']['heartbeat'],
                          headers: {
                            'Content-Length': 0
                          }
        rescue Exception => e
          #
        end

        if response.code != 200
          #
          # Attempting to send a heartbeat for an expired instance will result in HTTP status code 410 (Gone).
          return false
        end

        # curl -X PUT -H "Authorization: Bearer 12o191sqk5h***" -H "Content-Length: 0" https://servicediscovery.ng.bluemix.net/api/v1/instances/6ae425dd79f1962e/heartbeat
        true
      end

      # Set-up a separate Thread to send continuous heartbeats (renew) calls to
      # indicate the service is alive.
      #
      # @example
      #   sd.heartbeat('sample_service', 45)
      #
      # @param service_name [String] The name of the microservice
      # @param interval [Integer] The number of seconds between heartbeats
      # @return [Boolean] `true` if the heartbeat thread was started, `false` otherwise
      #
      def heartbeat(service_name, interval=60)

        # kill the existing thread
        unless @@heartbeats[service_name].nil?
          ServiceDiscovery.logger.debug 'killing an existing heartbeat thread'
          Thread.kill @@heartbeats[service_name]
        end

        # create a new thread that is going to run forever
        @@heartbeats[service_name] = Thread.new{
          while true
            # TODO: how to handle errors in the thread?
            ServiceDiscovery.logger.debug 'sending heartbeat'
            self.renew(service_name)
            sleep interval
          end
        }

        # # something happened?
        # true
      end

      # Stops a previously established heartbeat Thread
      #
      # @example
      #   sd.unheartbeat('sample_service')
      #
      # @param service_name [String] The name of the microservice
      # @return [Boolean] `true` if the heartbeat thread was stopped, `false` otherwise
      #
      def unheartbeat(service_name)
        Thread.kill @@heartbeats[service_name]
      end

      # Deletes a service entry from Service Discovery
      #
      # @example
      #   sd.delete('sample_service')
      #
      # @param service_name [String] The name of the microservice
      # @return [Boolean] `true` if the service was removed, `false` otherwise
      #
      def delete(service_name)

        # error, we didn't register the service yet
        return false unless @@services.has_key? service_name

        service = @@services[service_name]
        ServiceDiscovery.logger.debug 'Deleting: ' + service.to_s

        begin
          response = Unirest.delete service['links']['self']
        rescue Exception => e
          #
          ServiceDiscovery.logger.debug "Exception: #{e.class} #{e.message}"
        end

        if response.code != 200
          #
          # Attempting to send a heartbeat for an expired instance will result in HTTP status code 410 (Gone).
        end
        @@services.delete service_name
        true
      end

      # Resets the state of this service.  This includes stopping any existing
      # heartbeat Threads as well as deleting all registered services.
      #
      # @example
      #   sd.reset
      #
      # @return [Boolean] `true` if the reset was successful, `false` otherwise
      #
      def reset

        # cancel any threads
        @@heartbeats.keys.each do |k|
          self.unheartbeat(k)
        end

        # delete all of the services
        @@services.keys.each do |k|
          self.delete(k)
        end

        true
      end

      # Returns information about the current local state of Service Discovery.
      # This includes information about the services and the heartbeats.
      #
      # @example
      #   sd.info
      #
      # @return [Hash] { services: ['s1', 's2'], heartbeats: ['s1'] }
      #
      def info
        { services: @@services.keys, heartbeats: heartbeats.keys }
      end

      # Get the current list of registered services within Service Discovery
      #
      # @example
      #   sd.list
      #
      # @return [Hash] { services: ['s1', 's2'] }
      #
      def list

        # curl -X GET -H "Authorization: bearer 12o191sqk5h***"https://servicediscovery.ng.bluemix.net/api/v1/services

        begin
          response = Unirest.get SERVICE_DISCOVERY_ENDPOINT
        rescue Exception => e
          #
          ServiceDiscovery.logger.debug "Exception: #{e.class} #{e.message}"
        end

        if response.code != 200
          #
          # Attempting to send a heartbeat for an expired instance will result in HTTP status code 410 (Gone).
        end

        response.body
      end

      # Discovers the connection information for a given microservice.
      #
      # @example
      #   sd.discover('sample_service')
      #
      # @param service_name [String] The name of the microservice
      # @return [Hash]
      #   {
      #      "service_name":"my_service",
      #      "instances":[
      #      {
      #         "endpoint":
      #         {
      #            "type": "tcp",
      #            "value": "192.168.1.32:80",
      #         },
      #         "status": "UP",
      #         "last_heartbeat": "2015-05-01T08:28:06.801064+02:00",
      #         "metadata": {"key":"value"}
      #      }]
      #   }
      #
      def discover(service_name)
        # curl -X GET -H "Authorization: bearer 12o191sqk5h***" https://servicediscovery.ng.bluemix.net/api/v1/services/my_service

        # {
        #    "service_name":"my_service",
        #    "instances":[
        #    {
        #       "endpoint":
        #       {
        #          "type": "tcp",
        #          "value": "192.168.1.32:80",
        #       },
        #       "status": "UP",
        #       "last_heartbeat": "2015-05-01T08:28:06.801064+02:00",
        #       "metadata": {"key":"value"}
        #    }]
        # }

        begin
          response = Unirest.get SERVICE_DISCOVERY_ENDPOINT + '/' + service_name
        rescue Exception => e
          #
          ServiceDiscovery.logger.debug "Exception: #{e.class} #{e.message}"
        end

        if response.code != 200
          #
          # Attempting to send a heartbeat for an expired instance will result in HTTP status code 410 (Gone).
        end

        response.body
      end

    end
  end
end
