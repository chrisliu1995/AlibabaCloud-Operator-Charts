# AlibabaCloud Operators Helm Chart

这个 Helm Chart 用于在 Kubernetes 集群中一键安装 AlibabaCloud NLB Operator、EIP Operator 和 NLB Pool Operator。

## 功能特性

- 🎯 **组件可选安装**：可以选择性安装 NLB Operator、EIP Operator 和 NLB Pool Operator
- 🔄 **参数复用**：通用配置参数在多个组件间复用
- 🔐 **安全凭证管理**：统一管理 AlibabaCloud 认证信息
- ⚙️ **灵活配置**：支持自定义资源限制、副本数、环境变量等
- 📦 **生产就绪**：包含健康检查、RBAC、安全上下文等最佳实践

## 组件说明

### NLB Operator
负责管理阿里云网络负载均衡器（NLB）资源 CRD（NLB / ServerGroup / Listener），将 K8s 自定义资源同步到阿里云。

### EIP Operator
负责管理阿里云弹性公网 IP（EIP）资源 CRD，自动为 K8s 资源分配和管理公网 IP。

### NLB Pool Operator
基于上述两者之上，提供 NLB 资源池能力（NLBPool / PortAllocation CRD），支持端口预分配、Pod 绑定、网络隔离、批量回收等高阶场景。

> **NLB Pool Operator 强依赖 NLB Operator**（创建 NLB CR），并推荐与 EIP Operator 同时启用。如果用户单独启用 `components.nlbPool.enabled=true` 但禁用 NLB Operator，Chart 不会校验，但运行时会失败。

## 前置要求

- Kubernetes 1.19+
- Helm 3.0+
- 阿里云 AccessKey ID 和 Secret

## 组件版本

| 组件 | 镜像 | 版本 |
|------|------|------|
| NLB Operator | `registry.cn-hangzhou.aliyuncs.com/chrisliu/nlb-operator` | `v0.2.0` |
| EIP Operator | `registry.cn-hangzhou.aliyuncs.com/chrisliu/eip-operator` | `v0.3.0` |
| NLB Pool Operator | `registry.cn-hangzhou.aliyuncs.com/chrisliu/nlb-pool-operator` | `v0.1.1` |

镜像仓库为公开匿名拉取，无需 imagePullSecret。

## 安装方法

### 1. 安装所有组件

```bash
# 创建自定义 values 文件
cat > my-values.yaml <<EOF
global:
  alibabacloud:
    accessKeyId: "your-access-key-id"
    accessKeySecret: "your-access-key-secret"
    region: "cn-hangzhou"
EOF

# 安装 chart
helm install alibabacloud-operators . -f my-values.yaml
```

### 2. 仅安装 NLB Operator

```bash
helm install alibabacloud-operators . -f values-nlb-only.yaml
```

### 3. 仅安装 EIP Operator

```bash
helm install alibabacloud-operators . -f values-eip-only.yaml
```

### 4. 自定义安装

```bash
helm install alibabacloud-operators . \
  --set global.alibabacloud.accessKeyId=YOUR_KEY_ID \
  --set global.alibabacloud.accessKeySecret=YOUR_KEY_SECRET \
  --set global.alibabacloud.region=cn-hangzhou \
  --set components.nlb.enabled=true \
  --set components.eip.enabled=true
```

## 配置参数

### 全局配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `global.alibabacloud.accessKeyId` | 阿里云 AccessKey ID | `""` |
| `global.alibabacloud.accessKeySecret` | 阿里云 AccessKey Secret | `""` |
| `global.alibabacloud.region` | 阿里云地域 | `"cn-hangzhou"` |
| `global.imageRegistry` | 镜像仓库地址 | `"registry.cn-hangzhou.aliyuncs.com"` |
| `global.namespace` | 安装的命名空间 | `"kube-system"` |
| `global.imagePullSecrets` | 镜像拉取密钥 | `[]` |

### 组件启用控制

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `components.nlb.enabled` | 是否启用 NLB Operator | `true` |
| `components.eip.enabled` | 是否启用 EIP Operator | `true` |

### NLB Operator 配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `nlbOperator.replicaCount` | 副本数 | `1` |
| `nlbOperator.image.repository` | 镜像仓库 | `chrisliu1995/alibabacloud-nlb-operator` |
| `nlbOperator.image.tag` | 镜像标签 | `"v0.1.0"` |
| `nlbOperator.image.pullPolicy` | 镜像拉取策略 | `IfNotPresent` |
| `nlbOperator.resources.limits.cpu` | CPU 限制 | `500m` |
| `nlbOperator.resources.limits.memory` | 内存限制 | `512Mi` |
| `nlbOperator.resources.requests.cpu` | CPU 请求 | `100m` |
| `nlbOperator.resources.requests.memory` | 内存请求 | `128Mi` |
| `nlbOperator.serviceAccount.create` | 是否创建 ServiceAccount | `true` |
| `nlbOperator.serviceAccount.name` | ServiceAccount 名称 | `"nlb-operator"` |
| `nlbOperator.rbac.create` | 是否创建 RBAC 资源 | `true` |
| `nlbOperator.webhook.enabled` | 是否启用 Webhook | `true` |
| `nlbOperator.webhook.port` | Webhook 端口 | `9443` |

