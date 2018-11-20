#!/bin/bash


####################################################################
#                                                                  #
# WARNING - PLEASE CONSIDER THIS A WORK IN PROGRESS. I HAVE TESTED #
# IT ON MY SERVER AND THERE WAS NO ISSUE  BUT THAT DOESNT MEAN IN  #
# ANY WAY IT IS FREE FROM BUGS/ISSUES SO PLEASE USE AT YOUR OWN    #
# RISK UNTIL IT HAS BEEN TESTED FURTHER - WARNING                  #
#                                                                  #
####################################################################


####################################################################
#                                                                  #
# unraid-autovmbackup copyright 2015-2016, Daniel Jackson (danioj) #
#                                                                  #
####################################################################


# for support please goto script support page: 
#
# https://lime-technology.com/forum/index.php?topic=47986


# what is the scripts' official name.

official_script_name="unraid-autovmbackup-0-4.sh"


# default 0 but set the master switch to 1 if you want to enable the script otherwise it will not run.

enabled="0"


# set the name of the script to a variable so it can be used.

me=`basename "$0"`


# this script has been created to automate the backup of unRAID vm's vdisks(s) to a specified location. 
# this script does not yet run using variables passed from the cli as yet but there is intention to do so if there is interest.
# for now the variables below are what are needed to be ammended to have the script run.


# Change Log

# v0.1  20160330.
#	initial release.
#
#	notes: initial realease is more concept and to see if there is a need for it. it lacks basic error handling and recovery.
#	which could be developed later.

# v0.2  20160330.
#	bug fixes.
#
#	changed how the bash script is recognising the failed shutdown flag as after testing even a failed shutdown would start a backup.
#	changed default mins to wait for shutdown to 6.

# v0.3  20160415.
#	bug fixes and enhancements.
#
#	applied strickter naming conventions to variables. 
#	cleaned up the code, added comments, removed unecessary 'do' loops.
#	added input validation and verification.
#	added addition status messages. applied a bit more consistency.
#	added ability to deal with vm's with names that have spaces in them.
#	vms now seperated by "new line" not space.
#	added rsync copy over standard nix cp command.
#	added backup of vm xml configuration.
#	added option to add timestamps to backup files.
# 	added script name check for version control.
#	added option to enable / disable the script.
#	added option to start vm after failure.
#	added option to "dry-run" copy operation - note all other functionality is enabled.
# 	added ability to ignore vm's which are not installed on the system.
#	set defaults for all options to 0.
#	added guidence for options and inputs.
#	added constraint to only backup .img vdisks so to skip installation media etc.
#	changed method of obtaining vdisks list.
#	fixed issue which had script fail if no vdisks were present.

# v0.4  20160416.
#	administration.
#
#	script name changed to facilitate code being added to github.

# bug tracker (order by severity)

#	<reference>	<description>		<link to post>		<severity>		<date added>		<by whome>		<accepted/refected>		<comment>	


# to do list

# core
# 	error capturing and handling -- started (v0.3).
# 	apply stricter naming conventions -- done (v0.3).
# 	code clean up -- ongoing (v0.3)
# 	input validation and verification -- done (v0.3).
# 	logging.
# 	clean up status messages -- done (v0.3).
# 	deal with vm's named with spaces -- done (v0.3).

# possible improvements
#	use rsync to copy the vdisks instead of copy -- done (v0.3).

# possible future features
# 	backup vm xml file -- done (v0.3).
# 	have the script run from variables passed in from the cli.
# 	add timestamps to files -- done (v0.3).
# 	add iterations of backups and number of backups to maintain at any given time.
# 	plugin -- started (v0.3).

# plugin to-do's
#	basic structure and requirements -- done (v0.3)
#	git-hub account
#	ui validation via menus
#	.... much much more ....


##################################################### change these variables ###################################################


# script variables


# backup location to put vdisks.
# e.g backup_location="/mnt/user/share/backup_folder/"

backup_location=""


# list of domains that will be backed up seperated by a new line.
# e.g.: 
# vms_to_backup="
# windows 10
# ubuntu_main
# mac_OSXv3
# vm that doesnt exist on system"

vms_to_backup="
"


# default is 0 but set this to 1 if you would like to actually copy and backup files.

actually_copy_files="0"


# default is 0 but set this to 1 if you would like to add a timestamp to the backed up files.

timestamp_files="0"


# default is 10. set this to the number of times you would like to check if a clean shutdown of a vm has been successfull.

clean_shutdown_checks="10"


