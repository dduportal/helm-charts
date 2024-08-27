{{/*
Generate the job-dsl definition of an organization (Scanning) Folder
*/}}
{{- define "organization-folder-dsl-definition" }}
  {{- $repository := .repository | default .id }}
  {{- $repositoryOwner := .repoOwner | default "jenkins-infra" }}
organizationFolder('{{ .fullId | default .id }}') {
  // This is the "Child Scan Triggers" item
  {{- include "triggers-job-dsl-definition" . | indent 2 }}
  configure { node ->
    node / 'properties' << 'jenkins.branch.OrganizationChildTriggersProperty' {
      templates {
        'com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger' {
          spec('H/5 * * * *')
          interval('86400000') // 1d (ms)
        }
      }
    }
  }
  properties {
    suppressFolderAutomaticTriggering {
      branches('.*')
      strategy('INDEXING') // Can be 'NONE' (default), 'INDEXING' or 'EVENTS'
    }
  }
  organizations {
    github {
      repoOwner('{{ $repositoryOwner }}')
      credentialsId('{{ coalesce .githubCredentialsId .parentGithubCredential "github-app-infra" }}')
      enableAvatar(true)

      traits {
  {{- with .repositoryRegexFilter }}
        sourceRegexFilter {
          regex('{{ . }}')
        }
  {{- end }}
  {{- with .repositoryWildcardFilter }}
        sourceWildcardFilter {
    {{- with .includes }}
          includes('{{ . }}')
    {{- end }}
          excludes('{{ .excludes | default "" }}')
        }
  {{- end }}
    }
  {{- include "githubbranchsource-traits-job-dsl-definition" . | indent 6 }}
    }
  }
  projectFactories {
    workflowMultiBranchProjectFactory {
      scriptPath("{{ .markerFile | default "Jenkinsfile" }}")
    }
  }
  {{- include "buildstrategy-job-dsl-definition" . | indent 2 }}
  {{- include "orphanedItemStrategy-job-dsl-definition" . | indent 2 }}
  {{- include "common-job-dsl-definition" . | indent 2 }}
}
{{- end }}
