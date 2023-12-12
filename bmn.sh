#!/usr/bin/env bash
### Core functions ###
load_data(){
## Evironment Variables : Can be used in recipe scripts ##
	#General commands 
	r="sudo"
	ir=""
	chm="$ir chmod"
	cho="$ir chown"
	cp="$ir cp -r"
	rm="$ir rm -rf"
	rmd="$ir rmdir --ignore-fail-on-non-empty"
	mv="$ir mv"
	prt="echo -e"
	mk="$ir touch"
	mkd="$ir mkdir"
	elf="$ir chmod 755"
	cat="$ir cat"
	dl="$ir wget"
	d0="/dev/0"
	jmp="2> blog &"
	gitc="$ir git clone"
	bmi="$ir bmn -i"
	bmn="bmn"
	add_ppa="$ir add-apt-repository"
	flatpak_remote="flatpak remote-add --if-not-exists"
	fp_overide="$ir flatpak override"
	pnl="$prt \n"
	rpath="realpath"
	pwd="$ir pwd"
	pkgi="pkg_install"
	header="output -bH"
	
	#Safe File Manager Commands Varariables
	srm="sfm -r"
	srmd="sfm -rd"
	smk="sfm -f"
	smkd="sfm -d"
	scat="sfm -c"
	src="sfm -rc"
	
	#Directorys collection
	rsr="/usr/share" #root share
	hsr="$h/.local/share" #home share
	rlc="/usr/local" #root local
	hlc="$h/.local" #home local
	cfg="$h/.config"
	etc="/etc"
	dev="/dev"
	mdi="/media"
	mnt="/mnt"
	tmp="/temp"

## References ##
	name="bmn"
	name_upper="$($prt $name|tr [:lower:] [:upper:])"
	script="$(pwd)/${name}.sh"
	file_format="tar"
	pkg_flag="null"
	args=$*
	cmd="$1"
	rex="$r bash recipe"
	editor="nano"
	deps="wget bash $ir $editor"
	script_src="https://github.com/MatheusNDDS/${name}-script/raw/main/${name}.sh"
	sfm_verbose=0 #Enable verbose log for SFM
	bkc=@
	rtext="output -a $name this program needs root privileges"

## Work Directorys ##
	pdir="/etc/$name"
	cfg_file="$pdir/cfg"
	init_file="$pdir/init"
	lsh_init="$pdir/.lshrc"
	cmd_srcd="/bin"
	log="$pdir/.log"

## Flatpak Configuration ##
	flathub="flathub https://flathub.org/repo/flathub.flatpakrepo"
	fp_mode="--system"
	fp_remote="flathub"
	
## External Data Import ##
	source $cfg_file
	source /etc/os-release
	release=($($scat $pdir/release))
	
## Configure pm,u,h variables
	detect_user_props
	# Directories that use data from detect_user_props()
	lc_dir="$h/.$name"
	bnd_dir="$h/.$name/bundles"
	hsr="$h/.local/share"
	hlc="$h/.local"
	cfg="$h/.config"
}
bmn_init(){
	load_data $*
	$smkd $lc_dir $bnd_dir
	if [[ "$1" = '-i' ]] || [[ "$1" = '--install' ]]
	then
		if [ $UID != 0 ];then $rtext;exit 0;fi
		for i in ${args[@]:2}
		do
			bnd_parser $i
			if [[ "${release[@]}" = *"$bndf"* ]] #checks if the bundle exists in the repository.
			then
				output -hT "Installing “$bnd_name$(bnd_parser -pbf)”"
				$srm $bnd_dir/$bnd_name
				cd $bnd_dir/
				download $bnd_name 0
				unpack $bnd_name
				cook $bnd_name ${bnd_flags[@]}
				$srm $bnd_dir/$bnd_name
				lc_inst=0
			else
				output -a $name "“$bnd_name” bundle not found in repository"
				output -d i "Maybe the relese file has outdated, try “$name -rU”."
			fi
		done
	elif [[ "$1" = '-li' ]] || [[ "$1" = '--lc-install' ]]
	then
		if [ $UID != 0 ];then $rtext;exit 0;fi
		if [[ $2 = *"$file_format"* ]]
		then
			bnd_ignore=()
			output -hT "Importing bundle"
			for i in ${args[@]:3}
			do
				bnd_parser $i
				if [ -f $bndf ]
				then
					output -p $name "Importing “$bnd_name”"
					$cp $bndf $bnd_dir/
				else
					output -a $name "File “$i” does not exists"
					bnd_ignore+=($i)
				fi
			done
			for i in ${args[@]:3}
			do
				if [[ ${bnd_ignore[*]} != *"$i"* ]]
				then
					bnd_parser $i
					output -hT "Installing “$bnd_name$(bnd_parser -pbf)”"
					$srm $bnd_dir/$bnd_name
					cd $bnd_dir/
					unpack $bnd_name
					cook $bnd_name ${bnd_flags[@]}
					$srm $bnd_dir/$bnd_name
					lc_inst=0
				fi
			done
		else
			output -a $name "“$file_format” file not especified"
		fi
	elif [[ "$1" = '-di' ]] || [[ "$1" = '--dir-install' ]]
	then
		if [ $UID != 0 ];then $rtext;exit 0;fi
		bnd_ignore=()
		output -hT "Importing bundle from directory"
		for i in ${args[@]:3}
		do
			bnd_parser $i
			if [ -d $bndf ]
			then
				output -p $name "Importing “$bnd_name”"
				$cp $bndf $bnd_dir/
			else
				output -a $name "Directory “$bnd_name” does not exists"
				bnd_ignore+=($i)
			fi
		done
		for i in ${args[@]:3}
		do
			if [[ ${bnd_ignore[*]} != *"$i"* ]]
			then
				bnd_parser $i
				output -hT "Installing “$bnd_name$(bnd_parser -pbf)”"
				cd $bnd_dir/
				cook $bnd_name ${bnd_flags[@]}
				$srm $bnd_dir/$bnd_name
				lc_inst=0
			fi
		done
	elif [[ "$1" = "-iu" ]]
	then
		pm_update=1
		bmn_init -i ${args[@]:3}
	elif [[ "$1" = "-liu" ]]
	then
		pm_update=1
		bmn_init -li ${args[@]:4}
	elif [[ "$1" = "-diu" ]]
	then
		pm_update=1
		bmn_init -di ${args[@]:4}
	elif [[ $1 = '-e' ]] || [[ "$1" = '--enable-extras' ]]
	then
		enable_extras $*
	elif [[ $1 = '-d' ]] || [[ "$1" = '--download' ]]
	then
		for i in ${args[@]:2}
		do
			download $i 1
		done
	elif [[ $1 = '-bp' ]] || [[ "$1" = '--bnd-pack' ]]
	then
		for i in ${args[@]:3}
		do
			bnd_pack $i
		done
	elif [[ $1 = '-s' ]] || [[ "$1" = '--setup' ]]
	then
		if [ $UID != 0 ]
		then
			$rtext
			exit 0
		fi
		setup $*
	elif [[ $1 = '-ss' ]] || [[ "$1" = '--setup' ]]
	then
		cfgb_update $script
	elif [[ $1 = '-U' ]] || [[ "$1" = "--$name-update" ]]
	then
		cfgb_update $2
	elif [[ $1 = '-rU' ]] || [[ "$1" = '--repo-update' ]]
	then
		qwerry_bnd $1
	elif [[ $1 = '-l' ]] || [[ "$1" = '--list-bnds' ]]
	then
		qwerry_bnd ${args[@]:2}
	elif [[ $1 = '-p' ]] || [[ $1 = '--properties' ]]
	then
		output 0
		output 1
	elif [[ ! -z $2 ]] && [[ $1 = '-bd' ]] || [[ $1 = '--bnd-data' ]]
	then
		output -hT "$2"
		bnd_parser $2
		output 3
	elif [[ $1 = '-h' ]] || [[ $1 = '--help' ]]
	then
		output 0
		output 2
	elif [[ $1 = '-ph' ]]
	then
		output 0
		output 1
		output 2
	elif [[ $1 = '-sh' ]] || [[ $1 = '--live-shell' ]]
	then
		live_shell
	fi
}

