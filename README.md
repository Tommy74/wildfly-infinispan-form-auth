# Using Form Authentication with WildFly and Infinispan

This project sets up a **2-node WildFly/JBoss EAP cluster** with a **2-node Infinispan/Data Grid cluster** as an external session store, using **Form-based authentication** and **Single Sign-On (SSO)** without TLS.

WildFly connects to Infinispan via the HotRod protocol and caches SSO data into Infinispan (WildFly configures `single-sign-on-management` using `hotrod-single-sign-on-management` to store SSO data into a `remote-cache-container` backed by Infinispan).

## Architecture

| Component      | Instance | HTTP/HotRod Port | Port Offset |
|----------------|----------|-------------------|-------------|
| Infinispan 1   | jdg1     | 11222             | 0           |
| Infinispan 2   | jdg2     | 11322             | 100         |
| WildFly 1      | wildfly1 | 8180              | 100         |
| WildFly 2      | wildfly2 | 8480              | 400         |

## Prerequisites

- Java 17+ (Java 25+ when using `infinispan-server-16.1.3`)
- Maven
- WildFly zip (e.g. `wildfly-40.0.0.Beta1-*.zip`) in `$HOME/Downloads/`
- Infinispan Server zip (e.g. `infinispan-server-16.1.3.zip`) in `$HOME/Downloads/`

## Setup

### Step 1: Configure Infinispan

This unzips the Infinispan server twice (one per node) and creates an `admin` user on each:

```bash
./configure-infinispan-16.1.3.sh
```

### Step 2: Configure WildFly

This unzips WildFly twice, generates and runs JBoss CLI scripts to configure JGroups (TCP stack), Infinispan remote-cache-containers, Elytron security (form authentication with user `ssoUser`/`ssoPassw`), Undertow SSO, and deploys the `form-auth-webapp`:

```bash
./configure-wildfly-40.0.0.sh
```

### Step 3: Start Infinispan nodes

Start the two Infinispan nodes in separate terminals:

```bash
# Node 1
$HOME/Documents/CLUSTERING/BUG-JDG-SSO/SSO-BASIC/infinispan-server-16.1.3-1/bin/server.sh \
  --bind-address=127.0.0.1 \
  --cluster-address=127.0.0.1 \
  --server-config=infinispan.xml \
  --cluster-stack=tcp \
  --cluster-name=cluster_234.99.54.24 \
  --node-name=jdg1

# Node 2
$HOME/Documents/CLUSTERING/BUG-JDG-SSO/SSO-BASIC/infinispan-server-16.1.3-2/bin/server.sh \
  --port-offset=100 \
  --bind-address=127.0.0.1 \
  --cluster-address=127.0.0.1 \
  --server-config=infinispan.xml \
  --cluster-stack=tcp \
  --cluster-name=cluster_234.99.54.24 \
  --node-name=jdg2
```

### Step 4: Start WildFly nodes

Start the two WildFly nodes in separate terminals:

```bash
# Node 1 (HTTP on port 8180)
$HOME/Documents/CLUSTERING/BUG-JDG-SSO/SSO-BASIC/wildfly-40.0.0-1/bin/standalone.sh \
  --server-config=standalone-ha.xml \
  -Djboss.default.multicast.address=230.0.0.190 \
  -Djboss.node.name=wildfly1 \
  -Djboss.socket.binding.port-offset=100

# Node 2 (HTTP on port 8480)
$HOME/Documents/CLUSTERING/BUG-JDG-SSO/SSO-BASIC/wildfly-40.0.0-2/bin/standalone.sh \
  --server-config=standalone-ha.xml \
  -Djboss.default.multicast.address=230.0.0.190 \
  -Djboss.node.name=wildfly2 \
  -Djboss.socket.binding.port-offset=400
```

### Step 5: Test

Open either URL in a browser:

- http://localhost:8180/form-auth-webapp/session
- http://localhost:8480/form-auth-webapp/session

Login with:
- **Username:** `ssoUser`
- **Password:** `ssoPassw`

SSO is enabled, so logging in on one node should grant access on the other without re-authenticating. Session data is stored in Infinispan, so it survives individual WildFly node restarts.
