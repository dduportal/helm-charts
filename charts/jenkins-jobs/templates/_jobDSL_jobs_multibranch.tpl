{{/* vim: set filetype=mustache: */}}
{{/*
Generate the job-dsl definition of a multibranch job
*/}}
{{- define "multibranch-job-dsl-definition" -}}
  {{- $repository := .repository | default .id -}}
  {{- $repositoryOwner := .repoOwner | default "jenkins-infra" -}}
multibranchPipelineJob('{{ .fullId | default .id }}') {
  {{- include "triggers-job-dsl-definition" . | indent 2 }}

  branchSources {
    branchSource {
      source {
        github {
          id('{{ .fullId | default .id | toString }}')
          credentialsId('{{ coalesce .githubCredentialsId .parentGithubCredential "github-app-infra" }}')
          configuredByUrl(true)
          repositoryUrl('https://github.com/{{ $repositoryOwner }}/{{ $repository }}')
          repoOwner('{{ $repositoryOwner }}')
          repository('{{ $repository }}')
    {{- include "githubbranchsource-traits-job-dsl-definition" . | indent 10 }}
        }
    {{- include "buildstrategy-job-dsl-definition" . | indent 8 }}
      }
    }
  }
  factory {
    workflowBranchProjectFactory {
      scriptPath('{{ .jenkinsfilePath | default "Jenkinsfile_k8s" }}')
    }
  }

  {{- include "orphanedItemStrategy-job-dsl-definition" . | indent 2 }}
  {{- include "common-job-dsl-definition" . | indent 2 }}
}
{{- end }}
