#!/bin/bash
### Core functions ###
load_data(){
## Evironment Variables : Can be used in recipe scripts ##
	#General commands 
	export cp="sudo cp -r"
	export rm="sudo rm -rf"
	export mv="sudo mv"
	export prt="echo -e"
	export mk="sudo touch"
	export mkd="sudo mkdir"
	export elf="sudo chmod 755"
	export cat="sudo cat"
	export dl="sudo wget -q"
	export d0="/dev/0"
	export cfgbi="sudo cfgb -i"
	export add_ppa="sudo add-apt-repository"
	export flatpak_remote="flatpak remote-add --if-not-exists"
	export fp_overide="sudo flatpak override"
	
	#Functions
	export -f output
	export -f pma
	
	#directories collection
	export rsr="/usr/share" #root share
	export hsr="$h/.local/share" #home share
	export rlc="/usr/local" #root local
	export hlc="$h/.local" #home local
	export cfg="$h/.config"
	export etc="/etc"
	export dev="/dev"
	export mdi="/media"
	export mnt="/mnt"
	export tmp="/temp"

## References ##
	name="cfgb"
	script="$(pwd)/cfgb.sh"
	script_src="https://github.com/MatheusNDDS/cfgb-script/raw/main/${name}.sh"
	file_format="tar.gz"
	pkg_flag="null"
	deps="wget bash sudo tr"
	args=$*
	cmd="$1"

## Work Directories ##
	pdir="/etc/$name"
	bnd_dir="$pdir/bundles"
	cfg_file="$pdir/cfg"
	bin="/bin/$name"

## Flatpak Configuration ##
	flathub="flathub https://flathub.org/repo/flathub.flatpakrepo"
	fp_mode="--system"
	fp_remote="flathub"
}
start(){
load_data $*
	output 0 "Configuration Bundles Manager" "Matheus Dias"
	if [ $1 != '-s' ]
	then
		for i in $(cat $cfg_file)
		do 
			export $i
		done
	fi
	detect_home
	if [[ "$1" = *"-i"* ]]
	then
		for i in ${args[@]:2}
		do
			if [ $i != "u" ]
			then
				cd $bnd_dir
				$rm $i/ 2> $d0
				$rm $i.$file_format 2> $d0
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
		for i in ${args[@]:2}
		do
			download $i 1
		done
	elif [ $1 = '-s' ]
	then
		setup $*
	elif [ $1 = '-U' ]
	then
		update
	elif [ $1 = '-l' ]
	then
		qwerry_bnd $2
	elif [ $1 = '-sh' ]
	then
		live_shell
	fi
}

