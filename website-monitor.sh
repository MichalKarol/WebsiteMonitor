#!/bin/bash
# Copyright (C) 2016 Michał Karol <michal.p.karol@gmail.com>
# Script is licenced under GNU GPLv3 licenced
# Licence tekst: http://www.gnu.org/licenses/

# website-monitor.sh - Monitors a web page for changes
# and sends an email notification if the content change

CONFFILE=$HOME/.website-monitor/config.txt
URLSFILE=$HOME/.website-monitor/urls.txt

if ([ ! -d $HOME/.website-monitor/ ]); then
    mkdir -p $HOME/.website-monitor/data
    touch $URLSFILE
    echo -e "# Place one url per line\n" > $URLSFILE
    editor $URLSFILE
    touch $CONFFILE
    echo -e "MAILADDR=\"yourmail@domain.com\"\nPASS=password\nSERVER=server (eg. gmail.com)\nSERVERPORT=465\nIDENTITY=\"identity (eg. John Doe)\"\nSUBJECT=\"subject\"\nMESSAGE=\"message\"" > $CONFFILE
    editor $CONFFILE
    chmod 600 $CONFFILE
fi

if ([ -e $URLSFILE ] && [ -e $CONFFILE ]); then
    while read URL; do
        if ([ ! -z "$URL" ] && [[ ! $URL =~ ^#+ ]]); then
            . $CONFFILE
            
            USERNAME=$(echo $MAILADDR | base64)
            PASSWORD=$(echo $PASS | base64)
            
            SUM=$(echo $URL | md5sum | awk '{print $1}')
            WEBFILE=$HOME"/.website-monitor/data/"$SUM".html"
            links -dump $URL > $WEBFILE".new"
            LEFTSUM=" "
            
            if ([ -e $WEBFILE ]); then
                LEFTSUM=$(cat $WEBFILE | md5sum | awk '{print $1}')
            fi
            
            RIGHTSUM=$(cat $WEBFILE".new" | md5sum | awk '{print $1}')
                        
            if ([ -e $WEBFILE ] && [ ! $LEFTSUM == $RIGHTSUM ]); then
                (echo -ne "ehlo "$SERVER"\r\n"; sleep 1;
                echo -ne "auth login\r\n"; sleep 1;
                echo -ne $USERNAME"\r\n"; sleep 1;
                echo -ne $PASSWORD"\r\n"; sleep 1;
                echo -ne "mail from: <"$MAILADDR">\r\n"; sleep 1;
                echo -ne "rcpt to: <"$MAILADDR">\r\n"; sleep 1;
                echo -ne "data\r\n"; sleep 1;
                echo -ne "Subject: "$SUBJECT"\r\nTo: "$IDENTITY"<"$MAILADDR">\r\n\r\n"$MESSAGE": "$URL"\r\n.\r\n";       sleep 1;
                echo -ne "quit\r\n";) | openssl s_client -connect smtp.$SERVER:$SERVERPORT
            fi
            mv $WEBFILE".new" $WEBFILE
        fi
    done < $URLSFILE
fi
