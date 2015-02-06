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


require 'nokogiri'
require 'sensu-plugin/check/cli'


class CheckBackup < Sensu::Plugin::Check::CLI
    # Backup directory path
    option :dir,
            short: '-d DIR',
            default: "/opt/zimbra/backup/"

    def run
        date = Time.new.strftime("%Y%m%d")
        
        daily_bak_dir = Dir[config[:dir]+"sessions/*"+date+"*"][0]
        
        if daily_bak_dir.nil? or daily_bak_dir.empty?
            critical "No backup today in "+config[:dir]

        else
            daily_bak_session = daily_bak_dir+"/session.xml"
        
            @doc = Nokogiri::XML(File.read(daily_bak_session))
        
            begin
                msg = @doc.xpath('//xmlns:message')[0].to_str.split(":")[1]
                warning msg
            rescue
                ok "No error on backup"
            end
        end
    end
end
