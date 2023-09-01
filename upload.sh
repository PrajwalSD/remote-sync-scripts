#!/bin/bash
###################################################################################
#                                                                                 #
#  Script: upload.sh                                                              #
#    Desc: Syncs the remote repository with a local repository via rsync          #
#   Usage: ./upload.sh <directory-list>(optional) <exclusion-list>(optional)      #
#                                                                                 #
###################################################################################

################################ Utility functions ################################
#------
# Name: set_colors_codes()
# Desc: Bash color codes, reference: https://misc.flogisoft.com/bash/tip_colors_and_formatting
#   In: <NA>
#  Out: <NA>
#------
function set_colors_codes(){
    # Foreground colors
    black=$'\e[30m'
    red=$'\e[31m'
    green=$'\e[1;32m'
    yellow=$'\e[1;33m'
    blue=$'\e[1;34m'
    light_blue=$'\e[94m'
    magenta=$'\e[1;35m'
    cyan=$'\e[1;36m'
    grey=$'\e[38;5;243m'
    white=$'\e[0m'
    light_yellow=$'\e[38;5;101m' 
    orange=$'\e[38;5;215m'

    # Color term
    end=$'\e[0m'

    # Background colors
    red_bg=$'\e[41m'
    green_bg=$'\e[42m'
    blue_bg=$'\e[44m'
    yellow_bg=$'\e[43m'
    darkgrey_bg=$'\e[100m'
    orange_bg=$'\e[48;5;215m'
    white_bg=$'\e[107m'

    # Manipulators
    blink=$'\e[5m'
    bold=$'\e[1m'
    italic=$'\e[3m'
    underline=$'\e[4m'

    # Reset text attributes to normal without clearing screen.
    alias reset_colors="tput sgr0" 

    # Checkmark (green)
    green_check_mark="\033[0;32m\xE2\x9C\x94\033[0m"
}
#------
# Name: remove_a_line_from_file()
# Desc: Remove a line from a file
#   In: string, filename
#  Out: <NA>
#------
function remove_a_line_from_file(){
    # Input parameters
    rm_pat=$1
    rm_file=$2

    # Match and remove the line (in line edit)
    if [[ ! "$rm_pat" == "" ]]; then
        sed -i "/$rm_pat/d" $rm_file
    fi
}
#------
# Name: add_a_newline_char_to_eof()
# Desc: This function will add a new line character to the end of file (only if it doesn't exists)
#   In: file-name
#  Out: <NA>
#------
function add_a_newline_char_to_eof(){
	if [[ -f $1 ]]; then
		if [ "$(tail -c1 "$1"; echo x)" != $'\nx' ]; then     
			echo "" >> "$1"; 
		fi
	fi
}
#------
# Name: check_if_the_dir_exists()
# Desc: Check if the specified directory exists
#   In: directory-name (multiple could be specified)
#  Out: <NA>
#------
function check_if_the_dir_exists(){
    for dir in "$@"
    do
        if [[ ! -d "$dir" ]]; then
            printf "${red}*** ERROR: Directory ${white}${red_bg}$dir${white}${red} was not found in the server, make sure you have correctly set the script parameters as per the environment (PWD: $PWD)*** ${white}"
            exit 1
        fi
    done
}
#------
# Name: rsync_remote_directory_with_local_directory()
# Desc: Sync the remote directory with local directory contents
#   In: 
#  Out: <NA>
#------
function rsync_remote_directory_with_local_directory(){
	# Input parameters
    rs_local_dir_pre=$1
    rs_remote_dir_pre=$2
	
	# Edits
	rs_local_dir=$rs_local_dir_pre
    rs_remote_dir=$(dirname ${rs_remote_dir_pre})

    # Go ahead and sync
    printf "${grey}${rs_local_dir}(local) ---> ${rs_remote_dir_pre}(remote: $remote_server_user@$remote_server_hostname)${white}\n"

    # Print the command for ref 
    if [[ "$enable_debug" == "Y" || "$enable_debug" == "y" ]]; then
        printf "${grey}$rsync_cmd \"${rs_local_dir}\" --rsync-path=\"mkdir -p ${rs_remote_dir} && rsync\" \"${remote_server_user}@${remote_server_hostname}:${rs_remote_dir}\" ${white}\n\n"
    fi

    # Sync
    $rsync_cmd "${rs_local_dir}" --rsync-path="mkdir -p ${rs_remote_dir} && rsync" "${remote_server_user}@${remote_server_hostname}:${rs_remote_dir}"
}
#------
# Name: create_a_file_if_not_exists()
# Desc: This function will create a new file if it doesn't exist, that's all.
#   In: file-name (multiple files can be provided)
#  Out: <NA>
#------
function create_a_file_if_not_exists(){
    for fil in "$@"
    do
        if [[ ! -f $fil ]]; then
            echo 0 > $fil
            # Check if the file was created successfully
            if [[ ! -f $fil ]]; then
                printf "${red}*** ERROR: ${white}${red_bg}$fil${white}${red} could not be created, check the permissions *** ${white}\n"
                exit 1
            else
                chmod 775 $fil
            fi
        fi
    done
}
#------
# Name: create_a_directory_if_not_exists()
# Desc: This function will create a new directory if it doesn't exist, that's all.
#   In: dir-name
#  Out: <NA>
#------
function create_a_directory_if_not_exists(){
    # Input parameters
    dir_name=$1

    # Create a directory, if it's not present
    if [ ! -d ${dir_name} ]; then
        printf "${grey}${dir_name} is missing, creating a new directory...${white}\n";
        mkdir -p ${dir_name};
    fi

    # Check
    if [ ! -d ${dir_name} ]; then
        printf "${red}ERROR: Something went wrong, ${dir_name} directory cannot be created (invalid path OR permission issues?)${white}\n";
        exit
    fi
}
#------
# Name: print_a_line_break()
# Desc: This prints a line break
#   In: line-break-single-char
#  Out: <NA>
#------
function print_a_line_break(){
    # Input parameters
    line_break_msg=${1:-Complete}
    line_break_color=${2:-green}

    # Create a directory, if it's not present
    printf ${!line_break_color}
    printf '%.s─' $(seq 1 $(tput cols))
    printf ${end}
}
#------
# Name: print_a_timestamp()
# Desc: Formats and prints a timestamp ("mins ago or days ago" format) 
#   In: last-sync-timestamp
#  Out: <NA>
#------
function print_a_timestamp(){
    # Input parameters
    prnt_timestamp=$1
    prnt_timestamp_msg=$2
    prnt_timestamp_color=${3:-green}

    # Current Timestamp
    current_timestamp=$(date +%s)

    # Calc
    if [[ $(((current_timestamp-last_sync_timestamp))) -lt 60 ]]; then
        prnt_time_elapsed_msg="$(((current_timestamp-last_sync_timestamp))) secs ago";
    elif [[ $((((current_timestamp-last_sync_timestamp)+60-1)/60)) -lt 60 ]]; then
        prnt_time_elapsed_msg="$((((current_timestamp-last_sync_timestamp)+60-1)/60)) mins ago";
    elif [[ $((((current_timestamp-last_sync_timestamp)+3600-1)/3600)) -lt 24 ]]; then
        prnt_time_elapsed_msg="$((((current_timestamp-last_sync_timestamp)+3600-1)/3600)) hours ago";
    else
        prnt_time_elapsed_msg="$((((current_timestamp-last_sync_timestamp)+86400-1)/86400)) days ago";
    fi
        
    # Print
    if [[ $last_sync_timestamp -gt 0 ]]; then 
        if [[ $OSTYPE == 'darwin'* ]]; then # macoS bash quirk!
            printf "${!prnt_timestamp_color}${prnt_timestamp_msg}`date -r ${last_sync_timestamp}` (i.e., ~${prnt_time_elapsed_msg})${white}\n"
        else
            printf "${!prnt_timestamp_color}${prnt_timestamp_msg}`date -d @${last_sync_timestamp} +"%d/%m/%Y %T"` (i.e., ~${prnt_time_elapsed_msg})${white}\n"
        fi
    else
        printf "${!prnt_timestamp_color}${white}\n"
    fi
}
#------
# Name: print_last_sync_info()
# Desc: Just prints a timestamp and 
#   In: timestamp-file-that-contains-last-sync-string-date-value
#  Out: <NA>
#------
function print_last_sync_info(){
    # Input parameters
    sync_timestamp_file_for_a_sync_target=$1

    # Print the last sync info
    create_a_file_if_not_exists ${sync_timestamp_file_for_a_sync_target}
    last_sync_timestamp=$(<${sync_timestamp_file_for_a_sync_target})
    current_timestamp=$(date +%s)
    print_a_timestamp ${last_sync_timestamp} ", last synced on "
}
#------
# Name: get_current_terminal_cursor_position()
# Desc: Get the current cursor position, reference: https://stackoverflow.com/questions/2575037/how-to-get-the-cursor-position-in-bash
#   In: col-pos-output-variable-name (optional), row-pos-output-variable-name (optional)
#  Out: current_cursor_row_pos, current_cursor_col_pos
#------
function get_current_terminal_cursor_position() {
    # Input parameters
    row_pos_output_var="${1:-current_cursor_row_pos}"
    col_pos_output_var="${2:-current_cursor_col_pos}"

    # Get cursor position
    local pos
    printf "${red}"
    IFS='[;' read -p < /dev/tty $'\e[6n' -d R -a pos -rs || echo "*** ERROR: The cursor position fetch function failed with an error: $? ; ${pos[*]} ***"
    # Assign to the output variables
    eval "$row_pos_output_var=${pos[1]}"
    eval "$col_pos_output_var=${pos[2]}"
    printf "${white}"
}
#------
# Name: fill_up_remaining_cols_with_a_char()
# Desc: Fill up the rest of the line with a character (Ansible style)
#   In: message, character-to-fill, color
#  Out: current_cursor_row_pos, current_cursor_col_pos
#------
function fill_up_remaining_cols_with_a_char(){
    # Input parameters
    flup_msg=$1
    flup_char=${2:-"-"}
    flup_color=${!3}

    # Print the message
    printf "${green}${flup_msg}${white}" 

    # Get the current cursor position based on the above message, fill the rest
    get_current_terminal_cursor_position curr_cursor_row_pos curr_cursor_col_pos

    # Fill up!
    cols=$(tput cols)
    remaining_cols=$((cols-curr_cursor_col_pos))
    for ((i=0; i<remaining_cols; i++));do printf "${green}${flup_char}${white}"; done; echo
}
#------
# Name: string_to_hash()
# Desc: Creates a hash of string using md5sum utility
#   In: string, hash-output-var-name
#  Out: ${!hash-output-var-name}
#------
function string_to_hash(){
    # Input parameters
    s2h_in_string=$1
    s2h_hash_out_var_name=${2:-string_hash_out}

    # Create a hash
    if [[ $OSTYPE == 'darwin'* ]]; then # macoS bash quirk!
        eval "$s2h_hash_out_var_name=`echo ${s2h_in_string} | md5`"
    else
        eval "$s2h_hash_out_var_name=`/bin/echo ${s2h_in_string} | /usr/bin/md5sum | /bin/cut -f1 -d" "`"
    fi
}
#------
# Name: check_if_file_has_been_modified()
# Desc: This checks if the file specified has been modified 
#   In: file-name, last-sync-timestamp (%s format)
#  Out: <NA>
#------
function check_if_file_has_been_modified(){

    # Input parameters
    file_name_to_check_for_modif=$1
    last_sync_timestamp=${2:-0}

    # Check
    if [[ ! "$file_name_to_check_for_modif" == "" ]]; then
        if [[ -f "$file_name_to_check_for_modif" ]]; then
            file_last_modified=$(date -r $file_name_to_check_for_modif +%s)
            # Check the diff since the last modified date...
            if [[ $last_sync_timestamp -gt 0 ]]; then
                time_in_seconds_since_last_sync=$(((file_last_modified-last_sync_timestamp)))
            else
                time_in_seconds_since_last_sync=0
            fi
        fi
    else
        file_last_modified=0
        time_in_seconds_since_last_sync=0
    fi

    if [[ $time_in_seconds_since_last_sync -gt 0 ]]; then
        printf "${red}*** File in exclusion list ${file_name_to_check_for_modif} was modified since the last sync on `print_a_timestamp ${last_sync_timestamp} \"\" \"red\"`${red}. Upload it manually ***${white}\n"
    fi
}
#------
# Name: check_if_file_has_been_modified_recursive()
# Desc: Checks for an existence of file, and then checks the time elapsed since the specified timestamp
#   In: search-type ("filename" or "file-list"), filename-or-listfile, timestamp, search-directory
#  Out: <NA>
#------
function check_if_file_has_been_modified_recursive(){
    # Input parameters
    filechk_input_type=${1:-"filename"}
    filechk_input_file_or_list=$2
    filechk_since_last_timestamp=${3:-0}
    filechk_srch_dir=${4:-"."}

    # Recursively check for all the files in the target directory
    if [[ "$filechk_input_type" == "file-list" ]]; then
        # A list of file is provided for check
        while IFS='' read -r filename; do
            # Loop only through the files, ignore the directories
            if [[ ! "${filename##*.}" == "" ]] && [[ ! "${filename%.*}" == "" ]]; then 
                files_found=$(find $filechk_srch_dir -type f -name "$filename")
                if [[ ! ${files_found} == "" ]]; then 
                    # Loop through the space-limited files (if there are multiple files by the same name that is)
                    for file_found in ${files_found}; do
                        check_if_file_has_been_modified "$file_found" "$filechk_since_last_timestamp"
                    done
                fi
            fi
        done < $filechk_input_file_or_list    
    else
        files_found=$(find $filechk_srch_dir -type f -name "$filename")
        if [[ ! ${files_found} == "" ]]; then
            # Loop through the space-limited files (if there are multiple files by the same name that is)
            for file_found in ${files_found}; do
                check_if_file_has_been_modified "$file_found" "$filechk_since_last_timestamp"
            done
        fi
    fi
}
#------
# Name: trim()
# Desc: trims the leading and trailing whitespaces
#   In: input-var
#  Out: <NA>
#------
function trim() {
  local var="$1"
  var="${var#"${var%%[![:space:]]*}"}" # trim leading whitespace chars
  var="${var%"${var##*[![:space:]]}"}" # trim trailing whitespace chars
  echo -n "$var"
}
#------
# Name: delete_a_file()
# Desc: Removes/deletes file(s) 
#   In: file-name (wild-card "*" supported, multiple files not supported), post-delete-message (optional, specify "--silent" for no message post deletion), delete-options(optional), post-delete-message-color(optional)
#  Out: <NA>
#------
function delete_a_file(){
    # Parameters
    delete_filename=$1
    delete_message="${2:-...(DONE)}"
    delete_options="${3:--rf}"
    delete_message_color="${4:-green}"

    # Check if the file exists before attempting to delete it.
    if ls $delete_filename 1> /dev/null 2>&1; then
        rm $delete_options $delete_filename
        # Check if the file exists post delete
        if ls $delete_filename 1> /dev/null 2>&1; then
            printf "${red}\n*** ERROR: Delete request did not complete successfully, $delete_filename was not removed (permissions issue?) ***\n${white}"
            exit 1
        else
            if [[ ! "$delete_message" == "--silent" ]]; then 
                printf "${!delete_message_color}${delete_message}${white}"
            fi
        fi
    else
        if [[ ! "$delete_message" == "--silent" ]]; then 
            printf "${grey}...(file does not exist, no action taken)${white}"
        fi
    fi        
}
#------
# Name: ping_a_server()
# Desc: ping_a_server
#   In: server-host-or-ip
#  Out: $ping_test_successful (Y/N)
#------
function ping_a_server(){
    # Input parameters
    ping_server=$1

    printf "${grey}Checking if the specified remote server (${ping_server}) is accessible, please wait...${white}"
    ping -c 1 ${ping_server} &> /dev/null
    
    if [[ $? -eq 0 ]]; then
        ping_test_successful=Y
        printf "${grey}ping successful${white}\n"
    else
        ping_test_successful=N
        if [[ -f /proc/version ]] && [[ `cat /proc/version | grep -i Microsoft` ]]; then #check for WSL
			printf "\n${grey}"
			ping -c 1 ${ping_server} # for users to see the IP address etc.
			printf "${white}"
            printf "${grey}*** ERROR: Server cannot be accessed. Make sure you run ${blue}Restart-Service LxssManager*${white}${grey} in Powershell (as adminstrator) to auto-update the hosts file. If it still doesn't work, disconnect your VPN and run ${blue}sudo apt-get update${white}${grey} in the WSL (Ubuntu?) shell ***${white}\n" # for WSL 
        else
			printf "\n${grey}"
			ping -c 1 ${ping_server} # for users to see the IP address etc.
			printf "${white}"
            printf "${red}*** ERROR: Server cannot be accessed, did you update /etc/hosts file? ***${white}\n"
        fi
    fi
}
#------
# Name: check_if_file_is_empty()
# Desc: Empty file check
#   In: file_name, error|warning
#  Out: <NA>
#------
function check_if_file_is_empty(){
	# Input parameters
	file_empty_check_filename=$1
	file_empty_check_opt=${2:-"exit"}

	if [[ ! -s "${file_empty_check_filename}" ]] || ! grep -q '[^[:space:]]' "${file_empty_check_filename}"; then
		printf "${red}*** ERROR: ${file_empty_check_filename} file is empty! ***${white}\n\n"
		if [[ "$file_empty_check_opt" == "exit" ]]; then
			exit
		fi
	fi
}

#------
# Name: git_pull()
# Desc: A simple git pull from remote function
#   In: git-root-directory, repo-array, git-options
#  Out: <NA>
#------
function git_pull(){
	# parameters
	git_root_directory=${1}
	git_repos_to_pull_array=${2}
	git_options=${3}

	# Save the PWD
	git_pull_curr_dir=$PWD

	# git pull
	if [[ -d "${git_root_directory}" ]]; then
		for git_repo_i in "${git_repos_to_pull_array[@]}"
		do	
			if [[ ! "$git_repo_i" == "" ]]; then
				if [[ -d "${git_root_directory}/${git_repo_i}" ]]; then
						cd ${git_root_directory}/${git_repo_i}
						if [[ -d ".git" ]]; then
							printf "${green}${blue}${git_repo_i}${green}: Git repository found, pulling the latest code...${white}\n"
							printf "${grey}"
							git pull ${git_options}
							printf "${white}"
						else
							printf "${red}ERROR: ${git_root_directory}/${git_repo_i} is not a Git repo, skipping ${white}\n"
						fi
				else
					printf "${red}ERROR: ${git_repo_i}: Git repository not found in ${git_root_directory} directory ${white}\n"
				fi
			else
				printf "${red}ERROR: Empty git repo input ${white}\n"
				exit
			fi
		done
	else
		printf "${red}ERROR: Directory ${git_root_directory} is not found ${white}\n"
		exit
	fi

	# Reset to the original PWD
	cd ${git_pull_curr_dir}
}
##########################################################################################

# Defaults (DO NOT CHANGE THESE CONFIG)
rsync_cmd="rsync -rltz --itemize-changes --delete"
rsync_cmd_debug_options="-v --progress"
temp_dir=~/.tmp
list_file=.upload.list
x_list_file=.upload_x.list
enable_debug=N

# Init
last_sync_timestamp=0
set_colors_codes
create_a_directory_if_not_exists ${temp_dir}

# Get the config file name
in_config_file=${1:-$list_file}
in_x_file=${2:-$x_list_file}
in_local_root_directory=${3}
in_remote_root_directory=${4}

# Just to be neat
printf "\n"

# Process the parameters passed to script
for p in "$@"
do 
    case $p in   
    --debug)
        enable_debug=Y
        ;;
    *)
        no_parameters_passed=Y
        ;;
    esac