# default is 60. set this to the number of seconds to wait in between checks to see if a clean shutdown has been successfull.

seconds_to_wait="60"


# default is 0 but set this to 1 if you would like to kill a vm if it cant be shutdown cleanly.

kill_vm_if_cant_shutdown="0"


# default is 0 but set this to 1 if you would like to start a vm after it has successfully been backed up.

start_vm_after_backup="0"


# default is 0 but set this to 1 if you would like to start a vm after it has failed to have been backed up.

start_vm_after_failure="0"


################################################## end of variables section #####################################################



################################################### dont edit below here #######################################################


	# start of script.


	# check the name of the script is as it should be. if yes, continue. if no, exit.


	if [ "$me" == "$official_script_name" ]; then

		
		echo "information: official_script_name is $official_script_name. script name is valid. continuing."

	
	elif [ ! "$me" == "$official_script_name" ]; then


		echo "failure: official_script_name is $official_script_name. script name is invalid. exiting."

		exit 1

	
	fi


	# check to see if the script has been enabled or disabled by the user. if yes, continue if no, exit. if input invalid, exit.


	if [[ "$enabled" =~ ^(0|1)$ ]]; then

	
		if [ "$enabled" -eq 1 ]; then

	
			echo "information: enabled is $enabled. script is enabled. continuing."


		elif [ ! "$enabled" -eq 1 ]; then

		
			echo "failure: enabled is $enabled. script is disabled. exiting."

			exit 1

		fi

	else


		echo "failure: enabled is $enabled. this is not a valid format. expecting [0 - no] or [1 - yes]. exiting."		
		
		exit 1

	fi


	# check to see if the backup_location specified by the user exists. if yes, continue if no, exit. if exists check if writable, if yes continue, if not exit. if input invalid, exit.


	if [ -d "$backup_location" ]; then


		echo "information: backup_location is $backup_location. this location exists. continuing."


		# if backup_location does exist check to see if the backup_location is writable.


		if [ -w "$backup_location" ]; then


			echo "information: backup_location is $backup_location. this location is writable. continuing."

		
		else


			echo "failure: backup_location is $backup_location. this location is not writable. exiting."

			exit 1


		fi


	else

		
		echo "failure: backup_location is $backup_location. this location does not exist. exiting."

		exit 1


	fi


	# validate the actually_copy_files option. if yes the rsync command line option for dry-run. if input invalid, exit.

		
	if [[ "$actually_copy_files" =~ ^(0|1)$ ]]; then


		if [ "$actually_copy_files" -eq 0 ]; then

	
			echo "information: actually_copy_files flag is 0. no files will be copied."

		
			# create a variable which tells rsync to do a dry-run.

			rsync_dry_run_option="n"


		elif [ "$actually_copy_files" -eq 1 ]; then

		
			echo "warning: actually_copy_files is 1. files will be copied."


		fi


	else


		echo "failure: actually_copy_files is $actually_copy_files. this is not a valid format. expecting [0 - no] or [1 - yes]. exiting."

		exit 1


	fi	


	# check to see if i should add a timestamp to backed up files or not. if yes, continue if no, continue. if input invalid, exit.


	if [[ "$timestamp_files" =~ ^(0|1)$ ]]; then


		if [ "$timestamp_files" -eq 0 ]; then


			echo "information: timestamp_files is $timestamp_files. timestamp will not be added to backup files."


		elif  [ "$timestamp_files" -eq 1 ]; then


			echo "information: timestamp_files is $timestamp_files. timestamp will be added to backup files."

			# create a variable which is only used in rsync commands
	
			timestamp=`date '+%m%d%Y_%H%M%p'`"_"

		fi
		
	else 


		echo "failure: timestamp_files is $timestamp_files. this is not a valid format. expecting [0 - no] or [1 - yes]. exiting."

		exit 1


	fi


	# check to see how many times i should check for vm shutdown. if yes, continue if no, continue if input invalid, exit.


	if [[ "$clean_shutdown_checks" =~ ^[0-9]+$ ]]; then


		if [ "$clean_shutdown_checks" -lt 5 ]; then

		
			echo "warning: clean_shutdown_checks is $clean_shutdown_checks. this is potentially an insufficient number of shutdown checks."

	
		elif [ "$clean_shutdown_checks" -gt 50 ]; then


			echo "warning: clean_shutdown_checks is $clean_shutdown_checks. this is a vast number of shutdown checks."


		elif [ "$clean_shutdown_checks" -ge 5 -a "$clean_shutdown_checks" -le 50 ]; then

		
			echo "information: clean_shutdown_checks is $clean_shutdown_checks. this is probably a sufficient number of shutdown checks."

		
		fi


	else


		echo "failure: clean_shutdown_checks is $clean_shutdown_checks. this is not a valid format. expecting a number between [0 - 1000000]. exiting."		

		exit 1


	fi


	# check to see how long i should wait between checks for vm shutdown. messages to user only. if input invalid, exit.


	if [[ "$seconds_to_wait" =~ ^[0-9]+$ ]]; then


		if [ "$seconds_to_wait" -lt 60 ]; then

		
			echo "warning: seconds_to_wait is $seconds_to_wait. this is potentially an insufficient number of seconds to wait between shutdown checks."

	
		elif [ "$seconds_to_wait" -gt 3000 ]; then

		
			echo "warning: seconds_to_wait is seconds_to_wait. this is a vast number of seconds to wait between shutdown checks."

	
		elif [ "$seconds_to_wait" -ge 60 -a "$seconds_to_wait" -le 3000 ]; then

		
			echo "information: seconds_to_wait is $seconds_to_wait. this is probably a sufficent number of seconds to wait between shutdown checks."

		fi


	else


		echo "failure: seconds_to_wait is $seconds_to_wait. this is not a valid format. expecting a number between [0 - 1000000]. exiting."	

		exit 1


	fi	


	# check to see if i should force kill the vm if i cant do a clean shutdown. if yes, continue if no, continue. if input invalid, exit.

		
	if [[ "$kill_vm_if_cant_shutdown" =~ ^(0|1)$ ]]; then


		if [ "$kill_vm_if_cant_shutdown" -eq 0 ]; then

	
			echo "information: kill_vm_if_cant_shutdown is $kill_vm_if_cant_shutdown. vms will not be forced to shutdown if a clean shutdown can not be detected."


		elif [ "$actually_copy_files" -eq 1 ]; then

		
			echo "warning: kill_vm_if_cant_shutdown is $kill_vm_if_cant_shutdown. vms will be forced to shutdown if a clean shutdown can not be detected."


		fi


	else


		echo "failure: kill_vm_if_cant_shutdown is $kill_vm_if_cant_shutdown. this is not a valid format. expecting [0 - no] or [1 - yes]. exiting."

		exit 1


	fi	


	# check to see if i should start vms after a successfull backup. if yes, continue if no, continue. if input invalid, exit.

		
	if [[ "$start_vm_after_backup" =~ ^(0|1)$ ]]; then


		if [ "$start_vm_after_backup" -eq 0 ]; then

	
			echo "information: start_vm_after_backup is $start_vm_after_backup vms will not be started following a successfull backup."


		elif [ "$actually_copy_files" -eq 1 ]; then

		
			echo "warning: start_vm_after_backup is $start_vm_after_backup. vms will be started following successfull backup."


		fi


	else


		echo "failure: start_vm_after_backup is $start_vm_after_backup. this is not a valid format. expecting [0 - no] or [1 - yes]. exiting."

		exit 1


	fi	


	# check to see if i should start vms after an unsuccessfull backup. if yes, continue if no, continue. if input invalid, exit.

		
	if [[ "$start_vm_after_failure" =~ ^(0|1)$ ]]; then


		if [ "$start_vm_after_failure" -eq 0 ]; then

	
			echo "information: start_vm_after_failure is $start_vm_after_failure. vms will not be started following an unsuccessfull backup."


		elif [ "$actually_copy_files" -eq 1 ]; then

		
			echo "warning: start_vm_after_failure is $start_vm_after_failure. vms will be started following an unsuccessfull backup."


		fi


	else


		echo "failure: start_vm_after_failure is $start_vm_after_failure. this is not a valid format. expecting [0 - no] or [1 - yes]. exiting."

		exit 1


	fi	


	echo "information: started attempt to backup "$vms_to_backup" to $backup_location"


	# set this to force the for loop to split on new lines and not spaces. 
	

	IFS=$'\n'


	# loop through the vms in the list and try and back up thier associated xml configurations and vdisk(s).
	

	for vm in $vms_to_backup

	do


		# get a list of the vm names installed on the system.


		vm_exists=$(virsh list --all --name)	

		
		# assume the vm is not going to be backed up until it is found on the system

		skip_vm="y"


		# check to see if the vm exists on the system to backup.


		for vmname in $vm_exists
		
		do
	
			# if the vm doesnt match then set the skip flag to y.


			if [ "$vm" == "$vmname" ] ; then


				# set a flag i am going to check later to indicate if i should skip this vm or not.

				skip_vm="n"

				
				# skips current loop


				continue


			fi

		done


		# if the skip flag was set in the previous section then we have to exit and move onto the next vm in the list.


		if [ "$skip_vm" == "y" ]; then


			echo "warning: $vm can not be found on the system. skipping vm."
			
			skip_vm="n"

			
			# skips current loop.			

		
			continue


		else


			echo "information: $vm can be found on the system. attempting backup."

	
		fi


		# lets create a directory named after the vm within backup_location to store the backup files.


		if [ ! -d $backup_location/$vm ] ; then
 

			echo "action: backup_location/$vm does not exist. creating it."


			# make the directory as it doesnt exist. added -v option to give a confirmation message to command line.


			mkdir -vp $backup_location/$vm


		else


			echo "information: $backup_location/$vm exists. continuing."


		fi


		# get the state of the vm.

	
		vm_state=$(virsh domstate "$vm")

		
		# resume the vm if it is suspended, based on testing this should be instant but will trap later if it has not resumed.


		if [ "$vm_state" == "paused" ]; then
 

			echo "action: $vm is $vm_state. resuming."


			# resume the vm.


			virsh resume "$vm"


		fi

		
		# get the state of the vm.

	
		vm_state=$(virsh domstate "$vm")		

		
		# if the vm is running try and shut it down.


		if [ "$vm_state" == "running" ]; then
 

			echo "action: $vm is $vm_state. shutting down."

			
			# attempt to cleanly shutdown the vm.


			virsh shutdown "$vm"


			echo "information: performing $clean_shutdown_checks $seconds_to_wait second cycles waiting for $vm to shutdown cleanly"

				
			# the shutdown of the vm may last a while so we are going to check periodically based on global input variables.


			for (( i=1; i<=$clean_shutdown_checks; i++ ))

			do

				echo "information: cycle $i of $clean_shutdown_checks: waiting $seconds_to_wait seconds before checking if the vm has shutdown"


				# wait x seconds based on how many seconds the user wants to wait between checks for a clean shutdown.


				sleep $seconds_to_wait


				# get the state of the vm.

	
				vm_state=$(virsh domstate "$vm")		
					

				# if the vm is running decide what to do.


				if [ "$vm_state" == "running" ]; then


					echo "information: $vm is $vm_state"


					# if we have already exhausted our wait time set by the script variables then its time to do soemthing else.


					if [ $i = "$clean_shutdown_checks" ] ; then


						# check if the user wants to kill the vm on failure of unclean shutdown.


						if [ "$kill_vm_if_cant_shutdown" -eq 1 ]; then
 

							echo "action: kill_vm_if_cant_shutdown is $kill_vm_if_cant_shutdown. killing vm."


							# destroy vm, based on testing this should be instant and without failure.

							virsh destroy "$vm"

							
							# get the state of the vm.

	
							vm_state=$(virsh domstate "$vm")

							
							# if the vm is shut off then proceed or give up.	
							
							
							if [ "$vm_state" == "shut off" ]; then


								# set a flag to check later to indicate whether to backup this vm or not.


								can_backup_vm="y"


								echo "information: $vm is $vm_state. can_backup_vm set to $can_backup_vm"

								
								break


							else
	

								# set a flag to check later to indicate whether to backup this vm or not.

								can_backup_vm="n"

								echo "failure: $vm is $vm_state. can_backup_vm set to $can_backup_vm"
	

							fi
				

						# if the user doesnt want to force a shutdown then there is nothing more to do so i cannot backup the vm.	
							

						else

							# set a flag to check later to indicate whether to backup this vm or not.

							can_backup_vm="n"


							echo "failure: $vm is $vm_state. can_backup_vm set to $can_backup_vm"


						fi


					fi

				
				# if the vm is shut off then go onto backing it up.


				elif [ "$vm_state" == "shut off" ]; then


					# set a flag to check later to indicate whether to backup this vm or not.

					can_backup_vm="y"


					echo "information: $vm is $vm_state. can_backup_vm set to $can_backup_vm"


					break


				# if the vm is in a state that is not explicitly defined then do nothing as it is unknown how to handle it.


				else


					# set a flag to check later to indicate whether to backup this vm or not.


					can_backup_vm="n"


					echo "failure: $vm is $vm_state. can_backup_vm set to $can_backup_vm"



				fi

				
			done


		# if the vm is shut off then go straight onto backing it up.


		elif [ "$vm_state" == "shut off" ]; then


			# set a flag to check later to indicate whether to backup this vm or not.

			
			can_backup_vm="y"


			echo "information: $vm is $vm_state. can_backup_vm set to $can_backup_vm"


		# if the vm is suspended then something went wrong with the attempt to recover it earlier so do not attempt to backup.


		elif [ "$vm_state" == "suspended" ]; then


			# set a flag to check later to indicate whether to backup this vm or not.

			
			can_backup_vm="n"


			echo "failure: $vm is $vm_state. can_backup_vm set to $can_backup_vm"


		# if the vm is in a state that has not been explicitly defined then do nothing as it is unknown how to handle it.


		else


			# set a flag to check later to indicate whether to backup this vm or not.


			can_backup_vm="n"


			echo "failure: $vm is $vm_state. can_backup_vm set to $can_backup_vm"


		fi


		# check whether to backup the vm or not.


		if [[ "$can_backup_vm" == "y" ]]; then


			echo "action: can_backup_vm flag is $can_backup_vm. starting backup of $vm xml configuration and vdisk(s)."


			# dump the vm xml configuration locally first.


			virsh dumpxml "$vm" > "$vm.xml"

			
			echo "action: actually_copy_files is $actually_copy_files."


			# copy or pretend to copy the vdisk to the backup location specified by the user.


			rsync -av$rsync_dry_run_option "$vm.xml" "$backup_location/$vm/$timestamp$vm.xml"

			
			# delete the local copy of the xml configuration.


			rm "$vm.xml"

			
			# send a message to the user based on whether there was an actual copy or a dry-run.		


			if [ "$actually_copy_files" -eq 0 ]; then


				echo "information: dry-run backup of $vm xml configuration to $backup_location/$vm/$timestamp$vm.xml complete."


			else			

			
				echo "information: backup of $vm xml configuration to $backup_location/$vm/$timestamp$vm.xml complete."


			fi

			

			# get the list of the vdisks associated with the vm and address them one by one.


			vdisks=$(virsh domblklist "$vm" --details | grep -v "^$" | grep -v "^Target" | grep -v "\-\-\-\-\-" | awk -F" {2,}" '{print $4}')


			# check for the header in vdisks to see if there are any disks


			if [ "$vdisks" == "Source" ]; then

				
				echo "warning: there are no vdisk(s) associated with $vm to backup."

			fi



			for disk in $vdisks


			do
	
				if [ ! "$disk" == "Source" ]; then


					# get the filename of the disk without the path.


					new_disk=$(basename $disk)


					# check the extension of the disk to ensure only .img disks are copied.

					
					if [ ! "${disk##*.}" == "img" ]; then

		
						echo "warning: $disk of $vm is not a vdisk. skipping."


						continue


					fi
		
			
					echo "action: actually_copy_files is $actually_copy_files."
	

					# copy or pretend to copy the vdisk to the backup location specified by the user.


			        	rsync -av$rsync_dry_run_option "$disk" "$backup_location/$vm/$timestamp$new_disk"
				

					# send a message to the user based on whether there was an actual copy or a dry-run.	

				
					if [ "$actually_copy_files" -eq 0 ]; then


						echo "information: dry-run backup of $new_disk vdisk to $backup_location/$vm/$timestamp$new_disk complete."


					else			

			
						echo "information: backup of $new_disk vdisk to $backup_location/$vm/$timestamp$new_disk complete."


					fi

				fi
	
			done


			# if start_vm_after_backup is set to 1 then start the vm but dont check that it has been successfull.


			if [ "$start_vm_after_backup" -eq 1 ]; then 


                               	echo "action: start_vm_after_backup is $start_vm_after_backup. starting $vm."


				# try and start the vm.

                               	virsh start "$vm"


			fi


		else


			# for whatever reason the backup attempt failed.
		

			echo "failure: backup of "$vm" to $backup_location/$vm failed."


			# if start_vm_after_failure is set to 1 then start the vm but dont check that it has been successfull.


			if [ "$start_vm_after_failure" -eq 1 ]; then 


                               	echo "action: start_vm_after_failure is $start_vm_after_failure starting $vm."


				# try and start the vm.

                               	virsh start "$vm"


			fi


		fi


		echo "information: backup of "$vm" to $backup_location/$vm completed."


	done


	echo "information: finished attempt to backup "$vms_to_backup" to $backup_location."


	exit 0


	# end of script


################################################### dont edit above here #######################################################

