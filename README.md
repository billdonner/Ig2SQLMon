# IGBlueMon - dynamic server monitor for IOS and OSX

Monitoring a dozen or so bluemix servers with this tool.

Reads a remote JSON configuration file to specify servers.

Optimally servers are using [https://github.com/billdonner/IgKitCommons](https://github.com/billdonner/IgKitCommons) to generate standard json status responses.

## Setting Up monitoring

- make a config file
- start target servers
- build IOS App
- build Mac App


#### Post Configuration file at Network URL

This is just a sample

    {
        "comment": "servers monitored by igblue",
        "servers": [ 
            {
                "server": "https://bluigreport.mybluemix.net",
                "status-url": "https://bluigreport.mybluemix.net"
            },  
            {
                "server": "https://billdonner.com",
                "status-url": "https://billdonner.com/json"
            }]
    }


#### Each server

Each server needs a /json route to return a small JSON dictionary 

- servertitle -- a short name for your server
- description -- a longe fuller description 
- up-time -- the float uptime for the server
- softwareversion -- version as x.y.z string
- httpgets -- integer count of basic gets, supply  0 if static
- response-status -- integer status, normally 200


Servers  failing to present these fields will display error code 529
