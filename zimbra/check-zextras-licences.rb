#!/usr/bin/env ruby
#
# check-zextras-licences
#
# DESCRIPTION:
# Check number of Zextras licences left
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
# check-zextras-licences [-c CRITICAL -w WARNING]
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
require 'date'

class CheckZextrasLicences < Sensu::Plugin::Check::CLI
    option :critical,
            short: '-c CRITICAL',
            description: 'How many licences left before throw CRITICAL error',
            default: -1
    option :warning,
            short: '-w WARNING',
            description: 'How many licences left before throw WARING error',
            default: 2

    def run
        licences_info = {}
        output = `sudo -u zimbra /opt/zimbra/bin/zxsuite core getLicenseInfo`.lines

        output.each { |line|
            bits = line.split
            if line.split(' ').length > 1
                key = bits.first.strip
                bits.shift
                value = bits.join(' ')

                licences_info[key] = value
            end
        }

        licences_left = licences_info['licensedUsers'].to_i-licences_info['accountCount'].to_i

        if licences_left <= config[:critical].to_i
            critical "#{licences_left} licences left"
        elsif licences_left <= config[:warning].to_i
            warning "#{licences_left} licences left"
        else
            ok
        end
    end
end
