#!/usr/bin/env ruby
#
# check-backup-size
#
# DESCRIPTION:
# Check returning sizes of Zimbra Network Edition backup for Sensu.
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
# check-backup-size [-d /path/to/backup/dir/]
#
# NOTES:
#
# LICENSE:
# Emeric MILLION <dev@oasiswork.fr>
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'nokogiri'
require 'sensu-plugin/check/cli'


class CheckBackupSize < Sensu::Plugin::Check::CLI
    # Backup directory path
    option :dir,
            short: '-d DIR',
            default: "/opt/zimbra/backup/"

    def run

        metrics = [:ldap_bytes, :redologs_bytes, :db_bytes, :sysdb_bytes]

        date = Time.new.strftime("%Y%m%d")
        
        daily_bak_dir = Dir[config[:dir]+"sessions/*"+date+"*"][0]
        
        if daily_bak_dir.nil? or daily_bak_dir.empty?
            critical "No backup today in "+config[:dir]

        else
            daily_bak_session = daily_bak_dir+"/session.xml"

            msg = ""

            @doc = Nokogiri::XML(File.read(daily_bak_session))

            @doc.xpath('//xmlns:counter').each { |line|

                metrics.each { |metric|
                    if line["name"] == metric.to_s
                        config[metric] = line['sum'].to_i
                        msg += "#{metric.to_s}=#{line['sum']} "
                    end
                }
            }

            total_bytes = config[:ldap_bytes]+config[:redologs_bytes]+config[:db_bytes]+config[:sysdb_bytes]
            ok "total_bytes : #{total_bytes} "+msg
        end
    end
end