done

# dos2unix
dos2unix -q ${in_config_file}
dos2unix -q ${in_x_file}

# Info banner
printf "${green}Using ${in_config_file} configuration...${white}\n\n"
check_if_file_is_empty ${in_config_file} noexit

# Ensure the files end of lines
add_a_newline_char_to_eof ${in_config_file}
add_a_newline_char_to_eof ${in_x_file}

# Messages
printf "${green}${red}The following are not synced as they're in the exclusion list (${in_x_file}):\n"
printf "`cat ${in_x_file} | xargs | sed -e 's/ /\n/g'`${white}\n\n"
printf "${red}Press ENTER key to continue...${white}"
read enter_to_continue_user_input

printf "\n${yellow}Upload operation will upload/sync the contents of your local machine to the server, press ENTER key to continue? ${white}"
read enter_to_continue_user_input

# Add the debug options
if [[ "$enable_debug" == "Y" || "$enable_debug" == "y" ]]; then
    printf "${yellow}*** Running in debug mode ***${white}\n" 
	rsync_cmd+=" ${rsync_cmd_debug_options}"
fi

# Add the exclusions
if [[ -s $in_x_file ]]; then
    while IFS='' read -r x; do
        rsync_cmd+=" --exclude=${x}" 
    done < $in_x_file
