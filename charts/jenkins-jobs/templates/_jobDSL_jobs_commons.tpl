{{/* vim: set filetype=mustache: */}}
{{/*
Generate the job-dsl configuration from specified values
*/}}
{{- define "jobs-dsl-config" }}
  {{- $root := . }}
  {{- range $jobId, $jobDef := .Values.jobsDefinition }}
{{ indent 4 (include "generic-job-dsl-definition" (merge $jobDef (dict "id" $jobId "root" $root))) }}
    {{- range $childId, $childDef := $jobDef.children }}
      {{- /*  Jenkins + Job DSL allow to define job children by concatenating their id with the parent id, separated by a / */}}
      {{- $childFullId := printf "%s/%s" $jobId $childId }}
      {{- $parentGithubCredential := $jobDef.childrenGithubCredential }}
      {{- $child := (dict "id" $childId "fullId" $childFullId "root" $root "parentGithubCredential" $parentGithubCredential) }}
      {{- if $childDef }}
        {{- $child = (merge $childDef (dict "id" $childId "fullId" $childFullId "root" $root "parentGithubCredential" $parentGithubCredential)) }}
      {{- end }}
{{ indent 4 (include "generic-job-dsl-definition" $child) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Generate the job-dsl definition of a single generic item
*/}}
{{- define "generic-job-dsl-definition" }}
  {{- $jobKind := .kind | default "multibranchPipelineJob" }}
  {{- if eq "folder" $jobKind }}
{{- include "folder-job-dsl-definition" . }}
  {{- else if eq "multibranchPipelineJob" $jobKind }}
{{- include "multibranch-job-dsl-definition" . }}
  {{- else if eq "organizationFolder" $jobKind }}
{{- include "organization-folder-dsl-definition" . }}
  {{- end }}
{{- end }}

{{/*
Generate the "common" elements for any job-dsl definition
*/}}
{{- define "common-job-dsl-definition" -}}
displayName('{{ coalesce .name .id }}')
description('{{ coalesce .description .name .id }}')
{{- include "common-credentials-job-dsl-definition" . }}
{{- end }}

{{/*
Generate the "commons" element of GitHub Branch sourcejob orphanedItemStrategy section
*/}}
{{- define "githubranch-commons-job-dsl-definition" }}
repoOwner('{{ .repositoryOwner }}')
      credentialsId('{{ coalesce .githubCredentialsId .parentGithubCredential "github-app-infra" }}')
{{- end }}

{{/*
Generate the job triggers section
*/}}
{{- define "triggers-job-dsl-definition" }}
triggers {
  periodicFolderTrigger {
    interval('{{ .periodicFolderTrigger | default "2h" }}')
  }
}
{{- end }}

{{/*
Generate the job's GitHub Branch Source traits block
*/}}
{{- define "githubbranchsource-traits-job-dsl-definition" }}
traits {
  gitHubNotificationContextTrait {
    contextLabel('jenkins/{{ .root.Values.jenkinsFqdn | default "localhost" }}/{{ .fullId | default .id }}')
    typeSuffix(true)
  }
  gitHubSCMSourceStatusChecksTrait {
    // Note: changing this name might have impact on github branch protections if they specify status names
    name({{ .githubCheckName | default "jenkins" | squote }})
    {{- if empty .enableGitHubChecks }}
    skip(true)
    {{- else }}
    skip({{ not .enableGitHubChecks }})
    {{- end }}
    // If this option is checked, the notifications sent by the GitHub Branch Source Plugin will be disabled.
    skipNotifications(false)
    skipProgressUpdates(false)
    // Default value: false. Warning: risk of secret leak in console if the build fails
    // Please note that it only disable the detailed logs. If you really want no logs, then use "skip(false)' instead
    suppressLogs(true)
    unstableBuildNeutral(false)
  }
  gitHubBranchDiscovery {
    strategyId(1) // 1-only branches that are not pull requests
  }
  gitHubPullRequestDiscovery {
    strategyId(1) // 1-Merging the pull request with the current target branch revision
  }
  gitHubForkDiscovery {
    strategyId(1) // 1-Merging the pull request with the current target branch revision
    trust {
      gitHubTrustPermissions()
    }
  }
  pruneStaleBranchTrait()
    {{- if not .disableTagDiscovery }}
  gitHubTagDiscovery()
    {{- end }}
  pullRequestLabelsBlackListFilterTrait {
    labels('on-hold,ci-skip,skip-ci')
  }
  // Select branches and tags to build based on these filters
  headWildcardFilterWithPR {
    includes('{{ .branchIncludes | default "main master PR-*" }}') // only branches listed here
    excludes('{{ .branchExcludes | default "" }}')
    tagIncludes('*')
    tagExcludes('')
  }
}
{{- end }}

{{/*
Generate the job buildStrategy section
*/}}
{{- define "buildstrategy-job-dsl-definition" }}
buildStrategies {
  buildAnyBranches {
    strategies {
  {{- if eq (.buildOnFirstIndexing | toString) "<nil>" }}
      skipInitialBuildOnFirstBranchIndexing()
  {{- end }}
      buildChangeRequests {
        ignoreTargetOnlyChanges(true)
  {{- if eq (.allowUntrustedChanges | toString) "<nil>" }}
        ignoreUntrustedChanges(true)
  {{- else }}
        ignoreUntrustedChanges({{ not .allowUntrustedChanges }})
  {{- end }}
      }
      buildRegularBranches()
  {{- if not .disableTagDiscovery }}
      buildTags {
        atLeastDays('-1')
        atMostDays('3')
      }
  {{- end }}
    }
  }
}
{{- end }}

{{/*
Generate the job orphanedItemStrategy section
*/}}
{{- define "orphanedItemStrategy-job-dsl-definition" }}
orphanedItemStrategy {
  defaultOrphanedItemStrategy {
    pruneDeadBranches(true)
    daysToKeepStr("{{ .orphanedItemStrategyDaysToKeep | default "" }}")
    numToKeepStr("{{ .orphanedItemStrategyNumToKeep | default "" }}")
    abortBuilds(true)
  }
}
{{- end }}
