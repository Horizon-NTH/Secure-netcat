#!/bin/bash

# Function to generate RSA key pair
# ARGS: 1->Private key file name 2->Public key file name
function gen_key()
{
	if ! [ -d "._key" ]
	then
		mkdir ._key
	fi
	openssl genpkey -algorithm RSA -out ._key/"$1" >& /dev/null
	openssl pkey -pubout -in ._key/"$1" -out ._key/"$2"
}

# Function to encrypt a message using RSA public key
# ARGS: 1->message 2->public key
function crypt()
{
	echo -n "$1" | openssl pkeyutl -encrypt -pubin -inkey ._key/"$2" | base64 -w 0
}

# Function to decrypt a message using RSA private key
# ARGS: 1->message 2->private key
function decrypt()
{
	echo -n "$1" | base64 -d | openssl pkeyutl -decrypt -inkey ._key/"$2"
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
	echo "$(printf '%q' "$(cat ._key/$1)")"
}

# Function to get the encrypted password
function get_crypt_passwd()
{
	echo -n "$(cat ._key/passwd.crypt)"
}

# Function to set the encrypted password
# ARGS: 1->New encrypted password 2->public key to encrypt
function set_crypt_passwd()
{
	crypt "$1" "$2"> ._key/passwd.crypt
}

# Function to test the entered password
# ARGS: 1->Password to test
function is_passwd()
{
	if [[ "$(decrypt "$(get_crypt_passwd)" server.pem)" == "$1" ]]
	then
		echo ":§:0"
		return 0
	else
		echo ":§:1"
		return 1
	fi
}

# Function to change the password
function set_passwd()
{
	echo -n "Please enter the password : "
	read -r -s newpasswd
	echo
	echo -n "Please retype the password : "
	read -r -s retype
	echo
	if [ "$newpasswd" = "$retype" ]
	then
		set_crypt_passwd "$newpasswd" server.pub
		echo ">>>Password changed"
		return 0
	else
		echo -e "Passwords do not match\n>>>Password unchanged"
		return 1
	fi
}

# Function to parse the input and execute commands
# ARGS: 1->Input to parse
function parser()
{
	local input="$1"
    if echo "$input" | grep -q -E "BEGIN PUBLIC KEY" &> /dev/null
    then
		input=${input#"$'"} && input=${input%"'"}
        echo -e "$input" > ._key/client.pub
		send_key server.pub
    else
		if [ -n "$input" ]
		then
			input=$(decrypt "$input" server.pem)
			if [[ ${input:0:3} == ":§:" ]]
			then
				input=${input#":§:"}
        		echo -e "\e[31m@server\e[0m:\e[34m$(date)\e[0m! $input" >&2
			else
				command=$(printf '%q' "$(eval "$input" 2>&1)")
        		send client.pub "$command"
			fi
		fi
    fi
}

# Function to handle server operations
function server()
{
	while IFS=  read -r line;
	do
		parser "$line"
	done
}

# Check if the FIFO file exists and remove it if it does
if test -e "./.fifo"
then
	rm ./.fifo
fi

# Create a FIFO fil
mkfifo ".fifo"

echo ">>>Initialization"

# Generate the server key pair and change the password if the '-n' option is provided
for args in "$@"
do
	if [ "$args" = "-n" ]
	then
		gen_key server.pem server.pub
		until set_passwd
		do
			true
		done
	fi
done

# Check if there is existing keys and password
if ! [ -d "._key/" ]
then
	gen_key server.pem server.pub
	until set_passwd
	do
		true
	done
fi

echo ">>>Server initialized"

# Continuously listen for incoming connections and process them
while true
do
	nc -l localhost 12345 < ./.fifo | server > ./.fifo
done