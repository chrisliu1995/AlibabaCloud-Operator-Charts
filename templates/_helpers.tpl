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
Image registry
*/}}
{{- define "alibabacloud-operators.imageRegistry" -}}
{{- .Values.global.imageRegistry }}
{{- end }}
