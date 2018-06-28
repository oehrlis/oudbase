# OUD 12c EUS AD Proxy

Create and configuration scripts to setup an Oracle Unified Directory 12c proxy server with Oracle Enterprise User Security (EUS) and MS ActiveDirectory integration.

## Scripts

| Script                          | Description                                                                                                                                                                 |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 00_init_environment             | File to set the instance-specific environment and parameter. Must be customized.                                                                                            |
| 01_create_eus_proxy_instance.sh | Create the OUD proxy instance with EUS integration                                                                                                                          |
| 02_config_eus_context.sh        | Configuration of the AD integration workflow eg. transformation, proxy, extensions etc. Does execute the the dsconfig commands in 02_config_eus_context.conf in batch mode. |
| 02_config_eus_context.conf      | dsconfig commands to setup AD integration workflow                                                                                                                          |  |
| 03_config_eus_realm.sh          | Adjust and load EUS realm configuration. Group and user search base is adjusted according to 00_init_environment.                                                           |
| 03_config_eus_realm.ldif        | EUS realm configuration.                                                                                                                                                    |
| 04_config_oud_ad_proxy.sh       | Fix a few EUS specific configurations eg. MOS Note 2001851.1. Does execute the the dsconfig commands in 04_config_oud_ad_proxy.conf in batch mode.                          |
| 04_config_oud_ad_proxy.conf     | dsconfig commands to configure EUS specific configurations according MOS note 2001851.1                                                                                     |
| 05_update_directory_***REMOVED***.sh  | Update Directory Manager (cn=Directory Manager) and reset its password to create AES password storage scheme entry                                                          |
| 06_create_root_users.sh         | Create additional root user cn=oudadmin, cn=useradmin and cn=eusadmin                                                                                                       |
| 06_create_root_users.ldif       | definition of root users                                                                                                                                                    |
| 07_create_eusadmin_users.sh     | Add cn=eusadmin to the EUS groups.                                                                                                                                          |

## Usage

The scripts are always to be called sequentially, starting with 01. Either manually when interactively building an OUD instance or automatically when creating an OUD Docker container. When using to setup a OUD Docker container the scripts have to be put into the instance init folder. eg. $OUD_INSTANCE_INIT/setup or $OUD_INSTANCE_ADMIN/create 

**Note:** It is highly recommended to at least review and adjust _00_init_environment_ file. This file contains all the default configuration values like Base DN, ports, AD credentials etc.

Define a bunch of default values:
* _MY_VOLUME_ is the local folder used as volumne
* _MY_CONTAINER_ is the container name used to setup the OUD Docker container.
* _MY_OUD_INSTANCE_ is the OUD instance name
* _MY_HOST_ is the hostname of the Docker container
```
export MY_VOLUME="/volume"
export MY_CONTAINER=oudeng
export MY_OUD_INSTANCE=oud_adproxy
export MY_HOST=oudad.postgasse.org
```

create a volume directory for the Docker container and put the scripts into the $OUD_INSTANCE_ADMIN/create folder. 
```
mkdir -p $MY_VOLUME/$MY_CONTAINER/admin/$MY_OUD_INSTANCE/create
mkdir -p $MY_VOLUME/$MY_CONTAINER/admin/$MY_OUD_INSTANCE/etc
cp oud12c_eus_ad_proxy/* $MY_VOLUME/$MY_CONTAINER/admin/$MY_OUD_INSTANCE/create
```

Optionally you may also create a password file, if you do not want to have auto generated passwords.
```
echo ***REMOVED*** >$MY_VOLUME/$MY_CONTAINER/admin/$MY_OUD_INSTANCE/etc/$MY_OUD_INSTANCE_pwd.txt
echo ***REMOVED*** >$MY_VOLUME/$MY_CONTAINER/admin/$MY_OUD_INSTANCE/etc/$MY_OUD_INSTANCE_root_users_pwd.txt
```

Review and adjust the _00_init_environment_ file.
```
vi $MY_VOLUME/$MY_CONTAINER/admin/$MY_OUD_INSTANCE/create/00_init_environment
```

Create a OUD Docker Container.
```
docker run --detach --volume $MY_VOLUME/$MY_CONTAINER:/u01 \
   -p 1389:1389 -p 1636:1636 -p 4444:4444 \
   -e OUD_CUSTOM=TRUE -e BASEDN="dc=postgasse,dc=org" -e OUD_INSTANCE=$MY_OUD_INSTANCE \
   --hostname $MY_HOST --name $MY_CONTAINER oracle/oud:12.2.1.3.180322
```

Check the logs and enjoy the automatic setup of OUD EUS AD proxy.
```
docker logs -f $MY_CONTAINER
```

## Issues
Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/oudbase/issues)
* [submit new issue](https://github.com/oehrlis/oudbase/issues/new)

## License
oehrlis/docker is licensed under the GNU General Public License v3.0. You may obtain a copy of the License at <https://www.gnu.org/licenses/gpl.html>.