#基础配置
NAT
192.168.0.200	master0
192.168.0.201	master1
192.168.0.202	master2

LAN
192.168.0.200	master0
192.168.0.201	master1
192.168.0.202	master2


#基础优化配置三台环境
echo 'net.ipv4.ip_forward=1 ' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_tw_recycle=1 ' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse=1 ' >>/etc/sysctl.conf
sysctl -p
chmod +x /etc/rc.d/rc.local
yum install -y mlocate lrzsz tree vim nc nmap wget bash-completion bash-completion-extras htop iotop iftop lsof net-tools sysstat unzip bc psmisc ntpdate wc telnet-server bind-utils sshpass

#配置yum源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

#在master节点上分发ssh秘钥
cat fenfa_pub.sh
#!/bin/bash
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''
for ip in 200 202
do
 sshpass -p123456 ssh-copy-id -o StrictHostKeyChecking=no 192.168.0.$ip
done

sh fenfa_pub.sh

#在master节点上为其他node节点分发hosts文件
cat /etc/hosts
192.168.0.200	master0
192.168.0.201	master1
192.168.0.202	master2

for ip in 200 202 ;do scp -rp /etc/hosts 192.168.0.$ip:/etc/hosts ;done



#ansible命令部署多台docker环境(需要配置ssh免秘钥)
yum install ansible -y
#2. 添加hosts文件列表(所有节点的IP地址)
vim /etc/ansible/hosts
[master]
192.168.0.200
[node]
192.168.0.201
192.168.0.202
# 3. 测试连通性
ansible all -a 'hostname'
192.168.0.200 | CHANGED | rc=0 >>
master0
192.168.0.201 | CHANGED | rc=0 >>
master1
192.168.0.202 | CHANGED | rc=0 >>
master2
#3.卸载旧版本(没有写playbook文件)
ansible all -m yum -a 'name=docker,docker-client,docker-client-latest.docker-common,docker-latest,docker-latest-logrotate,docker-logrotate,docker-engine state=absent'

# 4. 安装yum-utils
ansible all -m yum -a 'name=yum-utils state=installed'
# 5. 设置国内镜像仓库
ansible all -m shell -a 'yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo'
# 6. 更新yum
ansible all -m shell -a 'yum makecache fast'
# 7. 安装docker相关的依赖
ansible all -m yum -a 'name=docker-ce,docker-ce-cli,containerd.io state=installed'
# 8. 启动docker
ansible all -m service -a 'name=docker state=started enabled=yes'

#高可用rancher
#rke二进制文件下载：
https://github.com/rancher/rke/releases/download/v1.3.4/rke_linux-amd64
#加速站点1：
https://ghproxy.com/
https://mirror.ghproxy.com/
#加速站点2：
https://shrill-pond-3e81.hunsh.workers.dev/
https://gh.api.99988866.xyz/

mv rke_linux-amd64  /usr/local/bin/rke

#编写cluster.yml ，启动k8s集群
nodes:
  - address: 192.168.0.200
    user: rancher
    role:
      - controlplane
      - etcd
      port: 2222
      docker_socket: /var/run/docker.sock
    - address: 192.168.0.201
      user: rancher
      role:
        - worker
      ssh_key_path: /home/rancher/.ssh/id_rsa
    - address: 192.168.0.202
      user: rancher
      role:
        - worker
      internal_address:
      labels:
        app: ingress
# If set to true, RKE will not fail when unsupported Docker version
# are found
ignore_docker_version: false

# Enable running cri-dockerd
# Up to Kubernetes 1.23, kubelet contained code called dockershim
# to support Docker runtime. The replacement is called cri-dockerd
# and should be enabled if you want to keep using Docker as your
# container runtime
# Only available to enable in Kubernetes 1.21 and higher
enable_cri_dockerd: true

# Cluster level SSH private key
# Used if no ssh information is set for the node
ssh_key_path: ~/.ssh/id_rsa
# Enable use of SSH agent to use SSH private keys with passphrase
# This requires the environment `SSH_AUTH_SOCK` configured pointing
#to your SSH agent which has the private key added
ssh_agent_auth: true
# List of registry credentials
# If you are using a Docker Hub registry, you can omit the `url`
# or set it to `docker.io`
# is_default set to `true` will override the system default
# registry set in the global settings
private_registries:
     - url: registry.cloud.com
       is_default: true
# Bastion/Jump host configuration
bastion_host:
    address: 192.168.0.200
    user: rancher
    port: 22
    ssh_key_path: /home/user/.ssh/bastion_rsa
