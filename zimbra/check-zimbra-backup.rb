#!/usr/bin/env ruby
#
# check-zimbra-backup
#
# DESCRIPTION:
# Check Zimbra Network Edition backup for Sensu.
#
# OUTPUT:
# plain text
#
# PLATFORMS:
# Linux
#
# DEPENDENCIES:
# gem: sensu-plugin
# gem: nokogiri
#
# USAGE:
# check-zimbra-backup [-d /path/to/backup/dir/]
#
# NOTES:
#
# LICENSE:
# Emeric MILLION <dev@oasiswork.fr>
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'sensu-plugin/check/cli'


class CheckBackup < Sensu::Plugin::Check::CLI
    # Backup directory path
    option :dir,
            short: '-d DIR',
            default: "/opt/zimbra/backup/"

    def run
        date = `date -d-1day +%Y%m%d`.strip

        backup_info = {}
        output = `sudo -u zimbra /opt/zimbra/bin/zmbackupquery |head -n 7`.lines

        output.each { |line|
            bits = line.split(': ')

            if line.split(' ').length > 1

              key = bits.first.strip
              bits.shift
              value = bits.join(' ').strip

              backup_info[key] = value
            end
        }

        if backup_info["Status"] == 'completed'
            ok "Backup " + backup_info["Label"] + " ended successfully " + backup_info["Ended"]
        else
            critical "Backup " + backup_info["Label"] + " fail"

        end
    end
end
