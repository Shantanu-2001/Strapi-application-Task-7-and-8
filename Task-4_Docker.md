# **Docker Deep-Dive Documentation**

## **1. What Problem Does Docker Solve? (Why Docker Exists)**

Before Docker, developers relied largely on **Virtual Machines (VMs)** to isolate applications. But VMs are *heavy*, *slow*, and *resource-intensive*. Teams faced serious issues:

### **A. “Works on my machine” Problem**

Applications behaved differently on different systems because of:

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

<br>

# **6. Docker Networking**

Docker provides multiple network types:

---

## **A. Bridge Network (Default)**

Default when you run:

```
docker run nginx
```

* Containers can talk to each other using container names.
* Example:
  Backend calls DB using:

  ```
  http://mysql:3306
  ```

---

## **B. Host Network**

Container uses host’s network stack.

```
docker run --network host nginx
```

* No isolation
* High performance
* Port mapping not required

---

## **C. None Network**

Container has no network.

```
docker run --network none ubuntu
```

Useful for isolation or testing.

---

## **D. Overlay Network**

For **multi-node Docker Swarm / Kubernetes** clusters.

---

## **E. Custom Bridge Networks**

Recommended for microservices.

Example:

```
docker network create mynet
docker run --network mynet --name app1 nginx
docker run --network mynet --name app2 nginx
```

Both containers can resolve each other by name.

---

<br>

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

