#!/usr/bin/env ruby
#
# check-smtp
#
# DESCRIPTION:
# Check SMTP connection to a server
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
# check-smtp -h HOST [-p PORT] [-H HELO ]
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
# Nicolas BRISAC <nbrisac@oasiswork.fr>

require 'sensu-plugin/check/cli'
require 'date'

class CheckZextrasBackup < Sensu::Plugin::Check::CLI
    option :host,
            short: '-h HOST',
            description: 'SMTP host to connect to'

    option :port,
            short: '-p PORT',
            description: 'SMTP port to connect to',
            default: 25

    option :helo,
            short: '-H HELO',
            description: 'SMTP helo to submit when connecting',
            default: 'localhost'

    def run
        begin
            Net::SMTP.start(config[':host'], config[':port'], config[':helo'])
            ok
        rescue Exception => e
            critical "Connection failed: #{e.message}"
        end        
    end
end
