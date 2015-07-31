#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   interface-metrics
#
# DESCRIPTION:
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2012 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'
require 'json'

class InterfaceGraphite < Sensu::Plugin::Metric::CLI::Graphite
  client_conf = File.read('/etc/sensu/conf.d/client.json')
  client_conf_hash = JSON.parse(client_conf)
  sensu_name = client_conf_hash['client']['name']

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{sensu_name}.interface"

  option :excludeinterface,
         description: 'List of interfaces to exclude',
         short: '-x INTERFACE[,INTERFACE]',
         long: '--exclude-interface',
         proc: proc { |a| a.split(',') }

  def run
    # Metrics borrowed from hoardd: https://github.com/coredump/hoardd

    metrics = %w(rxBytes
                 rxPackets
                 rxErrors
                 rxDrops
                 rxFifo
                 rxFrame
                 rxCompressed
                 rxMulticast
                 txBytes
                 txPackets
                 txErrors
                 txDrops
                 txFifo
                 txColls
                 txCarrier
                 txCompressed)

    File.open('/proc/net/dev', 'r').each_line do |line|
      interface, stats_string = line.scan(/^\s*([^:]+):\s*(.*)$/).first
      next if config[:excludeinterface] && config[:excludeinterface].find { |x| line.match(x) }
      next unless interface
      if interface.is_a?(String)
        interface = interface.gsub('.', '_')
      end

      stats = stats_string.split(/\s+/)
      next if stats == ['0'].cycle.take(stats.size)

      metrics.size.times { |i| output "#{config[:scheme]}.#{interface}.#{metrics[i]}", stats[i] }
    end

    ok
  end
end
