{{- define "mywebapp.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "mywebapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name -}}
{{- end -}}

{{- define "mywebapp.labels" -}}
app.kubernetes.io/name: {{ include "mywebapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "mywebapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mywebapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
