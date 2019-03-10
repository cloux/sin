# Simple Installer

## About

**S**imple **IN**staller provides a common interface for running multiple scripts in series, aimed to automate the installation and updates of applications outside of the main software repositories. Easily customizable and extendable using modular file structure. Poses no restrictions on the programming language, installation methods or required privileges for used commands. It is aimed at GNU/Linux, but it should run on any OS with a shell like FreeBSD or MacOS.

### Structure

Simple Installer works with **modules** and **commands**. Modules are directories in the installer module path, and commands are executable scripts within these directories. SIN searches for modules/commands in:

 1. ~/.local/share/sin/_module/command_
 1. /usr/local/share/sin/_module/command_
 1. /usr/share/sin/_module/command_
 1. in the **sin** script path inside _modules_ subdirectory

Module paths are searched in this order. If there is more than one module with the same name, the first found _module/command_ is the one that will be executed.

### Command Scripts

All command scripts should:

 * have executable bit set
 * be able to run unattended and never require user input
 * never use parameters, use config files if required
 * be able to run as standalone outside of **sin**
 * have log-friendly output and don't use color codes or other terminal sequences
 * return 0 on success and non-zero on failure

Every module should have at least one command script named **install**. This command should be able to install and optionally update software if already installed.

### Cache

Some SIN command scripts might use system directories to track installations and version updates:

 * /var/cache/sin/
 * /usr/src/
 * /opt/

### Logfiles

If run as root, command output is logged into _/var/log/sin/COMMAND.log_. Existing logfiles are overwritten, no log rotation is necessary. If run as local user, terminal output is not logged to a file. If required, you might run `sin MODULE | tee LOGFILE` to save the output to a _LOGFILE_.

---
## Installation

To install SIN with the base modules, run:

```
git clone https://github.com/cloux/sin
sudo sin/sin sin
```

After the installation, you can remove the local repository by running `rm -rf sin`. Note that SIN can be used without installation, see [Usage witout installation](#without-installation).

To update an existing installation, run:

```
sin sin
```

To uninstall SIN and all its base modules, run:

```
sin remove sin
```

---
## Usage

### Syntax

`sin [COMMAND] MODULE`

A single parameter is expected to be a module name. The default command is _install_.

`sin COMMAND MODULE MODULE ...`

For two or more parameters, the first parameter is command followed by a list of modules for which the command is executed.

### Without installation

You can download and run SIN locally without installation. To install and run SIN locally:

```
git clone https://github.com/cloux/sin
sin/sin COMMAND MODULE
```

Also, every script for every module can be downloaded and run separately as a standalone program. To download and use a single module installer without SIN, e.g. to install/update [wireguard](https://www.wireguard.com):

```
wget https://raw.githubusercontent.com/cloux/sin/master/modules/wireguard/install
chmod 755 install
./install
```

For a list of available modules and scripts see [modules](modules).

### Examples

 * `sin gitahead`  
   A single parameter is assumed to be a module name with _install_ command => install/update [GitAhead](https://gitahead.github.io/gitahead.com/)
 * `sin install kernel wireguard`  
   Install/update Linux kernel and [wireguard](https://www.wireguard.com) tunnel
 * `sin check kernel`  
   Check if a new Linux kernel is available on kernel.org


---
<a href="http://www.wtfpl.net"><img src="http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl-badge-2.png" align="right"></a>
## License

This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net for more details. If you feel that releasing this work under WTFPL is not appropriate, just do WTF you want to. If you feel that using some of this code might be violating some other license, don't use the code (see [Disclaimer](#disclaimer)).

---
## Author

This repository is maintained by _cloux@rote.ch_

### Disclaimer

I do not claim fitness of this project for any particular purpose and do not take any responsibility for its use. You should always choose your system and all of its components very carefully, if something breaks it's on you. See [license](#license).

### Contributing

I will keep this project alive as long as I can. This is however a private project, so my support is fairly limited. Any help with further development, testing, and bugfixing will be appreciated. If you want to report a bug, please either [raise an issue](https://github.com/cloux/sin/issues), or fork the project and send me a pull request.

---