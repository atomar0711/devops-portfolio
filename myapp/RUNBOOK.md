//-------- Code Spell Checker Configuration --------
// The Language locale to use when spell checking. "en", "en-US" and "en-GB" are currently supported by default.
"cSpell.language": "en",

## Service won't start

1. Verify the service state error using the command:
```
systemctl status myapp.service
```

2.1 If the service failed with `203/EXEC`, it indicates the service executable file cannot be started.
2.1.1 Identify the user under which the service is running:
```
systemctl show --property=User  myapp.service
```

2.1.2 Check the owner, owner group and permissions are correct for the service executable file:
```
ls -l /opt/myapp/heartbeat.sh
```

It must be the owner `root` and the owner group `appsvc`   
The group owner must have permissions RX.

2.1.3 Set the correct owner and owner group if needed:
```
sudo chown root:appsvc /opt/myapp/heartbeat.sh
```

2.1.4 Set correct permissions if needed:
```
sudo chmod 650 /opt/myapp/heartbeat.sh
```

2.1.5 Verify the service state is `active (running)` using the command:
```
systemctl status myapp.service
```

2.2 If the service failed with `1/FAILURE`, it indicates the service executable file can be ran but the issue appeared while it was running.

2.2.1 Retrieve the full error stack for the service:
```
# to get only the last attempt to execute the service
journalctl -u myapp.service -I
# to get the available records
journalctl -u myapp.service
# to get last 20 records
journalctl -u myapp.service | tail -20
```

2.2.2 For instance, the service failed with 'Permission denied' to file /etc/myapp/app.conf which contains the heart beat message.

2.2.3 Check the owner, owner group and permissions are correct for the message file:
```
ls -l /etc/myapp/app.conf
```

It must be the owner `root` and the owner group `appsvc` 
The group owner must have permissions RO.

2.2.4 Set the correct owner and owner group if needed:
```
sudo chown root:appsvc /etc/myapp/app.conf
```

2.2.5 Set correct permissions if needed:
```
sudo chmod 640 /etc/myapp/app.conf
```

2.2.6 Verify the service state is `active (running)` using the command:
```
systemctl status myapp.service
```
## Disk full

The following steps should be taken to troubleshoot the error `Disk is full`
3.1 Check how many free space left on the disk:
```
$ df -h
```
Look at the column `Use%` for a value that close or equal to 100% and the mount directory name at column `Mounted on`. Compare the columns `Size` for total size of the filesystem and `Used` for space size used by files and folders.

3.2 If delta between `Size` and `Used` is sufficient enough to save the file or data, check how many inodes left:
```
df -hi
```
Look at the column `IUse%` for the inodes usage rate and at the column `IFree` for the inodes left of the filesystem. 

If no one inode is left, it means there is enormous number of small files that consumed all inodes.
In this case, it worth to identify the folders where inodes are mostly consumed:
```
sudo du / --inodes -x -a -h -d 1 2>/dev/null | sort -hr | head -10
```

Repeat the step for each subfolder that mostly consume inodes:
```
sudo du <dir_path> --inodes -x -a -h -d 1 2>/dev/null | sort -hr | head -10
```

3.3 Lets assume the filesystem `/dev/mapper/rl-root`corresponding with the root disk `/`is used on 100%.

3.4 Verify that the `/` overall usage size is similar to the column `Used` in the command `df` output:
```
sudo du / -h -x --summarize
```
The key `-x` will show only files and folders on this file system and won't show mounted resources like `/proc`, `run`. The disk usage will be displayed close to the the command `df`

Look at the first column for overall usage size of `/` and compare it with the column `Used` in the command `df` output. If they don match, go to the next step for additional troubleshooting.

3.4.1 If the overall size of `/` in the `du` output is lesser than the `Used` value in the `df` output, it may indicate that the file is deleted but a descriptor to it inode is still opened. Check the files that has less than 1 hard links (deleted) with the command:
```
sudo lsof +L1
```
Look at the columns PID for the process opened the file and NAME for the files having (deleted) in their names.

3.4.2 To release the descriptor and completely delete the files' inodes, restart the service that locks them:
- Identify the service using its PID from the previous step:
```
sudo systemctl status <PID>
```
- Restart the service:
```
sudo systemctl restart <service>
```

If you can't restart the service, empty the file through the fd:
```
sudo truncate -s 0 /proc/<PID>/fd/<N>
```
`fd` is displayed in the output at the stage 3.4.1 as `number`+`access mode` eg. `3w`. Replace <N> with this number in command above. In our example it is `3`.

3.5 Identify top 10 files and folders in the root directory that consume the most part of space:
```
sudo du / -ha -x -d 1 2>/dev/null | sort -hr | head -10
```
The key `-x` will show only files and folders on this file system and won't show mounted resources like `/proc`, `run`. The disk usage will be displayed close to the the command `df`

NOTE: Make sure the command `du` is always ran under root or sudo to be sure that all folders are counted. Otherwise, some files and folders may not be counted in the disk usage.

Look at the first column for directories that have biggest size.

3.6 Lets assume the folder `/home` is the biggest one.

3.7 Identify top 10 files and folders in the `/home` directory that consume the most part of space:
```
sudo du /home -ha -x -d 1 2>/dev/null | sort -hr | head -10
```
Look at the first column for directories that have biggest size.

3.8 Repeat step 3.7 for all subfolders (replace `/home` with the correct path like `/home/.../...`)

3.9 Lets assume the subfolder `/home/user1/home-video` is the biggest one and the subfolder `/home/user1/home-video` is decided to be deleted.

3.10 Delete the subfolder `/home/user1/home-video` and its content:
```
sudo rm -rf /home/user1/home-video
```

