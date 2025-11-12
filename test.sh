#!/bin/bash

# Helm Chart 测试脚本
# 用于验证 chart 配置和模板渲染

set -e

CHART_DIR="."
RELEASE_NAME="test-release"
NAMESPACE="kube-system"

echo "=========================================="
echo "  AlibabaCloud Operators Chart 测试脚本"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Helm 是否安装
if ! command -v helm &> /dev/null; then
    echo -e "${RED}错误: Helm 未安装${NC}"
    echo "请访问 https://helm.sh/docs/intro/install/ 安装 Helm"
    exit 1
fi

echo -e "${GREEN}✓ Helm 已安装 ($(helm version --short))${NC}"
echo ""

# 1. Lint 检查
echo "1. 执行 Helm Lint 检查..."
if helm lint $CHART_DIR; then
    echo -e "${GREEN}✓ Lint 检查通过${NC}"
else
    echo -e "${RED}✗ Lint 检查失败${NC}"
    exit 1
fi
echo ""

# 2. 测试模板渲染 - 安装所有组件
echo "2. 测试模板渲染 - 安装所有组件..."
helm template $RELEASE_NAME $CHART_DIR \
    --set global.alibabacloud.accessKeyId=test-key \
    --set global.alibabacloud.accessKeySecret=test-secret \
    > /tmp/all-components.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 所有组件模板渲染成功${NC}"
    echo "  生成的资源："
    grep -E "^kind:" /tmp/all-components.yaml | sort | uniq -c
else
    echo -e "${RED}✗ 模板渲染失败${NC}"
    exit 1
fi
echo ""

# 3. 测试仅启用 NLB Operator
echo "3. 测试模板渲染 - 仅启用 NLB Operator..."
helm template $RELEASE_NAME $CHART_DIR \
    --set global.alibabacloud.accessKeyId=test-key \
    --set global.alibabacloud.accessKeySecret=test-secret \
    --set components.nlb.enabled=true \
    --set components.eip.enabled=false \
    > /tmp/nlb-only.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ NLB Operator 模板渲染成功${NC}"
    echo "  生成的资源："
    grep -E "^kind:" /tmp/nlb-only.yaml | sort | uniq -c
    
    # 验证没有 EIP 资源
    if grep -q "eip-operator" /tmp/nlb-only.yaml; then
        echo -e "${RED}✗ 发现 EIP 资源（应该被禁用）${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ 确认没有 EIP 资源${NC}"
    fi
else
    echo -e "${RED}✗ 模板渲染失败${NC}"
    exit 1
fi
echo ""

# 4. 测试仅启用 EIP Operator
echo "4. 测试模板渲染 - 仅启用 EIP Operator..."
helm template $RELEASE_NAME $CHART_DIR \
    --set global.alibabacloud.accessKeyId=test-key \
    --set global.alibabacloud.accessKeySecret=test-secret \
    --set components.nlb.enabled=false \
    --set components.eip.enabled=true \
    > /tmp/eip-only.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ EIP Operator 模板渲染成功${NC}"
    echo "  生成的资源："
    grep -E "^kind:" /tmp/eip-only.yaml | sort | uniq -c
    
    # 验证没有 NLB 资源
    if grep -q "nlb-operator" /tmp/eip-only.yaml; then
        echo -e "${RED}✗ 发现 NLB 资源（应该被禁用）${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ 确认没有 NLB 资源${NC}"
    fi
else
    echo -e "${RED}✗ 模板渲染失败${NC}"
    exit 1
fi
echo ""

# 5. 测试使用预定义的 values 文件
echo "5. 测试使用预定义的 values 文件..."
if [ -f "values-nlb-only.yaml" ]; then
    helm template $RELEASE_NAME $CHART_DIR \
        -f values-nlb-only.yaml \
        --set global.alibabacloud.accessKeyId=test-key \
        --set global.alibabacloud.accessKeySecret=test-secret \
        > /tmp/values-nlb-only.yaml
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ values-nlb-only.yaml 渲染成功${NC}"
    else
        echo -e "${RED}✗ values-nlb-only.yaml 渲染失败${NC}"
        exit 1
    fi
fi

