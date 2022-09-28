#!/bin/bash
#Default functions
load_data(){
	#mini shell
	export cp="sudo cp -r"
	export rm="sudo rm -rf"
	export prt="echo -e"
	export mkd="sudo mkdir"
	export add_ppa="sudo add-apt-repository"
	export elf="sudo chmod +x"
	export print="echo -e"
	export dl="wget -q"
	export dnull="/dev/0"
	
	#references
	name="cfgb"
	file_format="tar.gz"
	pdir="/usr/share/$name"
	bnd_dir="$pdir/bundles"
	bin="/bin/cfgb"
	script="$(pwd)/cfgb_script.sh"
	pkg_flag="null"
}
start(){
load_data
	clear
	output header "/Configuration Bundles Manager/" "Matheus Dias"
	for i in $(cat $pdir/cfg)
	do 
		export $i
	done
	if [ $1 = '-i' ]
	then
		b=$*
		for i in ${b[@]:2}
		do
			cd $bnd_dir
			download $i 
			unpack $i
			cook $i

		done
	elif [ $1 = '-e' ]
	then
		enable_extras $2 $3
	elif [ $1 = '-d' ]
	then
		download $2
	else
		$1 $*
	fi
}

#Custom Functions
setup(){
	sudo $mkd $pdir 2> $dnull
	sudo $mkd $bnd_dir 2> $dnull
	sudo $cp $script $bin 2> $dnull
	sudo $elf $bin
	#setting configs variables
	sudo echo -e "
		export h=/home/$2
		export pm=$3
		export repo=$4" > $pdir/cfg
	$print "C.F.G.B Manager instaled"
exit
}
output(){
	declare -A t
	t[header]="\033[01;36m-=$2=-\033[00;37m\n~ $3 \n"
	t[bnd_header]="Bundle:$2\nRepo:$repo"
	t[progress]="\033[00;32m-=- [$2]: $3 -=-\033[00;37m"
	t[show_files]="\033[00;37mfiles: [ $2 ] -Ok\033[00;37m "
	t[title]="\033[01;36m-=- $2 -=-\033[00;37m"
	t[sub_title]="\033[00;33m- $2\033[00;37m"
	t[dialogue]="\033[00;37m$2: [ $3 ]\033[00;37m"
	$prt ${t[$1]}
}
pkg_parser(){
	if [ $1 = "parse" ]
	then
		for i in $(cat $bnd_dir/$2/$3)
			do
				if [ $i = "#install" ]
				then
					pkg_flag="install"
				elif [ $i = "#remove" ]
				then
					pkg_flag="remove"
				else
					if [ $pkg_flag = "install" ]
					then
						to_install+=($i)
					fi
					if [ $pkg_flag = "remove" ]
					then
						to_remove+=($i)
				fi
				
			fi
		done
		
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
	fi
}
pkg_install(){
#Distro Pkgs
	if [ -e $bnd_dir/$1/packages -a $pkg_flag != "null" ]
	then
		output progress $pm "Installing Packages"
		pkg_parser parse $1 packages
		output sub_title "Updating repositories"
		sudo $pm update -y
		sudo $pm upgrade -y
		for i in ${to_install[*]}
		do
			output sub_title "Installing: $i"
			sudo $pm install $i
		done
		for i in ${to_remove[*]}
		do
			output sub_title "Removing: $i"
			sudo $pm remove $i
		done
		pkg_parser clean
	fi
#Flatpaks
	if [ -e $bnd_dir/$1/flatpaks -a $pkg_flag != "null" ]
	then
		output progress Flatpak "Installing Flatpaks"
		pkg_parser parse $1 flatpaks
		output sub_title 'Uptating Flathub'
		flatpak update -y
		for i in ${to_install[*]}
		do
			output sub_title "Installing: $i"
			flatpak install --system flathub $i -y
		done
		for i in ${to_remove[*]}
		do
			output sub_title "Removing: $i"
			flatpak uninstall --system flathub $i -y
		done
		pkg_parser clean
	fi
	if [ $pkg_flag = "null" ]
	then
		output dialogue $name "No packages to install"
	fi
}
download(){
	output bnd_header $1
	output title "Downloading $1"
	$dl $repo/$1.$file_format
	output show_files "$(ls $bnd_dir/)"
}
unpack(){
	output progress "tar" "Unpacking"
	$mkd $1/  
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	output show_files "$(ls $bnd_dir/$1/)"
}
cook(){
	output title "Setting-up $1"
	cd $bnd_dir/$1/
	pkg_install $1
	if [ -e $bnd_dir/$1/recipe ]
	then
		output progress $1 "Setting Recipe Script"
		#cat recipe
		bash recipe
	fi
	output title "$1 Instaled"
	$rm $bnd_dir/$1
}
enable_extras(){
	for i in $*
	do 
		if [ $i = flatpak ] ; then
			$prt "-=- [$name]: Configuring ${a[$i]} -=-"
			$pm install flatpak -y
			flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
			$prt "-=- [$name]: OK! -=-"
		fi
		if [ $i = snap ] ; then
			$prt "soom... maybe.."
		fi
	done
exit
}

start $*
