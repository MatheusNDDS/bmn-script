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
}
start(){
load_data $*
	output header "Configuration Bundles Manager" "Matheus Dias"
	for i in $(cat $pdir/cfg)
	do 
		export $i
	done
	if [ $1 = '-i' ]
	then
		for i in ${filter[@]:2}
		do
			cd $bnd_dir
			download $i 0
			unpack $i
			cook $i

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
	t[header]="\033[01;36m-=/$2/=-\033[00;37m\n~ $3 \n"
	t[bnd_header]="Bundle:$2\nRepo:$repo"
	t[progress]="\033[00;32m-=- [$2]: $3 -=-\033[00;37m"
	t[ok_dialogue]="\033[00;37m$2: [ $3 ] -Ok\033[00;37m "
	t[title]="\033[01;36m-=- $2 -=-\033[00;37m"
	t[sub_title]="\033[00;33m- $2\033[00;37m"
	t[dialogue]="\033[00;37m$2: [ $3 ]\033[00;37m"
	t[error]="\033[01;31m[$2]: { $3 }\033[00;37m"
	$prt ${t[$1]}
}
pkg_parser(){
	if [ $1 = "parse" -a -e $bnd_dir/$2/$3 ]
	then
		if [ $3 = "flatpaks" ]
		then
			installed="$(flatpak list | tr [:upper:] [:lower:])"
		else
			installed="$($pm list --installed)"
		fi
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
pkg_install(){
#Distro Pkgs
	pkg_parser parse $1 packages
	if [ $pkg_flag != "null" ]
	then
		output progress $pm "Installing Packages"
		pkg_parser list_pkgs
		output sub_title "Updating repositories"
		sudo $pm update -y
		sudo $pm upgrade -y
		for i in ${to_install[*]}
		do
			if [[ "${installed[*]}" = *"$i"* ]]
			then
				output error "$pm/install" "$i is already installed"
			else
				output sub_title "Installing: $i"
				sudo $pm install $i
			fi
		done
		for i in ${to_remove[*]}
		do
			if [[ "${installed[*]}" = *"$i"* ]]
			then
				output sub_title "Removing: $i"
				sudo $pm remove $i
			else
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
		output sub_title 'Uptating Flathub'
		flatpak update -y
		for i in ${to_install[*]}
		do
			if [[ "${installed[*]}" = *"$i"* ]]
			then
				output error "flatpak/install" "$i is already installed"
			else
				output sub_title "Installing: $i"
				flatpak install --system flathub $i -y
			fi
		done
		for i in ${to_remove[*]}
		do
			if [[ "${installed[*]}" = *"$i"* ]]
			then
				output sub_title "Removing: $i"
				flatpak uninstall --system flathub $i -y
			else
				output error "flatpak/remove" "$i is not installed"
			fi
		done
		pkg_parser clean
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
}
cook(){
	output title "Setting-up $1"
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