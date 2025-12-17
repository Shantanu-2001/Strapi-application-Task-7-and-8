# **Docker Deep-Dive Documentation **

## **1. What Problem Does Docker Solve? **

Before Docker, developers relied largely on **Virtual Machines (VMs)** to isolate applications. But VMs are *heavy*, *slow*, and *resource-intensive*. Teams faced serious issues :

### **A. “Works on my machine” Problem **

Applications behaved differently on different systems because of :

* Library mismatch
* OS differences
* Dependency conflicts

 **Docker solves this by packaging the entire environment into a container**, making the app **run the same everywhere**.

---

### **B. Slow provisioning**

Spinning up a VM took **minutes**, required gigabytes of disk space, and booted a full OS.

 **Docker spins up containers in seconds**, using MBs instead of GBs.

---

### **C. Inefficient resource usage**

VM = full OS + CPU/Memory overhead → only few VMs per machine.

 Docker containers share the host OS kernel → **lightweight**, so you can run **dozens of containers** on the same machine.

---

### **D. Harder CI/CD pipelines**

Deploying apps was error-prone because environments differed.

 Docker images guarantee reproducible environments → **predictable CI/CD**.

---

### **In One Line**

**Docker solves portability, consistency, speed, efficiency, and scalability issues in modern software development.**

---

<br>

