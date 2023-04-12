#!/bin/bash
## Core functions ##
load_data(){
#Evuronment variables
#Can be used in recipe scripts
	export cp="sudo cp -r"
	export rm="sudo rm -rf"
	export prt="echo -e"
	export mk="sudo touch"
	export mkd="sudo mkdir"
	export elf="sudo chmod 755"
	export dl="sudo wget -q"
	export d0="/dev/0"
	export cfgbi="sudo cfgb -i"
	export -f output
	export add_ppa="sudo add-apt-repository"
	export flatpak_remote="flatpak remote-add --if-not-exists"
	
#References
	name="cfgb"
	script="$(pwd)/cfgb.sh"
	file_format="tar.gz"
	pkg_flag="null"
	deps="wget bash sudo"
	filter=$*
	cmd="$1"
#Work directories
	pdir="/etc/$name"
	bnd_dir="$pdir/bundles"
	cfg="$pdir/cfg"
	bin="/bin/cfgb"
#Flatpak configuration
	flathub="flathub https://flathub.org/repo/flathub.flatpakrepo"
	fp_mode="--system"
	fp_remote="flathub"
	fp_opt="$fm_mode $fp_remote"
}
start(){
load_data $*
	$rm $bnd_dir/*
	output header "Configuration Bundles Manager" "Matheus Dias"
	if [ $1 != '-s' ]
	then
		for i in $(cat $cfg)
		do 
			export $i
		
		done
	fi
	if [[ "$1" = *"-i"* ]]
	then
		for i in ${filter[@]:2}
		do
			if [ $i != "u" ]
			then
				cd $bnd_dir
				download $i 0
				unpack $i
				cook $i
			fi
		done
	elif [ $1 = '-e' ]
	then
		enable_extras $*
	elif [ $1 = '-d' ]
	then
		for i in ${filter[@]:2}
		do
			download $i 1
		done
	elif [ $1 = '-s' ]
	then
		setup $*
	elif [ $1 = '-l' ]
	then
		live_shell
	fi
}

## Custom Functions ##
setup(){
#Script install
	$mkd $pdir 2> $d0
	$mkd $bnd_dir 2> $d0
	$mk $cfg 2> $d0
	$cp $script $bin 2> $d0
	$elf $bin
#Package manager autodetect
	output progress $name "Detecting package manager"
	pma -qpm
	output sub_title "Package Manager : $pm_detected"
#Detecting home directorie
	output progress $name "Detecting Home directorie"
	detect_home
	output sub_title "Home : $home_detected"
#Installing dependencies
	output progress $name "Installing dependencies"
	pm=$pm_detected
	pma -u
	pma -i $deps
#Setting environment variables
	if [ -z "$2" ]
	then
		if [ -e repo ]
		then
			$prt "pm=$pm_detected h=$home_detected repo=$(cat repo)" > $cfg
			output title "C.F.G.B instelled with portable repo file"
		else
			output error "install error" "required portable 'repo' file, or type the repository url address last. "
			exit 1
		fi
	else
		$prt "pm=$pm_detected h=$home_detected repo=$2" > $cfg
		output title "C.F.G.B instaled"
	fi
exit
}
pma(){
args=($*)
	declare -A pm_i
	declare -A pm_r
	declare -A pm_l
	declare -A pm_u
	declare -A pm_g
	pkg="${args[*]:1}"
#Package Managers internal database 
#(it's ugly and huge, but internal)
##apt##
	pm_i[apt]="install"
	pm_r[apt]="remove"
	pm_l[apt]="list --installed"
	pm_u[apt]="update"
	pm_g[apt]="upgrade"
##pacman##
	pm_i[pacman]="-S"
	pm_r[pacman]="-Rs"
	pm_l[pacman]="-Qs"
	pm_u[pacman]="-Syu"
	pm_g[pacman]=0
##apk##
	pm_i[apk]="add"
	pm_r[apk]="del"
	pm_l[apk]="info"
	pm_u[apk]=@
	pm_g[apk]=@
##dnf##
	pm_i[dnf]=@
	pm_r[dnf]=@
	pm_l[dnf]=@
	pm_u[dnf]=@
	pm_g[dnf]=0
#Package Managers Abstraction
	if [ $1 = "-qpm" ] #Qwerry Package Manager
	then
		bin_dirs="$(echo $PATH | tr ':' ' ')"
		for dir in ${bin_dirs[@]}
		do
			bin_list+=($(ls $dir/))
		done
		#Package Manager Auto Detect
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
output(){
	declare -A t
	t[header]="\033[01;36m-=/$2/=-\033[00m ~ $3 \n"
	t[bnd_header]="Bundle:$2\nRepo:$repo"
	t[progress]="\033[00;32m-=- [$2]: $3 -=-\033[00m"
	t[ok_dialogue]="\033[00m$2: [ $3 ] -Ok\033[00m "
	t[title]="\033[01;36m\n-=- $2 -=-\n\033[00m"
	t[sub_title]="\033[00;33m- $2\033[00m"
	t[dialogue]="\033[00m$2: [ $3 ]\033[00m"
	t[error]="\033[01;31m[$2]: { $3 }\033[00m"
	$prt ${t[$1]}
}
detect_home(){
	script_dir=($(pwd|tr '/' ' '))
	if [ "${script_dir[0]}" = "home" ]
	then
		home_detected="/home/${script_dir[1]}"
	else
		home_detected="/root"
	fi
}
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
			output dialogue "install" "${to_install[*]}"
		fi
		if [ -n "${to_remove[*]}" ]
		then
			output dialogue "remove" "${to_remove[*]}"
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
			pkgs_in=(pma -l)
		fi
	fi
}
pkg_install(){
#Distro Pkgs
	pkg_parser parse $1 packages
	if [ $pkg_flag != "null" ]
	then
		output progress $pm "Installing Packages"
		pkg_parser list_pkgs
		if [[ $cmd = *"u"* ]]
		then
			pma -u
		fi
		pkg_parser check pma
		for i in ${to_install[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output sub_title "$pm/installing: $i"
				output error "$pm/install" "$i is already installed"
			else
				output sub_title "$pm/installing: $i"
				pma -i $i
			fi
		done
		pkg_parser check pma
		for i in ${to_remove[*]}
		do	
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output sub_title "$pm/removing: $i"
				pma -r $i
			else
				output sub_title "$pm/removing: $i"
				output error "$pm/remove" "$i is not installed"
			fi
		done
		pkg_parser clean
	fi
#Flatpaks
	pkg_parser parse $1 flatpaks
	if [ $pkg_flag != "null" ]
	then
		output progress Flatpak "Installing Flatpaks"
		pkg_parser list_pkgs
		if [[ $cmd = *"u"* ]]
		then
			output sub_title 'Uptating Flathub'
			sudo flatpak update -y
		fi
		pkg_parser check fp
		for i in ${to_install[*]}
		do	
			if [[ "$pkgs_in" = *"$i "* ]]
			then
				output sub_title "flatpak/nstalling: $i"
				output error "flatpak/install" "$i is already installed"
			else
				output sub_title "flatpak/installing: $i"
				sudo flatpak $fp_mode install $fp_remote $i -y
			fi
		done
		pkg_parser check fp
		for i in ${to_remove[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output sub_title "flatpak/removing: $i"
				sudo flatpak uninstall $fp_mode $i -y
			else
				output sub_title "Removing: $i"
				output error "flatpak/remove" "$i is not installed"
			fi
		done
		pkg_parser clean
	fi
}
enable_extras(){
	for i in $*
	do 
		if [ $i = flatpak ]
		then
			output progress $name "Configuring flatpak"
			pma -i flatpak
			$flatpak_remote $flathub
			output ok_dialogue $name "flatpak enabled"
		fi
		if [ $i = snap ]
		then
			$prt "soom..."
		fi
	done
exit
}
download(){
	output bnd_header $1
	output title "Downloading $1"
	$dl $repo/$1.$file_format
	if [ $2 != 1 ]
	then 
		output ok_dialogue "files" "$(ls $bnd_dir/)"
	else
		output ok_dialogue "files" "$(ls . | grep $1.$file_format)"
	fi
}
unpack(){
	output progress "tar" "Unpacking"
	$mkd $1/  
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	output ok_dialogue "files" "$(ls $bnd_dir/$1/)"
}
cook(){
	output title "Setting-up $1"
	cd $1/
	pkg_install $1
	if [ -e recipe ]
	then
		output progress $1 "Setting Recipe Script"
		export id="$1"
		bash recipe
	fi
	output title "$1 Instaled"
	$rm $bnd_dir/$1
}
live_shell(){
	while [ 1 ]
	do
		read -p "Live: " cmd
		$cmd
	done
}
start $*