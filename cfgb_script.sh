#!/bin/bash
clear
u=$(whoami) ; if [ $u != root ]; then echo 'Error: this command needs run with sudo: 
Ex: sudo command/script' ; exit 1 ; fi

#setup Script
if [ $1 = setup ]; then
if [ $2 = "" ] ; then echo  ; exit ; fi ;
sudo mkdir /usr/share/cfgb ; sudo mkdir /usr/share/cfgb/bundles ;
sudo cp -r "$(pwd)/cfgb_script.sh" /bin/cfgb ; sudo chmod +x /bin/cfgb ;
#setting configs variables
sudo echo -e "
export repo=$4
export h=/home/$2
export pm=$3" > /usr/share/cfgb/cfg ; echo C.F.G.B Manager instaled;
exit
fi

#Setup Global variables (mini shell)
export name=cfgb ; export cp="sudo cp -r";export rm="sudo rm -rf";export prt="echo -e" ; export pdir=/usr/share/$name ; export id=$2 ; export mkd='sudo mkdir' ; export bnd_dir=$pdir/bundles;export add_ppa="sudo add-apt-repository" ;

#Start Setup
cfg=$(cat $pdir/cfg); $cfg ; cd $bnd_dir ;

#extra package managers
if [ $1 = '-e' ]; then 
for a in $2 $3 ; do 
if [ $a = flatpak ] ; then
echo "-=- [$name]: Configuring $a -=-" ; $pm install flatpak -y ;
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo ; echo "-=- [$name]: OK! -=-"
fi
if [ $a = snap ] ; then
echo soom!
fi
done ; exit 0 ; fi ;

#configurations debug
if [ $1 = -l ]; then cat /usr/share/cfgb/cfg ; exit ; fi

pkg_install () {
#Distro Pkgs
if [ -e $bnd_dir/$id/packages ] ; then
	pkgm=($pm 'install' 'update' 'upgrade');
	echo -=- [${pkgm[0]}]: Installing Packages -=-;
	echo '-=- Atualizando '${pkmg[0]}' -=-'
	sudo ${pkgm[0]} ${pkgm[2]} -y ;
	sudo ${pkgm[0]} ${pkgm[3]} -y ;
	for i in $(cat $bnd_dir/$id/packages) ; do echo -=$i=- ; sudo ${pkgm[0]} ${pkgm[1]} $i -y ; done ; 
	fi ;
#Flatpaks
	if [ -e $bnd_dir/$id/flatpaks ] ; then
	pkgm=('flatpak' 'install' 'update' 'flathub') ;
	echo '-=- Atualizando Flathub -=-'
	sudo ${pkgm[0]} ${pkgm[2]} -y ;
	for i in $(cat $bnd_dir/$id/flatpaks) ; do echo -=$i=- ; sudo ${pkgm[0]} ${pkgm[1]} ${pkgm[3]} $i -y ; done ;
fi ;

$prt '[Configuration Bundles Manager] by -=Matheus Dias=-
~Making desktop setups most simple possible!~
'
if [ $1 = -i ]; then 
args=($2 $3 $4 $5 $6) ; for a in ${args[@]} ; do
#getting a bundle
echo '-=- ['$name']: Download Bundle -=-
Repository: '$repo''
wget -q $repo/$a.tar.gz ;
echo 'tar: ['$(ls $bnd_dir/ )'] -Ok
'
#unpacking a bundle
echo '-=- ['$a']: Unpacking Bundle -=-'
$mkd $a/ ; tar -xf $a.tar.gz -C $a/ ; $rm $a.tar.gz
echo files: [$(ls -c $bnd_dir/$a)] -Ok

#Cooking directories recipes
$prt '-=- ['$a']: Cooking Bundle -=-'
cd $bnd_dir/$a/ ; pkg_install ; 
if [ -e $bnd_dir/$a/recipe ] ; then
echo -=- [$name]: Cooking Directories -=- ; } ;
bash recipe ;
fi ; echo '-=- '$a' Instaled -=-' ;  done ;
fi

#Clean bundles folder
$rm $bnd_dir/*
