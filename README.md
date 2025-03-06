# Inception notes
## What is Docker? How does it work?
- Engine that automates the package and delivery of applications into containers
- It is a client-server application with the following key components:
	- Engine, Client, Daemon, Images, Containers, Hub
- The flow for Docker is typically:
	1. Create a Dockerfile
	2. Build the image or pull an existing one
	3. Run a container
	4. Manage containers or share images

## What are images? How do they work?
- Building blocks where containers are launched (the “source code” of containers)
- Can be created using a Dockerfile

## What is a Dockerfile?
- Text file that contains the instructions for building a Docker image
- Specifies the base image, dependencies/software/scripts to install
- The subject PDF forbids the use of the `latest` tag for the base image as it is just a label and does not guarantee it points to the most recent release of an image. It can lead to unexpected behavior if the image gets updated without notice

## What are containers? How do they work?
- A container is a standard unit of software that packages up code and all its dependencies that allows application to run quickly and reliably from one computing environment to another
	- In other words, they are running process(es) isolated from the OS with all its/their dependencies installed
- They are launched from images and can contain one or more running processes

## What is Docker Compose? How does it work?
- A tool that simplifies the management of multi-container Docker applications
- Instead of running multiple `docker run` commands manually (manually start and link containers), Docker Compose allows you to define and manage all your containers in a single docker-compose.yml file
- The documentation suggests the use of `compose.yaml` over `docker-compose.yml`
- The flow is typically:
	1. Define services in the `YAML` file
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
- This can affect the graceful shutdown of containers since the daemon might still be running when we send e.g., a `SIGTERM` signal, potentially leading to data corruption
- `MariaDB` runs in the foreground by default but we must explicitly make sure `PHP-FPM` and `nginx` do that too!

## Relevance of our directory structure
- Each service is compartmentalized into its own directory. This ensures changes to one service don’t inadvertently affect others

## Volumes
- Persistent storage mechanism that lets containers store data outside their filesystem
- Volumes don’t disappear when the container stops or is deleted
- Pros of volumes are as follows:
	- Prevents data loss when a container restarts
	- Multiple containers can access the same volume allowing data to be shared easily
	- Volumes can be backed up separately from containers
	- Volumes work across different systems (e.g., Windows, Linux) and is independent of the host

### Named Volumes
- Docker fully manages the volume
- Stored under `/var/lib/docker/volumes/`
- Best for persistent data like databases

### Anonymous Volumes
- Similar to named volumes but gets deleted when no containers use it

### Bind Mounts (Maps a Specific Host Directory)
- Directly binds a host folder to the container
- Can access files outside Docker’s control
- Bind mounts give full access to the host, which may be a security risk

## Network
- The subject PDF forbids the use of `--network=host` because it disables container isolation by making the container share the host’s network stack. This imposes the following risks:
	- Security Risk – Containers will have full access to the host’s `port`s and services, increasing attack surface
	- Port Conflicts – Since the container shares the host’s IP, it can't bind the same `port`s as other applications
	- Not Cross-Platform – Works only on Linux, not on Mac or Windows, making it less portable.
`--link` or `links` on the other hand is forbidden just because it’s deprecated
- Read further for more details

### Default Bridge Network
- On download, Docker deploys its own default network
	- `ip address show` and you’ll see `docker0` which is our default virtual bridge interface/network (sth like a switch)
		- The address shown will be the gateway address for the Docker network and all our Docker containers (can also type `ip a show docker0`)
		- External networks e.g., the Internet can also be reached using NAT via the host
	- `sudo docker network ls` and you’ll see more
- When a container is started (without `docker compose`), Docker creates a virtual Ethernet interface pair
	- One end attached to the container `eth0`, the other connected to `docker0` on the host (`veth`)
		- Analyze the output of `bridge link` to prove that they’re connected to `docker0`
	- Can check again using `ip address show`
- Docker also hands out IP address to the new container (it’s running some DHCP)
	- `sudo docker inspect bridge`
	- Their IP addresses belong to the same network as `docker0`
	- This means that all containers in this network can talk to each other directly (`docker0` is kinda acting like a switch)
	- They can also talk to the host and the Internet (if host itself is connected)
