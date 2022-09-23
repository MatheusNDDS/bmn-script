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
	
	#references
	name="cfgb"
	file_format="tar.gz"
	export id="$2"
	pdir="/usr/share/$name"
	bnd_dir="$pdir/bundles"
	bin="/bin/cfgb"
	script="$(pwd)/cfgb_script.sh"
}
start(){
load_data
	clear
	for i in $(cat /usr/share/cfgb/cfg)
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
	sudo $mkd $pdir 
	sudo $mkd $bnd_dir
	sudo $cp $script $bin
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
	t[bnd_header]="Bundle:$2\nRepo:$repo"
	t[progress]="-=- [$2]: $3 -=-"
	t[show_files]="files: [$2] -Ok"
	t[title]="-=- $2 -=-"
	t[sub_title]="- $2"
	
	$prt ${t[$1]}
	
}
pkg_install(){
#Distro Pkgs
	if [ -e $bnd_dir/$1/packages ]
	then
		pkgm=($pm 'install' 'update' 'upgrade')
		output progress ${pkgm[0]} "Installing Packages"
		output sub_title "Atualizando ${pkmg[0]}"
		sudo ${pkgm[0]} ${pkgm[2]} -y
		sudo ${pkgm[0]} ${pkgm[3]} -y
		for i in $(cat $bnd_dir/$1/packages) 
		do 
			output sub_title $i
			sudo ${pkgm[0]} ${pkgm[1]} $i -y 
		done 
	fi
#Flatpaks
	if [ -e $bnd_dir/$1/flatpaks ]
	then
		pkgm=('flatpak' 'install' 'update' 'flathub')
		output progress ${pkgm[0]} "Installing flatpaks"
		output sub_title 'Uptating Flathub'
		sudo ${pkgm[0]} ${pkgm[2]} -y
		for i in $(cat $bnd_dir/$1/flatpaks) 
		do 
			output sub_title $i
			sudo ${pkgm[0]} ${pkgm[1]} ${pkgm[3]} $i -y
		done
	fi 
}
download(){
	output bnd_header $1
	output progress $name "Downloading..."
	$dl $repo/$1.$file_format
	output show_files "$(ls $bnd_dir/)"
}
unpack(){
	output progress "tar" "Unpacking..."
	$mkd $1/  
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	output show_files "$(ls $bnd_dir/$1/)"
}
cook(){
	output title "Cooking $1"
	cd $bnd_dir/$1/
	pkg_install $1
	if [ -e $bnd_dir/$1/recipe ]
	then
		output progress $1 "Setting Files"
		bash recipe
	fi
	output progress $name "$1 Instaled"
	$rm $bnd_dir/*
}
enable_extras(){
	for i in $*
	do 
		if [ $i = flatpak ] ; then
			$prt "-=- [$name]: Configuring ${a[$i]} -=-"
			$pm install flatpak -y
			flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 
			$prt "-=- [$name]: OK! -=-"
		fi
		if [ $i = snap ] ; then
			$prt "soom... maybe.."
		fi
	done
exit
}

start $*
