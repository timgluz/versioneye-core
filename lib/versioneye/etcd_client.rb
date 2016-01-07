require 'singleton'
require 'etcd'

module Versioneye
  class EtcdClient
    include Singleton

    def initialize
      @client = nil

      etcd_ip   = ENV['ETCD_IP']
      etcd_port = ENV['ETCD_PORT']
      etcd_port = 2379 if etcd_port.to_s.empty?

      if !etcd_ip.to_s.empty?
        @client = Etcd.client( host: etcd_ip, port: etcd_port )
      end
    end

    def etcd
      @client
    end

    def setBackendEnvs
      setMongoEnvs
      setRabbitEnvs
    end

    def setRabbitEnvs
      return nil if @client.nil?

      rabbit_ip   = @client.get('/rabbit/ip').value
      rabbit_port = @client.get('/rabbit/port').value

      ENV['RM_PORT_5672_TCP_ADDR'] = rabbit_ip   if !rabbit_ip.to_s.empty?
      ENV['RM_PORT_5672_TCP_PORT'] = rabbit_port if !rabbit_port.to_s.empty?
    end

    def setMongoEnvs
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
