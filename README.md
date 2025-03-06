# Inception notes
## What is Docker? How does it work?
- Engine that automates the package and delivery of applications into containers
- It is a client-server application with the following key components:
	- Engine, Client, Daemon, Images, Containers, Hub
- The flow for Docker is typically:
	1. Create a Dockerfile
	2. Build the Image or pull an existing one
	3. Run a Container
	4. Manage Containers or Share Images

## What are images? How do they work?
- Building blocks where containers are launched (the “source code” of containers)
- Can be created using a Dockerfile

## What is a Dockerfile?
- Text file that contains the instructions for building a Docker image
- Specifies the base image, dependencies/software/scripts to install
- The ‘latest’ tag is forbidden here e.g., for the base image as it is just a label and does not guarantee it points to the most recent release of an image. It can lead to unexpected behavior if the image gets updated without notice

## What are containers? How do they work?
- A container is a standard unit of software that packages up code and all its dependencies that allows application to run quickly and reliably from one computing environment to another
	- In other words, they are running process(es) isolated from the OS with all its/their dependencies installed
- They are launched from images and can contain one or more running processes

## What is docker compose? How does it work?
- A tool that simplifies the management of multi-container Docker applications
- Instead of running multiple docker run commands manually (manually start and link containers), Docker Compose allows you to define and manage all your containers in a single docker-compose.yml file
- The documentation suggests the use of `compose.yaml` over `docker-compose.yml`
- The flow is typically:
	1. Define services in the YAML file
	2. Build and start services with `docker compose up`
		- Note that `docker-compose` was a standalone Python-based tool that needed to be installed separately but `docker compose` (without a hyphen) is now a Docker CLI plugin, integrated into newer versions of Docker.
	3. Manage running containers: `docker compose down`, `docker compose restart`, `docker compose logs`

## Comparison with VM
- Docker shares the host OS kernel, so is more lightweight and efficient in terms of start up time, resource usage and overhead
	- The use of a layered file systems mean common files are shared between containers, reducing redundancy (saves storage space)
	- Scalable and can be deployed very quickly (fast and CI/CD friendly)
- It also ensures applications run identically across different environments. This isn’t true for VMs as applications may behave differently depending on the OS and configuration of the VM
- Some cons include:
	- Less security compared to VMs due to incomplete OS isolation (no kernel or hardware isolation)
	- Runs only on Linux-based OS kernels unlike VMs that can run on any OS
		- Meaning my containers should not be able to run on Mac/Windows (without Docker Desktop with Linux or WSL)

## Daemons
- Containers are designed run one main process (PID 1, the application) and does not require a persistent background service or daemon
- Using `tail -f /dev/null` or other similar hacks to keep a container running effectively causes the container to do nothing useful, while still keeping the container alive
- This can be problematic for graceful shutdown of containers since the daemon might still be running when we send e.g., a `SIGTERM` signal, potentially leading to data corruption
- `MariaDB` runs in the foreground by default but we must explicitly make sure `PHP-FPM` and `Nginx` do that too!

## Relevance of our directory structure
- Each service is compartmentalized into its own directory. This ensures changes to one service don’t inadvertently affect others

## Volumes
- Persistent storage mechanism that lets containers store data outside their filesystem
- Volumes don’t disappear when the container stops or is deleted
- Benefits of volumes include:
	- Data Persistence – Prevents data loss when a container restarts.
	- Sharing Data Between Containers – Multiple containers can access the same volume.
	- Easier Backups – Volumes can be backed up separately from containers.
	- Host Independence – Volumes work across different systems (e.g., Windows, Linux).

### Named Volumes
- Docker fully manages the volume
- Stored under /var/lib/docker/volumes/
- Best for persistent data like databases

### Anonymous Volumes
- Similar to named volumes but gets deleted when no containers use it

### Bind Mounts (Maps a Specific Host Directory)
- Directly binds a host folder to the container
- Can access files outside Docker’s control
- Bind mounts give full access to the host, which may be a security risk

## Network
### Default Bridge Network
- On download, Docker deploys its own default network
	- `ip address show` and you’ll see `docker0` which is our default virtual bridge interface/network (sth like a switch)
		- The address shown will be the gateway address for the Docker network and all our Docker containers (can also type `ip a show docker0`)
		- External networks e.g., the Internet can also be reached using NAT via the host
	- `sudo docker network ls` and you’ll see more
- When a container is started (without `docker compose`), Docker creates a virtual Ethernet interface pair
	- One end attached to the container `eth0`, the other connected to `docker0` on the host (`veth`)
		- `bridge link` to prove that they’re connected to `docker0`
	- Can check again using ip address show
- Docker also handed out IP address to the new container (it’s running some DHCP)
	- `sudo docker inspect bridge`
	- Their IP addresses belong to the same network as `docker0`
	- This means that all containers in this network can talk to each other directly (`docker0` is kinda acting like a switch)
	- They can also talk to the host and the internet (if host itself is connected)
- However, in order for an external connection to reach a container, we’ll need to expose its port

### User-defined network
- If you define your own network, it’ll get a new subnet e.g., 172.18.0.1/16.
	- Again, can check with `ip address show`, `bridge link`,  and `sudo docker inspect <network-name>`.
- This user defined network is isolated from the default network but containers within it can perform DNS lookup. This feature isn’t available in the default network

### Default Host Network
- No network interfaces are created
- Containers here directly share the host’s network stack, meaning they use the host’s IP and ports as if they were processes running on the host itself
- This means you don’t have to expose any ports

### MACVLAN (Bridge mode)
- Basically it’s like connecting your containers directly to your house’s physical switch
- Containers connected like this get their own MAC addresses
	- But may need to enable promiscuous due to this
- They also get IP addresses on the home network
- Has all the benefits of the default bridge network on top of this but with no DHCP (so have to manually assign IP address)

### MACVLAN (802.1q mode)
- Sth cool idk. Trunks? Create new virtual interfaces?

### IPVLAN (L2 mode)
- Same as MACVLAN (bridge mode) but they share a MAC address with their host so no promiscuous issues
- Also have their own IP address

### IPVLAN (L3 mode)
- Kinda connects to the host directly like the host is a router
- No more broadcasting so cannot talk to anyone outside their network, exposed ports also don’t work. Need to manually configure in the router
- Very high isolation<br>

- The subject PDF forbids the use of --network=host because it disables container isolation by making the container share the host’s network stack. This imposes the following risks:
	- Security Risk – Containers will have full access to the host’s ports and services, increasing attack surface
	- Port Conflicts – Since the container shares the host’s IP, it can't bind the same ports as other applications
	- Not Cross-Platform – Works only on Linux, not on Mac or Windows, making it less portable.
`--link` or `links` on the other hand is forbidden just because it’s deprecated
