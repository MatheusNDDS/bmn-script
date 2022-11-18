#!/bin/bash
#Default functions
load_data(){
	#mini shell
	export cp="sudo cp -r"
	export rm="sudo rm -rf"
	export prt="echo -e"
	export mkd="sudo mkdir"
	export elf="sudo chmod +x"
	export dl="wget -q"
	export d0="/dev/0"
	export cfgbi="sudo cfgb -i"
	export -f output
	export add_ppa="sudo add-apt-repository"
	export flatpak_remote="flatpak remote-add --user --if-not-exists"
	
	#references
	name="cfgb"
	script="$(pwd)/cfgb.sh"
	file_format="tar.gz"
	pdir="/etc/$name"
	bnd_dir="$pdir/bundles"
	bin="/bin/cfgb"
	pkg_flag="null"
	deps="wget bash sudo"
	flathub="flathub https://flathub.org/repo/flathub.flatpakrepo"
	filter=$*
	cmd="$1"
}
start(){
load_data $*
	output header "Configuration Bundles Manager" "Matheus Dias"
	for i in $(cat $pdir/cfg)
	do 
		export $i
	done
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
		enable_extras $2 $3
	elif [ $1 = '-d' ]
	then
		for i in ${filter[@]:2}
		do
			download $i 1
		done
	elif [ $1 = '-s' ]
	then
		setup $*
	fi
}

#Custom Functions
setup(){
	$mkd $pdir 2> $d0
	$mkd $bnd_dir 2> $d0
	$cp $script $bin 2> $d0
	$elf $bin
	output progress $name "Installing dependencies"
	sudo $2 update -y
	sudo $2 install $deps -y &&
	#setting configs variables
	if [ -z "$4" ]
	then
		if [ -e repo ]
		then
			$prt "
			pm=$2
			h=/home/$3
			repo=$(cat repo)
			" > $pdir/cfg
			output title "C.F.G.B instelled with portable repo file"
		else
			output error "install error" "required portable 'repo' file, or type the repository url address last. "
			exit 1
		fi
	else
		$prt "
		pm=$2
		h=/home/$3
		repo=$4
		" > $pdir/cfg
		output title "C.F.G.B instaled"
	fi
	
exit
}
output(){
	declare -A t
	t[header]="\033[01;36m-=/$2/=-\033[00m\n~ $3 \n"
	t[bnd_header]="Bundle:$2\nRepo:$repo"
	t[progress]="\033[00;32m-=- [$2]: $3 -=-\033[00m"
	t[ok_dialogue]="\033[00m$2: [ $3 ] -Ok\033[00m "
	t[title]="\033[01;36m-=- $2 -=-\033[00m"
	t[sub_title]="\033[00;33m- $2\033[00m"
	t[dialogue]="\033[00m$2: [ $3 ]\033[00m"
	t[error]="\033[01;31m[$2]: { $3 }\033[00m"
	$prt ${t[$1]}
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
	fi
}
check_pkgs(){
	if [ $1 = "fp" ]
	then
		flatpak list | tr [:upper:] [:lower:]
	else
		pma -l
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
		for i in ${to_install[*]}
		do
			if [[ "$(check_pkgs 0)" = *"$i"* ]]
			then
				output sub_title "Installing: $i"
				output error "$pm/install" "$i is already installed"
			else
				output sub_title "Installing: $i"
				pma -i $i
			fi
		done
		for i in ${to_remove[*]}
		do	
			if [[ "$(check_pkgs 0)" = *"$i"* ]]
			then
				output sub_title "Removing: $i"
				pma -r $i
			else
				output sub_title "Removing: $i"
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
			flatpak update -y
		fi
		for i in ${to_install[*]}
		do	
			if [[ "$(check_pkgs fp)" = *"$i"* ]]
			then
				output sub_title "Installing: $i"
				output error "flatpak/install" "$i is already installed"
			else
				output sub_title "Installing: $i"
				sudo flatpak install $fp_opt $i -y
			fi
		done
		for i in ${to_remove[*]}
		do
			if [[ "$(check_pkgs fp)" = *"$i"* ]]
			then
				output sub_title "Removing: $i"
				sudo flatpak uninstall $fp_opt $i -y
			else
				output sub_title "Removing: $i"
				output error "flatpak/remove" "$i is not installed"
			fi
		done
		pkg_parser clean
	fi
}
pma(){
args=($*)
	declare -A pm_i
	declare -A pm_r
	declare -A pm_l
	declare -A pm_u
	declare -A pm_g
	pkg="${args[*]:1}"
	fp_opt="--system flathub"
	spm=$pm
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
##flatpak##
	pm_i[flatpak]="install $fp_opt"
	pm_r[flatpak]="uninstall $fp_opt"
	pm_l[flatpak]="list | tr [:upper:] [:lower:]"
	pm_u[flatpak]=@
	pm_g[flatpak]=0
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
	if [ $1 = "-i" ]	
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
	output title "Setting-up $1"
}
cook(){
	cd $1/
	pkg_install $1
	if [ -e recipe ]
	then
		output progress $1 "Setting Recipe Script"
		#cat recipe
		export id="$1"
		bash recipe
	fi
	output title "$1 Instaled"
	$rm $bnd_dir/$1
}
enable_extras(){
	for i in $*
	do 
		if [ $i = flatpak ] ; then
			output progress $name "Configuring flatpak"
			$pm install flatpak -y
			$flatpak_remote $flathub
			output ok_dialogue $name "flatpak enabled"
		fi
		if [ $i = snap ] ; then
			$prt "soom..."
		fi
	done
exit
}
start $*