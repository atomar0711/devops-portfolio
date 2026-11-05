Service won't start: the steps I use are
1. Verify the service state error using the command:
    systemctl status myapp.service

2.1 If the service failed with '203/EXEC', it indicates the service executable file cannot be started.
    2.1.1 Identify the user under which the service is running:
    systemctl show --property=User  myapp.service

    2.1.2 Verify the service user group has sufficient permissions to the service executable file:
    ls -l /opt/myapp/heartbeat.sh

    The group owner must have permissions RX.

    2.1.3 Set correct permissions if needed:
    chmod 650 /opt/myapp/heartbeat.sh

2.2 If the service failed with '1/FAILURE', it indicates the service executable file can be ran but the issue appeared while it was running.

    2.2.1 Retreive the full error stack for the service:
    journalctl -u myapp.service -I - to get only the last attempt to execute the service
    journalctl -u myapp.service - to get the avaialable records
    journalctl -u myapp.service | tail -20 - to get last 20 records

    2.2.3 For instance, the service failed with 'Permission denied' to file /etc/myapp/app.conf which contains the heart beat message.
    
    Verify the service user group has sufficient permissions to the message file:
    ls -l /etc/myapp/app.conf

    The group owner must have permissions RO.

    2.1.3 Set correct permissions if needed:
    chmod 640 /opt/myapp/heartbeat.sh

