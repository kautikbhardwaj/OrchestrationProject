{{- define "mern.labels" -}}
app.kubernetes.io/part-of: mern-app
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "mern.mongoSecretName" -}}
{{- if .Values.mongodb.existingSecret -}}
{{ .Values.mongodb.existingSecret }}
{{- else -}}
mern-mongodb
{{- end -}}
{{- end }}

{{- define "mern.mongoUrl" -}}
{{- if .Values.mongodb.externalUrl -}}
{{ .Values.mongodb.externalUrl }}
{{- else -}}
mongodb://mongodb:27017/{{ .Values.mongodb.database }}
{{- end -}}
{{- end }}