# or
#   ssh_key: |-
#     -----BEGIN RSA PRIVATE KEY-----
#
#     -----END RSA PRIVATE KEY-----
# Set the name of the Kubernetes cluster
cluster_name: cluster
# The Kubernetes version used. The default versions of Kubernetes
# are tied to specific versions of the system images.
#
# For RKE v0.2.x and below, the map of Kubernetes versions and their system images is
# located here:
# https://github.com/rancher/types/blob/release/v2.2/apis/management.cattle.io/v3/k8s_defaults.go
#
# For RKE v0.3.0 and above, the map of Kubernetes versions and their system images is
# located here:
# https://github.com/rancher/kontainer-driver-metadata/blob/master/rke/k8s_rke_system_images.go
#
# In case the kubernetes_version and kubernetes image in
# system_images are defined, the system_images configuration
# will take precedence over kubernetes_version.
kubernetes_version: v1.10.3-rancher2
# System Images are defaulted to a tag that is mapped to a specific
# Kubernetes Version and not required in a cluster.yml.
# Each individual system image can be specified if you want to use a different tag.
#
# For RKE v0.2.x and below, the map of Kubernetes versions and their system images is
# located here:
# https://github.com/rancher/types/blob/release/v2.2/apis/management.cattle.io/v3/k8s_defaults.go
#
# For RKE v0.3.0 and above, the map of Kubernetes versions and their system images is
# located here:
# https://github.com/rancher/kontainer-driver-metadata/blob/master/rke/k8s_rke_system_images.go
#
system_images:
    kubernetes: rancher/hyperkube:v1.10.3-rancher2
    etcd: rancher/coreos-etcd:v3.1.12
    alpine: rancher/rke-tools:v0.1.9
    nginx_proxy: rancher/rke-tools:v0.1.9
    cert_downloader: rancher/rke-tools:v0.1.9
    kubernetes_services_sidecar: rancher/rke-tools:v0.1.9
    kubedns: rancher/k8s-dns-kube-dns-amd64:1.14.8
    dnsmasq: rancher/k8s-dns-dnsmasq-nanny-amd64:1.14.8
    kubedns_sidecar: rancher/k8s-dns-sidecar-amd64:1.14.8
    kubedns_autoscaler: rancher/cluster-proportional-autoscaler-amd64:1.0.0
    pod_infra_container: rancher/pause-amd64:3.1
services:
    etcd:
      # Custom uid/guid for etcd directory and files
      uid: 52034
      gid: 52034
      # if external etcd is used
      # path: /etcdcluster
      # external_urls:
      #   - https://etcd-example.com:2379
      # ca_cert: |-
      #   -----BEGIN CERTIFICATE-----
      #   xxxxxxxxxx
      #   -----END CERTIFICATE-----
      # cert: |-
      #   -----BEGIN CERTIFICATE-----
      #   xxxxxxxxxx
      #   -----END CERTIFICATE-----
      # key: |-
      #   -----BEGIN PRIVATE KEY-----
      #   xxxxxxxxxx
      #   -----END PRIVATE KEY-----
    # Note for Rancher v2.0.5 and v2.0.6 users: If you are configuring
    # Cluster Options using a Config File when creating Rancher Launched
    # Kubernetes, the names of services should contain underscores
    # only: `kube_api`.
    kube-api:
      # IP range for any services created on Kubernetes
      # This must match the service_cluster_ip_range in kube-controller
      service_cluster_ip_range: 10.43.0.0/16
      # Expose a different port range for NodePort services
      service_node_port_range: 30000-32767
      pod_security_policy: false
      # Encrypt secret data at Rest
      # Available as of v0.3.1
      secrets_encryption_config:
        enabled: true
        custom_config:
          apiVersion: apiserver.config.k8s.io/v1
          kind: EncryptionConfiguration
          resources:
          - resources:
            - secrets
            providers:
            - aescbc:
                keys:
                - name: k-fw5hn
                  secret: RTczRjFDODMwQzAyMDVBREU4NDJBMUZFNDhCNzM5N0I=
            - identity: {}
      # Enable audit logging
      # Available as of v1.0.0
      audit_log:
        enabled: true
        configuration:
          max_age: 6
          max_backup: 6
          max_size: 110
          path: /var/log/kube-audit/audit-log.json
          format: json
          policy:
            apiVersion: audit.k8s.io/v1 # This is required.
            kind: Policy
            omitStages:
              - "RequestReceived"
            rules:
              # Log pod changes at RequestResponse level
              - level: RequestResponse
                resources:
                - group: ""
                  # Resource "pods" doesn't match requests to any subresource of pods,
                  # which is consistent with the RBAC policy.
                  resources: ["pods"]
      # Using the EventRateLimit admission control enforces a limit on the number of events
      # that the API Server will accept in a given time period
      # Available as of v1.0.0
      event_rate_limit:
        enabled: true
        configuration:
          apiVersion: eventratelimit.admission.k8s.io/v1alpha1
          kind: Configuration
          limits:
          - type: Server
            qps: 6000
            burst: 30000
      # Enable AlwaysPullImages Admission controller plugin
      # Available as of v0.2.0
      always_pull_images: false
      # Add additional arguments to the kubernetes API server
      # This WILL OVERRIDE any existing defaults
      extra_args:
        # Enable audit log to stdout
        audit-log-path: "-"
        # Increase number of delete workers
        delete-collection-workers: 3
        # Set the level of log output to debug-level
        v: 4
    # Note for Rancher 2 users: If you are configuring Cluster Options
    # using a Config File when creating Rancher Launched Kubernetes,
    # the names of services should contain underscores only:
    # `kube_controller`. This only applies to Rancher v2.0.5 and v2.0.6.
    kube-controller:
      # CIDR pool used to assign IP addresses to pods in the cluster
      cluster_cidr: 10.42.0.0/16
      # IP range for any services created on Kubernetes
      # This must match the service_cluster_ip_range in kube-api
      service_cluster_ip_range: 10.43.0.0/16
      # Add additional arguments to the kubernetes API server
      # This WILL OVERRIDE any existing defaults
      extra_args:
        # Set the level of log output to debug-level
        v: 4
        # Enable RotateKubeletServerCertificate feature gate
        feature-gates: RotateKubeletServerCertificate=true
        # Enable TLS Certificates management
        # https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
        cluster-signing-cert-file: "/etc/kubernetes/ssl/kube-ca.pem"
        cluster-signing-key-file: "/etc/kubernetes/ssl/kube-ca-key.pem"
    kubelet:
      # Base domain for the cluster
      cluster_domain: cluster.local
      # IP address for the DNS service endpoint
      cluster_dns_server: 10.43.0.10
    # Fail if swap is on
    fail_swap_on: false
    # Configure pod-infra-container-image argument
      pod-infra-container-image: "k8s.gcr.io/pause:3.2"
      # Generate a certificate signed by the kube-ca Certificate Authority
      # for the kubelet to use as a server certificate
      # Available as of v1.0.0
      generate_serving_certificate: true
      extra_args:
        # Set max pods to 250 instead of default 110
        max-pods: 250
        # Enable RotateKubeletServerCertificate feature gate
        feature-gates: RotateKubeletServerCertificate=true
      # Optionally define additional volume binds to a service
      extra_binds:
        - "/usr/libexec/kubernetes/kubelet-plugins:/usr/libexec/kubernetes/kubelet-plugins"
    scheduler:
      extra_args:
        # Set the level of log output to debug-level
        v: 4
    kubeproxy:
      extra_args:
        # Set the level of log output to debug-level
        v: 4
