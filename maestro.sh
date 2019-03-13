#!/bin/bash


#maestro.sh: Execute batch commands in a pool of servers/routers/whatever
#Author: Eder Carneiro	


#Usage mastro.sh [-t <num threads] <hosts file> <commands file> 
#The Hosts file is a plain text file, whose have a host/ip adrress per line
#The commands file is also a plain text file, which have a command per line
#The '-t' option is aimed at parallelizing the execution
#Both files accept comments with a '#'

#TODO:
# - Print Better formatted messages on console
# - Add better treatment for connection timeout

#By adjusting some variables, someone could make this
#script work for a variety of devices.


HOSTSFILE=$1
CMDFILE=$2
LOGFOLDER="maestro_logs"

#PROMPT="001>"		 #prompt for huawei devices
PROMPT=":~"          	 #prompt for ubuntu
SUPROMPT="#"             #prompt for super user 
PSWDPROMT="*?assword"
LOGOUTCMD="quit"
SSHCMD="ssh" #Maybe "ssh -oKexAlgorithms=+diffie-hellman-group1-sha1" or something like that

#-#
function usage () {
	echo -e "\nUsage: mastro.sh [-t <int>] <hfile> <cmdfile> 
where:	
  -t 		Number of concurrent execution threads (default=1)
  hfile 	File containing the targeted hosts
  cmdfile 	File containing the commands to be executed on the hosts"
	exit
}

function getDate(){
    echo $(date +%d%m%Y_%H%M%S)
}

function doTheMagic(){

	#Cria um file de log para cada hosts
	H_LOGFILE=$(echo -ne "$1-$(getDate)")
			
	#echo "Host: $1 -->"

	expect -c "
	
	
	set timeout 60
	
	log_user 0
	log_file -a \"$LOGFOLDER/$H_LOGFILE\"
	
	
	
	set ff [open $CMDFILE \"r\"]
	set filedata [ read \$ff ]
	set cmdarray [split \$filedata \"\n\"]

	close \$ff
	

	## Login                
	
	spawn $SSHCMD $USERNAME@$1
	#log_user 1
	puts \"\r\"
	expect {
		\"yes/no\" { 
						send \"yes\r\"
						expect \"$PSWDPROMT\" { 
							send \"$PASSWORD\r\" 
							expect {
								\"$PROMPT\"   { send \"\r\" }	
								\"*failed\" { puts \"Host $1	 Not OK\" 
												exit 1 }
							}								
						}
				}
		\"$PSWDPROMT\" { 
						send \"$PASSWORD\r\" 
						expect {
							\"$PROMPT\"  { send \"\r\" }	
							\"*failed\" { puts \"Host $1	 Not OK\" 
										exit 1 }
							}								
						}
		\"*refused\"  { puts \"Host $1	 Not OK\" 
						exit 1 }
						
		\"No route to host\" { puts \"Host $1	 Not OK\" 
							   exit 1 }
							   
		\"timed out\" { puts \"Host $1	 Not OK\" 
							   exit 1 }                        
	}	

							 
	## Comannds	
	#log_user 1
	
	foreach cmd \$cmdarray {
			set cm \"\"
			set tr  \"#\n\"
			
			set cm [ lindex [ split \$cmd \$tr ] 0 ]
			#puts \"cm=\$cm\"
			 
			if { \$cm  != \"\" } {
				expect { 
						\"$PROMPT\" 	{ send \"\$cm \r\"}
						\"$SUPROMPT\"	{ send \"\$cm \r\"}
				}		 
			} 
						   
			
		}
	
	expect \"$PROMPT\" { send \"$LOGOUTCMD\r\" }		#pede pra sair
	puts \"\Host $1\t\tOK.\"
	exit 
	"
	
	
	#generates unique log
        echo -e "Start: Host=$TARGET -----------------------------------------" >> $LOGFOLDER/$EFOLDER/$EFOLDER.log
        cat $LOGFOLDER/$H_LOGFILE >> $LOGFOLDER/$EFOLDER/$EFOLDER.log
        echo -e "\nEnd: ($TARGET) -----------------------------------------------\n\n" >> $LOGFOLDER/$EFOLDER/$EFOLDER.log       
        rm $LOGFOLDER/$H_LOGFILE
		

}

THREADS=1 

while getopts 't:' opt
do
	case $opt in
		t) THREADS=$OPTARG;;
	
	esac
done
shift $((OPTIND-1))
HOSTSFILE=$1
CMDFILE=$2
if [[ -z $CMDFILE || -z $HOSTSFILE ]]; then
   usage
fi


read -p  "Username: "  USERNAME
read -sp "Password: "  PASSWORD
echo -e "\n"
 
 

#Create a general log folder
if [ ! -d "$LOGFOLDER" ]; then
  mkdir $LOGFOLDER
fi

#Create a folder for a single execution logs
EFOLDER=$(getDate)
if [ ! -d "$EFOLDER" ]; then
    mkdir $LOGFOLDER/$EFOLDER
fi
 

TCOUNTER=0 # threads counter. 
while read TARGET ;
do 
    TARGET=$(echo $TARGET | cut -d'#' -f1 ) # Allow comentaries in hosts file.
	
    declare -a ARRTRDS #PID Array
    if [ ! -z $TARGET ]  
    then
		doTheMagic $TARGET & ARRTRDS[$TCOUNTER]=$!
		TCOUNTER=$(( TCOUNTER + 1 ))		
		
		if [ $TCOUNTER -eq $THREADS ]
		then
			wait ${ARRTRDS[0]}	     #Wait until the first PID on array ends
			ARRTRDS=("${ARRTRDS[@]:1}")  #delete first element of thread's array
			TCOUNTER=$(( TCOUNTER - 1 ))
		fi
        
	fi
done < $(echo $HOSTSFILE)
echo -e "\n"

    
