#!/usr/bin/env ruby
#  encoding: UTF-8
#
# RabbitMQ Queue messages watcher
# ===
#
# DESCRIPTION:
# This plugin checks if the number of messages is the same as previous check
#
# PLATFORMS:
#   Linux, BSD, Solaris
#
# DEPENDENCIES:
#   RabbitMQ rabbitmq_management plugin
#   gem: sensu-plugin
#   gem: carrot-top
#
# LICENSE:
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'socket'
require 'carrot-top'

# main plugin class
class RabbitMQMessagesNumber < Sensu::Plugin::Check::CLI
  option :host,
         description: 'RabbitMQ management API host',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'RabbitMQ management API port',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 15_672

  option :vhost,
         description: 'Regular expression for filtering the RabbitMQ vhost',
         short: '-v',
         long: '--vhost VHOST'

  option :user,
         description: 'RabbitMQ management API user',
         long: '--user USER',
         default: 'guest'

  option :password,
         description: 'RabbitMQ management API password',
         long: '--password PASSWORD',
         default: 'guest'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to $queue_name.$metric',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.rabbitmq"

  option :filter,
         description: 'Regular expression for filtering queues',
         long: '--filter REGEX'

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  def acquire_rabbitmq_queues
    begin
      rabbitmq_info = CarrotTop.new(
        host: config[:host],
        port: config[:port],
        user: config[:user],
        password: config[:password],
        ssl: config[:ssl]
      )
    rescue
      warning 'could not get rabbitmq queue info'
    end

    if config[:vhost]
      return rabbitmq_info.queues.select { |x| x['vhost'].match(config[:vhost]) }
    end

    rabbitmq_info.queues
  end

  def run
    acquire_rabbitmq_queues.each do |queue|
      if config[:filter]
        next unless queue['name'].match(config[:filter])
      end

      # calculate and output time till the queue is drained in drain metrics
      queue['messages'] ||= 0

      tmp_file = '/tmp/sensu_' + queue['name'] + '.tmp'

      current_value = queue['messages'].to_s

      if File.exist?(tmp_file) then
          previous_value = File.read(tmp_file)

          if current_value == '0' then
              message 'queue is empty'
          elsif previous_value == current_value then
              message 'queue still at ' + current_value
              critical
          else
              File.open(tmp_file, 'w') { |file| file.write(current_value) }
              message 'value has changed since last time'
          end
      else
          File.open(tmp_file, 'w') { |file| file.write(current_value) }
          message 'first run'
      end

    end
    ok
  end
end