### EIP Operator 配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `eipOperator.replicaCount` | 副本数 | `1` |
| `eipOperator.image.repository` | 镜像仓库 | `chrisliu1995/alibabacloud-eip-operator` |
| `eipOperator.image.tag` | 镜像标签 | `"v0.2.0"` |
| `eipOperator.image.pullPolicy` | 镜像拉取策略 | `IfNotPresent` |
| `eipOperator.resources.limits.cpu` | CPU 限制 | `500m` |
| `eipOperator.resources.limits.memory` | 内存限制 | `512Mi` |
| `eipOperator.resources.requests.cpu` | CPU 请求 | `100m` |
| `eipOperator.resources.requests.memory` | 内存请求 | `128Mi` |
| `eipOperator.serviceAccount.create` | 是否创建 ServiceAccount | `true` |
| `eipOperator.serviceAccount.name` | ServiceAccount 名称 | `"eip-operator"` |
| `eipOperator.rbac.create` | 是否创建 RBAC 资源 | `true` |
| `eipOperator.webhook.enabled` | 是否启用 Webhook | `true` |
| `eipOperator.webhook.port` | Webhook 端口 | `9443` |

## 使用示例

### 检查部署状态

```bash
# 查看所有部署
kubectl get deployment -n kube-system | grep operator

# 查看 NLB Operator 日志
kubectl logs -l app.kubernetes.io/name=nlb-operator -n kube-system

# 查看 EIP Operator 日志
kubectl logs -l app.kubernetes.io/name=eip-operator -n kube-system
```

### 升级配置

```bash
# 修改 values.yaml 后升级
helm upgrade alibabacloud-operators . -f my-values.yaml

# 动态调整副本数
helm upgrade alibabacloud-operators . \
  --set nlbOperator.replicaCount=3 \
  --reuse-values
```

### 卸载

```bash
helm uninstall alibabacloud-operators
```

## 高级配置

### 使用私有镜像仓库

```yaml
global:
  imageRegistry: "your-registry.com"
  imagePullSecrets:
    - name: your-registry-secret

nlbOperator:
  image:
    repository: your-namespace/nlb-operator
    tag: "v1.0.0"

eipOperator:
  image:
    repository: your-namespace/eip-operator
    tag: "v1.0.0"
```

### 节点选择和容忍度

```yaml
nlbOperator:
  nodeSelector:
    kubernetes.io/os: linux
  tolerations:
    - key: "node-role.kubernetes.io/master"
      operator: "Exists"
      effect: "NoSchedule"
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app.kubernetes.io/name: nlb-operator
            topologyKey: kubernetes.io/hostname
```

### 自定义环境变量

```yaml
nlbOperator:
  env:
    - name: LOG_LEVEL
      value: "debug"
    - name: SYNC_PERIOD
      value: "30s"
  extraArgs:
    - --metrics-bind-address=:8080
    - --health-probe-bind-address=:8081
```

## 故障排查

### Operator 无法启动

1. 检查 AccessKey 是否正确：
```bash
kubectl get secret nlb-operator-credentials -n kube-system -o yaml
```

2. 查看 Pod 日志：
```bash
kubectl logs -l app.kubernetes.io/name=nlb-operator -n kube-system --tail=100
```

3. 检查 RBAC 权限：
```bash
kubectl get clusterrole nlb-operator-role
kubectl get clusterrolebinding nlb-operator-rolebinding
```

### 查看 Helm Release 信息

```bash
# 查看已安装的 release
helm list

# 查看 release 详细信息
helm get all alibabacloud-operators

# 查看 values
helm get values alibabacloud-operators
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目使用 Apache 2.0 许可证。

## 相关链接

- [AlibabaCloud NLB Operator](https://github.com/chrisliu1995/AlibabaCloud-NLB-Operator)
- [AlibabaCloud EIP Operator](https://github.com/chrisliu1995/AlibabaCloud-EIP-Operator)
- [阿里云 NLB 文档](https://www.alibabacloud.com/help/zh/slb/)
- [阿里云 EIP 文档](https://www.alibabacloud.com/help/zh/eip/)
