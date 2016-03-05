# This is an example program that makes use of each of the endpoints defined
# by the Bluemix Service Discovery service.

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ibm/bluemix/service_discovery'

# TODO: you need to replace this with a working auth_token from Bluemix
AUTH_TOKEN = ENV['AUTH_TOKEN']

# create a new service discovery instance using our auth_token from the
# Bluemix Service Discovery credentials
sd = IBM::Bluemix::ServiceDiscovery.new(AUTH_TOKEN)

# register a new microservice with service discovery
# service_name: sample_service
# host: host.ibm.com
# port : 1234
# meta: empty
p "REGISTER"
reference = sd.register('sample_service', 'host.ibm.com:12345', {ttl: 45}, {})
p reference

# send a heatbeat right away
p "RENEW"
reference = sd.renew('sample_service')
p reference

# get a list that should include our newly registered service
p "LIST"
list = sd.list
p list

# discover the service
p "DISCOVER"
reference = sd.discover('sample_service')
p reference

# delete the service
p "DELETE"
reference = sd.delete('sample_service')
# p reference

# get a list that should no longer include the 'sample_service'
p "LIST"
list = sd.list
p list
