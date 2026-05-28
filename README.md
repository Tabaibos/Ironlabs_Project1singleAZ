WIP 

playbook ping connection failed.
   -> Review bastion connection sg to all ec2. Why success in db, but failure in app and frontend

fatal: [app]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Connection timed out during banner exchange\r\nConnection to UNKNOWN port 65535 timed out", "unreachable": true}
fatal: [frontend]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Connection timed out during banner exchange\r\nConnection to UNKNOWN port 65535 timed out", "unreachable": true}
ok: [db]
Fatal: [db]: FAILED! => {"changed": false, "msg": "Failed to lock apt for exclusive operation: Failed to lock directory /var/lib/apt/lists/: E:Could not open lock file /var/lib/apt/lists/lock - open (13: Permission denied)"}
