#!/usr/bin/env python

import subprocess
import datetime

from sensu_plugin import SensuPluginCheck


class MailqSize(SensuPluginCheck):
    def setup(self):
        self.parser.add_argument(
          '--ignore-quota',
          action='store_true',
          help=('don\'t count over quota messages')
        )

        self.parser.add_argument(
            '-p',
            '--mailq-path',
            default='/usr/bin/mailq',
            help=('Path to the postfix mailq binary.'
                         'Defaults to /usr/bin/mailq')
        )

        self.parser.add_argument(
          '-w',
          '--warning',
          type=int,
          default=30,
          help=('Number of messages in the queue considered to be a warning')
        )

        self.parser.add_argument(
          '-c',
          '--critical',
          type=int,
          default=40,
          help=('Number of messages in the queue considered to be an error')
        )

    def call_mailq(self):
        '''
        Call mailq and return stdout as a string
        '''
        cmd = subprocess.Popen(
            [self.options.mailq_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        stdout, stderr = cmd.communicate()
        return stdout.strip()

    def remove_over_quota(self, msgs):
        msgs_filtered = {}
        for queue_id, data in msgs.items():
            if 'quota' not in data['reason']:
                msgs_filtered[queue_id] = data

        return msgs_filtered

    def parse_mq(self):
        '''
        Parse mailq output and return data as a dict.
        '''
        mailq_stdout = self.call_mailq()
        curmsg = None
        msgs = {}
        for line in mailq_stdout.splitlines():
            if not line or line[:10] == '-Queue ID-' or line[:2] == '--':
                continue
            if line[0] in '0123456789ABCDEF':
                s = line.split()
                curmsg = s[0]
                if curmsg[-1] == '*':
                    status = 'active'
                    curmsg = curmsg[:-1]
                else:
                    status = 'deferred'
                msgs[curmsg] = {
                    'size': s[1],
                    'rawdate': ' '.join(s[2:6]),
                    'sender': s[-1],
                    'reason': '',
                    'status': status,
                    }
                msgs[curmsg]['date'] = datetime.datetime.strptime(
                    msgs[curmsg]['rawdate'], '%a %b %d %H:%M:%S')
            elif '@' in line: # XXX: pretty dumb check
                msgs[curmsg]['recipient'] = line.strip()
            elif line.lstrip(' ')[0] == '(':
                msgs[curmsg]['reason'] = line.strip()[1:-1].replace('\n', ' ')
        return msgs

    def run(self):
        '''
        Main function
        '''

        # Load messages
        msgs = {}
        msgs.update(self.parse_mq())

        # remove unimportant messages
        if self.options.ignore_quota:
            msgs = self.remove_over_quota(msgs)

        queue_size = len(msgs.keys())
        if queue_size > self.options.critical:
            self.critical(
                '{} messages in queue after possible filters'.format(
                    queue_size)
                )
        elif queue_size > self.options.warning:
            self.warning(
                '{} messages in queue after possible filters'.format(
                    queue_size)
                )
        else:
            self.ok(
                '{} messages in queue after possible filters'.format(
                    queue_size)
                )

if __name__ == "__main__":
    f = MailqSize()
