#!/bin/bash
# Copyright (C) 2016 Michał Karol <michal.p.karol@gmail.com>
# Script is licenced under GNU GPLv3 licenced
# Licence tekst: http://www.gnu.org/licenses/

# website-monitor.sh - Monitors a web page for changes
# and sends an email notification if the content change

if ([ ! -d $HOME/.website-monitor/ ]); then
    mkdir -p $HOME/.website-monitor/data
    touch $HOME/.website-monitor/urls.txt
    echo -e "# Place one url per line\n" > $HOME/.website-monitor/urls.txt
    editor $HOME/.website-monitor/urls.txt
    touch $HOME/.website-monitor/config.txt
    echo -e "MAILADDR=\"yourmail@domain.com\"\nPASS=password\nSERVER=server (eg. gmail.com)\nSERVERPORT=465\nIDENTITY=\"identity (eg. John Doe)\"\nSUBJECT=\"subject\"\nMESSAGE=\"message\"" > $HOME/.website-monitor/config.txt
    editor $HOME/.website-monitor/config.txt
    chmod 600 $HOME/.website-monitor/config.txt
fi

if ([ -e $HOME"/.website-monitor/urls.txt" ] && [ -e $HOME"/.website-monitor/config.txt" ]); then
    while read URL; do
        if ([ ! -z "$URL" ] && [[ ! $URL =~ ^#+ ]]); then
            . $HOME"/.website-monitor/config.txt"
            
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
            echo $LEFTSUM
            echo $RIGHTSUM
            
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
    done < $HOME"/.website-monitor/urls.txt"
fi



