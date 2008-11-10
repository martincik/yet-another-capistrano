require 'rubygems'
require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/engine/engine'
require 'net/ssh'

engine = OpenWFE::Engine.new(:definition_in_launchitem_allowed => true)

module Configuration
  def servers
    [
      { 
        :name => 'krypton',
        :host => 'krypton.exmaple.com',
        :user => 'laco',
        :password => 'password',
        :port => 33321,
      },
      { 
        :name => 'aeryn',
        :host => 'aeryn.example.com',
        :user => 'laco',
        :port => 33321,
        :keys => [File.join(ENV["HOME"], ".ssh", "id_rsa")] 
      },
      { 
        :name => 'keiko',
        :host => 'keiko.example.com',
        :user => 'laco',
        :port => 33321,
        :keys => [File.join(ENV["HOME"], ".ssh", "id_rsa")] 
      },
      { 
        :name => 'chiana',
        :host => 'chiana.example.com',
        :user => 'laco',
        :port => 33321,
        :keys => [File.join(ENV["HOME"], ".ssh", "id_rsa")] 
      }
    ]
  end
end

include Configuration

servers.each do |server|
  engine.register_participant server[:name] do |workitem|
    puts "Connecting to '#{server[:host]}'..."
    output = ''
    
    if server[:keys]
      ssh_options = {
        :keys => server[:keys],
        :port => server[:port]
      }
    else
      ssh_options = {
        :password => server[:password],
        :port => server[:port]
      }
    end
    
    Net::SSH.start(server[:host], server[:user], ssh_options) do |ssh|
      output = ssh.exec!("ls -al /home")
    end

    workitem.send("#{server[:name]}_output=".to_sym, output)
  end
end

engine.register_participant :summarize do |workitem|
  puts 
  puts "summary of process #{workitem.fei.workflow_instance_id}"
  workitem.attributes.each do |k, v|
    next unless k.match ".*_output$"
    puts " - #{k} : '#{v}'"
  end
end

class TheProcessDefinition0 < OpenWFE::ProcessDefinition
  include Configuration
  
  sequence do
    concurrence do
      servers.each do |server|
        participant server[:name]
      end
    end
    participant :summarize
  end
end

li = OpenWFE::LaunchItem.new(TheProcessDefinition0)
fei = engine.launch li
engine.wait_for fei