# Fission

## Intro
Fission is a simple command line tool for cloning of VMware Fusion VMs.


## Config
By default, fission will use the default VMware Fusion VM directory
(~/Documents/Virtual Machines.localized/) when cloning.  If you want to use a
different directory, you can set this in a config file.

The config file needs to be in yaml format and live at '~/.fissionrc'

    $cat ~/.fissionrc
    ---
    vm_dir: "/vm"


## Install
    gem install fission


## Usage
### Clone
    fission clone my_vm new_vm

### Help
    fission -h

or just

    fission


## Other
Notable Info As of now, VMware Fusion doesn't provide an easy, out of
the box, way to modify the personality (hostname, ip, etc.) of a VM.  Because of
this, a clone created by fission is an _exact_ copy of the original (including
hostname, ip address, etc.).  Most likely, this isn't what you want.

One approach is to create a VM which will act as a template.  Create the VM with
the desired install method (ideally with easy install) and settings, but do not
power on the VM.  You can create clones from this VM and when you power it on,
it will start the OS install process (and assign a new ip, etc.)


## Contribute
* Fork the project
* Make your feature addition or bug fix (with tests) in a topic branch
* Bonus points for not mucking with the gemspec or version
* Send a pull request and I'll get it integrated
