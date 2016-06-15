#!/usr/bin/env ruby
#
# check-zextras-version
#
# DESCRIPTION:
# Check number of Zextras version left
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
# check-zextras-version [-c CRITICAL -w WARNING]
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
require 'versionomy'

class CheckZextrasVersion < Sensu::Plugin::Check::CLI
    option :critical,
            short: '-c CRITICAL',
            description: 'Minimal ZeXtras version under which Sensu will throw CRITICAL error',
            default: "1.0.0"
    option :warning,
            short: '-w WARNING',
            description: 'Minimal ZeXtras version under which Sensu will throw WARNING error',
            default: "1.0.0"

    def run
        version_info = {}
        output = `sudo -u zimbra /opt/zimbra/bin/zxsuite core getVersion`.lines

        output.each { |line|
            bits = line.split
            if line.split(' ').length > 1
                key = bits.first.strip
                bits.shift
                value = bits.join(' ')

                version_info[key] = value
            end
        }

        if Versionomy.parse(version_info['zextras_version']) < Versionomy.parse(config[:critical])
            critical "ZeXtras version is #{version_info['zextras_version']} (#{config[:critical]} required)"
        elsif Versionomy.parse(version_info['zextras_version']) < Versionomy.parse(config[:warning])
            critical "ZeXtras version is #{version_info['zextras_version']} (#{config[:warning]} recommended)"
        else
            ok
        end
    end
end
