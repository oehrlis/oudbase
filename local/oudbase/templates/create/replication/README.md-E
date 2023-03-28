# Replication Create Scripts

This directory contains various scripts for setting up and configuring a replication. The scripts are designed for an OUD environment with 2-3 OUD instances and a default backend respectively `$BASEDN`. If the instance has multiple backends, the scripts have to be adapted accordingly. The scripts listed below can be added to the create directory of an existing OUD instance. The will use respectively require the `00_init_environment` file of the OUD instance.

- [21_enable_replication_host1.sh](21_enable_replication_host1.sh) Script to enable and initialize replication for the Base DN and EUS suffixes on Host 1 and Host 2. Base is Host 1. Only the script [21_enable_replication.sh] or [22_enable_replication.sh] needs to be executed.
- [21_replication_add_host2.sh](21_replication_add_host2.sh) Script to extend replication to host 2. base is host 1. Only one of the three scripts needs to be executed.
- [21_replication_add_host3.sh](21_replication_add_host3.sh) Script for extending replication to host 3. base is host 1. Only one of the three scripts needs to be executed.
- [22_enable_replication_host2.sh](22_enable_replication_host2.sh) Script to enable and initialize replication for the Base DN and EUS suffixes on host 2 and host 3. Base is host 2. Only the script [21_enable_replication.sh] or [22_enable_replication.sh] needs to be executed.
- [22_replication_add_host1.sh](22_replication_add_host1.sh) Script to extend replication to host 1. base is host 2. Only one of the three scripts needs to be executed.
- [31_initialize_host1.sh](31_initialize_host1.sh) Script for initializing replication on host 1, based on host 2.
- [31_initialize_host2.sh](31_initialize_host2.sh) Script for initializing replication on host 2 based on host 1.
- [31_initialize_host3.sh](31_initialize_host3.sh) Script for initializing replication on host 3 based on host 1.
- [40_status_replication.sh](40_status_replication.sh) Script for displaying the replication status.