fi

# Ask the user for Git pull?
# printf "\n${yellow}Do you want to pull the latest from the Git remote before uploading? (press ENTER key to skip OR Y to pull) ${white}"
# read user_wants_to_git_pull

# Main
while IFS='>' read -r local_dir remote_dir; do
    # Server & directories
    remote_dir_server_conn_string=`echo "$remote_dir" | awk -F':' '{print $1}'`
    remote_server_user=`echo "$remote_dir_server_conn_string" | awk -F'@' '{print $1}'`
    remote_server_hostname=`echo "$remote_dir_server_conn_string" | awk -F'@' '{print $2}'`
    remote_dir=`echo "$remote_dir" | awk -F':' '{print $2}'`

    # Prefix the root directories, if specified
    if [[ ! ${in_remote_root_directory} == "" ]]; then
        remote_dir=`echo ${in_remote_root_directory}/${remote_dir} | sed 's/ //g'`
    fi
    # Prefix the root directories, if specified
    if [[ ! ${in_local_root_directory} == "" ]]; then
        local_dir=`echo ${in_local_root_directory}/${local_dir} | sed 's/ //g'`
    fi    

    # Remove leading/trailing whitespace to avoid issues during ssh
    remote_server_user="$(trim "$remote_server_user")"
    local_dir="$(trim "$local_dir")"
    remote_dir="$(trim "$remote_dir")"

    # Print the last sync info
    string_to_hash "upload_${remote_dir}_${local_dir}" "path_hash_out" # creates a unique hash of the from & to paths 
    last_sync_timestamp_filename=${temp_dir}/.${path_hash_out}.lastsync
    if [[ -f $last_sync_timestamp_filename ]]; then
        last_sync_info_from_file=`print_last_sync_info ${last_sync_timestamp_filename}`
        last_sync_timestamp_latest=$(<${last_sync_timestamp_filename})
    else
        last_sync_info_from_file="${grey}, no info available on the last upload operation for this repo${white}"
        last_sync_timestamp_latest=0
    fi

    fill_up_remaining_cols_with_a_char "\n[Uploading ${blue}$(basename $remote_dir)${white}${last_sync_info_from_file}${green}]" "-" "green"

    # ping_a_server ${remote_server_hostname}

    create_a_directory_if_not_exists $(dirname ${local_dir})

    # Sync
    # if [[ $ping_test_successful == "Y" ]]; then               
        # Check if the files in exclusion list has changed since the last sync happened
        check_if_file_has_been_modified_recursive "file-list" "${in_x_file}" "${last_sync_timestamp_latest}" "${local_dir}"
        
        # Upload GIT info, if exists (ref: https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-log.html)
        check_dependency_cmd=`which git`
        if [[ ! -z "$check_dependency_cmd" ]]; then
            curr_working_dir=$PWD
            cd ${local_dir}
            if [[ -d ".git" ]]; then
                printf "${grey}${local_dir} is a git repository, generating 'git.info' file with git branch and commit details...${white}\n"
                git_commit_branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
                git_commit_ref=$(git rev-parse HEAD)
                echo "Sync Timestamp: `date '+%a %d %b %H:%M:%S %Y %z'`" > ${local_dir}/git.info
                echo "Git Branch: ${git_commit_branch}" >> ${local_dir}/git.info
                echo "Git Commit Ref: ${git_commit_ref}" >> ${local_dir}/git.info
                echo "Git Commit Details: "`git log -1 --pretty=format:"%h | %an | %ad | %s"` >> ${local_dir}/git.info
            fi
            cd ${curr_working_dir}
        fi

        rsync_remote_directory_with_local_directory ${local_dir} ${remote_dir}
        echo $(date +%s) > "${temp_dir}/.${path_hash_out}.lastsync" # Store the current sync timestamp
    # else
    #     printf "${red}Skipping the upload process as the server is unreachable, fix the issue and re-run the script...${white}\n\n"
    # fi

    fill_up_remaining_cols_with_a_char "[End]" "-" "green"

    # Clean up!
    delete_a_file ${local_dir}/git.info --silent
    
done < $in_config_file

# Housekeeping (delete unecessary files to avoid confusion!)
if [[ ! "$in_config_file" == "$list_file" ]]; then
    rm -rf $list_file
fi
if [[ ! "$in_x_file" == "$x_list_file" ]]; then
    rm -rf $x_list_file
fi

# Exit
printf "\n"
