# Install and manage a minecraft server

class minecraft-server {

	# let's try the open source jdk
	package { "openjdk-6-jre":
		ensure => "present"
	}
	
	# stable minecraft: https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar
	# snapshots: http://assets.minecraft.net/13w09a/minecraft_server.jar
	
	define manage (
		$properties	= {},
		$path	= "/home/minecraft",
		$user 	= "minecraft",
		$group 	= "minecraft",
		$ensure	= "present",
		$memory	= "256M",
		$snapshot	= false
	) {
		
		$server_path = "${path}/minecraft_server.jar"
		
		group { "$group-$title":
			name		=> $group,
			ensure	=> $ensure
		}
		
		user { "$user-$title":
			name	=> $user,
			ensure	=> $ensure,
			home	=> $path,
			shell	=> "/bin/false",
			gid		=> $group
		}
		
		file { $path:
			ensure	=> directory,
			owner		=> $user,
			group 	=> $group,
			mode		=> 755
		}
		
		if $snapshot {
			# get a snapshot version
			$url	= "http://assets.minecraft.net/$snapshot/minecraft_server.jar"
			$version= $snapshot
		} else {
			# get the latest stable version by default
			$url	= "https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar"
			$version= "stable"
		}
		
		exec { "download-server-$title":
			command	=> "wget -O $server_path $url",
			unless	=> "test `cat $path/version` = '$version'",
			require	=> File[$path],
			path	=> "/usr/bin/:/bin"
		}
		
		file { "$path/version":
			ensure	=> file,
			content	=> $version,
			require	=> Exec['download-server']
		}
		
		# create a start up script for this minecraft server
		file { "/etc/init.d/minecraft-$title":
			content	=> template ("minecraft-server/init.erb"),
			mode	=> 755,
			owner	=> root,
			group 	=> root,
			require	=> Exec['download-server']
		}
		
		# Manage server properties (port, etc)
		if keys($properties) {
			
			file { "$path/server.properties":
				ensure => file,
			}
			
			$defaults = {
				path   => "$path/server.properties"
			}
			
			# since there are no real loops in puppet,
			# we have to resort to hacks like this. See:
			# http://docs.puppetlabs.com/references/latest/function.html#createresources
			
			create_resources(minecraft-server::property, $properties, $defaults)
			
		}
	}
	
	define property(
		$value,
		$path
	) {
		
		file_line { "$name-$path":
		    path   => $path,
		    line   => "$name=$value",
		    match  => "$name=.*"
		  }
	
	}
}