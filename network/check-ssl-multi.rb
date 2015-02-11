#!/usr/bin/env ruby
# encoding: UTF-8
#  check-ssl-host.rb
#
# DESCRIPTION:
#   SSL certificate checker
#   Connects to a HTTPS (or other SSL) server and performs several checks on
#   the certificate:
#     - Is the hostname valid for the host we're requesting
#     - If any certificate chain is presented, is it valid (i.e. is each
#       certificate signed by the next)
#     - Is the certificate about to expire
#   Currently no checks are performed to make sure the certificate is signed
#   by a trusted authority.
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   # Basic usage
#   check-ssl-host.rb -h <hostname>
#   # Specify specific days before cert expiry to alert on
#   check-ssl-host.rb -h <hostmame> -c <critical_days> -w <warning_days>
#   # Use -p to specify an alternate port
#   check-ssl-host.rb -h <hostname> -p 8443
#   # Use --skip-hostname-verification and/or --skip-chain-verification to
#   # disable some of the checks made.
#   check-ssl-host.rb -h <hostname> --skip-chain-verification
#
# LICENSE:
#   Copyright 2014 Chef Software, Inc.
#   Released under the same terms as Sensu (the MIT license); see LICENSE for
#   details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'date'
require 'openssl'
require 'socket'

class CheckSSLMulti < Sensu::Plugin::Check::CLI
  check_name 'check_ssl_multi'

  option :critical,
         description: 'Return critical this many days before cert expiry',
         short: '-c',
         long: '--critical DAYS',
         proc: proc(&:to_i),
         default: 7

  option :warning,
         description: 'Return warning this many days before cert expiry',
         short: '-w',
         long: '--warning DAYS',
         required: true,
         proc: proc(&:to_i),
         default: 14

  option :host,
         description: 'Hostnames of servers to check',
         short: '-h',
         long: '--hosts HOST',
         required: true

  option :port,
         description: 'Port on servers to check',
         short: '-p',
         long: '--port PORT',
         default: 443

  option :skip_hostname_verification,
         description: 'Disables hostname verification',
         long: '--skip-hostname-verification',
         boolean: true

  option :skip_chain_verification,
         description: 'Disables certificate chain verification',
         long: '--skip-chain-verification',
         boolean: true

  def get_cert_chain(host, port)
    tcp_client = TCPSocket.new(host, port)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
    # SNI
    ssl_client.hostname = host if ssl_client.respond_to? :hostname=
    ssl_client.connect
    certs = ssl_client.peer_cert_chain
    ssl_client.close
    certs
  end

  def verify_expiry(cert, host)
    # Expiry check
    days = (cert.not_after.to_date - Date.today).to_i
    message = "#{host} - #{days} days until expiry"
    return 2, "#{host} - Expired #{days} days ago" if days < 0
    return 2, message if days < config[:critical]
    return 1, message if days < config[:warning]
    return 0, ''
  end

  def verify_certificate_chain(certs, host)
    # Validates that a chain of certs are each signed by the next
    # NOTE: doesn't validate that the top of the chain is signed by a trusted
    # CA.
    valid = true
    parent = nil
    certs.reverse.each do |c|
      if parent
        valid &= c.verify(parent.public_key)
      end
      parent = c
    end
    return 2, "#{host} - Invalid certificate chain" unless valid
    return 0, ''
  end

  def verify_hostname(cert, host)
    unless OpenSSL::SSL.verify_certificate_identity(cert, host)
      return 2, "#{host} hostname mismatch (#{cert.subject})"
    end
    return 0, ''
  end

  def run
    results = {
      'hostname' => {
        'code' => 0,
        'message' => ''
      },
      'chain' => {
        'code' => 0,
        'message' => ''
      },
      'expiry' => {
        'code' => 0,
        'message' => ''
      }
    }

    config[:hosts].split(',').each { |host|
      chain = get_cert_chain(host, config[:port])

      ret, msg = verify_hostname(chain[0], host) unless config[:skip_hostname_verification]
      results['hostname']['code'] = ret if ret > results['hostname']['code']
      results['hostname']['message'] += "#{msg}; " if msg != ''

      ret, msg = verify_certificate_chain(chain, host) unless config[:skip_chain_verification]
      results['chain']['code'] = ret if ret > results['chain']['code']
      results['chain']['message'] += "#{msg}; " if msg != ''

      ret, msg = verify_expiry(chain[0], host)
      results['expiry']['code'] = ret if ret > results['expiry']['code']
      results['expiry']['message'] += "#{msg}; " if msg != ''
    }

    code = [results['hostname']['code'], results['chain']['code'], results['expiry']['code']].max
    message = results['hostname']['message'] + results['chain']['message'] + results['expiry']['message']

    puts "Sensu::Plugin::CLI: #{message}"
    exit(code)
  end
end
