# Install and manage a minecraft server

class minecraft-server {

	# let's try the open source jdk
	package { "openjdk-6-jre":
		ensure => "present"
	}
	
	# stable minecraft: https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar
	# snapshots: http://assets.minecraft.net/13w09a/minecraft_server.jar
	
	define manage (
		$path	= "/home/minecraft",
		$user 	= "minecraft",
		$group 	= "minecraft",
		$ensure	= "present",
		$memory	= "256M",
		$snapshot	= false
	) {
		
		$server_path = "${path}/minecraft_server.jar"
		
		# get the latest stable version by default
		$url	= "https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar"
		$version= "stable"
		
		group { $group:
			ensure	=> $ensure
		}
		
		user { $user:
			ensure	=> $ensure,
			home	=> $path,
			shell	=> "/bin/false",
			gid		=> $group
		}
		
		file { $path:
			ensure	=> directory,
			owner	=> $user,
			group 	=> $group,
			mode	=> 755
		}
		
		if $snapshot {
			# get a snapshot version
			$url	= "http://assets.minecraft.net/$snapshot/minecraft_server.jar"
			$version= $snapshot
		}
		
		exec { "download-server":
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
			rewuire	=> Exec['download-server']
		}
	}
}