# Generic OUD Setup Files

This folder contains all files to setup a generic OUD instance with demo users
which can be served as Oracle Names directory. Corresponding bash files have to
be used to setup / run .LDIF and .CONF files.

- [00_init_environment](00_init_environment) Configuration file for instance
  specific settings like BaseDN, User OU etc.
- [01_create_eus_instance.sh](01_create_eus_instance.sh) Script for creating the instance. Executes 'oud-setup'.
- [02_config_basedn.sh](02_config_basedn.sh) Wrapper script to configure base DN and add ou's for users, groups, acis etc.
- [02_config_basedn.conf](02_config_basedn.conf) Batch file loaded by wrapper script `02_config_basedn.sh`.
- [02_config_basedn.ldif](02_config_basedn.ldif) LDIF file loaded by wrapper script `02_config_basedn.sh`.
- [03_config_oud.conf](03_config_oud.conf) Batch file for the configuration of the OUD instance. Adaptation of various instance parameters such as logging, password policies, etc.
- [03_config_oud.sh](03_config_oud.sh) Wrapper script for the configuration of the OUD instance.
- [04_create_root_user.conf](04_create_root_user.conf) dsconfig batch file loaded by wrapper script `04_create_root_user.sh`.
- [04_create_root_user.ldif](04_create_root_user.ldif) LDIF file loaded by wrapper script `04_create_root_user.sh`. 
- [04_create_root_user.sh](04_create_root_user.sh) Wrapper script to create additional root user.
- [10_reset_directory_manager_password.sh](10_reset_directory_manager_password.sh) Reset `cn=Directory Manager` password.
- [11_reset_root_passwords.sh](11_reset_root_passwords.sh) Reset or regenerate all admin users passwords.
- [14_create_demo_users.ldif](14_create_demo_users.ldif) LDIF file loaded by wrapper script `14_create_demo_users.sh`.
- [14_create_demo_users.sh](14_create_demo_users.sh) Wrapper script to create a couple of users and groups.
- [15_reset_user_passwords.sh](15_reset_user_passwords.sh) Reset all passwords for the demo users to $DEFAULT_PASSWORD.
- [setup_oud_instance](setup_oud_instance) Script to create the OUD instance. The script will go execute all `0?_*.sh` and `1?_*.sh` files create the instance. All files in sequence after `19_*.sh` have to be executed manually. This includes the replication.

Using the scripts from the template, creating an OUD instance is relatively
easy. The instance can be created either completely with the wrapper script
`setup_oud_instance` or step by step by running the bash scripts from the
template one by one. Alternatively, the OUD instance can be created manually
with 'oud-setup'. In this case, however, any adjustments must be made directly
with LDIF or dsconfig.
