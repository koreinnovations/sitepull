# README

Definitions:

* "remote server" is the production server you will be syncing from
* "local server" is the development server you will be syncing to


## REMOTE SERVER ACTIONS:

1. Install `prepsite.sh` on remote server in HOME/bin directory.  (If this directory doesn't exist, create it.)  
   Example:  
   If your home directory is `/home/johndoe`, put the script in `/home/johndoe/bin`
1. Make the file executable:  
   `chmod u+x PATH/TO/FILE`
1. Set up a config file in your HOME/conf directory.  (If this directory doesn't exist, create it.)  
   Use `prepsite_config_example.conf` as your template.


## LOCAL SERVER ACTIONS:

1. Install `sitepull.sh` on your local server in HOME/bin directory.
1. Make the file executable:  
   `chmod u+x PATH/TO/FILE`
1. Install `pull_help.txt` on your local server in HOME/bin directory.  
   (Should be in the same directory as "sitepull.sh")
1. Set up a config file in your HOME/conf directory.  (If this directory doesn't exist, create it.)  
   Use `sitepull_config_example.conf` as your template.


## EXECUTING THE SCRIPT

From your local server, type

`sitepull.sh ~/conf/CONFIG_FILE.conf`  
(This will download the latest files from the remote server)

Additionally, you can add any command-line switches available, such as:

`sitepull.sh ~/conf/CONFIG_FILE.conf --install-db`  
(That will also download and install a dump of the remote database)

OR

`sitepull.sh ~/conf/CONFIG_FILE.conf --install-db --backup-local-db`  
(That will also download and install a dump of the remote database, but will back up the local database first)

*SHORTCUT*

`pull CONFIG_FILE`
is a shortcut for
`sitepull.sh ~/conf/CONFIG_FILE.conf --install-db --backup-local-db`