- However, in order for an external connection to reach a container, we’ll need to expose its `port`

### User-defined network
- If you define your own network, it’ll get a new subnet e.g., 172.18.0.1/16.
	- Again, can check with `ip address show`, `bridge link`,  and `sudo docker inspect <network-name>`
- This user-defined network is isolated from the default network but containers within it can perform DNS lookup. This feature isn’t available in the default network

### Default Host Network
- No network interfaces are created
- Containers here directly share the host’s network stack, meaning they use the host’s IP and `port`s as if they were processes running on the host itself
- This means you don’t have to expose any `port`s

### MACVLAN (Bridge mode)
- Basically it’s like connecting your containers directly to your house’s physical switch
- Containers connected like this get their own MAC addresses
	- But may need to enable 'promiscuous' due to this
- They also get IP addresses on the home network
- Has all the benefits of the default bridge network on top of this but with no DHCP (so have to manually assign IP address)

### MACVLAN (802.1q mode)
- Sth cool idk. Trunks? Create new virtual interfaces?

### IPVLAN (L2 mode)
- Same as MACVLAN (bridge mode) but they share a MAC address with their host so no promiscuity issues
- Also have their own IP addresses

### IPVLAN (L3 mode)
- Kinda connects to the host directly like the host is a router
- No more broadcasting so cannot talk to anyone outside their network, exposed `port`s also don’t work. Need to manually configure in the router
- Very high isolation<br>

