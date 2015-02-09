#!/usr/bin/env ruby
#
# check-zextras-backup
#
# DESCRIPTION:
# Check Zimbra Zextras backup for Sensu.
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
# check-zextras-backup [-d /path/to/backup/dir/]
#
# NOTES:
#
# LICENSE:
# Emeric MILLION <dev@oasiswork.fr>
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'sensu-plugin/check/cli'
require 'date'

class CheckBackup < Sensu::Plugin::Check::CLI
    # Backup directory path
    option :dir,
            short: '-d DIR',
            default: "/opt/zimbra/bin/"
    option :hours,
            short: '-h HOURS',
            default: 25

    def run
        infos_parsed = {}
        infos_without_one_words = ""
        #infos = `#{config[:dir]}zxsuite backup getBackupInfo`.lines.to_a[1..-1]
        infos = `#{config[:dir]}zxsuite backup getBackupInfo`.lines
        # Keep only lines not including lines with less than one word
        infos.each { |line|
            if line.split(' ').length > 1
                infos_without_one_words += line
            end
        }

        infos_without_one_words.lines.to_a[0..-1].each { |line|
            # Get only the service name
            name = line.split(/\s{2,}/)[1]
            # Remove \t
            name = name.tr("\t", '')
            # Remove \n
            name = name.tr("\n", '')
            # Get only the key
            info_key = line.split(/\s{2,}/)[2]
            # Remove \t
            info_key = info_key.tr("\t", '')
            # Remove \n
            info_key = info_key.tr("\n", '')

            infos_parsed[name] = info_key

        }

        date = DateTime.now.strftime("%s").to_i

        smart_scan = `#{config[:dir]}zxsuite backup getServices |grep -A3 "smartscan-cron" |grep running`.split()

        if smart_scan[1] == "false"
            warning "Smart_scan is Not running"
        elsif DateTime.strptime(infos_parsed["lastScan"], "%Y-%m-%d %H:%M:%S %Z").to_time.to_i+(config[:hours].to_i*60*60) > date
            ok "Backup scan done (at least) #{config[:hours]}H from now"
        elsif infos_parsed["firstScan"] == "0"
            critical "No backup scan at all"
        else
            critical "No backup scan since #{config[:hours]}H"
        end
    end
end
