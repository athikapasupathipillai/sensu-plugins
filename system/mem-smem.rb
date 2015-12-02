#! /usr/bin/env ruby
#
#   netif-metrics
#
# DESCRIPTION:
#   Network interface throughput
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
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Sonian, Inc. and contributors. <support@sensuapp.org>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'

class NetIFMetrics < Sensu::Plugin::Metric::CLI::Graphite
  client_conf = File.read('/etc/sensu/conf.d/client.json')
  client_conf_hash = JSON.parse(client_conf)
  sensu_name = client_conf_hash['client']['name']

  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{sensu_name}"

  def run
    # #YELLOW
    `smem -tw |grep -v Area | sed 's/ //;s/ //'`.each_line do |line|  # rubocop:disable Style/Next
      stats = line.split(/\s+/)
      unless stats.empty?
        if stats[0] == ""
            output "#{config[:scheme]}.smem.total.used", stats[1].to_f if stats[2]
            output "#{config[:scheme]}.smem.total.cache", stats[2].to_f if stats[2]
            output "#{config[:scheme]}.smem.total.noncache", stats[3].to_f if stats[2]
        else
            output "#{config[:scheme]}.smem.#{stats[0]}.used", stats[1].to_f if stats[2]
            output "#{config[:scheme]}.smem.#{stats[0]}.cache", stats[2].to_f if stats[2]
            output "#{config[:scheme]}.smem.#{stats[0]}.noncache", stats[3].to_f if stats[2]

        end
      end
    end

    ok
  end
end
