require 'singleton'

module Versioneye
  class Etcd
    include Singleton

    def initialize
      @client = nil

      etcd_ip   = ENV['ETCD_IP']
      etcd_port = ENV['ETCD_PORT']

      if !etcd_id.to_s.empty?
        @client = Etcd.client( host: etcd_id, port: etcd_port )
      end
    end

    def client
      @client
    end

    def setBackendEnvs
      return nil if @client.nil?

      mongo1_ip = @client.get('/mongodb/replica/host1/ip').value
      mongo2_ip = @client.get('/mongodb/replica/host2/ip').value
      mongo3_ip = @client.get('/mongodb/replica/host3/ip').value

      mongo1_port = @client.get('/mongodb/replica/host1/port').value
      mongo2_port = @client.get('/mongodb/replica/host2/port').value
      mongo3_port = @client.get('/mongodb/replica/host3/port').value

      ENV['DB_PORT_27017_TCP_ADDR'] = mongo1_ip   if !mongo1_ip.to_s.empty?
      ENV['DB_PORT_27017_TCP_PORT'] = mongo1_port if !mongo1_port.to_s.empty?

      ENV['MONGO_RS_2_ADDR'] = mongo2_ip   if !mongo2_ip.to_s.empty?
      ENV['MONGO_RS_2_PORT'] = mongo2_port if !mongo2_port.to_s.empty?

      ENV['MONGO_RS_3_ADDR'] = mongo3_ip   if !mongo3_ip.to_s.empty?
      ENV['MONGO_RS_3_PORT'] = mongo3_port if !mongo3_port.to_s.empty?
    end

  end
end
