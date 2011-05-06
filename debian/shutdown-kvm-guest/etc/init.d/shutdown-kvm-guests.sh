#!/bin/sh
### BEGIN INIT INFO
# Provides:          shutdown-kvm-guests
# Required-Start:    
# Required-Stop:     shutdown-kvm-guests $remote_fs
# Should-Stop:
# Default-Start:
# Default-Stop:      0 1 6
# Short-Description: Cleanly shut down all running KVM domains.
# Description:
### END INIT INFO
# Inspired by https://bugs.launchpad.net/ubuntu/+source/libvirt/+bug/350936.

# Configure timeout (in seconds).
TIMEOUT=300
VIRSH=/usr/bin/virsh

# List running domains.
list_running_domains() {
	$VIRSH list | grep running | awk '{ print $2}'
}

case "$1" in
	start,reload,restart,force-reload)
		# We don't do anything here.
		;;

	stop)
		echo "Try to cleanly shut down all running KVM domains..."

		# Create some sort of semaphore.
		touch /tmp/shutdown-kvm-guests

		# Try to shutdown each domain, one by one.
		list_running_domains | while read DOMAIN; do
			# Try to shutdown given domain.
			$VIRSH shutdown $DOMAIN
		done

		# Wait until all domains are shut down or timeout has reached.
		END_TIME=$(date -d "$TIMEOUT seconds" +%s)

		while [ $(date +%s) -lt $END_TIME ]; do
			# Break while loop when no domains are left.
			test -z "$(list_running_domains)" && break
			# Wait a litte, we don't want to DoS libvirt.
			sleep 1
		done

		# Clean up left over domains, one by one.
		list_running_domains | while read DOMAIN; do
			# Try to shutdown given domain.
			$VIRSH destroy $DOMAIN
			# Give libvirt some time for killing off the domain.
			sleep 3
		done
		;;
esac
