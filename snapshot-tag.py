#!/usr/bin/env python
from boto import ec2
from boto import utils
from datetime import datetime, timedelta

region = utils.get_instance_metadata()['placement']['availability-zone'][:-1]
conn = ec2.connect_to_region(region)
instance_id = utils.get_instance_metadata()['instance-id']

def get_volumes():
	volumes = []
	volumes = [v for v in conn.get_all_volumes() if v.attach_data.instance_id == instance_id]
	return volumes

def main():
	volumes = get_volumes()
	for volume in volumes:
		description =  "%s - %s" % (volume.attach_data.device, datetime.utcnow())
		if not volume.tags.get('Name'):
			print "Volume sem tag, adicionando..."
			volume.add_tag('Name', instance_id)

		snap = conn.create_snapshot(volume.id, description=description)
		print "Snapshot - %s " % snap.id

if __name__ == '__main__':
	main()
