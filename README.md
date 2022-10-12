# Configuration Bundles Manager (C.F.G.B)
cfgb is a package manager-like tool created to facilitate post-installation of Linux distributions.
***
The tool works with a specific packaging pattern, which groups packages lists of distributions and flatpaks to install and remove, along with the minishell environment variables kit for creating simple recipe shell scripts.

Packages are downloaded from your own online repository. The only repository tested was github, but it works with any URL that supports direct download. . 

Look at the example.tar.gz package to learn the packaging pattern, and the minishell is present in the load_data function inside cfgb.sh.
