#!/usr/bin/env bash
### Core functions ###
load_data(){
## Configure pm,u,h variables
	detect_user_props

## Evironment Variables : Can be used in recipe scripts ##
	#General commands 
	r="sudo"
	chm="$r chmod"
	cho="$r chown"
	cp="$r cp -r"
	rm="$r rm -rf"
	mv="$r mv"
	prt="echo -e"
	mk="$r touch"
	mkd="$r mkdir"
	elf="$r chmod 755"
	cat="$r cat"
	dl="$r wget -q"
	d0="/dev/0"
	jmp="2> $log &"
	src="source"
	gitc="$r git clone"
	cfgbi="$r cfgb -i"
	add_ppa="$r add-apt-repository"
	flatpak_remote="flatpak remote-add --if-not-exists"
	fp_overide="$r flatpak override"
	pnl="$prt \n"
	
	#Safe File Manager Commands Varariables
	#SFM prevents accidental removal of the system root directory and prevents conflicts with existing files and directories 
	srm="sfm -r"
	smk="sfm -f"
	smkd="sfm -d"
	scat="sfm -c"
	
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
	name="cfgb"
	script="$(pwd)/${name}.sh"
	file_format="tar.gz"
	pkg_flag="null"
	deps="wget bash sudo"
	args=$*
	cmd="$1"
	log="$pdir/log"
	sfm_verbose=0 #Enable verbose log for SFM

## Work Directorys ##
	pdir="/etc/$name"
	bnd_dir="$pdir/bundles"
	cfg_file="$pdir/cfg"
	cfgb_bin="/bin/$name"

## Flatpak Configuration ##
	flathub="flathub https://flathub.org/repo/flathub.flatpakrepo"
	fp_mode="--system"
	fp_remote="flathub"
	
## External Data Import
	source $cfg_file
	source /etc/os-release
	release=($($scat $pdir/release))
}
start(){
load_data $*
	if [[ "$1" = *"-i"* ]] || [[ "$1" = *"--install"* ]]
	then
		if [[ "$1" = "-iu" ]]
		then
			pm_update=1
		fi
		for i in ${args[@]:2}
		do
			cd $pdir
			$srm $pdir/bundles/*
			if [[ $i != "u" ]]
			then
				if [[ "${release[@]}" = *"$i"* ]]
				then
					output -hT "Installing “$i”"
					cd $bnd_dir
					$srm $i/
					$srm $i.$file_format
					download $i 0
					unpack $i
					cook $i
				else
					output -e $name "“$i” bundle not found"
				fi
			fi
		done
	elif [[ $1 = '-e' ]] || [[ "$1" = '--enable-extras' ]]
	then
		enable_extras $*
	elif [[ $1 = '-d' ]] || [[ "$1" = '--download' ]]
	then
		for i in ${args[@]:2}
		do
			download $i 1
		done
	elif [[ $1 = '-s' ]] || [[ "$1" = '--setup' ]]
	then
		setup $*
	elif [[ $1 = '-U' ]] || [[ "$1" = '--cfgb-update' ]]
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
	elif [[ $1 = '-h' ]] || [[ $1 = '--help' ]]
	then
		output 0
		output 2
	elif [[ $1 = '-sh' ]] || [[ $1 = '--live-shell' ]]
	then
		live_shell
	fi
}

### Program Functions ###
## Utilities
output(){
	declare -A t
	t[header]="\033[01;36m-=/Configuration Bundles Manager/=-\033[00m \n~ MatheusNDDS : https://github.com/MatheusNDDS\n"
	t[info_header]="\033[01;33m[Properties]\033[00m\n User: $u\n Home: $h\n PkgM: $pm\n Repo: $repo"
	t[help_text]="\033[01;33m[Commands]\033[00m\n --install,-i : Install bundles from repository, use -iu to update $pm repositories during installation.\n --dowload,-d : Download bundles from repository.\n --repo-update,-rU : Update repository release file, use this regularly.\n --cfgb-update,-U : Update cfgb script from Repo source or local script.\n --list-bnds,-l : List or search for bundles in repo file.\n --live-shell,-sh : Run live shell for testing cfgb functions.\n --properties,-p : Prints the user information that cfgb uses.\n --help,-h : Print help text."
	t[progress]="\033[01;35m [$2]: -=- $3 -=-\033[00m"
	t[list]="\033[01m $2: [ $($prt $3|tr ' ' ', ') ]\033[00m "
	t[dialogue]="\033[01m [$2]: $3\033[00m"
	t[high_title]="\033[01;36m\n******** $2 ********\n\033[00m"
	t[title]="\033[01;36m\n ### $2 ###\n\033[00m"
	t[sub_title]="\033[01;33m - $2\033[00m"
	t[error]="\033[01;31m {$2}: $3\033[00m"
	t[sucess]="\033[01;32m ($2): $3\033[00m"
	
	#Simplification Redirect
	t[0]=${t[header]}
	t[1]=${t[info_header]}
	t[2]=${t[help_text]}
	t['-p']=${t[progress]}
	t['-l']=${t[list]}
	t['-d']=${t[dialogue]}
	t['-T']=${t[title]}
	t['-hT']=${t[high_title]}
	t['-t']=${t[sub_title]}
	t['-e']=${t[error]}
	t['-s']=${t[sucess]}
	
	$prt ${t[$1]}
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
			sudo $pm ${pm_i[apt]} ${pkg} -y
		else
			sudo $pm ${pm_i[$pm]} ${pkg} -y
		fi 
	elif [ $1 = "-r" ]
	then
		if [ "${pm_r[$pm]}" = "@" ]
		then
			sudo $pm ${pm_r[apt]} ${pkg} -y
		else
			sudo $pm ${pm_r[$pm]} ${pkg} -y
		fi
	elif [ $1 = '-s' ]
	then
		if [ "${pm_s[$pm]}" = "@" ]
		then
			sudo $pm ${pm_s[apt]} ${pkgs}
		else
			sudo $pm ${pm_s[$pm]} ${pkgs}
		fi 
	elif [ $1 = "-l" ]
	then
		if [ "${pm_l[$pm]}" = "@" ]
		then
			sudo $pm ${pm_l[apt]}
		else
			sudo $pm ${pm_l[$pm]}
		fi 
	elif [ $1 = "-u" ]
	then
		if [ "${pm_u[$pm]}" = "@" ]
		then
			sudo $pm ${pm_u[apt]} -y
			if [ ${pm_g[$pm]} != 0 ]
			then
				sudo $pm ${pm_g[apt]} -y
			fi
		else
			sudo $pm ${pm_u[$pm]} -y
			if [ ${pm_g[$pm]} != 0 ]
			then
				sudo $pm ${pm_g[$pm]} -y
			fi
		fi
	fi
}
sfm(){
	sfm_a=($*)
	for dof in ${sfm_a[@]:1}
	do
		if [ $dof != "/" ]
		then
			case ${sfm_a[0]} in
				'-d')
					if [ ! -d $dof ]
					then
						$mkd $dof
						if [ $sfm_verbose = 1 ]
						then
							output -t "Directory “$dof” maked"
						fi
					fi
				;;
				'-f') 
					if [ ! -e $dof ]
					then
						$mk $dof
						if [ $sfm_verbose = 1 ]
						then
							output -t "File “$dof” maked"
						fi
					fi
				;;
				'-r') 
					if [ -e $dof ]
					then
						$rm $dof
					elif [ -d $dof ]
					then
						$rm $dof
					fi
					if [ $sfm_verbose = 1 ]
						then
							output -t "File/Dir “$dof” removed"
					fi
				;;
				'-c')
					if [ -e $dof ]
					then
						$cat $dof
					fi
				;;
			esac
		else
			output -e "SFM" "cannot remove root directory “/”"
		fi
	done
}

## Package Install
pkg_parser(){
	if [ $1 = "parse" -a -e $bnd_dir/$2/$3 ]
	then
		for i in $(cat $bnd_dir/$2/$3)
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
	pkg_parser parse $1 packages
	if [ $pkg_flag != "null" ]
	then
		$pnl
		output -p $pm "Installing Packages"
		pkg_parser list_pkgs
		if [[ $pn_update = 1 ]]
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
	pkg_parser parse $1 flatpaks
	if [ $pkg_flag != "null" ]
	then
		$pnl
		output -p Flatpak "Installing Flatpaks"
		pkg_parser list_pkgs
		if [[ $pn_update = 1 ]]
		then
			output -t 'Uptating Flathub'
			sudo flatpak update -y
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
				sudo flatpak $fp_mode install $fp_remote $i -y
			fi
		done
		pkg_parser check fp
		for i in ${to_remove[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output -t "flatpak/removing: $i"
				sudo flatpak uninstall $fp_mode $i -y
			else
				output -t "flatpak/removing: $i"
				output -s "flatpak" "$i is not installed"
			fi
		done
		pkg_parser clean
	fi
}

## Bundle Process
download(){
	output -p $name "Downloading “$1”"
	$dl $repo/$1.$file_format
	if [ $2 != 1 ]
	then
		output -l "files" "$(ls $bnd_dir/)"
	else
		output -l "files" "$(ls . | grep $1.$file_format)"
	fi
}
unpack(){
	output -p $name "Unpacking “$1”"
	$smkd $1/
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	output -l "files" "$(ls $bnd_dir/$1/)"
}
cook(){
load_data
	cd $1/
	pkg_install $1
	if [ -e recipe ]
	then
		output -T "Setting “$1” Recipe"
		sudo bash recipe $1
	fi
	output -hT "“$1” Instaled"
	$srm $bnd_dir/$1
}

## Script Managment
setup(){
	output -hT "CFGB installation"
	sfm -d $pdir $bnd_dir
	sfm -f $cfg $log
	$cp $script $cfgb_bin
	$elf $cfgb_bin
#Package manager autodetect
	output -p $name "Detecting Package Manager"
	pma -qpm
	output -t "Package Manager : $pm_detected"
#Detecting home and user
	output -p $name "Detecting Home Directory and User"
	detect_user_props
	output -t "Default Home : $h"
	output -t "Default User : $u"
#Installing dependencies
	output -p $name "Installing Dependencies"
	pm=$pm_detected
	pma -u
	pma -i $deps
#Downloading repository release
	qwerry_bnd -rU
#Saving environment variables
	if [ -z "$2" ]
	then
		if [ -e repo ]
		then
			$prt "pm=$pm_detected h=$h u=$u repo=$(cat repo)" > $cfg_file
			output -hT "C.F.G.B instelled with portable repo file"
		else
			output -e "install error" "required portable 'repo' file, or type the repository url address last. "
			exit 1
		fi
	else
		$prt "pm=$pm_detected h=$h u=$u repo=$2" > $cfg_file
		output -hT "C.F.G.B instaled"
	fi
}
cfgb_update(){
	output -hT "Updating CFGB Script"
	if [[ $1 = "" ]]
	then
		current_dir=$(pwd)
		script_src="https://github.com/MatheusNDDS/cfgb-script/raw/main/${name}.sh"
		output -p $name 'Downloading Script'
		output -d 'Source' $script_src
		cd $pdir
		$dl $script_src
		cd $current_dir
	else
		script_src="$1"
		output -p $name 'Installing from local'
		output -d 'local' $script_src
		$cp $1 $pdir/
	fi
	output -p $name 'Installing Script'
	$mv "$pdir/$name.sh" $cfgb_bin
	$elf $cfgb_bin
	output -hT "CFGB Script Updated "
}
qwerry_bnd(){
	if [[ $1 = '-rU' ]]
	then
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
		# Import e verify release file
		if [[ ! -e $pdir/release ]]
		then
			output -e 'Error / No release file' 'Use “cfgb -rU” to download.'
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
	curent_path=($(pwd|tr '/' ' '))
	if [ "${curent_path[0]}" = "home" ]
	then
		h="/home/${curent_path[1]}"
		u="${curent_path[1]}"
	elif [ "${curent_path[0]}" = "root" ]
	then
		h="/root"
		u="root"
	fi
}
live_shell(){
	while [ 1 ]
	do
		read -p "$(output -d "cfgb")" cmd
		$cmd
	done
}

### Program Start ###
start $*