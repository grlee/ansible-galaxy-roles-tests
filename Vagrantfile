# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'logger'
require 'vagrant'

VAGRANTFILE_API_VERSION = "2"

ip_prefix="95"

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

commands_that_allow_primary=Set.new [
  'up',
  'halt',
  'destroy',
  'ssh',
  'provision',
  'pristine'
]

env=ENV['ENV']

if env.nil?
  env="vbox"
end

logger.info("Using env #{env}")
logger.debug("ARGV is #{ARGV}")

only_launch_primary = ((ARGV.size == 1) and commands_that_allow_primary.member? ARGV[1])

logger.debug("only_launch_primary #{only_launch_primary}")

$defaults_boxes = {
    :vb_customizations => [
    ]
}

$boxes = {
    :precise => {
        :box => "precise",
        :box_url => "http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-i386-vagrant-disk1.box"
    },
    :trusty => {
        :box => "trusty",
        :box_url => "http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-i386-vagrant-disk1.box"
    },
    :centos_64 => {
        :box => "centos_64",
        :box_url => "http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210-nocm.box"
    }
}

$defaults_vms = {
    :box => $boxes[:trusty],
    :vb_customizations => [
        ["modifyvm", :id, "--memory", "256"]
    ],
    :synched_folders => [
        {:local => ".", :remote => "/vagrant/", owner: "vagrant", group: "vagrant", mount_options: ["dmode=700", "fmode=600"]},
        {:local => Dir.home + "/.ssh", :remote => "/ssh_user", owner: "vagrant", group: "vagrant", mount_options: ["dmode=700", "fmode=600"]},
    ],
#    :playbook => "site.yml"
}

$vms = { 
  "vbox" => [
    {
        :name => "precise.vbox",
        :is_primary => true,
        :ip_num => 2,
        :port_forwards => [
          { :guest => 22, :host => 20022 }
        ]        
    },
    {
        :name => "trusty.vbox",
        :box => $boxes[:trusty],
        :is_primary => true,
        :ip_num => 3,
        :port_forwards => [
          { :guest => 22, :host => 30022 }
        ]        
    },
    {
        :name => "centos-64.vbox",
        :box => $boxes[:centos_64],
        :is_primary => true,
        :ip_num => 4,
        :port_forwards => [
          { :guest => 22, :host => 40022 }
        ]        
    },
  ]  
}

logger.info("Setting up environment")
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  vms = $vms[env]

  if vms.nil?
    logger.error("No macines defined for environment #{env}")
    exit
  end

  vms.each do |vm|

    name=vm[:name]
    cluster=vm[:cluster].nil? ? 0 : vm[:cluster]
    count=vm[:count].nil? ? 1 : vm[:count]

    logger.debug("Setting up cluster #{name}, number #{cluster}, with #{count} machines")

    (1 .. count).each do |n|

      name=vm[:name]
      hostname = vm[:hostname].nil? ? name : vm[:hostname]

      is_primary = !vm[:is_primary].nil? ? vm[:is_primary] == true : false;
      box = vm[:box].nil? ? $defaults_vms[:box] : vm[:box]
      ip_num = vm[:ip_num]

      logger.debug("Machine #{name} (#{hostname}) ")
      logger.debug("is primary: #{is_primary}")
      logger.debug("box: #{box}")

      if env == "vbox"
        ip="192.168."+ip_prefix+"."+ip_num.to_s
        logger.info("HOSTS >>> " + ip + " " + hostname)
        logger.debug("Setting network to #{ip}")
      end

      if only_launch_primary == true 
        if vm[:is_primary].nil? or vm[:is_primary] == false
          logger.info("Skipping machine #{vm[:name]}")
          next
        end
      end

      config.vm.define name, primary: is_primary do |config|

        config.vm.hostname=name
        config.vm.box = box[:box]
        if !box[:box_url].nil?
          config.vm.box_url = box[:box_url]
        end

        case env
        when "vbox"
          config.vm.network "private_network", :ip => ip
        when "local"
          config.vm.network "public_network", :bridge => 'eth0'
        end 
                 
#        config.vm.provision :hosts
        config.cache.auto_detect = true

        logger.debug("Setting up virtual box")
        config.vm.provider :virtualbox do |vb|
          logger.debug("Customizing machine")

          vb_customizations=box[:vb_customizations].nil? ? $defaults_boxes[:vb_customizations] : box[:vb_customizations];
          vb_customizations.each do |vb_customization|
            vb.customize vb_customization
          end

          vb_customizations=vb[:vb_customizations].nil? ? $defaults_vms[:vb_customizations] : vb[:vb_customizations];
          vb_customizations.each do |vb_customization|
            vb.customize vb_customization
          end


          logger.debug("Adding sync folders")
          synched_folders = vm[:synched_folders].nil? ? $defaults_vms[:synched_folders] : vm[:synched_folders]

          if !synched_folders.nil?

            synched_folders.each do |synched_folder|
              local = synched_folder[:local]
              remote = synched_folder[:remote]
              owner = synched_folder[:owner]
              group = synched_folder[:group]
              mount_options = synched_folder[:mount_options]
              logger.debug("Adding sync folder from #{local} to #{remote}")
              config.vm.synced_folder local, remote, owner: owner, group: group, mount_options: mount_options
            end

          end

          # View the documentation for the provider you're using for more
          # information on available options.

          logger.debug("Setting shell script")
          shell_script = vm[:shell_script].nil? ? $defaults_vms[:shell_script] : vm[:shell_script]
          shell_script_args = vm[:shell_script_args].nil? ? $defaults_vms[:shell_script_args] : vm[:shell_script_args]
          if !shell_script.nil?
            config.vm.provision :shell, :path => shell_script, :args => shell_script_args
          end

          logger.debug("Setting ansible playbook")
          playbook = vm[:playbook].nil? ? $defaults_vms[:playbook] : vm[:playbook]
          if !playbook.nil?
            config.vm.provision "ansible" do |ansible|
              ansible.playbook = playbook
              ansible.inventory_path="inventories/#{env}"
              ansible.limit = hostname
#              ansible.verbose = "vvvv"
            end
          end

          logger.debug("Setting port forwarding")
          if !vm[:port_forwards].nil?
            vm[:port_forwards].each do |port_forward|
              config.vm.network "forwarded_port", guest: port_forward[:guest], host: port_forward[:host]
            end
          end

        end
      end
    end
  end
end