# Currently, only authentication strategy supported is x509.
# You can optionally create additional SANs (hostnames or IPs) to
# add to the API server PKI certificate.
# This is useful if you want to use a load balancer for the
# control plane servers.
authentication:
  strategy: x509
  sans:
    - "10.18.160.10"
    - "my-loadbalancer-1234567890.us-west-2.elb.amazonaws.com"

# Kubernetes Authorization mode
# Use `mode: rbac` to enable RBAC
# Use `mode: none` to disable authorization
authorization:
  mode: rbac

# If you want to set a Kubernetes cloud provider, you specify
# the name and configuration
cloud_provider:
  name: aws

# Add-ons are deployed using kubernetes jobs. RKE will give
# up on trying to get the job status after this timeout in seconds..
addon_job_timeout: 30

# Specify network plugin-in (canal, calico, flannel, weave, or none)
network:
  plugin: canal
  # Specify MTU
  mtu: 1400
  options:
    # Configure interface to use for Canal
    canal_iface: eth1
    canal_flannel_backend_type: vxlan
    # Available as of v1.2.6
    canal_autoscaler_priority_class_name: system-cluster-critical
    canal_priority_class_name: system-cluster-critical
  # Available as of v1.2.4
  tolerations:
  - key: "node.kubernetes.io/unreachable"
    operator: "Exists"
    effect: "NoExecute"
    tolerationseconds: 300
  - key: "node.kubernetes.io/not-ready"
    operator: "Exists"
    effect: "NoExecute"
    tolerationseconds: 300
  # Available as of v1.1.0
  update_strategy:
    strategy: RollingUpdate
    rollingUpdate:
      maxUnavailable: 6

# Specify DNS provider (coredns or kube-dns)
dns:
  provider: coredns
  # Available as of v1.1.0
  update_strategy:
    strategy: RollingUpdate
    rollingUpdate:
      maxUnavailable: 20%
      maxSurge: 15%
  linear_autoscaler_params:
    cores_per_replica: 0.34
    nodes_per_replica: 4
    prevent_single_point_failure: true
    min: 2
    max: 3
# Specify monitoring provider (metrics-server)
monitoring:
  provider: metrics-server
  # Available as of v1.1.0
  update_strategy:
    strategy: RollingUpdate
    rollingUpdate:
      maxUnavailable: 8
# Currently only nginx ingress provider is supported.
# To disable ingress controller, set `provider: none`
# `node_selector` controls ingress placement and is optional
ingress:
  provider: nginx
  node_selector:
    app: ingress
  # Available as of v1.1.0
  update_strategy:
    strategy: RollingUpdate
    rollingUpdate:
      maxUnavailable: 5
# All add-on manifests MUST specify a namespace
addons: |-
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: my-nginx
    namespace: default
  spec:
    containers:
    - name: my-nginx
      image: nginx
      ports:
      - containerPort: 80

addons_include:
  - https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-operator.yaml
  - https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-cluster.yaml
  - /path/to/manifest