# **2. Virtual Machines vs Docker**
![Alt Text](https://media.geeksforgeeks.org/wp-content/uploads/20230109130229/Docker-vs-VM.png)
### **A. Virtual Machines (Traditional Virtualization)**

* Requires a **hypervisor** (VMware, VirtualBox, Hyper-V)
* Each VM includes
  -> full guest OS
  -> binaries
  -> libraries
  -> application
* Boot time: **minutes**
* Size: **GBs**
* Heavy resource consumption

Example:
3 apps → 3 VMs → 3 separate OS instances.

---

### **B. Docker (Containerization)**

* Uses host OS kernel
* Containers include only:
  -> application
  -> libraries
  -> dependencies
* Boot time: **seconds**
* Size: **MBs**
* Efficient resource sharing

Example:
3 apps → 3 containers → all share same OS → super lightweight.

---

### **C. VM vs Docker Summary Table**

| Feature     | Virtual Machines | Docker Containers      |
| ----------- | ---------------- | ---------------------- |
| Boot Time   | Minutes          | Seconds                |
| Size        | GBs              | MBs                    |
| Isolation   | Strong (full OS) | Medium (shared kernel) |
| Performance | Heavier          | Lightweight            |
| Scalability | Limited          | Highly scalable        |
| OS          | Guest OS per VM  | Shared host OS         |

---

<br>

# **3. Docker Architecture – What Gets Installed?**
![Alt Text](https://miro.medium.com/v2/resize:fit:1100/format:webp/0*kDJEckrqtk653KL_)

When you install Docker, you get **three main components**:

---

## **A. Docker Client (CLI)**

The command-line tool you use:

```
docker run
docker build
docker ps
```

The client **never runs containers**.
It only **talks** to the Docker daemon using REST API.

---

## **B. Docker Daemon (dockerd)**

The *heart* of Docker:

* Builds images
* Runs containers
* Manages volumes
* Manages networks

Daemon listens on UNIX socket `/var/run/docker.sock`.

---

## **C. Docker Registry**

Default registry: **Docker Hub**
Used to pull/push images.

Examples:

* `docker pull nginx` → pulls from DockerHub
* Private registries → AWS ECR, GitHub Container Registry, Harbor

---

## **D. Docker Objects Installed**

When Docker is installed, you get support for:

* **Images**
* **Containers**
* **Volumes**
* **Networks**
* **Buildx** (multi-platform builds)
* **compose plugin** (docker compose V2)

---

<br>

# **4. Dockerfile Deep Dive – Explain Each Line**

A sample `Dockerfile`:

```Dockerfile
# 1. Use base image
FROM node:18-alpine

# 2. Set working directory inside container
WORKDIR /app

# 3. Copy package files
COPY package.json package-lock.json ./

# 4. Install dependencies
RUN npm install

# 5. Copy all source code
COPY . .

# 6. Expose container port
EXPOSE 3000

# 7. Start the app
CMD ["npm", "start"]
```

---

### **Explanation of Each Line**

#### **1. FROM**

Defines the **base image**.

```
FROM node:18-alpine
```

* Uses Node.js 18 on Alpine Linux (lightweight)

---

#### **2. WORKDIR**

Sets default directory inside container.

```
WORKDIR /app
```

Future commands run inside `/app`.

---

#### **3. COPY package.json ...**

Copies dependency files first.

```
COPY package.json package-lock.json ./
```

Helps Docker **cache layers** → faster rebuilds.

---

#### **4. RUN npm install**

Runs a shell command during image build.

```
RUN npm install
```

This layer installs dependencies.

---

#### **5. COPY . .**

Copies rest of the project code.

```
COPY . .
```

---

#### **6. EXPOSE**

Documentation that container runs on port 3000.

```
EXPOSE 3000
```

---

#### **7. CMD**

Defines the command to start the container.

```
CMD ["npm", "start"]
```

CMD runs once when container starts.

---

### **Dockerfile Best Practices**

* Use lightweight base images (`alpine`)
* Put `RUN apt-get update && apt-get install ...` in one line to reduce layers
* Use `.dockerignore` to exclude node_modules, logs, temp files

---

<br>

# **5. Key Docker Commands (With Examples)**

### **Container Commands**

| Command                          | Description                      | Example            |
| -------------------------------- | -------------------------------- | ------------------ |
| `docker run`                     | Run a container                  | `docker run nginx` |
| `docker run -d -p 8080:80 nginx` | Run in background + port mapping |                    |
| `docker ps`                      | List running containers          |                    |
| `docker ps -a`                   | All containers                   |                    |
| `docker stop <id>`               | Stop container                   |                    |
| `docker rm <id>`                 | Remove container                 |                    |
| `docker logs -f <id>`            | Follow logs                      |                    |

---

### **Image Commands**

| Command                    | Description    |
| -------------------------- | -------------- |
| `docker build -t app:v1 .` | Build image    |
| `docker images`            | List images    |
| `docker rmi <image>`       | Remove image   |
| `docker pull nginx`        | Download image |

---

### **Volume Commands**

| Command                        | Description   |
| ------------------------------ | ------------- |
| `docker volume create data`    | Create volume |
| `docker run -v data:/app/data` | Mount volume  |
| `docker volume ls`             | List volumes  |

---

### **Network Commands**

| Command                         | Description      |
| ------------------------------- | ---------------- |
| `docker network create backend` | Create network   |
| `docker run --network backend`  | Attach container |

---

Here is **only the content you asked for** — the **five types of Docker networking**, each explained with a **small clear paragraph + a practical example**.
You can directly paste this into your README.md.

---
# Docker Networking
![Alt Text](https://miro.medium.com/v2/resize:fit:1100/format:webp/1*MxxCmxxE1bc1BOXaOAKm-w.jpeg)
## **Docker Networking Types (With Examples)**

## **1. Bridge Network (Default)**

The **bridge network** is Docker’s default networking mode. Containers connected to a bridge network can communicate with each other using their container names, while also staying isolated from containers on other networks. This mode is ideal for running multi-container applications on a single host during development.

**Example:**

```bash
docker network create mybridge
docker run -d --name app1 --network mybridge nginx
docker run -d --name app2 --network mybridge nginx
```

Here, `app1` can reach `app2` using:

```
http://app2
```

---

## **2. Host Network**

In host mode, Docker **removes the network isolation** and the container directly uses the host’s networking stack. This means the container will share the host’s IP address, and any ports used inside the container are directly accessible from the host without port mapping. It's useful for high-performance networking or running system-level applications.

**Example:**

```bash
docker run --network host nginx
```

Nginx will be available directly on host’s port 80 — **without writing `-p 80:80`**.

---

## **3. None Network**

The `none` network gives a container **no external networking** at all. The container has its own network namespace but no interfaces except the loopback interface (`lo`). This is useful for security-sensitive workloads, testing isolated environments, or running containers that don’t need any network.

**Example:**

```bash
docker run -it --network none ubuntu
```

Inside the container:

```
ping google.com → will not work
```

---

## **4. Overlay Network**

The **overlay network** is used in distributed environments (Docker Swarm or multi-host setups). It allows containers running on different physical or virtual machines to communicate with each other securely. Docker handles all routing, encryption, and node-to-node communication automatically.

**Example (Swarm Mode):**

```bash
docker swarm init
docker network create -d overlay myoverlay
docker service create --name web --network myoverlay nginx
docker service create --name api --network myoverlay node:18
```

Here, the `web` service can reach the `api` service using:

```
http://api
```

even if they are on **different machines**.

---

## **5. Custom Bridge Network**

A **custom bridge network** is similar to the default bridge network but gives more control, allowing you to define DNS resolution, IP ranges, and communication rules. Containers on the same custom network can resolve each other by name, making it perfect for microservices.

**Example:**

```bash
docker network create appnet
docker run -d --name backend --network appnet node:18
docker run -d --name database --network appnet mongo
```

Inside backend container, you can connect to MongoDB using:

```
mongodb://database:27017
```

---

# **7. Docker Volumes & Persistence**

Containers are ephemeral — when they die, data is lost.
So Docker provides **persistent storage**.

---

## **Types of Storage**

### **A. Volume (Recommended)**

Managed by Docker.

```
docker volume create data
docker run -v data:/var/lib/mysql mysql
```

**Use cases:**

* Databases
* User uploads
* Long-term storage

---

### **B. Bind Mounts**

Maps a host folder into container.

```
docker run -v /home/user/app:/app
```

**Use cases:**

* Local development
* Editing code from host

---

### **C. tmpfs Mounts**

Stored in RAM only.

```
docker run --tmpfs /app/cache
```

---

## **Why Volumes Are Best**

* Portable
* Backup friendly
* Not tied to host file structure
* Optimized by Docker Engine

---

<br>

# **8. Docker Compose – Multi-Container Management**

Docker Compose allows you to run multi-container applications using a simple file: `docker-compose.yml`.

---

### **Example: Node.js + MongoDB**

```yaml
version: "3.9"
services:
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - mongo
    networks:
      - appnet

  mongo:
    image: mongo:latest
    volumes:
      - mongodata:/data/db
    networks:
      - appnet

volumes:
  mongodata:

networks:
  appnet:
```

---

### **Commands**

| Command                | Description                  |
| ---------------------- | ---------------------------- |
| `docker compose up`    | Start all services           |
| `docker compose up -d` | Start in background          |
| `docker compose down`  | Stop & remove all containers |
| `docker compose build` | Build images                 |

---

### **Benefits of Compose**

* One file = entire application stack
* Automatic network creation
* Easy scaling (`docker compose up --scale app=3`)
* Good for microservices + development environments

---