### Program Functions ###
## Utilities
output(){
	out_a=($*)
	declare -A t
	t[0]="\033[01;36m-=/Configuration Bundles Manager/=-\033[00m \n~ MatheusNDDS : https://github.com/MatheusNDDS\n"
	t[1]="\033[01;33m[Properties]\033[00m\n User: $u\n Home: $h\n PkgM: $pm\n Repo: $repo"
	t[2]="\033[01;33m[Commands]\033[00m\n --install,-i : Install bundles from repository, use -iu to update $pm repositories during installation.\n --lc-install,-li : Install bundles from $file_format file path, use -liu to update $pm repositories during installation.\n --dir-install,-di : Install bundles from unpacked dir path, use -diu to update $pm repositories during installation.\n --dowload,-d : Download bundles from repository.\n --bnd-pack, -bp : Pack a bundle from a directory.\n --repo-update,-rU : Update repository release file, use this regularly.\n --$name-update,-U : Update $name script from Repo source or local script.\n --list-bnds,-l : List or search for bundles in repo file.\n --live-shell,-sh : Run live shell for testing $name functions.\n --properties,-p : Prints the user information that $name uses.\n --help,-h : Print help text."
	t[3]="bndp_a=(${bndp_a[@]})\nbndf=$bndf\nbnd_raw_name=$bnd_raw_name\nbnd_pre_name=(${bnd_pre_name[@]})\nbnd_name=$bnd_name\nflags=(${bnd_flags[@]})"
	
## Formatting arguments
#Text output formatting arguments are also used by blog() to register data.
	t['-p']="\033[01;35m [$2]: -=- ${out_a[@]:2} -=-\033[00m" #Process
	t['-l']="\033[01m $2: [ $($prt ${out_a[@]:2}|tr ' ' ', ') ]\033[00m " #List itens
	t['-hT']="\n\033[01;36m******** [ ${out_a[@]:1} ] ********\033[00m\n" #High Title
	t['-ahT']="\n\033[01;33m******** / ${out_a[@]:1} / ********\033[00m\n" #Alert High Title
	t['-ehT']="\n\033[01;31m*#*#*#*# { ${out_a[@]:1} } #*#*#*#*\033[00m\n" #Error High Title
	t['-T']="\n\033[01;36m ### [ ${out_a[@]:1} ] ###\033[00m\n" #Title
	t['-t']="\033[01;33m - ${out_a[@]:1}\033[00m" #Subtitle
	t['-d']="\033[01m [$2]: ${out_a[@]:2}\033[00m" #Dialog, blog Data
	t['-e']="\033[01;31m {$2}: ${out_a[@]:2}\033[00m" #Error Dialog
	t['-s']="\033[01;32m ($2): ${out_a[@]:2}\033[00m" #Sucess Dialog
	t['-a']="\033[01;33m /$2/: ${out_a[@]:2}\033[00m" #Alert Dialog
	t['-bH']="\033[01;36m ## ${out_a[@]:3} ##\n ~ $2 ~\033[00m\n" #Bundle Header
	
	if [[ $1 != "-qi" ]]
	then
		$prt ${t[$1]}
	else
		$prt ${!t[@]} | sed 's/[0-9]//g'
	fi
}
pma(){
pma_a=($*)
	declare -A pm_i
	declare -A pm_r
	declare -A pm_l
	declare -A pm_s
	declare -A pm_u
	declare -A pm_g
	pkg="${pma_a[*]:1}"

##apt##
	pm_i[apt]="install"
	pm_r[apt]="remove"
	pm_l[apt]="list --installed"
	pm_s[apt]="search"
	pm_u[apt]="update"
	pm_g[apt]="upgrade"
##pacman##
	pm_i[pacman]="-S"
	pm_r[pacman]="-Rs"
	pm_l[pacman]="-Qs"
	pm_s[pacman]="-Ss"
	pm_u[pacman]="-Syu"
	pm_g[pacman]=0
##apk##
	pm_i[apk]="add"
	pm_r[apk]="del"
	pm_l[apk]="info"
	pm_s[apk]=@
	pm_u[apk]=@
	pm_g[apk]=@
##slackpkg##
	pm_i[slackpkg]=@
	pm_r[slackpkg]=@
	pm_l[slackpkg]="$jmp;ls /var/log/packages"
	pm_s[slackpkg]=@
	pm_u[slackpkg]="upgrade"
	pm_g[slackpkg]=0
##dnf##
	pm_i[dnf]=@
	pm_r[dnf]=@
	pm_l[dnf]=@
	pm_s[dnf]=@
	pm_u[dnf]=@
	pm_g[dnf]=0
##apx##
	pm_i[apx]=@
	pm_r[apx]=@
	pm_l[apx]=@
	pm_s[apx]=@
	pm_u[apx]=@
	pm_g[apx]=@
	
	## options for pma ##
	if [ $1 = "-qpm" ] #Qwerry Package Manager
	then
		bin_dirs="$(echo $PATH | tr ':' ' ')"
		for dir in ${bin_dirs[@]}
		do
			bin_list+=($(ls $dir/))
		done
		for pmc in ${!pm_l[@]}
		do
			if [[ "${bin_list[@]}" = *"$pmc"* ]]
			then
				pm_detected=$pmc
			fi
		done
	elif [ $1 = "-i" ]
	then
		if [ "${pm_i[$pm]}" = "@" ]
		then
			$ir $pm ${pm_i[apt]} ${pkg} -y
		else
			$ir $pm ${pm_i[$pm]} ${pkg} -y
		fi 
	elif [ $1 = "-r" ]
	then
		if [ "${pm_r[$pm]}" = "@" ]
		then
			$ir $pm ${pm_r[apt]} ${pkg} -y
		else
			$ir $pm ${pm_r[$pm]} ${pkg} -y
		fi
	elif [ $1 = '-s' ]
	then
		if [ "${pm_s[$pm]}" = "@" ]
		then
			$ir $pm ${pm_s[apt]} ${pkgs}
		else
			$ir $pm ${pm_s[$pm]} ${pkgs}
		fi 
	elif [ $1 = "-l" ]
	then
		if [ "${pm_l[$pm]}" = "@" ]
		then
			$ir $pm ${pm_l[apt]}
		else
			$ir $pm ${pm_l[$pm]}
		fi 
	elif [ $1 = "-u" ]
	then
		if [ "${pm_u[$pm]}" = "@" ]
		then
			$ir $pm ${pm_u[apt]} -y
			if [ ${pm_g[$pm]} != 0 ]
			then
				$ir $pm ${pm_g[apt]} -y
			fi
		else
			$ir $pm ${pm_u[$pm]} -y
			if [ ${pm_g[$pm]} != 0 ]
			then
				$ir $pm ${pm_g[$pm]} -y
			fi
		fi
	fi
}
sfm(){
	sfm_a=($*)
	for dof in ${sfm_a[@]:1}
	do
		if [ "$dof" != "/" ] || [ "$dof" != "$pdir" ] || [ $pdir/* != *"$dof"* ]
		then
			case ${sfm_a[0]} in
				'-d')
					if [ ! -d "$dof" ]
					then
						$mkd "$dof"
						if [ $sfm_verbose = 1 ]
						then
							output -t "Directory “$dof” maked"
						fi
					fi
				;;
				'-f') 
					if [ ! -e "$dof" ]
					then
						$mk "$dof"
						if [ $sfm_verbose = 1 ]
						then
							output -t "File “$dof” maked"
						fi
					fi
				;;
				'-r') 
					if [ -e "$dof" ]
					then
						$rm "$dof"
					elif [ -d "$dof" ]
					then
						$rm "$dof"
					fi
					if [ $sfm_verbose = 1 ]
						then
							output -t "File/Dir “$dof” removed"
					fi
				;;
				'-rd') 
					if [ -d "$dof" ]
					then
						$rmd "$dof"
					fi
					if [ $sfm_verbose = 1 ]
						then
						output -t "Dir “$dof” removed"
					fi
				;;
				'-c')
					if [ -e "$dof" ]
					then
						$cat "$dof"
					fi
				;;
				'-rc')
					if [ -e "$dof" ]
					then
						source "$dof"
					fi
				;;
			esac
		else
			output -a "SFM" "cannot remove “$dof” directory"
		fi
	done
}
blog(){
	blog_a=($*)
	log_hist=($(cat $log))
	line=($(grep -- "$2 $3" $log))
	output_index="$(output -qi)"
	case $1 in
	"-a"|"-e"|"-d") #quick alert and error register for bundles
	if [[ $output_index != *"${blog_a[0]}"* ]] || [[ $2 != "${bkc}"* ]] || [[ ${blog_a[@]:2} = *"${bkc}"* ]]
	then
		output -d blog/syntax "blog $1 “${bkc}key” “text arguments (cannot contain ${bkc})”"
		output -d blog/dataTypes ${output_index[@]}
	else
		line=($(grep -- "$1 $2" $log))
		if [[ ! -z $line ]] && [[ $1 != "-d" ]] && [[ $line != "-e" ]]
		then
			sed -i "/$1 $2/d" $log
		fi
		if [[ $line != *"-e"* ]] || [[ $1 != "-a" ]]
		then
			echo "${blog_a[*]}" >> $log
		fi
		if [[ $blog_verbose = 1 ]]
		then
			output $(echo "${blog_a[*]}" | sed "s/${bkc}//g")
		fi
	fi
	;;
	"-reg") #register a custom value
		if [[ $output_index != *"$2"* ]] || [[ $3 != "${bkc}"* ]] || [[ ${blog_a[@]:3} = *"${bkc}"* ]]
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}key” “text arguments (cannot contain ${bkc})”"
			output -d blog/dataTypes ${output_index[@]}
		else
			echo "${blog_a[*]:1}" | sed "s/\n//g" >> $log
			if [[ $blog_verbose = 1 ]]
			then
				output $(echo "${blog_a[*]:1}" | sed "s/${bkc}//g")
			fi
		fi
	;;
	"-ail"|"-ril") #add and remove items in a line 
		if [[ $output_index != *"$2"* ]] || [[ $3 != *"@"* ]] || [[ ${blog_a[@]:3} = *"${bkc}"* ]]
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}keyQwerry” “text arguments (cannot contain ${bkc})”"
			output -d blog/dataTypes ${output_index[@]}
		else
			if [[ ! -z $line ]]
			then
				if [ $1 = "-ail" ]
				then
					sed -i "/$2 $3/d" $log
					echo "${line[*]} ${blog_a[*]:3}" | sed "s/\n//g" >> $log
				else
					for item in ${blog_a[@]:3}
					do
						blog -sub $2 $3 $(echo "${line[*]}" | sed "s/$item//g")
					done
				fi
			fi
		fi
	;;
	"-ed") #edit a line, keeps the previous key
		if [[ $output_index != *"$2"* ]] || [[ $3 != *"${bkc}"* ]] || [[ ${blog_a[@]:3} = *"${bkc}"* ]]
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}keyQwerry” “text arguments (cannot contain ${bkc})”"
			output -d blog/dataTypes ${output_index[@]}
		else
			if [[ ! -z $line ]]
			then
				sed -i "/$2 $3/d" $log
				echo "$2 $3 ${blog_a[*]:3}" | sed "s/\n//g" >> $log
			fi
		fi
	;;
	"-sub") #substitute the line
		if [[ $output_index != *"$2"* ]] || [[ $3 != "${bkc}"* ]] ||  [[ $output_index != *"$4"* ]] || [[ $5 != "${bkc}"* ]] || [[ ${blog_a[@]:5} = *"${bkc}"* ]] 
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}keyQwerry” “-d” “${bkc}key” “text arguments (cannot contain ${bkc})”"
			output -d blog/dataTypes ${output_index[@]}
		else
			if [[ ! -z $line ]]
			then
				sed -i "/$2 $3/d" $log
				echo "${blog_a[*]:3}" | sed "s/\n//g" >> $log
			fi
		fi
	;;
	"-rm") #removes a especific type and key line
		if  [[ $output_index != *"$2"* ]] || [[ "$3" != "${bkc}"* ]]
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}key”"
			output -d blog/dataTypes ${output_index[@]}
		else
			sed -i "/$2 $3/d" $log
		fi
	;;
	"-rma") #delete all key lines
		if  [[ "$2" != "${bkc}"* ]]
		then
			output -d blog/syntax 'blog -del “${bkc}key”'
		else
			sed -i "/$2/d" $log
		fi
	;;
	"-gl"|"-glf") #returns the line with the found value, -glf for remove @.
		if  [[ $output_index != *"$2"* ]] || [[ "$3" != "${bkc}"* ]]
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}key”"
			output -d blog/dataTypes ${output_index[@]}
		else
			if [[ $1 = "-gl" ]]
			then
				echo "${line[*]}"
			else
				echo "${line[*]}" | sed "s/${bkc}//"
			fi
		fi
	;;
	"-gal") #returns all the key lines
		if  [[ "$2" != "${bkc}"* ]]
		then
			output -d "blog/syntax" "blog $1 “${bkc}key”"
		else
			grep -- "$2" $log
		fi
	;;
	"-gd") #returns only the data without type or key
		if  [[ $output_index != *"$2"* ]] || [[ "$3" != "${bkc}"* ]]
		then
			output -d blog/syntax "blog $1 “-d” “${bkc}key”"
			output -d blog/dataTypes ${output_index[@]}
		else
			echo "${line[*]:2}"
		fi
	;;
	esac
}

## Package Install
pkg_parser(){
	if [ $1 = "parse" -a -e $2 ]
	then
		for i in $(cat $2)
		do
			if [ $i = "#install" ]
			then
				pkg_flag=$i
			elif [ $i = "#remove" ]
			then
				pkg_flag=$i
			else
				if [ $pkg_flag = "#install" ]
				then
					to_install+=($i)
				fi
				if [ $pkg_flag = "#remove" ]
				then
					to_remove+=($i)
				fi
			fi
		done
	elif [ $1 = "list_pkgs" ]
	then
		if [ -n "${to_install[*]}" ]
		then
			output -l "install" "${to_install[*]}"
		fi
		if [ -n "${to_remove[*]}" ]
		then
			output -l "remove" "${to_remove[*]}"
		fi
	elif [ $1 = "clean" ]
	then
		unset to_install
		unset to_remove
		pkg_flag="null"
	elif [ $1 = "check" ]
	then
		if [ $2 = "fp" ]
		then
			pkgs_in=$(flatpak list)
		elif [ $2 = "pma" ]
		then
			pkgs_in=$(pma -l)
		fi
	fi
}
pkg_install(){
#Distro Pkgs
	if [[ -z $1 ]]
	then
		pkg_parser parse packages
	else
		pkg_parser parse $1/packages
	fi
	if [ $pkg_flag != "null" ]
	then
		$pnl
		output -p $pm "Installing Packages"
		pkg_parser list_pkgs
		if [[ $pm_update = 1 ]]
		then
			output -p $pm "Updating Packages"
			pma -u
		fi
		pkg_parser check pma
		for i in ${to_install[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output -t "$pm/installing: $i"
				output -s "$pm" "$i is already installed"
			else
				output -t "$pm/installing: $i"
				pma -i $i
			fi
		done
		pkg_parser check pma
		for i in ${to_remove[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output -t "$pm/removing: $i"
				pma -r $i
			else
				output -t "$pm/removing: $i"
				output -s "$pm" "$i is not installed"
			fi
		done
		pkg_parser clean
	fi
#Flatpaks
	if [[ -z $1 ]]
	then
		pkg_parser parse flatpaks
	else
		pkg_parser parse $1/flatpaks
	fi
	if [ $pkg_flag != "null" ]
	then
		$pnl
		output -p Flatpak "Installing Flatpaks"
		pkg_parser list_pkgs
		if [[ $pm_update = 1 ]]
		then
			output -t 'Uptating Flathub'
			$ir flatpak update -y
		fi
		pkg_parser check fp
		for i in ${to_install[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output -t "flatpak/installing: $i"
				output -s "flatpak" "$i is already installed"
			else
				output -t "flatpak/installing: $i"
				$ir flatpak $fp_mode install $fp_remote $i -y
			fi
		done
		pkg_parser check fp
		for i in ${to_remove[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output -t "flatpak/removing: $i"
				$ir flatpak uninstall $fp_mode $i -y
			else
				output -t "flatpak/removing: $i"
				output -s "flatpak" "$i is not installed"
			fi
		done
		pkg_parser clean
	fi
}

## Bundle Processes
bnd_parser(){
bndp_a=($($prt $1|sed "s/:/ /"))
	case $1 in
	'-pbf') #brint bnd flags
		if [[ ! -z $bnd_flags ]]
		then
			$prt : ${bnd_flags[@]}
		fi
	;;
	*) #set flags
		bndf=${bndp_a[0]}
		bnd_raw_name=$1
		bnd_pre_name=($($prt $bndf|tr '/' ' '))
		bnd_name=$($prt ${bnd_pre_name[-1]}|sed "s/.$file_format//")
		bnd_flags=($($prt ${bndp_a[1]}|tr ',' ' '))
	;;
	esac
}
download(){
	output -p $name "Downloading “$1”"
	$srm $1.$file_format
	if [ $lc_repo = 0 ]
	then
		$dl $repo/$1.$file_format
	else
		$cp $lc_repo/$1.$file_format $bnd_dir/
	fi
	output -l "files" "$(ls . | grep $1.$file_format)"
}
unpack(){
	output -p $name "Unpacking “$1”"
	$srm $1/
	$smkd $1/
	tar -xf $1.$file_format -C $1/
	$srm $1.$file_format
	output -l "files" "$(ls $bnd_dir/$1/)"
}
cook(){
	cd $1/
	pkg_install
	if [ -e recipe ]
	then
		output -hT "Executing “$1” Recipe"
		$rex $*
	fi
	recipe_log=($(blog -gal @$1))
	blog -rma @$1
	if [[ "${recipe_log[@]}" = *"-a"* ]]
	then
		output -ahT "“$1$(bnd_parser -pbf)” Recipe Returned Problems" 
	elif [[ "${recipe_log[@]}" = *"-e"* ]]
	then
		output -ehT "“$1$(bnd_parser -pbf)” Recipe Returned Erros"
	else
		output -hT "“$1$(bnd_parser -pbf)” Instaled"
	fi
}
bnd_pack(){
	current_dir=$(pwd)
	if [ -d $1 ]
	then
		cd $1
		tar -zcvf "$current_dir/$1.$file_format" *
		cd $current_dir
	else
		output -e $name "Directory “$1” does not exist"
	fi
}

## Script Managment
setup(){
#Detect custom bin path
	if [[ $2 = *"srcd="* ]]
	then
		cmd_srcd=$($prt $2|sed "s/srcd=//g")
	elif [[ $3 = *"srcd="* ]]
	then
		cmd_srcd=$($prt $3|sed "s/srcd=//g")
	fi
#Creating directories
	output -hT "$name_upper installation"
	sfm -d $pdir $bnd_dir $cfg $hlc $hsr
	sfm -f $cfg_file $init_file $log
	$cp $script $cmd_srcd/$name
	$elf $cmd_srcd/$name
#init file buid
	$prt "source $cmd_srcd/$name" > $init_file
	$prt 'export PS1="\\n“\w”\\n$(output -d $name)"\nalias q="exit 0"\nalias x="clear"\nalias c="$editor $cfg_file"\nalias i="$editor $init_file"\nalias r="$editor $pdir/release"\nalias l="$editor $log"\nalias h="$prt +\\n c: edit config\\n i: edit init\\n r: edit release\\n l: edit log\\n x: clear prompt\\n h: help\\n q: exit+"\nblog_verbose=1' | tr '+' "'" >> $init_file
#Package manager autodetect
	output -p $name "Detecting Package Manager"
	pma -qpm 2> blog
	output -t "Package Manager : $pm_detected"
#Detecting home and user
	output -p $name "Detecting Home Directory and User"
	detect_user_props
	output -t "Default Home : $h"
	output -t "Default User : $u"
	output -a ATTENTION "If you run this program outside your home directory the directory defined in this setup will be used."
#Installing dependencies
	output -p $name "Installing Dependencies"
	pm=$pm_detected
	pma -u
	pma -i $deps
#Saving environment variables
	if [ -z "$2" ] && [[ $2 != *"srcd="* ]] || [ -z "$3" ] && [[ $3 != *"srcd="* ]]
	then
		if [ -e repo ]
		then
			$prt "pm=$pm_detected h=$h u=$u \nrepo=$(cat repo) \nlc_repo=0" > $cfg_file
			$src $cfg_file
#Downloading repository releas
			qwerry_bnd -rU
			output -hT "$name_upper instelled with portable repo file"
			output -d 'repository' "$repo"
		else
			output -e "install error" "required portable 'repo' file, or type the repository url address last. "
			exit 1
		fi
	else
		$prt "pm=$pm_detected h=$h u=$u \nrepo=$2 \nlc_repo=0" > $cfg_file
		$src $cfg_file
#Downloading repository release
		qwerry_bnd -rU
		output -hT "$name_upper instaled"
	fi
}
cfgb_update(){
	if [ $UID != 0 ];then $rtext;exit 0;fi
	output -hT "Updating $name_upper Script"
	bin_srcd=($(cat $init_file))
	cmd_bin=${bin_srcd[1]}
	if [[ $1 = "" ]]
	then
		current_dir=$(pwd)
		output -p $name 'Downloading Script'
		output -d 'Source' $script_src
		cd $pdir
		$dl $script_src
		cd $current_dir
	else
		script_src="$1"
		output -p $name 'Installing from local'
		output -d 'local' $script_src
		$cp $script_src $pdir/
	fi
	output -p $name 'Installing Script'
	$mv "$pdir/$name.sh" $cmd_bin
	$elf $cmd_bin
	output -hT "$name_upper Script Updated"
}
qwerry_bnd(){
	if [[ $1 = '-rU' ]]
	then
		if [ $UID != 0 ];then $rtext;exit 0;fi
		current_dir=$(pwd)
		output -hT "Updating Repository"
		cd $pdir
		$srm $pdir/release
		output -p $name "Downloading Release"
		$dl $repo/release
		# end
		output -hT "Repository Updated"
		cd $current_dir
	else
		# Import and verify release file
		if [[ ! -e $pdir/release ]]
		then
			output -e "Error / No release file' 'Use “$name -rU” to download."
			exit
		fi
		# Bundles list output
		rel_h=()
		case $1 in
		"")
			output -hT "Avaliable bundles"
			for bnd in ${release[@]}
			do
				output -t "$bnd"
			done
		;;
		*)
			output -hT "Results for “$1”"
			for argb in $*
			do
				for bnd in ${release[@]}
				do
					if [[ $bnd = *"$argb"* ]] && [[ ${rel_h[@]} != *"$bnd"* ]]
					then
						output -t "$bnd"
						rel_h+=($bnd)
					fi
				done
			done
		;;
		esac
	fi
}
enable_extras(){
	if [ $UID != 0 ];then $rtext;exit 0;fi
	for i in $*
	do
		if [ $i = flatpak ]
		then
			output -hT "Configuring flatpak"
			output -p $name "Installing flatpak"
			pma -i flatpak
			output -p $name "Adding Flathub"
			$flatpak_remote $flathub
			output -hT "flatpak enabled"
		fi
		if [ $i = snap ]
		then
			$prt "soom..."
		fi
	done
exit
}
detect_user_props(){
	pwdp=($(pwd|tr '/' ' '))
	if [ "${pwdp[0]}" = "home" ]
	then
		h="/home/${pwdp[1]}"
		u="${pwdp[1]}"
	elif [ "${pwdp[0]}" = "root" ]
	then
		h="/root"
		u="root"
	fi
}
live_shell(){
	current_dir=$(pwd)
	cd $pdir
	$ir bash --init-file $init_file
	cd $current_dir
}

### Program Start ###
bmn_init $*