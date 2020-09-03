require "yaml"
require "fileutils"
require_relative "jobgen.rb"

def error(msg)
  puts "#{File.basename($0)}: #{msg}"
  exit 1
end


module VM
  class <<self
    def vm_list
      %x{multipass list}.strip.lines[1..-1].to_a.map do | line |
        line.split(/\s+/, 4)
      end
    end

    def init_system(config_file)
      error "No configuration file provided" if not config_file
      $OscarConfigFile = config_file
      begin
        $OscarConfig = YAML.safe_load(File.read(config_file))
      rescue
        error "cannot load configuration file \"#{ARGV.first}\""
      end
      $VMSpec = $OscarConfig["vm"]
      $VMName = $VMSpec["name"]
      begin
        vms = vm_list
      rescue
        error "multipass not installed or usable"
      end
      # error "a multipass VM called \"#{$VMName}\" already exists" if find_vm
    end

    def launch_vm
      cpus = ($VMSpec["cpus"] || 2).to_s
      image = ($VMSpec["image"] || "release").to_s
      memory = $VMSpec["mem"] || "2G"
      diskspace = $VMSpec["disk"] || "8G"
      specfile = $VMSpec["spec"]
      specfile = File.expand_path(specfile, File.dirname($OscarConfigFile))
      error "Missing VM spec file in configuration" unless specfile
      system("multipass", "launch",
        "--cpus", cpus,
        "--mem", memory,
        "--disk", diskspace,
        "--name", $VMName,
        "--cloud-init", specfile,
        image)
    end

    def find_vm
      vms = vm_list
      for vm in vms do
        if vm.first == $VMName then
          return vm
        end
      end
      return nil
    end

    def start_vm
      system("multipass", "start", $VMName)
    end

    def stop_vm
      system("multipass", "stop", $VMName)
    end


    def transfer(source, dest)
      system("multipass", "transfer",
        source, "#{$VMName}:#{dest}")
    end

    def write(path, data)
      IO.popen(["multipass", "transfer", "-", "#{$VMName}:#{path}"], "w") do
        | pipe |
        pipe.write data
      end
    end

    def mount(source, dest)
      system("multipass", "mount",
        "-g", "#{%x{id -g}.strip}:1000",
        "-u", "#{%x{id -u}.strip}:1000",
        source, "#{$VMName}:#{dest}")
    end

    def umount
      system("multipass", "umount", $VMName)
    end

    def execute(*args)
      system("multipass", "exec", $VMName, "--", *args)
    end

    def ip_address
      for name, state, ip, image in vm_list do
        if name == $VMName and ip != "--" then
          return ip
        end
      end
      return nil
    end
  end
end