## Project flow
1. User types https://qtay.42.fr (replace 'qtay' with your login) in the browser
2. Browser performs DNS resolution and resolves https://qtay.42.fr to the IP address 127.0.0.1 (loopback) which [refers to our own computer](#initial-configuration)
3. Browser attempts to send a HTTPS request to our computer through `port` 443. Note that our [host’s port 443 is set to map traffic to `nginx`’s port 443](#nginx-ports)
4. `Nginx` which only listens on port 443 receives the request
	- `Nginx` looks at its [configuration file](#nginx-configuration-file) to determine which page to show which has to be set to `index.php`. Note that this file will be automatically created by `WordPress` upon installation
5. `Nginx` can only serve static files directly so it passes the dynamic `index.php` file to `PHP-FPM` (in our `WordPress` container) to be processed
	- The `WordPress` container can be [accessed directly using its name](#wordpressDNS) since both containers belong to the same user-defined network
6. `PHP-FPM` receives the request and processes the `.php` file
	- To allow this to happen, `PHP-FPM` has to be first configured to [listen for any `FastCGI` requests on a TCP socket](#phpfpmTCP) (instead of unix sockets which only allows localhost access) on its default `port` 9000
7. `PHP-FPM` has to fetch data from its `MariaDB` database, so it has to be accessible to and from the `MariaDB` container.
	- `PHP-FPM` looks at the value for `DB_HOST` in the `wp-config.php` file and sees ‘`mariadb`’ (i.e., your `MariaDB` container's name). It performs DNS resolution and finds the IP of `MariaDB` whose default `port` is 3306
	- We also need to [configure `MariaDB`](#mariadbbind) to listen on a TCP socket as well in order for PHP-FPM to reach it</span>
8. `PHP-FPM` successfully creates the webpage and sends it back to `nginx` which serves it back to our browser

## Initial configuration
- Add a non-root user with `sudo` privileges to manage Docker securely
	- Might need to use `su`
	- `sudo usermod -aG docker <myuser>; su - <myuser>`

### Virtual Machine
- To allow our own address to refer to localhost, we add the line:
`qtay.42.fr 127.0.0.1` to our `/etc/hosts` file

### WSL
- To run on `WSL`, you have to find out the IP address of your `WSL` instance using `wsl hostname -I` in the Windows Command Prompt
	- The first one is WSL’s, the second is Docker’s (double check for your case)
- Then add `<WSL-IP> qtay.42.fr` to the file `C:\Windows\System32\drivers\etc\hosts`

## MariaDB container
- `MariaDB` is a database that stores all the dynamic content, settings, and user data for a website
- In this project, `WordPress` (technically `PHP-FPM`) communicates with `MariaDB` to query or update it
- Depending on your base image, you might also need to create a directory called `/var/run/mysqld` to allow PID files to be stored
- <span id="mariadbbind">By default, `MariaDB` only listens to requests through its localhost unix socket which stops `WordPress`  from reaching it. Therefore you have to edit its `50-server.cnf` config file to listen on a TCP socket to all IP4 addresses on `port` 3306:
	- `bind-address = 0.0.0.0`</span>
- You can interact with your database using SQL queries by running the `mysql` command in the `MariaDB` container like so:
	- `docker exec -it mariadb mysql -u <username-or-root> -p`


## WordPress container
- `WordPress` is a backend content management system (CMS) that requires a database like `MariaDB`/`MySQL` to store information such as posts, pages, user data, settings, and comments
	- It's a [PHP](https://en.wikipedia.org/wiki/PHP) application that works together with `nginx` and `MariaDB` to serve content to users
	- Because of this we need to download `PHP-FPM` which is a `FastCGI` server that executes scripts written in `PHP`
	- The `php-mysqli` extension is also needed to allow `PHP` scripts to interact with `MySQL`/`MariaDB` databases
- Since we have to automate the installation of `WordPress`, we also need to download the [WordPress' CLI](https://wp-cli.org/)
- Depending on your base image, you might also need to create a directory called `/run/php` to allow PID files to be stored
- <span id="phpfpmTCP">By default</span>, `PHP-FPM` only listens to requests through its localhost unix socket which stops `nginx` from reaching it. Therefore you have to edit its `www.conf` file to allow it to listen on a TCP socket to all IP4 addresses on `port` 9000:
	- `listen = 0.0.0.0:9000`
	- `www.conf` is a pool configuration file that defines how `PHP` processes are managed for a specific website. It controls process settings, user permissions, and `FastCGI` behavior for `PHP` scripts
- After downloading `WordPress`' core files, you have to set up the `wp-config.php` file to connect with the correct database
- Once connected you can proceed to finish the installation by setting up `admin` and `user` information
- `PHP-FPM` has to be launched in the foreground to make it the main process (PID 1) in its container

## Nginx container
- Nginx needs access to the `/var/www/html` volume too in order to serve files

### Nginx ports
- Since we should only be able to reach our whole architecture through `port` 443, we should only expose `nginx`'s `port` 443 to our host in the `compose.yaml` file
- To ensure `nginx` listens on `port` 443 and not `port` 80, we also have to add `listen 443 ssl` to the `nginx` configuration file

### Transport Layer Security (TLS)
- This is a protocol used to encrypt data between a client and a server
- Can be done using `openssl`
- To demonstrate the use of TLS1.2/1.3:
	- Launch the 'Browser Developer Tools' and click on 'Security', or launch a `shell` terminal in the `nginx` container and type the following command:
		- `openssl s_client -connect qtay.42.fr:443 -verify_return_error -CAfile <path-to-certificate>`

### openssl
- An open-source cryptographic library that provides tools and implementations for SSL (Secure Sockets Layer) and TLS (Transport Layer Security) protocols

### Nginx configuration file
- The global config file for `nginx` is `/etc/nginx/nginx.conf`
	- If you `cat` it, you’ll see its contents include both `/etc/nginx/conf.d/*.conf` and `/etc/nginx/sites-enabled/*`
	- Click [here](https://serverfault.com/questions/527630/difference-in-sites-available-vs-sites-enabled-vs-conf-d-directories-nginx) to see the difference
- A config file tells `nginx` which `root` directory to look for files and what files to display when a `directory` request is sent
- It’s also responsible for passing any `FastCGI` requests to `PHP-FPM`
	- E.g., the line <span id="wordpressDNS">`fastcgi_pass wordpress:9000`</span> allows `nginx` to send the request to the correct `WordPress` IP through the correct `port`
- Ssl certificates, keys and protocols used are also listed here:
	- `listen 443 ssl` tells `nginx` to expect encrypted connections on `port` 443
	- `ssl_certificate` is the public SSL/TLS certificate that clients receive when connecting to your server (self-signed). It contains the public key and domain validation details
	- `ssl_certificate_key` is the private key that matches the public certificate
- Note that `nginx` has to be run explicitly in the foreground to make it the main process (PID 1) in its container
