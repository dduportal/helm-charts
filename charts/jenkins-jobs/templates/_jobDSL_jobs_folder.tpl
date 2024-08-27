{{/* vim: set filetype=mustache: */}}
{{/*
Generate the job-dsl definition of a folder
*/}}
{{- define "folder-job-dsl-definition" -}}
folder('{{ .id }}') {
{{ indent 2 (include "common-job-dsl-definition" . ) }}
}
{{- end }}