3.11 Verify the root directory has sufficient space:
```
$ df -h
```

## Process stuck in D state

## Understanding systemctl status after the service died

The following scenario should be used to check the status why the service dead:
5.1 Check the service status:
```
systemctl status myapp --no-pager | head -8
```
5.2 Look for the following string in the output:
`Active:` - indicates the current state of service
`Main PID:` - indicates the process ID and why it was stopped

5.2.1 If another process or user terminated the process associated with the service, the following records are displayed:
`Active: inactive (dead)`
`Main PID: PID (code=killed, signal=TERM)`

After the signal `TERM`, the service doesn't start automatically since this signal means that the process was terminated intentionally.

5.2.2 If another process or user forcefully terminated (killed) the process associated with the service, the following records are displayed:
`Active: activating (auto-restart) (Result: signal)`
`Main PID: PID (code=killed, signal=KILL)`

After the signal `KILL`, the service starts automatically since this signal means that the process was terminated unexpectedly.

5.2.3 If the process associated with the service is stopped due to an internal error, the following records may be displayed:
`Main PID: PID (code=killed, signal=1/FAILURE)` - see 2.2 for additional information
`Main PID: PID (code=killed, signal=203/EXEC)` - see 2.1 for additional information

After the internal signal, the service starts automatically since this signal means that the process was terminated unexpectedly

5.3 Table for quick reference:
┌──────────────────┬────────────────────────────────────────────────────────────────────────┬───────────────────────┐
│      Death       │                              status shows                              │ on-failure restarts?  │
├──────────────────┼────────────────────────────────────────────────────────────────────────┼───────────────────────┤
│ kill -15         │ ○ inactive (dead), code=killed, signal=TERM                            │ no (clean stop)       │
├──────────────────┼────────────────────────────────────────────────────────────────────────┼───────────────────────┤
│ kill -9          │ ● activating (auto-restart) (Result: signal), code=killed, signal=KILL │ yes, after RestartSec │
├──────────────────┼────────────────────────────────────────────────────────────────────────┼───────────────────────┤
│ app calls exit 1 │ code=exited, status=1/FAILURE                                          │ yes                   │
└──────────────────┴────────────────────────────────────────────────────────────────────────┴───────────────────────┘

## Can't reach the service

The following scenario should be used to troubleshoot the web application that doesn't respond:
web app is listening to port `8080`

6.1 Check that the web app is running:
```
systemctl status <unit_name>
```
If the web app is running as a service, its status must be:
`Active: active (running)`

6.2 Check that what process is listening to port 8080 and IP address it is bind to:
```
ss -tlpn | grep -E "State|8080"
```
Look for values in the columns `Address:Port` for IP and port the process bind to and `Process` for the PID of the process that listen to the port.

6.3 If `pid` in the `ss` output differs from the web app PID, it means the port is being listen by another process.
Identify the service that locks the port and troubleshoot how to solve the race condition.
If `pid` is correct, follow the next steps.

6.4 If the column `Address:Port` looks like `127.0.0.1:8080`, it indicates the web app is accessible from the local host only.

To verify the web app is accessible, run this command:
```
curl -v http://127.0.0.1:8080
``` 
In the output, the string `< HTTP/1.0 200 OK` indicates the connection to the web app is OK and body should contain the message from the web app.

6.5 If the column `Address:Port` looks like `<host-IP>:8080`, it indicates the web app should be accessible on this IP address.

6.6 To verify the web app is accessible locally, run this command on the web app server:
```
curl -v http://<web-app-host-IP>:8080
```
In the output, the string `< HTTP/1.0 200 OK` indicates the connection to the web app is OK and body should contain the message from the web app.

6.7 To check that the web app is accessible from a Windows machine, run a PowerShell console and execute the command:
```
curl.exe -v http://<web-app-host-IP>:8080
```
In the output, the string `< HTTP/1.0 200 OK` indicates the connection to the web app is OK and body should contain the message from the web app.

NOTE: Command `curl` in PowerShell is an alias for the cmdlet `Invoke-WebRequest` which is analogue of the app `curl` but has different syntax and keys.

6.8 If the command `curl`/`curl.exe` failed.
If the output contains error message like `Connection refused` or `Timed out`, and `Could not connect to server`, it indicates the connection was blocked, check that port 8080 is not blocked by firewall.

6.8.1 To display the current active zone in the firewall and its configuration:
```
sudo firewall-cmd --get-active-zone <-- it will return an active zone-->
sudo firewall-cmd --info-zone=<active_zone> <-- paste the active zone to get its configuration -->
```
Look for string `ports:` and `rich rules:`
  - if an empty values is in string `ports:`, add the web app port to the allowed ports (see step 6.8.2);
  - if the rich rules block contains a rule blocking (reject/drop) the web app port, remove it (see step 6.8.3).

6.8.2 To allow the web app port on the firewall, run the command
  ```
  sudo firewall-cmd --add-port=8080/tcp
  ```
  NOTE: the key `--add-port=8080/tcp` is case-sensitive and will return an error if its written as `--add-port=8080/TCP`

6.8.3 To remove a rich rule run this command:
```
sudo firewall-cmd --remove-rich-rule=<rule>
```
As an example: `sudo firewall-cmd --remove-rich-rule='rule family="ipv4" port port="8080" protocol="tcp" reject'`

6.8.4 Once the firewall settings are modified, run the command `curl`/`curl.exe` once again and verify the output contains `< HTTP/1.0 200 OK`.

Then, copy the current firewall config from the temporarily runtime to the permanent config file:
```
sudo firewall-cmd --runtime-to-permanent
```

NOTE: If the firewall config is not copied to the permanent config, the current configuration will be lost during the server reboot, the service restart, or the configuration reload.