#!/bin/bash

# Function to generate RSA key pair
# ARGS: 1->Private key file name 2->Public key file name
function gen_key()
{
	if ! [ -d "._key" ]
	then
	    mkdir ._key
	fi
	openssl genpkey -algorithm RSA -out ._key/$1 >& /dev/null
	openssl pkey -pubout -in ._key/$1 -out ._key/$2
}

# Function to encrypt a message using RSA public key
# ARGS: 1->message 2->public key
function crypt()
{
	echo -n $1 | openssl pkeyutl -encrypt -pubin -inkey ._key/$2 | base64 -w 0
}

# Function to decrypt a message using RSA private key
# ARGS: 1->message 2->private key
function uncrypt()
{
	echo -n $1 | base64 -d | openssl pkeyutl -decrypt -inkey ._key/$2
}

# Function to send an encrypted message using the recipient's public key
# ARGS: 1->Public key file name 2->Message
function send()
{
	echo "$(crypt "$2" "$1")"
}

# Function to send the public key to the recipient
# ARGS: 1->Key to send
function send_key()
{
	echo $(printf '%q' "$(cat ._key/$1)")
}

# Function to handle parsing of input messages
function parser()
{
	while IFS=  read -r message
    do
        if echo "$message" | grep -q -E "BEGIN PUBLIC KEY" &> /dev/null
        then
            message=${message#"$'"} && message=${message%"'"}
            echo -e "$message" > ._key/server.pub
        else
            message=$(uncrypt "$message" client.pem)
            if [[ ${message:0:2} == "\$'" ]]
            then
                message=${message#"$'"} && message=${message%"'"}
                echo -e $message
            elif [[ ${message:0:3} == ":§:" ]]
            then
                message=${message#":§:"}
                if [ "$message" = "0" ]
                then
                    echo true > ._key/connect
                    echo ">>>Connected"
                fi
            else
                echo "$message"
            fi
            if $(cat ._key/connect)
            then
                echo -n -e "\e[31m@user\e[0m:\e[34m$(date)\e[0m\$ " >&2
            fi
        fi
    done
}

# Function to handle changing the password
function cpasswd()
{
	echo -n "Please enter the new password : " >&2
	read -r -s newpasswd
	echo >&2
	echo -n "Please retype the new password : " >&2
	read -r -s retype
	echo >&2
	if [ "$newpasswd" = "$retype" ]
	then
		echo -n ">>>passwd changed" >&2
        send server.pub ":§:Password change"
		send server.pub "set_crypt_passwd $newpasswd server.pub"
	else
        send server.pub ":§:Attempt to change password"
		echo -e "Password do not match\n>>>passwd unchanged" >&2
        echo -n -e "\e[31m@user\e[0m:\e[34m$(date)\e[0m\$ " >&2
	fi
}

# Function to handle the connection process
function connection()
{
    if ! $1
    then
	    figlet Welcome >&2
	    echo -n "Please enter the password : " >&2
    else
        send server.pub ":§:Connexion attempt"
        echo -n "Wrong password please retry : " >&2
    fi
	read -rs passwd
    echo >&2
    send server.pub "is_passwd $passwd"
    sleep 1
    if ! $(cat ._key/connect)
    then
        connection true
    fi
}

# Function to start the client
function start()
{
    send_key client.pub
    echo false > ._key/connect
    connection  false
    send server.pub ":§:User connected"
    while read -r input;
	do
        if [ "$input" = "exit" ]
        then
            send server.pub ":§:User disconnected"
            echo ">>>Disconnected" >&2
            break
        elif [ "$input" = "cpasswd" ]
        then
            cpasswd
        else
            send server.pub "$input"
        fi
	done
}

# Parse arguments
ip=localhost
port=8080

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)	#Set the ip of the server you want to connect on
			shift
			ip="$1"
			;;
		-p)	#Set the port of the server you want to connect on
			shift
			port="$1"
			;;
    esac
    shift
done

# Check if the server is available
if ! nc -v -z -w 3 $ip $port &> /dev/null
then
    echo ">>>The server is down"
    exit
else
    echo ">>>The server is up"
    echo ">>>Connecting"
    gen_key client.pem client.pub
    start | nc -q 0 $ip $port | parser
fi
