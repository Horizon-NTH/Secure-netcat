# Secure-netcat

[![Release](https://img.shields.io/badge/Release-v1.0-blueviolet)](https://github.com/Horizon-NTH/Secure-netcat/releases)
[![Language](https://img.shields.io/badge/Language-Bash-0052cf)](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

## Introduction

Secure-netcat is a client/server application implemented using Netcat, featuring RSA-encrypted communication and password protection.

> ⚠️ **Note**: These scripts must be run on an environment where FIFOs (named pipes) are supported.

## Installation Instructions

You can simply install the release version [here](https://github.com/Horizon-NTH/Secure-netcat/releases).

### Get Source Code

First, clone the repository using [git](https://git-scm.com).

```bash
git clone https://github.com/Horizon-NTH/Secure-netcat.git
```

## Documentation

There are two scripts provided: one for the server and one for the client, allowing you to establish a secure connection.

### Server

The script `server.sh` starts the server. If it's the first time running it, you will be prompted to create a 
**password** for the server; otherwise, it will start without any prompts.

```bash
$ ./server.sh
>>>Initialization
Please enter the password:
Please retype the password:
>>>Password changed
>>>Server initialized
```

The server notifies when users connect or disconnect.

```bash
@server:Wed Feb 28 04:55:36 PM CET 2024! User connected
@server:Wed Feb 28 05:05:12 PM CET 2024! User disconnected
```

Here are the available arguments for the server script:

| Options |                Usage                 |
|:-------:|:------------------------------------:|
|    n    | Create a new password for the server |
|    i    |     Set the server's IP address      |
|    p    |        Set the server's port         |

### Client

The script `client.sh` allows you to connect to an existing [server](#server). 
If the server is down or the connection is impossible, the script will terminate.

```bash
$ ./client.sh
>>>The server is down
```

If the server is running, you will be prompted for the password before gaining access to the server's CLI.

```bash
./client.sh
>>>The server is up
>>>Connecting

__        __   _
\ \      / /__| | ___ ___  _ __ ___   ___
 \ \ /\ / / _ \ |/ __/ _ \|\'_ ` _ \ / _ \
  \ V  V /  __/ | (_| (_) | | | | | |  __/
   \_/\_/ \___|_|\___\___/|_| |_| |_|\___|

Please enter the password:
>>>Connected
@user:Wed Feb 28 04:55:35 PM CET 2024$
```

Here are the available arguments for the client script:

| Options |                          Usage                          |
|:-------:|:-------------------------------------------------------:|
|    i    | Set the IP address of the server you want to connect to |
|    p    |    Set the port of the server you want to connect to    |

### Usage

Once the [client](#client) is connected to a [server](#server), 
the user can execute any command as if they were directly on the server:

```bash
@user:Wed Feb 28 05:07:59 PM CET 2024$ ls
client.sh
LICENSE
README.md
server.sh
@user:Wed Feb 28 05:08:00 PM CET 2024$ cd .. && ls
Secure-netcat
```

> **Note**: All communications between the server and the client are encrypted.

## Dependencies

- **[netcat](https://en.wikipedia.org/wiki/Netcat)**: Used for communication. Make sure to use the OpenBSD version for compatibility.

- **[openssl](https://www.openssl.org)**: Used for encryption.

- **[figlet](https://en.wikipedia.org/wiki/FIGlet)** [Optional]: Used for displaying a welcome message.

## License

This project is licensed under the [MIT license](LICENSE).