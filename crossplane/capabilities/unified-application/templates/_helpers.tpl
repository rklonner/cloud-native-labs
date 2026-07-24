{{- define "unified-application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "unified-application.fullname" -}}
{{- include "unified-application.name" . -}}
{{- end -}}

{{- define "unified-application.connectionEnv" -}}
{{- $root := . -}}
{{- range $db := $root.Values.capabilities.databases }}
{{- range $role := $db.roles }}
{{- if $role.bindAs.connectionString.envVar }}
- name: {{ $role.bindAs.connectionString.envVar }}
  valueFrom:
    secretKeyRef:
      name: {{ printf "%s-%s-%s-app-connection" (include "unified-application.fullname" $root) $db.name $role.name }}
      key: {{ $role.bindAs.connectionString.envVar }}
{{- end }}
{{- end }}
{{- end }}
{{- range $access := $root.Values.capabilities.databaseAccess }}
{{- range $role := $access.roles }}
{{- if $role.bindAs.connectionString.envVar }}
- name: {{ $role.bindAs.connectionString.envVar }}
  valueFrom:
    secretKeyRef:
      name: {{ printf "%s-%s-%s-app-connection" (include "unified-application.fullname" $root) $access.name $role.name }}
      key: {{ $role.bindAs.connectionString.envVar }}
{{- end }}
{{- end }}
{{- end }}
{{- range $import := $root.Values.capabilities.secretImports }}
{{- if and $import.bindAs.usernamePassword $import.bindAs.usernamePassword.envVars $import.bindAs.usernamePassword.envVars.username }}
- name: {{ $import.bindAs.usernamePassword.envVars.username }}
  valueFrom:
    secretKeyRef:
      name: {{ default (printf "%s-%s" (include "unified-application.fullname" $root) $import.name) $import.bindAs.secretName }}
      key: {{ $import.bindAs.usernamePassword.envVars.username }}
{{- end }}
{{- if and $import.bindAs.usernamePassword $import.bindAs.usernamePassword.envVars $import.bindAs.usernamePassword.envVars.password }}
- name: {{ $import.bindAs.usernamePassword.envVars.password }}
  valueFrom:
    secretKeyRef:
      name: {{ default (printf "%s-%s" (include "unified-application.fullname" $root) $import.name) $import.bindAs.secretName }}
      key: {{ $import.bindAs.usernamePassword.envVars.password }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "unified-application.hasConnectionEnv" -}}
{{- $root := . -}}
{{- $has := false -}}
{{- range $db := $root.Values.capabilities.databases }}
{{- range $role := $db.roles }}
{{- if $role.bindAs.connectionString.envVar }}{{- $has = true -}}{{- end }}
{{- end }}
{{- end }}
{{- range $access := $root.Values.capabilities.databaseAccess }}
{{- range $role := $access.roles }}
{{- if $role.bindAs.connectionString.envVar }}{{- $has = true -}}{{- end }}
{{- end }}
{{- end }}
{{- range $import := $root.Values.capabilities.secretImports }}
{{- if and $import.bindAs.usernamePassword $import.bindAs.usernamePassword.envVars $import.bindAs.usernamePassword.envVars.username }}{{- $has = true -}}{{- end }}
{{- if and $import.bindAs.usernamePassword $import.bindAs.usernamePassword.envVars $import.bindAs.usernamePassword.envVars.password }}{{- $has = true -}}{{- end }}
{{- end }}
{{- if $has }}true{{- end -}}
{{- end -}}
