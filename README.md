# Automation Bundles Manager (BMN)
It is something like a package manager (but weirder) focused in shell script automation, created to facilitate my tasks in Linux based operational systems, especially package management across different distributions.

# Setup instructions  

**Dependencies:** ``bash``  
 Bash is used as a interpreter for bmn source code, so there is no need to use it as a main shell and the program will run fine in any other shell.   

**Install syntax:** ``sudo bash bmn.sh -s “repository”``  
- The repository field can be from github raw content or any other direct download URL.  
- You can insert the repository in the ``repo`` variable inside the config file and you won't need to specify this field.

# Usage instructions
Syntax: ``sudo bmn ”command” “arguments” ``  
For help: ``bmn --help``