if [ -f "values-eip-only.yaml" ]; then
    helm template $RELEASE_NAME $CHART_DIR \
        -f values-eip-only.yaml \
        --set global.alibabacloud.accessKeyId=test-key \
        --set global.alibabacloud.accessKeySecret=test-secret \
        > /tmp/values-eip-only.yaml
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ values-eip-only.yaml 渲染成功${NC}"
    else
        echo -e "${RED}✗ values-eip-only.yaml 渲染失败${NC}"
        exit 1
    fi
fi
echo ""

# 6. 验证必需的文件存在
echo "6. 验证 Chart 文件结构..."
required_files=(
    "Chart.yaml"
    "values.yaml"
    "templates/_helpers.tpl"
    "templates/nlb-deployment.yaml"
    "templates/nlb-rbac.yaml"
    "templates/nlb-serviceaccount.yaml"
    "templates/nlb-secret.yaml"
    "templates/eip-deployment.yaml"
    "templates/eip-rbac.yaml"
    "templates/eip-serviceaccount.yaml"
    "templates/eip-secret.yaml"
    ".helmignore"
)

all_files_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file 不存在${NC}"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" = false ]; then
    exit 1
fi
echo ""

# 7. 验证 Chart.yaml 内容
echo "7. 验证 Chart.yaml 配置..."
if grep -q "apiVersion: v2" Chart.yaml && \
   grep -q "name: alibabacloud-operators" Chart.yaml && \
   grep -q "type: application" Chart.yaml; then
    echo -e "${GREEN}✓ Chart.yaml 配置正确${NC}"
else
    echo -e "${RED}✗ Chart.yaml 配置不完整${NC}"
    exit 1
fi
echo ""

# 8. 验证 RBAC 权限
echo "8. 验证 RBAC 配置..."
if grep -q "ClusterRole" templates/nlb-rbac.yaml && \
   grep -q "ClusterRoleBinding" templates/nlb-rbac.yaml; then
    echo -e "${GREEN}✓ NLB RBAC 配置正确${NC}"
else
    echo -e "${RED}✗ NLB RBAC 配置不完整${NC}"
    exit 1
fi

if grep -q "ClusterRole" templates/eip-rbac.yaml && \
   grep -q "ClusterRoleBinding" templates/eip-rbac.yaml; then
    echo -e "${GREEN}✓ EIP RBAC 配置正确${NC}"
else
    echo -e "${RED}✗ EIP RBAC 配置不完整${NC}"
    exit 1
fi
echo ""

# 9. 检查模板语法
echo "9. 检查模板语法..."
template_errors=0
for template in templates/*.yaml; do
    if [ -f "$template" ]; then
        # 简单的语法检查
        if grep -q "{{" "$template"; then
            if ! grep -q "}}" "$template"; then
                echo -e "${RED}✗ $template 可能有未关闭的模板标签${NC}"
                template_errors=$((template_errors + 1))
            fi
        fi
    fi
done

if [ $template_errors -eq 0 ]; then
    echo -e "${GREEN}✓ 模板语法检查通过${NC}"
else
    echo -e "${RED}✗ 发现 $template_errors 个模板错误${NC}"
    exit 1
fi
echo ""

# 10. 打包测试
echo "10. 测试 Chart 打包..."
if helm package $CHART_DIR -d /tmp; then
    echo -e "${GREEN}✓ Chart 打包成功${NC}"
    ls -lh /tmp/alibabacloud-operators-*.tgz
else
    echo -e "${RED}✗ Chart 打包失败${NC}"
    exit 1
fi
echo ""

# 总结
echo "=========================================="
echo -e "${GREEN}✓ 所有测试通过！${NC}"
echo "=========================================="
echo ""
echo "生成的测试文件："
echo "  /tmp/all-components.yaml"
echo "  /tmp/nlb-only.yaml"
echo "  /tmp/eip-only.yaml"
echo "  /tmp/alibabacloud-operators-*.tgz"
echo ""
echo "下一步："
echo "  1. 验证生成的 YAML 文件"
echo "  2. 在测试集群中安装 Chart"
echo "  3. 运行集成测试"
echo ""
