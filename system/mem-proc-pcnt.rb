#! /usr/bin/env ruby
#
#   mem-proc-pcnt
#
# DESCRIPTION:
#   Get percentage of memory used by process
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
    pcnt_mem = `ps aux |awk '{s+=$4} END {print s}'`
    pcnt_mem = pcnt_mem.split(/\s+/)
      output "#{config[:scheme]}.mem_pcnt_process_used", pcnt_mem

    ok
  end
end
