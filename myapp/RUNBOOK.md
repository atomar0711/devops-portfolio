============== Service doesn't start ===========
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
# to get the avaialable records
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
============== Disk full ===========

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

If no one inode is left, it means there is enormous number of small files that consumed all indoes.
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
