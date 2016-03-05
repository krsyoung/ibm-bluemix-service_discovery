require 'spec_helper'
require 'byebug'

describe IBM::Bluemix::ServiceDiscovery do
  subject { IBM::Bluemix::ServiceDiscovery.new(ENV['AUTH_TOKEN']) }

  describe '#register' do
    let(:service_name) { 'sample_service' }
    let(:host) { 'example.test.mybluemix.net:12345' }
    let(:output) { subject.register( service_name, host, {ttl: 30}, {} ) }

    it 'registers' do
      expect(output).to be_a(Hash)
      expect(output).to include('id', 'ttl', 'links')
    end
  end

  describe '#renew' do
    let(:service_name) { 'sample_service' }
    let(:output) { subject.renew( service_name ) }

    it 'renews' do
      expect(output).to be(true)
    end
  end

  describe '#list' do
    let(:output) { subject.list }

    it 'list' do
      expect(output).to be_a(Hash)
      expect(output).to include('services')
      expect(output['services']).to include('sample_service')
    end
  end

  describe '#discover' do
    let(:service_name) { 'sample_service' }
    let(:output) { subject.discover(service_name) }

    it 'discovers' do
      expect(output).to be_a(Hash)
      expect(output).to include('service_name', 'instances')
      expect(output['service_name']).to eq(service_name)
      expect(output['instances']).to be_an(Array)
    end
  end

  describe '#delete' do
    let(:service_name) { 'sample_service' }
    let(:output) { subject.delete(service_name) }

    it 'deletes' do
      expect(output).to be(true)
    end
  end

  # tests for the module

  it 'has a version number' do
    expect(IBM::Bluemix::ServiceDiscovery::VERSION).not_to be nil
  end

end
