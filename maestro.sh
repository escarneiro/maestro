#!/bin/bash


#maestro.sh: Execute batch commands in a pool of servers/routers/whatever
#Author: Eder Carneiro	


#Usage huawei.sh <hosts file> <commands file> 
#The Hosts file is a plain text file, whose have a host/ip adrress per line
#The commands file is also a plain text file, which have a command per line
#Both files accept comments with a '#'


#By adjusting the following variables, someone could make this
#script work for a variety of devices.


HOSTSFILE=$1
CMDFILE=$2
LOGFOLDER="maestro_logs"

#PROMPT="001>"			#prompt for huawei devices
PROMPT=":~"          	#prompt for ubuntu
PSWDPROMT="*?assword"
LOGOUTCMD="quit"

#-#

function usage () {
	echo -e "Usage huawei.sh <hosts file> <commands file>  \n"
	exit
}

function getDate(){
    echo $(date +%d%m%Y_%H%M%S)
}


if [ "$#" -lt 2 ]; then
   usage
fi


read -p  "Username: "  USERNAME
read -sp "Password: "  PASSWORD
echo -e "\n"
 
 

#Generate a general log folder
if [ ! -d "$LOGFOLDER" ]; then
  mkdir $LOGFOLDER
fi

#Generate a folder for a single execution logs
EFOLDER=$(getDate)
if [ ! -d "$EFOLDER" ]; then
    mkdir $LOGFOLDER/$EFOLDER
fi
 

while read TARGET ;
do 
    TARGET=$(echo $TARGET | cut -d'#' -f1 ) 	#Allow comentaries

    if [ ! -z $TARGET ]  
    then
    
        #Creates a log file for each host
        H_LOGFILE=$(echo -ne "$TARGET-$(getDate)")
                
        #echo "Host: $TARGET -->"
    
        expect -c "
        
        puts -nonewline \"Host: $TARGET -->\"
        set timeout 60
        
        log_user 0
        log_file -a \"$LOGFOLDER/$H_LOGFILE\"
        
        
        
        set ff [open $CMDFILE \"r\"]
        set filedata [ read \$ff ]
        set cmdarray [split \$filedata \"\n\"]

        close \$ff
        

        ## Login                
        
        spawn ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 $USERNAME@$TARGET
        #log_user 1
        puts \"\r\"
        expect {
            \"yes/no\" { 
                            send \"yes\r\"
                            expect \"$PSWDPROMT\" { 
                                send \"$PASSWORD\r\" 
                                expect {
                                    \"$PROMPT\"   { send \"\r\" }	
                                    \"*failed\" { exit 1 }
                                }								
                            }
                    }
            \"$PSWDPROMT\" { 
                            send \"$PASSWORD\r\" 
                            expect {
                                \"$PROMPT\"  { send \"\r\" }	
                                \"*failed\" { exit 1 }
                                }								
                            }
            \"*refused\"  { puts \"Not OK\" 
                            exit 1 }
                            
            \"No route to host\" { puts \"Not OK\" 
                                   exit 1 }
                                   
            \"timed out\" { puts \"Not OK\" 
                                   exit 1 }                        
        }	

                                 
        ## Commands	
        #log_user 1
        
        foreach cmd \$cmdarray {
                set cm \"\"
                set tr  \"#\n\"
                
                set cm [ lindex [ split \$cmd \$tr ] 0 ]
                #puts \"cm=\$cm\"
                 
                if { \$cm  != \"\" } {
                    expect \"$PROMPT\" { send \"\$cm \r\"}
                } 
                               
                
            }
        
        expect \"$PROMPT\" { send \"$LOGOUTCMD\r\" }		#pede pra sair
        puts \"\OK.\"
        exit 
        "
        
        
        #generates unique log
        echo -e "Start: Host=$TARGET -----------------------------------------" >> $LOGFOLDER/$EFOLDER/$EFOLDER.log
        cat $LOGFOLDER/$H_LOGFILE >> $LOGFOLDER/$EFOLDER/$EFOLDER.log
        echo -e "\nEnd: ($TARGET) -----------------------------------------------\n\n" >> $LOGFOLDER/$EFOLDER/$EFOLDER.log       
        rm $LOGFOLDER/$H_LOGFILE
        
	fi
done < $(echo $HOSTSFILE)
echo -e "\n"

    
