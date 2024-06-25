#!/usr/bin/env bash
### Core functions ###
bmn_data(){
## Evironment Variables : Can be used in recipe scripts ##
	#General commands 
	r="sudo"
	ir=""
	chm="$ir chmod"
	cho="$ir chown"
	cp="$ir cp -r"
	rm="sfm -r"
	rmd="sfm -rd"
	mv="$ir mv"
	mk="sfm -f"
	mkd="sfm -d"
	elf="$ir chmod 755"
	cat="sfm -c"
	prt="echo -e"
	dl="$ir wget"
	gitc="$ir git clone"
	bmi="$ir bmn -i"
	add_ppa="$ir add-apt-repository"
	flatpak_remote="flatpak remote-add --if-not-exists"
	fp_overide="s$r flatpak override"
	pnl="$prt \n"
	pwd="$ir pwd"
	pkgi="pkg_install"
	header="output -bH"
	src="sfm -rc"
	
	#Redirect points
	d0="/dev/0"
	dnull="/dev/null"
	tmpf="/tmp/$$" #generate a unique temporary file
	
	#Directorys collection
	bin="/usr/bin"
	rsr="/usr/share" #root share
	rlc="/usr/local" #root local
	hsr="$h/.local/share" #home share
	hlc="$h/.local" #home local
	cfg="$h/.config"
	rapp="$rsr/applications"
	happ="$hsr/applications"
	etc="/etc"
	dev="/dev"
	mdi="/media"
	mnt="/mnt"
	tmp="/temp"
	sus="/etc/sudoers"
	xss="$rsr/xsessions"
	wss="$rsr/wayland-sessions"
	xdga="/etc/xdg/autostart"
	skel="$etc/skel"

## Script Variables : Change this variables broke bundle execution ##
	#References
	name="bmn"
	name_upper="$($prt $name|tr [:lower:] [:upper:])"
	script="$(pwd)/${name}.sh"
	file_format="tar"
	pkg_flag="null"
	args=($*)
	cmd="$1"
	rex="$r bash recipe"
	editor="nano"
	deps="wget $ir $editor shc"
	script_src="https://github.com/MatheusNDDS/${name}-script/raw/main/${name}.sh"
	sfm_verbose=0 #Enable verbose log for SFM
	bkc=@
	date_f=('§' '%d-%m-%Y,%H:%M')
	pki_verbose=0
	[[ $1 = *'V' ]] && pki_verbose=1 && args[0]="$($prt ${args[0]}|tr -d 'V')"

	#Work Directories
	pdir="/etc/$name"
	cfg_file="$pdir/cfg"
	init_file="$pdir/init"
	lsh_init="$pdir/.lshrc"
	cmd_srcd="/bin"
	bmr_db="$pdir/.globaldb"

	#Flatpak Configuration
	flathub="flathub https://flathub.org/repo/flathub.flatpakrepo"
	fp_mode="--system"
	fp_remote="flathub"
	
	#External Data Import ##
	$src $cfg_file
	$src /etc/os-release
	release=($($cat $pdir/release))
	
	#Configure pm,u,h variables
	detect_user_props
	
	#Directories and commands that use data from detect_user_props()
	lc_dir="$h/.$name"
	bnd_dir="$h/.$name/bundles"
	hsr="$h/.local/share"
	hlc="$h/.local"
	cfg="$h/.config"
	happ="$hsr/applications/"
	set_owner="$cho -R $u:$u"  #set dirs owner to current user
	set_owner_forced="$set_owner $(echo $h/.* $h/* | sed s/$(echo $lc_dir | sed s/'\/'/'\\\/'/g)//) &> $dnull" #force $set_owner in entire $HOME (slow)
}
bmn_init(){
	btest -master || return 1
	$mkd $lc_dir $bnd_dir && $cho -R root:root $lc_dir &> $dnull

	if [[ ${args[0]} = '-i' || ${args[0]} = '--install' ]]
	then
		btest -env -root || return 1
		for i in ${args[@]:1}
		do
			bnd_parser $i
			if [[ " ${release[@]} " = *" $bndf "* ]] #checks if the bundle exists in the repository release.
			then
				output -hT "Configuring “$bnd_name$(bnd_parser -pbf)”"
				$rm $bnd_dir/$bnd_name
				cd $bnd_dir/
				download $bnd_name 0 || return 1
				unpack $bnd_name  || return 1
				cook $bnd_name ${bnd_flags[@]}
				$rm $bnd_dir/$bnd_name
				lc_inst=0
			else
				output -a $name "“$bnd_name” bundle not found in repository"
				output -d i "Maybe the relese file has outdated, try “$name -rU”."
			fi
		done
	elif [[ ${args[0]} = '-li' || ${args[0]} = '--lc-install' && ! -z "${args[@]:1}" ]]
	then
		btest -env -root || return 1
		bnd_ignore=()
		output -hT "Importing bundles"
		for i in ${args[@]:1}
		do
			if [[ $i = *"$file_format" ]]
			then
				bnd_parser $i
				if [ -f $bndf ]
				then
					output -p $name "Importing “$bnd_name”"
					$cp $bndf $bnd_dir/ || return 1
				else
					output -a $name "File “$i” does not exists"
					bnd_ignore+=($i)
				fi
			else
				output -a $name "“$file_format” file not especified"
				bnd_ignore+=($i)
			fi
		done
		for i in ${args[@]:1}
		do
			if [[ ${bnd_ignore[*]} != *"$i"* ]]
			then
				bnd_parser $i
				output -hT "Configuring “$bnd_name$(bnd_parser -pbf)”"
				$rm $bnd_dir/$bnd_name
				cd $bnd_dir/
				unpack $bnd_name || return 1
				cook $bnd_name ${bnd_flags[@]}
				$rm $bnd_dir/$bnd_name
				lc_inst=0
			fi
		done
	elif [[ ${args[0]} = '-di' || ${args[0]} = '--dir-install' && ! -z "${args[@]:1}" ]]
	then
		btest -env -root || return 1
		bnd_ignore=()
		output -hT "Importing dir bundles"
		for i in ${args[@]:1}
		do
			bnd_parser $i
			if [ -d $bndf ]
			then
				output -p $name "Importing “$bnd_name”"
				$cp $bndf $bnd_dir/ || return 1
				output -l "files" $(ls $bnd_dir/$bnd_name/)
			else
				output -a $name "Directory “$bnd_name” does not exists"
				bnd_ignore+=($i)
			fi
		done
		for i in ${args[@]:1}
		do
			if [[ ${bnd_ignore[*]} != *"$i"* ]]
			then
				bnd_parser $i
				output -hT "Configuring “$bnd_name$(bnd_parser -pbf)”"
				cd $bnd_dir/
				cook $bnd_name ${bnd_flags[@]}
				$rm $bnd_dir/$bnd_name
				lc_inst=0
			fi
		done
	elif [[ ${args[0]} = "-iu" ]]
	then
		pm_update=1
		bmn_init -i ${args[@]:1}
	elif [[ ${args[0]} = "-liu" ]]
	then
		pm_update=1
		bmn_init -li ${args[@]:1}
	elif [[ ${args[0]} = "-diu" ]]
	then
		pm_update=1
		bmn_init -di ${args[@]:1}
	elif [[ ${args[0]} = '-e' || ${args[0]} = '--enable-extras' ]]
	then
		enable_extras $*
	elif [[ ${args[0]} = '-bdl' || ${args[0]} = '--bnd-dowload' ]]
	then
		for dbnd in ${args[@]:1}
		do
			download $dbnd 1
		done
	elif [[ ${args[0]} = '-bp' || ${args[0]} = '--bnd-pack' ]]
	then
		for i in ${args[@]:1}
		do
			bnd_pack $i
		done
	elif [[ ${args[0]} = '-s' || ${args[0]} = '--setup' ]]
	then
		setup $*
	elif [[ ${args[0]} = '-ss' || ${args[0]} = '--setup' ]]
	then
		bmn_update $script
	elif [[ ${args[0]} = '-U' || ${args[0]} = "--$name-update" ]]
	then
		bmn_update $2
	elif [[ ${args[0]} = '-rU' || ${args[0]} = '--repo-update' ]]
	then
		qwerry_bnd ${args[0]}
	elif [[ ${args[0]} = '-l' || ${args[0]} = '--list-bnds' ]]
	then
		qwerry_bnd ${args[@]:1}
	elif [[ ${args[0]} = '-p' || ${args[0]} = '--properties' ]]
	then
		output 0
		output 1
	elif [[ ! -z $2 && ${args[0]} = '-bd' || ${args[0]} = '--bnd-data' ]]
	then
		#output -hT "$2"
		bnd_parser $2
		output 3
	elif [[ ! -z $2 && ${args[0]} = '-rl' ]]
	then
		[[ "${args[1]}"  = "db="* ]] && bmr_db=$($prt ${args[1]} | sed "s/db=//" ) && unset args[1]
		bmr -glf ${args[@]:1}
	elif [[ ! -z $2 && ${args[0]} = '-rd' ]]
	then
		[[ "${args[1]}"  = "db="* ]] && bmr_db=$($prt ${args[1]} | sed "s/db=//" ) && unset args[1]
		bmr -gd ${args[@]:1}
	elif [[ ! -z $2 && ${args[0]} = '-rg' ]]
	then
		btest -env -root || return 1
		[[ "${args[1]}"  = "db="* ]] && bmr_db=$($prt ${args[1]} | sed "s/db=//" ) && unset args[1]
		bmr ${args[@]:1}
	elif [[ ${args[0]} = '-h' || ${args[0]} = '--help' ]]
	then
		output 0
		output 2
	elif [[ ${args[0]} = '-ph' ]]
	then
		output 0
		output 1
		output 2
	elif [[ ${args[0]} = '-c' || ${args[0]} = '--clean' ]]
	then
		btest -env -root || return 1
		bmn_invbnds="$(ls $bnd_dir/)"
		if [[ ! -z "$bmn_invbnd" ]]
		then
			output -p $name "Cleaning invalid bundles residues"
			output -l "bnds" $bmn_invbnds
			$rm $bnd_dir/*
		else
			output -s $name "No invalid b bundles found"
		fi
	elif [[ ${args[0]} = '-api' ]]
	then
		btest -env -api || return 1
		if [[ $2 = 'bmr' ]]
		then
			btest -root || return 1
			[[ "${args[2]}"  = "db="* ]] && bmr_db=$($prt ${args[2]} | sed "s/db=//" ) && unset args[2]
			bmr ${args[@]:2}
		else
			$2 ${args[@]:2}
		fi
	elif [[ ${args[0]} = '-sh' || "${args[0]}" = '--live-shell' ]]
	then
		live_shell
	fi
}

### Program Functions ###
## Utilities
output(){
out_a=($*)
	test_args=(1 2 3 4)
	declare -A t
	[[ $1 = 0 ]] && t[0]="\033[01;36m-=/Automation Bundles Manager/=-\033[00m \n~ MatheusNDDS : https://github.com/MatheusNDDS\n"
	[[ $1 = 1 ]] && t[1]="\033[01;33m[Properties]\033[00m\n User: $u\n Home: $h\n PkgM: $pm\n Repo: $repo"
	[[ $1 = 2 ]] && t[2]="\033[01;33m[Commands]\033[00m\n$(output -t "Bundles managment")\n --install,-i : Install bundles from repository, use “-iu” to update $pm packages during installation.\n --lc-install,-li : Install bundles from $file_format file path, use “-liu” to update $pm packages during installation.\n --dir-install,-di : Install bundles from unpacked dir path, use “-diu” to update $pm packages during installation.\n --dowload,-bdl : Download bundles from repository.\n --list-bnds,-l : List or search for bundles in repo file.\n --repo-update,-rU : Update repository release file, use this regularly.\n --clean,-c : Clean invalid bundles residues.\n\n$(output -t "Script tools")\n --$name-update,-U : Update $name script from Repo source or local script.\n --bnd-pack, -bp : Pack a bundle from a directory.\n --live-shell,-sh : Run live shell for testing $name functions.\n --properties,-p : Prints the user information that $name uses.\n\n$(output -t "BMN Register commands")\n Use “db=yourdbfile” in second argument to change database file.\n -rl : Read a Line.\n -rd : Read a line data only.\n -rg : Register and alter a line or use other BMR functions.\n\n\033[01;33m[Api Functions]\033[00m\n Some useful functions commands used in $name_upper that cam be acessible for every shell script language.\n Syntax: $name -api “function”.\n\n\033[01m  output :\033[00m The function used to format text in $name_upper and Recipe Srcipts. Use “output -h” for help.\n \033[01m pma :\033[00m The Package Manager Abstractor, a simple and extensible program for abstract package management across some Linux distros. Use “pma -h” for help.\n \033[01m bmr :\033[00m The $name_upper Register, provide a simple text based database, also cam be used in Recipe Scripts to send alerts and errors signals to $name main process. Use “bmr -h” for help.\n\n --help,-h : Print help text."
	[[ $1 = 3 ]] && t[3]="bndp_a=(${bndp_a[*]})\nbndf=$bndf\nbnd_raw_name=$bnd_raw_name\nbnd_pre_name=(${bnd_pre_name[*]})\nbnd_name=$bnd_name\nflags=(${bnd_flags[*]})"
	[[ $1 = '-h' ]] && t['-h']="$(output -T "$name_upper Output Formatter")\n\n$(output -t "Titles")\n -hT : High Normal.\n -ahT : High Alert.\n -shT : High Sucess.\n -ehT : High Error.\n -T : Low Title.\n\n$(output -t "Dialogs")\n -d : Normal.\n -l : List.\n -p : Process.\n -t : Task.\n -a : Alert.\n -s : Sucess.\n -e : Error."
	[[ $1 = '-p' ]] && t['-p']="\033[01;35m [$2]: -=- $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//") -=-\033[00m" #Process
	[[ $1 = '-l' ]] && t['-l']="\033[01m $2[ $($prt $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//")|tr ' ' ', ') ]\033[00m " #List itens
	[[ $1 = '-hT' ]] &&  t['-hT']="\n\033[01;36m******** [ ${out_a[*]:1} ] ********\033[00m\n" #High Title
	[[ $1 = '-ahT' ]] &&  t['-ahT']="\n\033[01;33m******** // ${out_a[*]:1} // ********\033[00m\n" #Alert High Title
	[[ $1 = '-shT' ]] &&  t['-shT']="\n\033[01;32m******** ( ${out_a[*]:1} ) ********\033[00m\n" #Sucess High Title
	[[ $1 = '-ehT' ]] &&  t['-ehT']="\n\033[01;31m*#*#*#*# { $( echo "${out_a[*]:1}" | tr [:lower:] [:upper:]) } #*#*#*#*\033[00m\n" #Error High Title
	[[ $1 = '-bH' ]] &&  t['-bH']="\033[01;36m ### $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//") ###\n ~ $2 ~\033[00m\n" #Bundle Header
	[[ $1 = '-T' ]] &&  t['-T']="\n\033[01;36m ## ${out_a[*]:1} ##\033[00m\n" #Title
	[[ $1 = '-t' ]] &&  t['-t']="\033[01m -- ${out_a[*]:1}\033[00m" #Subtitle
	[[ $1 = '-d' || $1 = '-qi' ]] &&  t['-d']="\033[01m [$2]: $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//")\033[00m" #Dialog, bmr Data
	[[ $1 = '-e' || $1 = '-qi' ]] &&  t['-e']="\033[01;31m {$2}: $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//")\033[00m" #Error Dialog
	[[ $1 = '-s' || $1 = '-qi' ]] &&  t['-s']="\033[01;32m ($2): $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//")\033[00m" #Sucess Dialog
	[[ $1 = '-a' || $1 = '-qi' ]] &&  t['-a']="\033[01;33m /$2/: $([[ ! -z $3 ]] && $prt "$*" | sed "s/$1 $2//")\033[00m" #Alert Dialog

	if [[ "$1" != "-qi" ]]
	then
		$prt "${t[$1]}"
	else
		$prt "${!t[@]}"
	fi
}
pma(){
pma_a=($*)

### Database ###
	declare -A pm_i
	declare -A pm_r
	declare -A pm_l
	declare -A pm_s
	declare -A pm_u
	declare -A pm_g
	pkgs="${pma_a[*]:1}"
	
##apt##
	pm_i[apt]="install"
	pm_r[apt]="remove"
	pm_l[apt]="list --installed"
	pm_s[apt]="list"
	pm_u[apt]="update"
	pm_g[apt]="upgrade"
##apt##
	pm_i['nix-env']="-iA"
	pm_r['nix-env']="-e"
	pm_l['nix-env']="--qwery --installed"
	pm_s['nix-env']="--qwery --avaliable"
	pm_u['nix-env']="--upgrade"
	pm_g['nix-env']=0
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
	pm_s[apk]="search"
	pm_u[apk]=@
	pm_g[apk]=@
##slackpkg##
	pm_i[slackpkg]=@
	pm_r[slackpkg]=@
	pm_l[slackpkg]="2> $dnull ; ls /var/log/packages"
	pm_s[slackpkg]="search"
	pm_u[slackpkg]="upgrade"
	pm_g[slackpkg]=0
##dnf##
	pm_i[dnf]=@
	pm_r[dnf]=@
	pm_l[dnf]=@
	pm_s[dnf]="search"
	pm_u[dnf]=@
	pm_g[dnf]=0
##apx##
	pm_i[apx]=@
	pm_r[apx]=@
	pm_l[apx]=@
	pm_s[apx]="search"
	pm_u[apx]=@
	pm_g[apx]=@

	#Command yes implementation
	[[ $1 = *'y' ]] && pm_yes='-y' && pma_a[0]="$($prt ${pma_a[0]}|tr -d 'y')"
	[[ ${pma_a[-1]} = '-y' ]] && pm_yes='-y' && unset pma_a[-1]

	case "${pma_a[0]}" in
	'-h')
		$prt "$(output -T "$name_upper Package Manager Abstractor")\n$(output -d "suported" ${!pm_l[@]})\n\n$(output -t "Commands")\n  -i : Install package.\n  -r : Remove package.\n  -l : List instaled.\n  -s : Search in repository.\n\n$(output -t "“yes” command support")\n  Standard: “pma -i pkgs... \033[01;36m-y\033[00m”.\n  In-argument: “pma -i\033[01;36my\033[00m pkgs...”"
	;;
	'-qpm')
		bin_dirs=($(echo $PATH | tr ':' ' '))
		for dir in ${bin_dirs[@]}
		do
			bin_list+=($(ls $dir/))
		done
		for pmc in ${!pm_l[@]}
		do
			if [[ "${bin_list[@]}" = *"$pmc "* ]]
			then
				pm_detected=$pmc
			fi
		done
	;;
	'-i')
		[[ -z "${pm_i[$pm]}" ]] && return 1 || [[ "${pm_i[$pm]}" = "@" ]] && pm_target='apt' || pm_target=$pm
		$r $pm ${pm_i[$pm_target]} $pkgs $pm_yes
	;;
	'-r')
		[[ -z "${pm_r[$pm]}" ]] && return 1 || [[ "${pm_r[$pm]}" = "@" ]] && pm_target='apt' || pm_target=$pm
		$r $pm ${pm_r[$pm_target]} $pkgs $pm_yes
	;;
	'-l')
		[[ -z "${pm_l[$pm]}" ]] && return 1 || [[ "${pm_l[$pm]}" = "@" ]] && pm_target='apt' || pm_target=$pm
		$r $pm ${pm_l[$pm_target]}
	;;
	'-s')
		[[ -z "${pm_s[$pm]}" ]] && return 1 || [[ "${pm_s[$pm]}" = "@" ]] && pm_target='apt' || pm_target=$pm
		$r $pm ${pm_s[$pm_target]} $pkgs
	;;
	'-u')
		[[ -z "${pm_u[$pm]}" ]] && return 1 || [[ "${pm_u[$pm]}" = "@" ]] && pm_target='apt' || pm_target=$pm
		$r $pm ${pm_u[$pm_target]} $pm_yes
		[[ -z ${pm_g[$pm_target]} || ${pm_g[$pm_target]} != 0 ]] && $r $pm ${pm_g[$pm_target]} $pm_yes
	;;
	esac
}
sfm(){
sfm_a=($*)
	sysdbl=(/ $pdir $pdir/*);for bldir in ${sysdbl[@]};do sysdbl+="$bldir/ ";done
	btest -master && sysdbl=( 'UNRESTR' )
	btest -master && smf_verbose=0 || sfm_verbose=1
	rootfs_dirs=(/*)
	rootfs_dirs2=($(for bldir in ${rootfs_dirs[@]};do $prt "$bldir/ ";done))
	rootfs_dirs3=($($prt ${rootfs_dirs[@]} | tr '/' ' '))
	
	for dof in ${sfm_a[@]:1}
	do
		sdof=$([ -f $dof ] && realpath $dof || $prt $dof)
		if [[ " ${sysdbl[@]} " != *"$sdof"* || $1 = '-r' && " ${sysdbl[@]} " != *"$sdof"* && "${sfm_a[@]:1}" != "${rootfs_dirs[@]}" && "${sfm_a[@]:1}" != "${rootfs_dirs2[@]}" && "${sfm_a[@]:1}" != "${rootfs_dirs3[@]}" || $1 = "-c" || $1 = "-rc" ]]
		then
			case ${sfm_a[0]} in
				'-d')
					if [[ ! -d "$dof" ]]
					then
						$ir mkdir "$dof"
						[[ $sfm_verbose = 1 ]] && output -t "Directory “$dof” maked"
					fi
				;;
				'-f') 
					if [[ ! -e "$dof" ]]
					then
						$ir touch "$dof"
						[[ $sfm_verbose = 1 ]] && output -t "File “$dof” maked"
					fi
				;;
				'-r') 
					if [[ -e "$dof" ]]
					then
						$ir rm -rf "$dof"
						dof_exists=1
					elif [[ -d "$dof" ]]
					then
						$ir rm -rf "$dof"
						dof_exists=1
					fi
					[[ $sfm_verbose = 1 && $dof_exists = 1 ]] && output -t "“$dof” removed"
					[[ $sfm_verbose = 1 && -z $dof_exists ]] && output  -a 'SFM' "“$dof” does not exist"
				;;
				'-rd') 
					if [[ -d "$dof" ]]
					then
						$ir rmdir --ignore-fail-on-non-empty "$dof"
					fi
					[[ $sfm_verbose = 1 ]] && output -t "Dir “$dof” removed"
				;;
				'-c')
					if [[ -e "$dof" ]]
					then
						$ir cat "$dof"
					fi
				;;
				'-rc')
					if [[ -e "$dof" ]]
					then
						source "$dof"
					fi
				;;
			esac
		else
			output -a "SFM $1" "Cannot alter “$dof”"
		fi
	done
}
bmr(){
bmr_a=($@)
	## Data
	log_hist=($(cat $bmr_db))
	line=($(grep -- "${bmr_a[1]} ${bmr_a[2]}" $bmr_db))
	output_index="$(output -qi)"
	blog_date_str="${date_f[0]}$(date +${date_f[1]})"
	
	## Switches the bmr verbosity for untrusted executions.
	btest -master && blog_verbose=0 || blog_verbose=1

	## change database file
	[[ ${bmr_a[-1]} = 'bmr_db='* ]] && declare ${bmr_a[-1]} && unset bmr_a[-1]

	## Helper
	[[ $1 = "-h" ]] && $prt "$(output -T "$name_upper Register")\n\n$(output -t "Commands")\n  -rg : Register a line. Use “-rgt” instead to instert a timestamp.\n  -srg : Register a single line that can only be updated. Use “-srgt” instead to instert a timestamp.\n  -rm : Remove lines by @key.\n  -gl : Get lines by @key. Use “-glf” instead to format the line for visibility.\n  -gd : Get the line data by @key. Works fine only with single data lines.\n  -ed : Substitutes a the data line and keep the @key.\n  -sub : Substitutes one line to another.\n  -ail : Insert items in a line.\n  -ril : Remove items in a line.\n  -o : Format the line using the output function. Works fine only with single data lines.\n\n$(output -t "Data Types")\n -d : Data.\n -a : Alert.\n -s : Sucess.\n -e : Error.\n\n$(output -t "Using other database")\n You can thange the database declaring the “bmr_db=yourdbfile” in your script or temporaly in the last agrument."
	
	## Handy shortcuts
	case $1 in
		'-rg'|'-rgt'|'-srg'|'-srgt'|'-gl'|'-glf'|'-gd'|'-rm'|'-o') #automatically adds a “-d” data type to a line in some insertions for convenience.
			if [[  $output_index != *"$2"* ]]
			then
				bmr_a=($1 '-d' ${bmr_a[@]:1})
				line=($(grep -- "${bmr_a[1]} ${bmr_a[2]}" $bmr_db))
			fi
		;;
		'@'*) #adds a alert data type when the arguments are no insertion instructions and a @key are passed, useful for generate bundles alerts quickly.
			bmr_a=('-a' ${bmr_a[@]:0})
			line=($(grep -- "${bmr_a[1]} ${bmr_a[2]}" $bmr_db))
		;;
	esac
	
	## Insertion Instructions
	case ${bmr_a[0]} in
	"-a"|"-e"|"-d") #quick alert and error register for bundles
	if [[ $output_index != *"${bmr_a[0]}"* || ${bmr_a[1]} != "${bkc}"* || ${bmr_a[@]:2} = *"${bkc}"* ]]
	then
		output -a syntax "bmr ${bmr_a[0]} “${bkc}key” “text arguments (cannot contain ${bkc})”"
		output -d dataTypes ${output_index[@]}
	else
		line=($(grep -- "${bmr_a[0]} ${bmr_a[1]}" $bmr_db))
		if [[ ! -z $line && ${bmr_a[0]} != "-d" && $line != "-e" ]]
		then
			sed -i "/${bmr_a[0]} ${bmr_a[1]}/d" $bmr_db
		fi
		if [[ $line != *"-e"* || ${bmr_a[0]} != "-a" ]]
		then
			echo "${bmr_a[*]}" >> $bmr_db
		fi
		if [[ $blog_verbose = 1 ]]
		then
			output $(echo "${bmr_a[*]}" | sed "s/${bkc}//g")
		fi
	fi
	;;
	'-o') #redirects the line output to the “output()” function.
		if [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* || ${bmr_a[@]:3} = *"${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}key” “text arguments (cannot contain ${bkc})”"
			output -d dataTypes ${output_index[@]}
		else
			output $(echo "${line[*]}" | sed "s/${bkc}//g")
		fi
	;;
	"-rg"|"-rgt") #register a custom value
		if [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* || ${bmr_a[@]:3} = *"${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}key” “text arguments (cannot contain ${bkc})”"
			output -d dataTypes ${output_index[@]}
		else
			if [ ${bmr_a[0]} = '-rgt' ]
			then
				bmr_a[2]="${bmr_a[2]}$blog_date_str"
			fi
			echo "${bmr_a[*]:1}" | sed "s/\n//g" >> $bmr_db
			[[ $blog_verbose = 1 ]] && output -s "bmr" "Line “$(echo "${bmr_a[*]:1}")” registered"
		fi
	;;
	"-srg"|"-srgt") # safe register, if the line exists, replace it with the newest one.
		if [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* || ${bmr_a[@]:3} = *"${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}key” “text arguments (cannot contain ${bkc})”"
			output -d dataTypes ${output_index[@]}
		else
			if [ ${bmr_a[0]} = '-srgt' ]
			then
				bmr_a[2]="${bmr_a[2]}$blog_date_str"
			fi
			if [ -z "$(bmr -gl ${bmr_a[1]} ${bmr_a[2]})" ]
			then
				echo "${bmr_a[*]:1}" | sed "s/\n//g" >> $bmr_db
			else
				sed -i "/${bmr_a[1]} ${bmr_a[2]}/d" $bmr_db
				echo "${bmr_a[*]:1}" | sed "s/\n//g" >> $bmr_db
			fi
			[[ $blog_verbose = 1 ]] && output -s "bmr" "Safe line “$(echo "${bmr_a[*]:1}")” registered"
		fi
	;;
	"-ail"|"-ril") #add and remove items in a line 
		if [[ $output_index != *"${bmr_a[1]}"* || $3 != *"@"* || ${bmr_a[@]:3} = *"${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}keyQwerry” “text arguments (cannot contain ${bkc})”"
			output -d dataTypes ${output_index[@]}
		else
			if [[ ! -z $line ]]
			then
				if [ ${bmr_a[0]} = "-ail" ]
				then
					sed -i "/${bmr_a[1]} ${bmr_a[2]}/d" $bmr_db
					echo "${line[*]} ${bmr_a[*]:3}" | sed "s/\n//g" >> $bmr_db
					[[ $blog_verbose = 1 ]] && output -s "bmr" "Added “${bmr_a[*]:3}” in line “${line[*]}”"
				else
					bmr_last_bv=$blog_verbose
					bmr_last_line="${line[*]}"
					bmr_irm="${bmr_a[*]:3}"
					blog_verbose=0
					for item in ${bmr_a[@]:3}
					do
						[[ -z $sbl ]] && sbl="${line[*]:2}"
						sbl="$(echo "$sbl" | sed "s/$item//")"
					done
					bmr -sub ${bmr_a[1]} ${bmr_a[2]} ${bmr_a[1]} ${bmr_a[2]} $sbl
					blog_verbose=$bmr_last_bv
					[[ $blog_verbose = 1 ]] && output -s "bmr" "Removed “$bmr_irm” in line “$bmr_last_line”"
				fi
			fi
		fi
	;;
	"-ed") #edit a line, keeps the previous key
		if [[ $output_index != *"${bmr_a[1]}"* || $3 != *"${bkc}"* || ${bmr_a[@]:3} = *"${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}keyQwerry” “text arguments (cannot contain ${bkc})”"
			output -d dataTypes ${output_index[@]}
		else
			if [[ ! -z $line ]]
			then
				sed -i "/${bmr_a[1]} ${bmr_a[2]}/d" $bmr_db
				echo "${bmr_a[1]} ${bmr_a[2]} ${bmr_a[*]:3}" | sed "s/\n//g" >> $bmr_db
				[[ $blog_verbose = 1 ]] && output -s "bmr" "Line “${line[1]}” edited : [${line[@]:2}] >> [${bmr_a[*]:3}]"
			fi
		fi
	;;
	"-sub") #substitute the line
		if [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* ]] ||  [[ $output_index != *"$4"* || $5 != "${bkc}"* || ${bmr_a[@]:5} = *"${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}keyQwerry” “-d” “${bkc}key” “text arguments (cannot contain ${bkc})”"
			output -d dataTypes ${output_index[@]}
		else
			if [[ ! -z $line ]]
			then
				sed -i "/${bmr_a[1]} ${bmr_a[2]}/d" $bmr_db
				echo "${bmr_a[*]:3}" | sed "s/\n//g" >> $bmr_db
				[[ $blog_verbose = 1 ]] && output -s "bmr" "Line “${line[@]}” substituted to “$(echo "${bmr_a[*]:3}")”"
			fi
		fi
	;;
	"-rm") #removes a especific type and key line
		if  [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}key”"
			output -d dataTypes ${output_index[@]}
		else
			sed -i "/${bmr_a[1]} ${bmr_a[2]}/d" $bmr_db
			[[ $blog_verbose = 1 ]] && output -a "bmr" "Line “${line[@]}” removed"
		fi
	;;
	"-rma") #delete all key lines
		if  [[ "${bmr_a[1]}" != "${bkc}"* ]]
		then
			output -a syntax 'bmr -del “${bkc}key”'
		else
			sed -i "/${bmr_a[1]}/d" $bmr_db
			[[ $blog_verbose = 1 ]] && output -a "bmr" "All lines with the key “${bmr_a[1]}” removed"
		fi
	;;
	"-gl"|"-glf") #returns the line with the found value, -glf for remove @.
		if  [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}key”"
			output -d dataTypes ${output_index[@]}
		else
			if [[ ${bmr_a[0]} = "-gl" ]]
			then
				[ ! -z $line ] && grep -- "${bmr_a[1]} ${bmr_a[2]}" $bmr_db
			else
				[ ! -z $line ] && grep -- "${bmr_a[1]} ${bmr_a[2]}" $bmr_db | sed "s/${bkc}//" | sed "s/${date_f[0]}/ /" | sed "s/${bmr_a[1]}//"
			fi
		fi
	;;
	"-gal") #returns all the key lines
		if  [[ "${bmr_a[1]}" != "${bkc}"* ]]
		then
			output -d "syntax" "bmr ${bmr_a[0]} “${bkc}key”"
		else
			grep -- "${bmr_a[1]}" $bmr_db
		fi
	;;
	"-gd") #returns only the data without type or key
		if  [[ $output_index != *"${bmr_a[1]}"* || ${bmr_a[2]}  != "${bkc}"* ]]
		then
			output -a syntax "bmr ${bmr_a[0]} “-d” “${bkc}key”"
			output -d dataTypes ${output_index[@]}
		else
			[ ! -z $line ] && echo "${line[*]:2}"
		fi
	;;
	esac
}

## Package Install
pkg_parser(){
	case $1 in
		'parse')
			[[ ! -e $2 ]] && return 1
			for i in $(cat $2)
			do
				case $i in
				'#install'|'#remove')
					pkg_flag=$i
				;;
				*)
					[[ $pkg_flag = "#install" ]] && to_install+=($i)
					[[ $pkg_flag = "#remove" ]] && to_remove+=($i)
				;;
				esac
			done
		;;
		'list_pkgs')
			[[ -n "${to_install[*]}" ]] && output -l "to install" "${to_install[*]}"
			[[ -n "${to_remove[*]}" ]] && output -l "to remove" "${to_remove[*]}"
		;;
		'clean')
			unset to_install to_remove
			pkg_flag="null"
		;;
		'check')
			case $2 in
				'fp')
					pkgs_in=$(flatpak list)
				;;
				'pma')
					output -t 'Checking installed packages'
					pkgs_in=($(pma -l "${to_install[*]}"))
				;;
				'pma-in')
					pkg_parser check pma
					output -t 'Checking packages in repository'
					pkgs_in_repo=($(pma -s "${to_install[*]}"))
				;;
			esac
		;;
	esac
}
pkg_install(){
	## Distro Pkgs
	[[ -z $1 ]] && pkg_parser parse packages || pkg_parser parse $1/packages
	if [[ $pkg_flag != "null" ]]
	then
		
		output -p $pm "Validate packages for installation"
		pkg_parser check pma-in
		pkg_parser list_pkgs
		
		if [[ $pm_update = 1 ]]
		then
			output -p $pm "Updating Packages"
			[[ $pki_verbose = 1 ]] && pma -u || pma -u &> $dnull
		fi

		for i in ${to_install[*]}
		do
			if [[ " ${pkgs_in[@]} " = *" $i"* ]]
			then
				output -t "$pm/installing: $i"
				output -s "$pm" "“$i” is already installed"
			else
				output -t "$pm/installing: $i"
				if [[ " ${pkgs_in_repo[@]} " = *" $i"* ]]
				then
					[[ $pki_verbose = 1 ]] && pma -iy "$i" || pma -iy "$i" &> $dnull
				else
					output -s "$pm" "“$i” not found in repository or not avaliable for “$PRETTY_NAME”"
				fi
			fi
		done

		[[ -z $to_remove ]] && return 1
		$pnl && output -p $pm "Validate installed packages for remove"
		pkg_parser check pma

		for i in ${to_remove[*]}
		do
			if [[ " ${pkgs_in[@]} " = *" $i"* ]]
			then
				output -t "$pm/removing: $i"
				[[ $pki_verbose = 1 ]] && pma -ry "$i" || pma -ry "$i" 2> $dnull
			else
				output -t "$pm/removing: $i"
				output -s "$pm" "“$i” is not installed"
			fi
		done
		pkg_parser clean
	fi
	
	## Flatpaks
	[[ -z $1 ]] && pkg_parser parse flatpaks || pkg_parser parse $1/flatpaks
	if [[ $pkg_flag != "null" ]]
	then
		output -hT "Installing “$bnd_name” Flatpaks"
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
				output -s "flatpak" "“$i” is already installed"
			else
				output -t "flatpak/installing: $i"
				[[ $pki_verbose = 1 ]] && $ir flatpak $fp_mode install $fp_remote $i -y || $ir flatpak $fp_mode install $fp_remote $i -y 0> $dnull
			fi
		done

		[[ -z $to_remove ]] && return 1
		pkg_parser check fp
		for i in ${to_remove[*]}
		do
			if [[ "$pkgs_in" = *"$i"* ]]
			then
				output -t "flatpak/removing: $i"

				[[ $pki_verbose = 1 ]] && $ir flatpak uninstall $fp_mode $i -y || $ir flatpak uninstall $fp_mode $i -y 2> $dnull
			else
				output -t "flatpak/removing: $i"
				output -s "flatpak" "“$i” is not installed"
			fi
		done
		pkg_parser clean
	fi
}

## Bundle Process
bnd_parser(){
bndp_a=($($prt $1|sed "s/:/ /"))
	case $1 in
	'-pbf') #brint bnd flags
		if [[ ! -z $bnd_flags ]]
		then
			$prt ":${bnd_flags[@]}" | tr ' ' ','
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
	btest -env -master || return 1
	$rm $1.$file_format
	if [[ $lc_repo = 0 ]] || [ $2 = 1 ]
	then
		output -p $name "Downloading “$1”"
		btest -net || return 1
		$dl $repo/$1.$file_format
	else
		output -p $name "Importing “$1”"
		output -d "dir" $lc_repo
		$cp $lc_repo/$1.$file_format $bnd_dir/
	fi
	output -l "files" "$(ls . | grep $1.$file_format)"
}
unpack(){
	btest -env -master || return 1
	output -p $name "Unpacking “$1”"
	$rm $1/
	$mkd $1/
	tar -xf $1.$file_format -C $1/
	$rm $1.$file_format
	output -l "files" "$(ls $bnd_dir/$1/)"
}
cook(){
	btest -env -master || return 1
	bndid=$1
	cd $bndid/

	## Auto writing file systems
	[[ -e rootfs ]] && output -p $name "Writing “$bndid” root file system" && $cp rootfs/* rootfs/.* / 2> $dnull
	[[ -e rootfs ]] && output -l "rootfs_dirs" "$rootfs_dots $(ls -A rootfs/)"
	[[ -e homefs ]] && output -p $name "Writing “$bndid” home file system" && $cp homefs/* homefs/.* $h/ 2> $dnull
	[[ -e homefs ]] && output -l "homefs_dirs" "$homefs_dots $(ls -A homefs/)"

	## Packages installation
	[[ -f packages || -f flatpaks ]] && output -hT "Installing “$bnd_name” packages"
	pkg_install

	## Recipe file process
	if [[ -e recipe ]]
	then
		output -hT "Executing “$bndid$(bnd_parser -pbf)” Recipe"
		$elf recipe
		$rex $bndid ${bnd_flags[@]}
	fi

	## Verify alerts in BMR Database
	recipe_log=($(bmr -gal "@$bndid "))
	bmr -rma "@$bndid "
	if [[ " ${recipe_log[@]} " = *" -a "* ]]
	then
		output -ahT "“$bndid$(bnd_parser -pbf)” Returned Alerts"
	elif [[ " ${recipe_log[@]} " = *" -e "* ]]
	then
		output -ehT "“$bndid$(bnd_parser -pbf)” Returned Erros"
	else
		output -hT "“$bndid$(bnd_parser -pbf)” Finished"
	fi
}
bnd_pack(){
	current_dir=$(pwd)
	if [[ -d $1 ]]
	then
		cd $1
		tar -zcvf "$current_dir/$1.$file_format" *
		cd $current_dir
	else
		output -e $name "Directory “$1” does not exist"
	fi
}

## Script Management
setup(){
	btest -root -installer || return 1
	unset pm u h repo lc_repo
	source config
	output 0
#Detect custom bin path
	[[ $2 = "cmd_srcd="* ]] && declare $2 || [[ $3 = "cmd_srcd="* ]] && declare $3
#Creating directories
	output -hT "$name_upper installation"
	sfm -d $pdir $bnd_dir $cfg $hlc $hsr
	sfm -f $cfg_file $init_file $bmr_db
	$cp $script "$pdir/source"
	$prt "#!/bin/sh\nexec bash $pdir/source" '$*' > $cmd_srcd/$name
	$elf $cmd_srcd/$name "$pdir/source"
#Init file buid
	$prt "source $pdir/source" > $init_file
	$prt 'export PS1="\\n“\w”\\n$(output -d $name)"\nalias q="exit 0"\nalias x="clear"\nalias s="$editor $pdir/source"\nalias c="$editor $cfg_file"\nalias i="$editor $init_file"\nalias r="$editor $pdir/release"\nalias l="$editor $bmr_db"\nalias h="$prt +\\n b: Edit $name_upper source\\n c: edit config\\n i: edit init\\n r: edit release\\n l: edit log\\n x: clear prompt\\n h: help\\n q: exit+"' | tr '+' "'" >> $init_file
#Package manager autodetect
	if [[ -z $pm ]]
	then
		output -p $name "Detecting Package Manager"
		pma -qpm 2> .log
		pm=$pm_detected
	else
		output -p $name "Custom Package Manager from “config”"
	fi
	output -t "Package Manager : $pm"
#Detecting home and user
	output -p $name "Detecting Home Directory and User"
	detect_user_props
	output -t "Default Home : $h"
	output -t "Default User : $u"
	output -a ATTENTION "If you run this program outside your home directory the directory defined in this setup will be used."
#Installing dependencies
	output -p $name "Installing Dependencies"
	pma -u
	for i in ${deps[@]}
	do
		output -t "$pm/install: $i"
		pma -i $i
	done
#Saving environment variables
	if [[ -z "$2" && $2 != *"srcd="* || -z "$3" && $3 != *"srcd="* ]]
	then
		if [ -e config ]
		then
			$prt "pm=$pm h=$h u=$u \nrepo=$repo \nlc_repo=$lc_repo" > $cfg_file
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
		$prt "pm=$pm h=$h u=$u \nrepo=$2 \nlc_repo=0" > $cfg_file
		$src $cfg_file
#Downloading repository release
		qwerry_bnd -rU
		output -hT "$name_upper instaled"
	fi
	bmr -rgt @setup "$name target “$cmd_srcd”. pm=$pm, h=$h, u=$u, repo=$repo"
}
bmn_update(){
	btest -env -root -master || return 1
	output -hT "Updating $name_upper Script"
	bin_srcd=($(cat $init_file))
	cmd_bin=${bin_srcd[1]}
	if [[ $1 = "" ]]
	then
		current_dir=$(pwd)
		output -p $name 'Downloading Script'
		btest -net || return 1
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
	bmr -rgt @update "from “$script_src”."
	output -p $name 'Installing Script'
	$mv "$pdir/$name.sh" $cmd_bin
	$elf $cmd_bin
	output -hT "$name_upper Script Updated"
}
qwerry_bnd(){
	if [[ $1 = '-rU' ]] #Condition for update release file
	then
		btest -env -root || return 1
		current_dir=$(pwd)
		output -hT "Updating Repository"
		cd $pdir
		$rm $pdir/release
		if [[ $lc_repo = 0 ]]
		then
			output -p $name "Downloading Release"
			btest -net || return 1
			$dl $repo/release
		else
			output -p $name "Importing Release"
			output -d "dir" $lc_repo
			$cp $lc_repo/release .
		fi
		bmr -rm @release
		bmr -rgt @release $($cat $pdir/release)
		output -hT "Repository Updated"
		cd $current_dir
	else #Until search bundles in current release file
		## Import and verify release file
		if [[ ! -e $pdir/release ]]
		then
			output -e "Error / No release file' 'Use “$name -rU” to download."
			return 1
		fi
		## Bundles list and search output
		rel_h=()
		case $1 in
		"") #List all
			output -hT "Avaliable bundles"
			for bnd in ${release[@]}
			do
				output -t "$bnd"
			done
		;;
		*) #List using regex
			output -hT "Results for “$1”"
			for argb in $*
			do
				for bnd in ${release[@]}
				do
					if [[ $bnd = *"$argb"* && ${rel_h[@]} != *"$bnd"* ]]
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
	btest -net -root || return 1
	for i in $*
	do
		if [[ $i = flatpak ]]
		then
			output -hT "Configuring flatpak"
			output -p $name "Installing flatpak"
			pma -i flatpak
			output -p $name "Adding Flathub"
			$flatpak_remote $flathub
			output -hT "flatpak enabled"
			bmr -rgt @extras "“flatpak” enabled -> remote=“$flathub”, mode=“$fp_mode”."
		fi
		if [[ $i = snap ]]
		then
			$prt "soom..."
		fi
	done
exit
}
detect_user_props(){
	pwdp=($(pwd|tr '/' ' '))
	if [[ "${pwdp[0]}" = "home" ]]
	then
		h="/home/${pwdp[1]}"
		u="${pwdp[1]}"
	elif [[ "${pwdp[0]}" = "root" ]]
	then
		h="/root"
		u="root"
	fi
}
btest(){
	## Error Texts BataBase
	declare -A bterr
	bterr['-root']="-ahT “$name $cmd” needs root privileges"
	bterr['-net']="-ehT No internet connection"
	bterr['-env']="-ahT BMN environment not correctly configured"
	bterr['-api']="-ahT Invalid “${args[1]}” api call"
	ef=0
	
	## Tests
	for err_type in $*
	do
		case $err_type in 
			'-root')
				[[ $UID != 0 ]] &&  err_out=${bterr[$err_type]} && ef=1
			;;
			'-net')
				wget -q --spider www.google.com
				[[ $? != 0 ]] && err_out=${bterr[$err_type]} && ef=1
			;;
			'-master')
				ef=1 && init_data=($([ -f $init_file ] && cat $init_file))
				[[ ! -z "$init_data" && $0 = "${init_data[1]}" || $0 = "/etc/bmn/source" && "${init_data[1]}" = '/etc/bmn/source' || $0 = "bmn.sh" ]] && ef=0
				unset init_data
			;;
			'-installer')
				ef=1 && [[ $0 = "bmn.sh" ]] && ef=0
			;;
			'-env')
				[[ ! -d $pdir && ! -d $bnd_dir && ! -f $init_file && ! -f $bmr_db && ! -f $cfg_file ]] && err_out=${bterr[$err_type]} && ef=1
			;;
			'api')
				[[ ${args[1]} != 'pma' || ${args[1]} != 'output' || ${args[1]} != 'bmr' ]] && ef=1
			;;
		esac
		[[ ! -z "${bterr[$err_type]}" && $ef = 1 ]] && output ${bterr[$err_type]}
		[[ $ef = 1 ]] && return $ef
	done
	return $ef
}
live_shell(){
	btest -env -root -master || return 1
	#export current_dir=$(pwd)
	#cd $pdir
	bash --init-file $init_file
	bmr -rgt @bsh_login
	#cd $current_dir
}
null(){
	return $?
}

### Program Start ###
bmn_data $* && bmn_init $*
