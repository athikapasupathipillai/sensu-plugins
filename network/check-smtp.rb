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
require 'net/smtp'

class CheckSMTP < Sensu::Plugin::Check::CLI
    option :host,
            short: '-h HOST',
            description: 'SMTP host to connect to'

    option :port,
            short: '-p PORT',
            description: 'SMTP port to connect to',
            default: 25

    def run
        begin
            Net::SMTP.start(config[:host], config[:port], Socket.gethostname)
        rescue Exception => e
            critical "Connection failed: #{e.message}"
        end        
        ok
    end
end
