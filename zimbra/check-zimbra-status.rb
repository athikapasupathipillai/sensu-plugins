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
# Authors:
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
        status.each { |line|
            service_name = line.split(/\s{2,}/)[0].strip
            service_status = line.split(/\s{2,}/)[1].strip.upcase

            status[service_name] = service_status
            if service_status != "Running"
                msg += "#{name} is #{service_status};"
            end
        }

        if msg != ""
            critical msg
        else
            ok
        end
    end
end

