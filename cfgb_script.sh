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
	#for i in $(cat $pdir/cfg)
	for i in $(cat /usr/share/cfgb/cfg) #probisore test change
	do 
		export $i
	done
	if [ $1 = '-i' ]
	then
		for i in $*
		do
			if [ $i != '-i' ]
			then
				cd $bnd_dir
				download $i ; unpack $i ; cook $i
			fi
		done
	elif [ $1 = '-e' ] 
	then
		enable_extras $2 $3
	elif [ $1 = '-d' ] 
	then
		cd $bnd_dir
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
	$prt "C.F.G.B Manager instaled"
exit
}
pkg_install(){
#Distro Pkgs
	if [ -e $bnd_dir/$1/packages ]
	then
		pkgm=($pm 'install' 'update' 'upgrade')
		$prt "-=- [${pkgm[0]}]: Installing Packages -=-"
		$prt "-=- Atualizando ${pkmg[0]} -=-"
		sudo ${pkgm[0]} ${pkgm[2]} -y
		sudo ${pkgm[0]} ${pkgm[3]} -y
		for i in $(cat $bnd_dir/$1/packages) 
		do 
			$prt "-=$i=-" ; 
			sudo ${pkgm[0]} ${pkgm[1]} $i -y 
		done 
	fi
#Flatpaks
	if [ -e $bnd_dir/$id/flatpaks ]
	then
	pkgm=('flatpak' 'install' 'update' 'flathub')
		$prt '-=- Atualizando Flathub -=-'
		sudo ${pkgm[0]} ${pkgm[2]} -y
		for i in $(cat $bnd_dir/$1/flatpaks) 
		do 
			$prt -=$i=-
			sudo ${pkgm[0]} ${pkgm[1]} ${pkgm[3]} $i -y
		done
	fi 
}
download(){
	$prt "-=- [$name]: Download Bundle -=-\n Repo: $repo"
	$dl $repo/$1.$file_format ;
	$print "files: [ $(ls $bnd_dir/) ] -Ok \n "
}
unpack(){
	$prt "-=- [$1: Unpacking Bundle -=-"
	$mkd $1/  
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	$prt files: [ $(ls -c $bnd_dir/$1) ] -Ok
}
cook(){
	$prt "-=- [$1: Cooking Bundle -=-"
	cd $bnd_dir/$1/
	pkg_install $1
	if [ -e $bnd_dir/$1/recipe ]
	then
		echo "-=- [$name]: Cooking Directories -=-" ;
		bash recipe
	fi
	$prt "-=- $1 Instaled -=-"
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
			$prt "soom..."
		fi
	done
exit
}

start $*
