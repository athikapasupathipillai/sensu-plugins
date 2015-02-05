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
# check-backup-size [-d /path/to/backup/dir/]
#
# NOTES:
#
# LICENSE:
# Emeric MILLION <dev@oasiswork.fr>
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'sensu-plugin/check/cli'
require 'yaml'


class CheckBackupSize < Sensu::Plugin::Check::CLI
    option :dir,
            short: '-d DIR',
            default: "/opt/zimbra/"
    option :cache,
            short: '-C cache',
            description: 'How many times zmcontrol result will be cached',
            default: 0

    def run
        msg = ""
        status_parsed = {}
        # We remove the first line describing the host
        status = `#{config[:dir]}bin/zmcontrol status`.lines.to_a[1..-1]
        # Store status in a hash
        status.each { |line|
            # Get only the service name
            name = line.split(/\s{2,}/)[0]
            # Remove \t
            name = name.tr("\t", '')
            # Remove \n
            name = name.tr("\n", '')
            # Get only the service service_status
            service_status = line.split(/\s{2,}/)[1]
            # Remove \t
            service_status = service_status.tr("\t", '')
            # Remove \n
            service_status = service_status.tr("\n", '')

            status_parsed[name] = service_status
            if service_status != "Running"
                msg += "#{name} is #{service_status};"
            end
        }

        if msg != ""
            critical msg
        else
            ok "All services running"
        end
    end
end

