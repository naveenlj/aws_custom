#!/usr/bin/env python
#
# Copyright 2012, 42Lines, Inc.
# Original Author: Jim Browne
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import boto
from boto.ec2 import regions
from optparse import OptionParser

VERSION = "1.0"
usage = """%prog [options]

For each instance in the given regions, look up the AMI, then look up
the AMI name and tag the instance with that value in an OS tag

"""

ami_cache = {}


def shorten_name(name):

    name = name.replace('ubuntu/images/', '')
    name = name.replace('ubuntu-images/', '')
    name = name.replace('ebs/', '')

    return name


def ami_lookup(options, connection, id):
    if options.debug:
        print "Looking up AMI ID %s" % id

    if id in ami_cache:
        if options.debug:
            print "AMI ID in cache"
        return ami_cache[id]

    ami = connection.get_image(id)
    if ami and ami.name:
        if options.debug:
            print "AMI ID found, name is %s" % ami.name
        name = shorten_name(ami.name)
        ami_cache[id] = name
        return name

    if options.debug:
        print "AMI not found"
    return None


def tag_instances(options, region):
    ec2 = boto.connect_ec2(region=region)
    for r in ec2.get_all_instances():
        for i in r.instances:
            if options.trace:
                print "Looking up AMI %s for instance %s" % (i.image_id, i.id)
            value = ami_lookup(options, ec2, i.image_id)

            if value:
                if options.trace:
                    print "Tagging %s with %s=%s" % (i.id, options.key, value)
                i.add_tag(options.key, value)

if __name__ == '__main__':
    import sys

    # Need get_all_instance filter option starting with Boto 2.0
    desired = '2.0'
    try:
        from pkg_resources import parse_version
        if parse_version(boto.__version__) < parse_version(desired):
            print 'Boto version %s or later is required' % desired
            print 'Try: sudo easy_install boto'
            sys.exit(-1)
    except (AttributeError, NameError):
        print 'Boto version %s or later is required' % desired
        print 'Try: sudo easy_install boto'
        sys.exit(-1)

    parser = OptionParser(version=VERSION, usage=usage)
    parser.add_option("--tagname",
                      help="Name to use for tag (default: os)",
                      default='os',
                      dest="key")
    parser.add_option("--region",
                      help="Region to tag (default: us-east-1)",
                      default=[],
                      action="append", dest="region")
    parser.add_option("--all",
                      help="Tag in all regions",
                      action="store_true", dest="allregions")
    parser.add_option("--debug",
                      help="Emit copious information to aid script debugging",
                      action="store_true", dest="debug")
    parser.add_option("--trace",
                      help="Trace execution steps",
                      action="store_true", dest="trace")

    (options, args) = parser.parse_args()

    if options.debug:
        options.trace = 1

    if not options.region:
        options.region = ["us-east-1"]

    if options.allregions:
        regs = regions()
    else:
        regs = []
        for ropt in options.region:
            for r in regions():
                if r.name == ropt:
                    regs.append(r)
                    break
            else:
                print "Region %s not found." % ropt
                sys.exit(-1)

    for r in regs:
        tag_instances(options, r)
