# Vagrant config file for Topher's web development courses & workshops.
# Source: https://github.com/topherhunt/??? [TODO - fill this in]
#
# Usage:
#   * Ensure Vagrant and VirtualBox are installed
#   * Open your terminal and navigate to the folder where this file lives
#   * Run: `vagrant up`
#   * Run: `vagrant ssh` to SSH into the box
#
# For more Vagrant usage tips, see [TODO - Vagrant cheatsheet link]

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/bionic64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # This project folder is synced to "/vagrant" inside the Vagrant VM.
  # See https://www.vagrantup.com/intro/getting-started/synced_folders.html

  # Customize the amount of memory on the VM
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  # See https://www.vagrantup.com/docs/provisioning/shell.html
  config.vm.provision "shell", path: "vagrant_provision.sh",
    privileged: false # do NOT run as root - sometimes this can cause problems
end
