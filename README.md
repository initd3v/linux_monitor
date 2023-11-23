# monitor.sh

## Table of contents
* [Description](#description)
* [Dependencies](#dependencies)
* [Setup](#setup)
* [Usage](#usage)

## Description
This bash script is used for monitoring essential parameters as an unprivileged user on a Linux system and pass a return value. This value can be evaluated by a monitoring software which calls the script by SSH access. Additionally it can send an email itself if the command dependencies are installed and configured.

The Project is written as a GNU bash shell script.

## Dependencies

| Dependency    | Version                               | Necessity     | Used Command Binary                                          |
|:--------------|:--------------------------------------|:-------------:|:------------------------------------------------------------:|
| bc            | >= 1.07.1                             | necessary     | bc                                                           |
| GNU bash      | >= 5.1.4(1)                           | necessary     | bash                                                         |
| GNU Awk       | >= 5.1.0                              | necessary     | awk                                                          |
| GNU Coreutils | >= 8.32c                              | necessary     | cat & date & echo & df & head & id & mkdir & tail & wc       |
| grep          | >= 3.6                                | necessary     | grep                                                         |
| iputils       | >= 20210202                           | necessary     | ping                                                         |
| procps-ng     | >= 3.3.17                             | necessary     | ps & free                                                    |
| util-linux    | >= 2.36.1                             | necessary     | dmesg & lsblk                                                |
| whereis       | >= 2.36.1                             | necessary     | whereis                                                      |
| GNU Mailutils | >= 3.10                               | optional      | mail                                                         |
| openrc        | >= 0.46                               | optional      | rc-status                                                    |
| systemd       | >= 247                                | optional      | systemctl                                                    |
| sysvinit      | >= 3.06                               | optional      | service                                                      |

## Setup
To run this project, you need to clone it to your local computer and run it as a shell script.

```
$ cd /tmp
$ git clone https://github.com/initd3v/linux_monitor.git
```
## Usage

### Running the script

To run this project, you must add the execution flag for the user context to the bash file. Afterwards execute it in a bash shell. 
After every successful execution the current option configuration will be saved in the download directory.
The log file is located in the download directory.

```
$ chmod u+x /tmp/linux_monitor/src/monitor.sh
$ echo 'SCRIPT_BASE_PATH="/tmp"' > /tmp/linux_monitor/src/monitor.conf
$ /tmp/linux_monitor/src/monitor.sh [--check | check | -check] [--help | help | -h] [--version | version | -v]
```

### Syntax

#### Syntax Overview

* monitor.sh [--check | check | -check]
* monitor.sh [--help | help | -h]
* monitor.sh [--version | version | -v]

#### Syntax Description

The folowing syntax options are valid.

| Option syntax                 | Description                               | Necessity | Supported value(s)  | Default |
|:------------------------------|:------------------------------------------|:---------:|:-------------------:|:-------:|
| --check \| check \| -c        | perform system check                      | optional  | -                   | -       |
| --help \| help \| -h          | display help information                  | optional  | -                   | -       |
| --version \| version \| -h    | display version information               | optional  | -                   | -       |

### Configuration

The configuration file needs to be placed / linked in the same folder as the main script and has to be named 'monitor.conf'.

#### Configuration Description

The folowing configuration options are valid.

| Variable                      | Description                                                                                       | Example                                                   |Necessity  | Supported value(s)    | Default |
|:------------------------------|:--------------------------------------------------------------------------------------------------|:----------------------------------------------------------|:---------:|:---------------------:|:-------:|
| SCRIPT_BASE_PATH              | defines the local base path where the log file will be written to                                 | SCRIPT_BASE_PATH="/tmp"                                   | necessary | STRING                | -       |
| CHECK_FS_LIMIT                | defines the alarm limit for filesystem / inode usage in percent                                   | CHECK_FS_LIMIT=90                                         | optional  | 0 <= INTEGER <= 100   | 80      |
| CHECK_DISK_AVAIL              | defines block device as 'MAJ:MIN' which must be available divided by an empty space               | CHECK_DISK_AVAIL="8:0 8:16 /dev/sda"                      | optional  | STRING                | -       |
| CHECK_SWAP                    | enable SWAP space check for usage above 50 percent                                                | CHECK_SWAP=1                                              | optional  | 1                     | -       |
| CHECK_NET_AVAIL               | defines network addresses as IP or DNS name which must be available divided by an empty space     | CHECK_NET_AVAIL="9.9.9.9 google.de"                       | optional  | STRING                | -       |
| CHECK_PS¹                     | defines processes which must be available divided by ":::"                                        | CHECK_PS="root:::/sbin/init:::mainuser:::/bin/bash"       | optional  | STRING                | -       |

**¹ Value Description vaiable 'CHECK_PS'**

* entry            : CHECK_PS="[STRING_1]:::[STRING_1]:::[STRING_2]:::[STRING_2]"

or

* first entry      : CHECK_PS="[STRING_1]:::[STRING_1]"
* additional entry : CHECK_PS+=":::[STRING_2]:::[STRING_2]"
