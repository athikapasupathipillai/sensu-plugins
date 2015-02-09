#!/usr/bin/env ruby
#
# check-backup-size
#
# DESCRIPTION:
# Check if all Zimbra services of this server are running.
#
# OUTPUT:
# plain text
#
# PLATFORMS:
# Linux
#
# DEPENDENCIES:
# gem: sensu-plugin
#
# USAGE:
# check-zimbra-status
#
# NOTES:
#
# LICENSE:
# Oasiswork <dev@oasiswork.fr>
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# AUTHORS:
# Emeric MILLION <emillion@oasiswork.fr>
# Nicolas BRISAC <nbrisac@oasiswork.fr>

require 'sensu-plugin/check/cli'
require 'yaml'


class CheckZimbraStatus < Sensu::Plugin::Check::CLI
    def run
        msg = ""
        status = {}
        # We remove the first line describing the host
        output = `su - zimbra -c '/opt/zimbra/bin/zmcontrol status'`.lines.to_a[1..-1]
        # Store statuses in a hash
        service_name = ''
        output.each { |line|
            bits = line.split
            if bits.length.between?(2, 3)
                if bits.length == 2
                    service_name = bits.first.strip
                else
                    service_name = bits.take(2).join('_')
                end
                service_status = bits.last.strip.upcase
                status[service_name] = {}
                status[service_name]['status'] = service_status
                status[service_name]['details'] = []
            else
                status[service_name]['details'].push(line.strip)
            end
        }
        puts(status)

        status.each { |k,v|
            if v['status'] != "RUNNING"
                msg += "#{k} is #{v['status']} (#{v['details'].join('; ')})"
            end
        }

        if msg != ""
            critical msg
        else
            ok
        end
    end
end
