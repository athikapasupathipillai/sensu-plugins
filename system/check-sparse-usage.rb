#!/usr/bin/env ruby
#
# check-sparse-usage
#
# DESCRIPTION:
# Check space left on a sparse file (ex: data.mdb)
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
# check-sparse-usage [-f SPARSE_FILE -c PERCENT -w PERCENT]
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

# Enforce UTF8 to avoid 'invalid byte sequence in US-ASCII'
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sensu-plugin/check/cli'

class CheckSparseUsage < Sensu::Plugin::Check::CLI
    option :critical,
            short: '-c PERCENT',
            description: 'Critical if PERCENT or more is used',
            default: 95
    option :warning,
            short: '-w PERCENT',
            description: 'Warn if PERCENT or more is used',
            default: 90
    option :sparse_file,
            short: '-f SPARSE_FILE',
            description: 'Minimal ZeXtras version under which Sensu will throw WARNING error'

    def run
        max_size = `ls -l /opt/zimbra/data/ldap/mdb/db/data.mdb`.split(' ')[4].to_f
        actual_size = (`du /opt/zimbra/data/ldap/mdb/db/data.mdb`.split[0].to_f)*1024
        percent = ((actual_size/max_size)*100).round(2)
        if config[:critical].to_f < percent
            critical "#{percent}% used (#{actual_size.to_i}/#{max_size.to_i})"
        elsif config[:warning].to_f < percent
            warning "#{percent}% used (#{actual_size.to_i}/#{max_size.to_i})"
        else
            ok "#{percent}% used (#{actual_size.to_i}/#{max_size.to_i})"
        end
    end
end