### Program Functions ###
## Utilities
output(){
	declare -A t
	t[header]="\033[01;36m-=/$2/=-\033[00m ~ $3 \n"
	t[info_header]="User: $u\nHome: $h\nPkgM: $pm\nRepo: $repo"
	t[progress]="\033[01;35m-=- [$2]: $3 -=-\033[00m"
	t[list]="\033[01m$2: [ $($prt $3|tr ' ' ', ') ]\033[00m "
	t[dialogue]="\033[01m[$2]: $3\033[00m"
	t[title]="\033[01;36m\n-=- $2 -=-\n\033[00m"
	t[sub_title]="\033[01;33m- $2\033[00m"
	t[error]="\033[01;31m{$2}: $3\033[00m"
	t[sucess]="\033[01;32m($2): $3\033[00m"
	
	#Simplification
	t[0]=${t[header]}
	t[1]=${t[info_header]}
	t['-p']=${t[progress]}
	t['-l']=${t[list]}
	t['-d']=${t[dialogue]}
	t['-T']=${t[title]}
	t['-t']=${t[sub_title]}
	t['-e']=${t[error]}
	t['-s']=${t[sucess]}
	
	$prt ${t[$1]}
}
detect_home(){
	curent_path=($(pwd|tr '/' ' '))
	if [ "${curent_path[0]}" = "home" ]
	then
		export h="/home/${curent_path[1]}"
		export u="${curent_path[1]}"
	elif [ "${curent_path[0]}" = "root" ]
	then
		export h="/root"
		export u="root"
	fi
}
pma(){
pmaa=($*)
	declare -A pm_i
	declare -A pm_r
	declare -A pm_l
	declare -A pm_u
	declare -A pm_g
	pkg="${pmaa[*]:1}"
#Package Managers internal database 
##apt##
	pm_i[apt]="install"
	pm_r[apt]="remove"
	pm_l[apt]="list --installed"
	pm_u[apt]="update"
	pm_g[apt]="upgrade"
##nix-env##
	pm_i['nix-env']="-iA"
	pm_r['nix-env']="-e"
	pm_l['nix-env']="-q"
	pm_u['nix-env']="-u"
	pm_g['nix-env']=0
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
##apx##
	pm_i[apx]=@
	pm_r[apx]=@
	pm_l[apx]=@
	pm_u[apx]=@
	pm_g[dnf]=@

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

## Package install
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
		output -p $pm "Installing Packages"
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
		output -p Flatpak "Installing Flatpaks"
		pkg_parser list_pkgs
		if [[ $cmd = *"u"* ]]
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
	output 1 $1
	output -T "Downloading “$1”"
	$dl $repo/$1.$file_format
	if [ $2 != 1 ]
	then
		output -l "files" "$(ls $bnd_dir/)"
	else
		output -l "files" "$(ls . | grep $1.$file_format)"
	fi
}
unpack(){
	output -p "tar" "Unpacking “$1”"
	$mkd $1/
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	output -l "files" "$(ls $bnd_dir/$1/)"
}
cook(){
load_data
	output -T "Installing “$1”"
	cd $1/
	pkg_install $1
	if [ -e recipe ]
	then
		output -p $1 "Setting Recipe"
		export id="$1"
		bash recipe
	fi
	output -T "“$1” Instaled"
	$rm $bnd_dir/$1
}

## Script managment
setup(){
	output -T "CFGB installation"
#Script install
	$mkd $pdir 2> $d0
	$mkd $bnd_dir 2> $d0
	$mk $cfg 2> $d0
	$cp $script $bin 2> $d0
	$elf $bin
#Package manager autodetect
	output -p $name "Detecting Package Manager"
	pma -qpm
	output -t "Package Manager : $pm_detected"
#Detecting home and user
	output -p $name "Detecting Home Directorie and User"
	detect_home
	output -t "Default Home : $h"
	output -t "Default User : $u"
#Installing dependencies
	output -p $name "Installing Dependencies"
	pm=$pm_detected
	pma -u
	pma -i $deps
#Saving environment variables
	if [ -z "$2" ]
	then
		if [ -e repo ]
		then
			$prt "pm=$pm_detected h=$h u=$u repo=$(cat repo)" > $cfg_file
			output -T "C.F.G.B instelled with portable repo file"
		else
			output -e "install error" "required portable 'repo' file, or type the repository url address last. "
			exit 1
		fi
	else
		$prt "pm=$pm_detected h=$h u=$u repo=$2" > $cfg_file
		output -T "C.F.G.B instaled"
	fi
exit
}
update(){
	output -T "Updating CFGB Script"
	current_dir=$(pwd)
	cd $pdir
	output -p $name 'Downloading Script'
	output -d 'Source' $script_src
	$dl $script_src
	output -p $name 'Installing Script'
	$mv "$pdir/$name.sh" $bin
	$elf $bin
	output -T 'CFGB Script Updated'
	cd $current_dir
}
qwerry_bnd(){
# Downloading
	output -p $name "Downloading release file"
	cd $pdir/
	$dl $repo/release
	release=($($cat $pdir/release))
# Bundles output
	case $1 in
	"")
		output -p $name "Listing avaliable bundles"
		for bnd in ${release[@]}
		do
			output -t "$bnd"
		done
	;;
	*)
		output -p $name "Searching for “$1”"
		for bnd in ${release[@]}
		do
			if [[ $bnd = *"$1"* ]]
			then
				output -t "$bnd"
			fi
		done
	;;
	esac
	$rm release
}
enable_extras(){
	for i in $*
	do
		if [ $i = flatpak ]
		then
			output -p $name "Configuring flatpak"
			pma -i flatpak
			$flatpak_remote $flathub
			output -s $name "flatpak enabled"
		fi
		if [ $i = snap ]
		then
			$prt "soom..."
		fi
	done
exit
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
