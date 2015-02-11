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
            required: true

    option :port,
            short: '-p PORT',
            description: 'SMTP port to connect to',
            default: 25

    option :tls,
            long: '--tls',
            description: 'Enable STARTTLS',
            boolean: true

    def run
        begin
            if config[:tls]
                Net::SMTP.enable_starttls(OpenSSL::SSL::VERIFY_PEER)
            end
            Net::SMTP.start(config[:host], config[:port], Socket.gethostname)
        rescue Exception => e
            critical "Connection failed: #{e.message}"
        end        
        ok
    end
end
