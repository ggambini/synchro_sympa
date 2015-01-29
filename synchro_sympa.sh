#!/bin/bash

#
# PARAM
#
	# Connexion site Sympa
	SYMPA_URL="https://<sympa_url>/wws/dump/<my_list>/light"
	SYMPA_FILE="owncloud_sympa.dump"
	SYMPA_MAIL="<sympa_mailaddress>"
	SYMPA_LIST="<my_list>"
	SYMPA_SENDER="<owncloud-server_mailaddress>"

	# Connexion mysql My CoRe
	MYSQL_HOST="localhost"
	MYSQL_PORT="3306"
	MYSQL_BASE="<owncloud_databasename>"
	MYSQL_USER="<owncloud_mysql-user>"
	MYSQL_PASS="<owncloud_mysql-pass>"
	MYSQL_FILE="owncloud_mysql.dump"
	MYSQL_SELECT="SELECT uid FROM oc_user_gtu_validations;"

	# Autres
	ADD_FILE="add_file.txt"
	DEL_FILE="del_file.txt"
	# Log_file vide = syslog
	LOG_FILE="synchro_sympa.log"
	LOG_HOSTNAME=`/bin/hostname`
	LOCK_FILE="synchro_sympa.lock"
	

#
# Functions
#
	function removeLock {
		debug=`/bin/rm ${LOCK_FILE} 2>&1`
	        if [[ $? -ge "1" ]]
	        then
                	# TODO Cmd fail + log
                	writeLog "FAIL removeLock : $debug"
                	exit 2
	        fi

	}

	function writeLog {
		message=$1
		if [[ "$LOG_FILE" != "" ]]
		then
			now=`date +%d/%m/%y-%H:%M:%S`
                        echo "$now - $message" >> $LOG_FILE
		else
			/usr/bin/logger $message
		fi
	}

#
# Check du verrou
#
	if [[ -f ${LOCK_FILE} ]]
	then
		exit
	else
		touch ${LOCK_FILE}
		START_DATE=`/bin/date +%s`
	fi

# WGET du dump sympa
	debug=`/usr/bin/wget --no-check-certificate ${SYMPA_URL} -O ${SYMPA_FILE} 2>&1`
	if [[ $? -ge "1" ]]
       	then
        	# Cmd fail
        	removeLock
		writeLog "FAIL wget_sympa : $debug"
        	exit 3
	fi

	# On trie dans l'ordre alpha
	debug=`/bin/sort -o ${SYMPA_FILE} ${SYMPA_FILE} 2>&1`
	if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
                writeLog "FAIL sort_sympa : $debug"
                exit 3
        fi


# SELECT users dans la base
        /usr/bin/mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} --password=${MYSQL_PASS} ${MYSQL_BASE} -s -e "${MYSQL_SELECT}" > ${MYSQL_FILE}
	if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
		#TODO debug_info
		writeLog "FAIL select_mysql"
                exit 4
        fi

	# On trie dans l'ordre alpha
        debug=`/bin/sort -o ${MYSQL_FILE} ${MYSQL_FILE} 2>&1`
        if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
                writeLog "FAIL sort_mysql : $debug"
                exit 3
        fi

# Diff adresses a abonner a la liste
	#/usr/bin/diff ${MYSQL_FILE} ${SYMPA_FILE} | egrep "^<" | sed -e "s/^</QUIET ADD ${SYMPA_LIST}/" > ${ADD_FILE}
	/usr/bin/comm -3 -2 ${MYSQL_FILE} ${SYMPA_FILE} > ${ADD_FILE}
	if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
                writeLog "FAIL comm_add"
                exit 3
        fi

	debug=`/bin/sed -i "s/\(.*\)/QUIET ADD ${SYMPA_LIST} \1/" ${ADD_FILE}`
	if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
                writeLog "FAIL sed_add : $debug"
                exit 3
        fi

	NB_ADD=`wc -l ${ADD_FILE} | cut -d " " -f 1`
	echo "QUIT" >> ${ADD_FILE}

# Diff adresses a desabonner a la liste
	#/usr/bin/diff ${MYSQL_FILE} ${SYMPA_FILE} | egrep "^>" | sed -e "s/^>/QUIET DELETE ${SYMPA_LIST}/" > ${DEL_FILE}
	/usr/bin/comm -3 -1 ${MYSQL_FILE} ${SYMPA_FILE} > ${DEL_FILE}
	if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
                writeLog "FAIL comm_del"
                exit 3
        fi

	debug=`/bin/sed -i "s/\(.*\)/QUIET DELETE ${SYMPA_LIST} \1/" ${DEL_FILE}`
	if [[ $? -ge "1" ]]
        then
                # Cmd fail
                removeLock
                writeLog "FAIL sed_del : $debug"
                exit 3
        fi

	NB_DEL=`wc -l ${DEL_FILE} | cut -d " " -f 1`
	echo "QUIT" >> ${DEL_FILE}

# Envoi commandes a sympa
	# Add
	if [[ $NB_ADD > 0 ]]
	then
		debug=`/bin/mail -r "${SYMPA_SENDER}" ${SYMPA_MAIL} < ${ADD_FILE}`
		if [[ $? -ge "1" ]]
	        then
	                # Cmd fail
	                removeLock
	                writeLog "FAIL wget : $debug"
	        	exit 5
        	fi
	fi

	# Delete
	if [[ $NB_DEL > 0 ]]
        then
                debug=`/bin/mail -r "${SYMPA_SENDER}" ${SYMPA_MAIL} < ${DEL_FILE}`
                if [[ $? -ge "1" ]]
                then
                        # Cmd fail
                        removeLock
                        writeLog "FAIL wget : $debug"
                        exit 5
                fi
        fi

# Nettoyage fichiers temp
	debug=`/bin/rm -f ${ADD_FILE} ${DEL_FILE} ${MYSQL_FILE} ${SYMPA_FILE} 2>&1`
	if [[ $? -ge "1" ]]
       	then
                # Cmd fail
                removeLock
		writeLog "FAIL removeTemp : $debug"
                exit 6
        fi

#Quit
	END_DATE=`/bin/date +%s`
	EXEC_TIME=`expr $END_DATE - $START_DATE`
	writeLog "OK : Add ${NB_ADD} address / delete ${NB_DEL} address / ${EXEC_TIME} seconds on $LOG_HOSTNAME"
	removeLock

