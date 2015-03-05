# Copyright 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
import uuid

def set_log_url(item, job, params):
    if hasattr(item.change, 'refspec'):
        path = "%s/%s/%s/%s" % (
            params['ZUUL_CHANGE'][-2:], params['ZUUL_CHANGE'],
            params['ZUUL_PATCHSET'], params['ZUUL_PIPELINE'])
    elif hasattr(item.change, 'ref'):
        path = "%s/%s/%s" % (
            params['ZUUL_NEWREV'][:2], params['ZUUL_NEWREV'],
            params['ZUUL_PIPELINE'])
    else:
        path = params['ZUUL_PIPELINE']
    params['BASE_LOG_PATH'] = path
    params['LOG_PATH'] = path + '/%s/%s' % (job.name,
                                            params['ZUUL_UUID'][:7])


def single_use_node(item, job, params):
    set_log_url(item, job, params)
    if job.name != "sahara-ci-syntax-check":
        params['OFFLINE_NODE_WHEN_COMPLETE'] = '1'


def set_ci_tenant(item, job, params):
    single_use_node(item, job, params)
    params['NEUTRON_LAB_TENANT_ID'] = '-CI_LAB_TENANT_ID-'
    params['NOVA_NET_LAB_TENANT_ID'] = '-STACK_SAHARA_TENANT_ID-'
    params['CLUSTER_HASH'] = str(uuid.uuid4()).split('-')[0]
