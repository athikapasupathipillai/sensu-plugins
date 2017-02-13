#!/usr/bin/env python2
#
# check-zextras-version
#
# DESCRIPTION:
# Check ZeXtras version
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

import subprocess
import json
from distutils.version import StrictVersion

from pythonzimbra.tools import auth
from pythonzimbra.communication import Communication
from sensu_plugin import SensuPluginCheck


class ZeXtrasVersion(SensuPluginCheck):
    def setup(self):
        self.parser.add_argument(
          '--api-url',
          default='https://localhost:7071/service',
          help=('URL to access ZeXtras API. Default : '
                'https://localhost:7071/service')
        )

        self.parser.add_argument(
          '-w',
          '--warning',
          default="1.0.0",
          help=('Minimal ZeXtras version under which Sensu will throw '
                'WARNING error')
        )

        self.parser.add_argument(
          '-c',
          '--critical',
          default="1.0.0",
          help=('Minimal ZeXtras version under which Sensu will throw '
                'CRITICAL error')
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

        self.check_name('zextras-version')
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
                "module": "ZxCore",
                "action": "getVersion",
                "targetServers": [{"_content": zimbra_server}]
            }
        )

        actual_version = req[
            'response'][zimbra_server]['response']['version']

        if StrictVersion(actual_version) <= StrictVersion(
                self.options.critical):
            self.critical('Actual version : {}. Needed : {}'.format(
                actual_version,
                self.options.critical
            ))
        elif StrictVersion(actual_version) <= StrictVersion(
                self.options.warning):
            self.warning('Actual version : {}. Needed : {}'.format(
                actual_version,
                self.options.warning
            ))

        else:
            self.ok('Actual version : {}'.format(actual_version))

if __name__ == "__main__":
    f = ZeXtrasVersion()
