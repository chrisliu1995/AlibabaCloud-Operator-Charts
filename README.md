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

## 获取 AccessKey

> ⚠️ **重要**：本 Chart 需要**明文** AK/SK 注入到 Secret 中。Chart 已内置校验，发现掩码值或格式错误时 `helm install` 会立即失败并给出修复提示。

### 推荐获取方式

**方式 1：从阿里云 RAM 控制台获取**

登录 [阿里云 RAM 控制台](https://ram.console.aliyun.com/manage/ak) → 选择子账号 → 创建 AccessKey → 复制弹窗中的明文 AK / SK（**只在创建时显示一次**）。

**方式 2：从本地 aliyun CLI 配置文件读取**

如果你已经配置过 `aliyun configure`，明文 AK/SK 存储在 `~/.aliyun/config.json` 中。可用 `jq` 提取：

```bash
# 假设 profile 名为 default
AK=$(jq -r '.profiles[] | select(.name=="default") | .access_key_id' ~/.aliyun/config.json)
SK=$(jq -r '.profiles[] | select(.name=="default") | .access_key_secret' ~/.aliyun/config.json)
```

### ❌ 不要使用的方式

```bash
# 错误！aliyun CLI 出于安全考虑会返回 "access-key-id=*****Vq8" 这种带前缀且掩码的字符串
AK=$(aliyun configure get access-key-id)
```

如果不慎使用了上述方式，`helm install` 时 Chart 会返回类似下面的错误并拒绝安装：

```
ERROR: accessKeyId looks masked (contains '***').
You likely used the output of `aliyun configure get access-key-id`, which is masked for security.
The correct way to obtain the plaintext AK:
  - Read directly from ~/.aliyun/config.json (jq '.profiles[].access_key_id')
  - Or copy from the Alibaba Cloud RAM console where the AccessKey was created.
```

### 所需权限

子账号 RAM Policy 至少需要包含以下权限（建议授予 `AliyunNLBFullAccess` + `AliyunEIPFullAccess` + `AliyunVPCFullAccess`）：

- NLB：`AliyunNLBFullAccess` 或等效权限（创建/删除 NLB、ServerGroup、Listener，AddServers / RemoveServers 等）
- EIP：`AliyunEIPFullAccess`（分配/释放 EIP，关联/解关联）
- VPC：读权限（查询 VPC / VSwitch）

## 组件版本

| 组件 | 镜像 | 版本 |
|------|------|------|
| NLB Operator | `registry.cn-hangzhou.aliyuncs.com/chrisliu/nlb-operator` | `v0.2.0` |
| EIP Operator | `registry.cn-hangzhou.aliyuncs.com/chrisliu/eip-operator` | `v0.3.0` |
| NLB Pool Operator | `registry.cn-hangzhou.aliyuncs.com/chrisliu/nlb-pool-operator` | `v0.1.1` |

镜像仓库为公开匿名拉取，无需 imagePullSecret。

## CRD 管理

本 Chart 的 6 个 CRD（NLB / ServerGroup / Listener / EIP / NLBPool / PortAllocation）放在 `crds/` 目录，遵循 Helm 官方推荐的 [CRD 管理实践](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/)：

- ✅ **首次安装**：`helm install` 时 Helm 会自动安装 CRD，无需额外操作
- ⚠️ **升级 CRD schema**：`helm upgrade` **不会**自动更新 CRD（防止 schema 变更破坏现有 CR）。如需升级 CRD，请先手工 apply：
  ```bash
  kubectl apply -f crds/
  helm upgrade alibabacloud-operators . -f my-values.yaml
  ```
- 🔒 **卸载保护**：`helm uninstall` **不会**删除 CRD 及其下的 CR 数据，避免误操作丢数据。如需彻底清理：
  ```bash
  helm uninstall alibabacloud-operators
  kubectl delete -f crds/   # 谨慎！会同时删除所有 NLBPool / NLB / EIP 等业务 CR
  ```

## 安装方法

> 安装前请先阅读 [获取 AccessKey](#获取-accesskey) 章节，确保使用**明文** AK/SK。

### 1. 安装所有组件

```bash
# 从 ~/.aliyun/config.json 提取明文 AK/SK（也可直接填写）
AK=$(jq -r '.profiles[] | select(.name=="default") | .access_key_id' ~/.aliyun/config.json)
SK=$(jq -r '.profiles[] | select(.name=="default") | .access_key_secret' ~/.aliyun/config.json)

helm install alibabacloud-operators . \
  --set global.alibabacloud.accessKeyId="$AK" \
  --set global.alibabacloud.accessKeySecret="$SK" \
  --set global.alibabacloud.region=cn-hangzhou
```

或写入 values 文件再 install：

```bash
cat > my-values.yaml <<EOF
global:
  alibabacloud:
    accessKeyId: "LTAI..."         # 必须明文，不可用 aliyun configure get 输出
    accessKeySecret: "..."
    region: "cn-hangzhou"
EOF

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
