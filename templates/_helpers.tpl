{{/*
Expand the name of the chart.
*/}}
{{- define "alibabacloud-operators.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "alibabacloud-operators.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "alibabacloud-operators.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "alibabacloud-operators.labels" -}}
helm.sh/chart: {{ include "alibabacloud-operators.chart" . }}
{{ include "alibabacloud-operators.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "alibabacloud-operators.selectorLabels" -}}
app.kubernetes.io/name: {{ include "alibabacloud-operators.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NLB Operator labels
*/}}
{{- define "nlb-operator.labels" -}}
helm.sh/chart: {{ include "alibabacloud-operators.chart" . }}
{{ include "nlb-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: nlb-operator
{{- end }}

{{/*
NLB Operator selector labels
*/}}
{{- define "nlb-operator.selectorLabels" -}}
app.kubernetes.io/name: nlb-operator
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NLB Operator ServiceAccount name
*/}}
{{- define "nlb-operator.serviceAccountName" -}}
{{- if .Values.nlbOperator.serviceAccount.create }}
{{- default "nlb-operator" .Values.nlbOperator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.nlbOperator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
EIP Operator labels
*/}}
{{- define "eip-operator.labels" -}}
helm.sh/chart: {{ include "alibabacloud-operators.chart" . }}
{{ include "eip-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: eip-operator
{{- end }}

{{/*
EIP Operator selector labels
*/}}
{{- define "eip-operator.selectorLabels" -}}
app.kubernetes.io/name: eip-operator
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
EIP Operator ServiceAccount name
*/}}
{{- define "eip-operator.serviceAccountName" -}}
{{- if .Values.eipOperator.serviceAccount.create }}
{{- default "eip-operator" .Values.eipOperator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.eipOperator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
NLB Pool Operator labels
*/}}
{{- define "nlb-pool-operator.labels" -}}
helm.sh/chart: {{ include "alibabacloud-operators.chart" . }}
{{ include "nlb-pool-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: nlb-pool-operator
{{- end }}

{{/*
NLB Pool Operator selector labels
*/}}
{{- define "nlb-pool-operator.selectorLabels" -}}
app.kubernetes.io/name: nlb-pool-operator
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NLB Pool Operator ServiceAccount name
*/}}
{{- define "nlb-pool-operator.serviceAccountName" -}}
{{- if .Values.nlbPoolOperator.serviceAccount.create }}
{{- default "nlb-pool-operator" .Values.nlbPoolOperator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.nlbPoolOperator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image registry
*/}}
{{- define "alibabacloud-operators.imageRegistry" -}}
{{- .Values.global.imageRegistry }}
{{- end }}

{{/*
Validate AccessKey credentials.
Fails the install/upgrade with a clear message if AK/SK is empty, masked
(contains '***'), or accidentally includes the 'access-key-id=' prefix
from `aliyun configure get` output.
*/}}
{{- define "alibabacloud-operators.validateCredentials" -}}
{{- $ak := .Values.global.alibabacloud.accessKeyId | toString -}}
{{- $sk := .Values.global.alibabacloud.accessKeySecret | toString -}}
{{- if not $ak -}}
  {{- fail "\n\nERROR: global.alibabacloud.accessKeyId is required.\nPlease provide your plaintext AccessKey ID (typically starts with 'LTAI').\nSee README section '获取 AccessKey' for how to obtain it.\n" -}}
{{- end -}}
{{- if not $sk -}}
  {{- fail "\n\nERROR: global.alibabacloud.accessKeySecret is required.\nPlease provide your plaintext AccessKey Secret (30 random characters).\nSee README section '获取 AccessKey' for how to obtain it.\n" -}}
{{- end -}}
{{- if contains "***" $ak -}}
  {{- fail "\n\nERROR: accessKeyId looks masked (contains '***').\nYou likely used the output of `aliyun configure get access-key-id`, which is masked for security.\nThe correct way to obtain the plaintext AK:\n  - Read directly from ~/.aliyun/config.json (jq '.profiles[].access_key_id')\n  - Or copy from the Alibaba Cloud RAM console where the AccessKey was created.\nSee README section '获取 AccessKey' for details.\n" -}}
{{- end -}}
{{- if contains "***" $sk -}}
  {{- fail "\n\nERROR: accessKeySecret looks masked (contains '***').\nSee accessKeyId error above.\n" -}}
{{- end -}}
{{- if hasPrefix "access-key-id=" $ak -}}
  {{- fail "\n\nERROR: accessKeyId contains the literal prefix 'access-key-id='.\nYou likely passed the entire line of `aliyun configure get` output, which is in 'key=value' format.\nUse only the value after the '=' sign, e.g. 'LTAI...' not 'access-key-id=LTAI...'.\n" -}}
{{- end -}}
{{- if hasPrefix "access-key-secret=" $sk -}}
  {{- fail "\n\nERROR: accessKeySecret contains the literal prefix 'access-key-secret='.\nSee accessKeyId error above.\n" -}}
{{- end -}}
{{- end -}}
