#!/usr/bin/env ruby
#
# check-zimbra-version
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
# check-zimbra-version [-z ZIMBRA_VERSION -p PATCH_VERSION]
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

class CheckZimbraVersion < Sensu::Plugin::Check::CLI
    option :zimbra,
            short: '-z ZIMBRA',
            description: 'Minimal Zimbra version under which Sensu will throw CRITICAL error',
            default: "8.6.0"
    option :patch,
            short: '-p PATCH_VERSION',
            description: 'Minimal patch version under which Sensu will throw WARNING error',
            default: "1153"

    def run
        full_version = `dpkg -l zimbra-core |grep zimbra |awk '{print $3}' |awk -F ".UB" '{print $1}'`.gsub("\n",'')

        zimbra_version = Versionomy.parse(full_version.split(/.GA./)[0])
        patch_version = Versionomy.parse(full_version.split(/.GA./)[1])

        if zimbra_version < config[:zimbra]
            critical "Zimbra version is #{zimbra_version} (#{config[:zimbra]} required)"
        elsif patch_version < config[:patch]
            critical "Patch version is #{patch_version} (#{config[:patch]} required)"
        else
            ok
        end
    end
end
