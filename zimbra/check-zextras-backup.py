#!/usr/bin/env python2
#
# check-zextras-backup
#
# DESCRIPTION:
# Check last Zextras backup run and backup options
#
# OUTPUT:
# plain text
#
# PLATFORMS:
# Linux
#
# DEPENDENCIES:
# pip: sensu-plugin
# pip: python-zimbra
#
# USAGE:
# check-zextras-backup [-h HOURS]
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

import subprocess
import json
from datetime import datetime

from pythonzimbra.tools import auth
from pythonzimbra.communication import Communication
from sensu_plugin import SensuPluginCheck


class ZeXtrasBackup(SensuPluginCheck):
    def setup(self):
        self.parser.add_argument(
          '--hours',
          default=25,
          type=int,
          help='Time delta to look for last scan'
        )
        self.parser.add_argument(
          '--api-url',
          default='https://localhost:7071/service',
          help=('URL to access ZeXtras API. Default : '
                'https://localhost:7071/service')
        )

    def get_token(self, url, user, secret, admin_auth):
        return auth.authenticate(
            url, user, secret, admin_auth=admin_auth)

    def run_request(self, creds, req, req_args={}):
        token = self.get_token(
            creds['url'], creds['user'], creds['pwd'], creds['admin_auth'])
        comm = Communication(creds['url'])
        zmreq = comm.gen_request(token=token, request_type="xml")
        zmreq.add_request(req, req_args, creds['urn'])
        resp = comm.send_request(zmreq)
        if resp.is_fault():
            print(resp.get_fault_code())
        ret = resp.get_response()
        return json.loads(ret['response']['content'])

    def get_zimbra_infos(self):
        all_infos = subprocess.check_output([
            'sudo',
            '-u',
            'zimbra',
            '/opt/zimbra/bin/zmlocalconfig',
            '-s',
            'zimbra_server_hostname', 'zimbra_ldap_password'
        ])

        zimbra_server = all_infos.split()[2]
        zimbra_pwd = all_infos.split()[5]

        return zimbra_server, zimbra_pwd

    def run(self):
        # this method is called to perform the actual check

        self.check_name('zextras-backup')
        zimbra_server, zimbra_pwd = self.get_zimbra_infos()

        zm_creds = {
            'zextras': {
                'url': '{}/admin/soap'.format(self.options.api_url),
                'user': 'zimbra',
                'pwd': zimbra_pwd,
                'admin_auth': True,
                'urn': 'urn:zimbraAdmin'
            }
        }

        req = self.run_request(
            zm_creds['zextras'],
            "zextras",
            {
                "module": "ZxBackup",
                "action": "getBackupInfo",
                "targetServers": [{"_content": zimbra_server}]
            }
        )

        curdate = int(datetime.now().strftime("%s")) * 1000
        backup_date = int(req['response'][zimbra_server]['response'][
            'backupStat']['scan']['lastScan']) + (self.options.hours * 60 * 60)

        req = self.run_request(
            zm_creds['zextras'],
            "zextras",
            {
                "module": "ZxBackup",
                "action": "getServices",
                "targetServers": [{"_content": zimbra_server}]
            }
        )

        smartscan_cron = req['response'][zimbra_server]['response'][
            'services']['smartscan-cron']['running']
        redolog = req['response'][zimbra_server]['response'][
            'services']['backup-redolog']['running']

        if not smartscan_cron:
            self.warning('Smartscan cron service is not running')
        elif not redolog:
            stop_cause = req['response'][zimbra_server]['response'][
                'services']['backup-redolog']['could_not_start_because']
            self.warning('Redolog not running. {}'.format(stop_cause))
        elif backup_date == 0:
            self.critical('No backup at all')
        elif backup_date > curdate:
            self.critical(
                "No backup for the last {} hours". format(self.options.hours))
        else:
            self.ok()

if __name__ == "__main__":
    f = ZeXtrasBackup()
