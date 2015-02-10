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

class CheckZextrasBackup < Sensu::Plugin::Check::CLI
    option :hours,
            short: '-h HOURS',
            description: 'Time delta to look for last scan',
            default: 25

    def run
        backup_info = {}
        output = `sudo -u zimbra /opt/zimbra/bin/zxsuite backup getBackupInfo`.lines

        output.each { |line|
            if line.split(' ').length > 1
                key = line.split.first.strip
                value = line.split.last.strip

                backup_info[key] = value
            end
        }

        curdate = DateTime.now.strftime("%s").to_i

        smartscan_cron = `sudo -u zimbra /opt/zimbra/bin/zxsuite backup getServices | grep -A3 "smartscan-cron" | grep running`.split.last.strip.upcase
        realtime_scanner = `sudo -u zimbra /opt/zimbra/bin/zxsuite backup getProperty ZxBackup_RealTimeScanner`.split()[1].upcase

        if smartscan_cron != 'TRUE'
            warning "Smartscan cron service is not running"
        elsif realtime_scanner != 'TRUE'
            warning "RealTime Scanner is disabled"
        elsif DateTime.strptime(backup_info["lastScan"], "%Y-%m-%d %H:%M:%S %Z").to_time.to_i+(config[:hours].to_i*60*60) > date
            ok
        elsif backup_info["firstScan"] == "0"
            critical "No backup at all"
        else
            critical "No backup for the last #{config[:hours]}H"
        end
    end
end
