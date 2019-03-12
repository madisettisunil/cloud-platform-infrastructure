# Default values for prometheus-operator.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

## Provide a name in place of prometheus-operator for `app:` labels
##
nameOverride: ""

## Provide a name to substitute for the full names of resources
##
fullnameOverride: ""

## Labels to apply to all resources
##
commonLabels: {}
# scmhash: abc123
# myLabel: aakkmd

## Create default rules for monitoring the cluster
##
defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: true
    general: true
    k8s: true
    kubeApiserver: true
    kubePrometheusNodeAlerting: true
    kubePrometheusNodeRecording: true
    kubeScheduler: true
    kubernetesAbsent: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    node: true
    prometheusOperator: true
    prometheus: true
  ## Labels for default rules
  labels: {}
  ## Annotations for default rules
  annotations: {}

##
global:
  rbac:
    create: true
    pspEnabled: true

  ## Reference to one or more secrets to be used when pulling images
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
  ##
  imagePullSecrets: []
  # - name: "image-pull-secret"

## Configuration for alertmanager
## ref: https://prometheus.io/docs/alerting/alertmanager/
##
alertmanager:

  ## Deploy alertmanager
  ##
  enabled: true

  ## Service account for Alertmanager to use.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
  ##
  serviceAccount:
    create: true
    name: ""

  ## Configure pod disruption budgets for Alertmanager
  ## ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget
  ## This configuration is immutable once created and will require the PDB to be deleted to be changed
  ## https://github.com/kubernetes/kubernetes/issues/45398
  ##
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
    maxUnavailable: ""

  ## Alertmanager configuration directives
  ## ref: https://prometheus.io/docs/alerting/configuration/#configuration-file
  ##      https://prometheus.io/webtools/alerting/routing-tree-editor/
  ##
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'null'
      routes:
      - match:
          alertname: CPUThrottlingHigh
        receiver: 'null'
      - match:
          alertname: DeadMansSwitch
        receiver: 'null'
      - match:
          alertname: DeploymentReplicasAreOutdated
        receiver: 'null'
      - match:
          alertname: PodIsRestartingFrequently
        receiver: 'null'
      - match:
          severity: critical
        receiver: pager-duty-high-priority
      - match:
          severity: warning
        receiver: slack-low-priority
      - match:
          severity: apply-for-legal-aid
        receiver: apply-for-legal-aid
      - match:
          severity: laa-cla-fala
        receiver: slack-laa-cla-fala
      - match:
          severity: prisoner-money
        receiver: slack-prisoner-money

    receivers:
    - name: 'null'
    # Add PagerDuty key to allow integration with a PD service.
    - name: 'pager-duty-high-priority'
      pagerduty_configs:
      - service_key: "${ pagerduty_config }"
    # Add Slack webhook API URL and channel for integration with slack.
    - name: 'slack-low-priority'
      slack_configs:
      - api_url: "${ slack_config }"
        channel: "#lower-priority-alarms"
        send_resolved: True
        title: '{{ template "slack.cp.title" . }}'
        text: '{{ template "slack.cp.text" . }}'
        footer: ${ alertmanager_ingress }
        actions:
        - type: button
          text: 'Runbook :blue_book:'
          url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
        - type: button
          text: 'Query :mag:'
          url: '{{ (index .Alerts 0).GeneratorURL }}'
        - type: button
          text: 'Silence :no_bell:'
          url: '{{ template "__alert_silence_link" . }}'
    - name: 'slack-apply-for-legal-aid'
      slack_configs:
      - api_url: "${slack_config_apply-for-legal-aid}"
        channel: "#apply-alerts-staging"
        send_resolved: True
        title: '{{ template "slack.cp.title" . }}'
        text: '{{ template "slack.cp.text" . }}'
        footer: ${ alertmanager_ingress }
        actions:
        - type: button
          text: 'Runbook :blue_book:'
          url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
        - type: button
          text: 'Query :mag:'
          url: '{{ (index .Alerts 0).GeneratorURL }}'
        - type: button
          text: 'Silence :no_bell:'
          url: '{{ template "__alert_silence_link" . }}' 
    - name: 'slack-laa-cla-fala'
      slack_configs:
      - api_url: "${slack_config_laa-cla-fala}"
        channel: "#cla-alerts"
        send_resolved: True
        title: '{{ template "slack.cp.title" . }}'
        text: '{{ template "slack.cp.text" . }}'
        footer: ${ alertmanager_ingress }
        actions:
        - type: button
          text: 'Runbook :blue_book:'
          url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
        - type: button
          text: 'Query :mag:'
          url: '{{ (index .Alerts 0).GeneratorURL }}'
        - type: button
          text: 'Silence :no_bell:'
          url: '{{ template "__alert_silence_link" . }}'
    - name: 'slack-prisoner-money'
      slack_configs:
      - api_url: "${slack_config_prisoner-money}"
        channel: "#prisoner-money-alerts"
        send_resolved: True
        title: '{{ template "slack.cp.title" . }}'
        text: '{{ template "slack.cp.text" . }}'
        footer: ${ alertmanager_ingress }
        actions:
        - type: button
          text: 'Runbook :blue_book:'
          url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
        - type: button
          text: 'Query :mag:'
          url: '{{ (index .Alerts 0).GeneratorURL }}'
        - type: button
          text: 'Silence :no_bell:'
          url: '{{ template "__alert_silence_link" . }}'
    templates:
    - '/etc/alertmanager/config/cp-slack-templates.tmpl'


  ## Alertmanager template files to format alerts
  ## ref: https://prometheus.io/docs/alerting/notifications/
  ##      https://prometheus.io/docs/alerting/notification_examples/
  ##
  templateFiles:
    cp-slack-templates.tmpl: |-
      {{ define "slack.cp.title" -}}
        [{{ .Status | toUpper -}}
        {{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{- end -}}
        ] {{ template "__alert_severity_prefix_title" . }} {{ .CommonLabels.alertname }}
      {{- end }}

      {{/* The test to display in the alert */}}
      {{ define "slack.cp.text" -}}
        {{ range .Alerts }}
            *Alert:* {{ .Annotations.message}}
            *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
            *-----*
          {{ end }}
      {{- end }}

      {{ define "__alert_silence_link" -}}
        {{ .ExternalURL }}/#/silences/new?filter=%7B
        {{- range .CommonLabels.SortedPairs -}}
          {{- if ne .Name "alertname" -}}
            {{- .Name }}%3D"{{- .Value -}}"%2C%20
          {{- end -}}
        {{- end -}}
          alertname%3D"{{ .CommonLabels.alertname }}"%7D
      {{- end }}

      {{ define "__alert_severity_prefix" -}}
          {{ if ne .Status "firing" -}}
          :white_check_mark:
          {{- else if eq .Labels.severity "critical" -}}
          :fire:
          {{- else if eq .Labels.severity "warning" -}}
          :warning:
          {{- else -}}
          :question:
          {{- end }}
      {{- end }}

      {{ define "__alert_severity_prefix_title" -}}
          {{ if ne .Status "firing" -}}
          :white_check_mark:
          {{- else if eq .CommonLabels.severity "critical" -}}
          :fire:
          {{- else if eq .CommonLabels.severity "warning" -}}
          :warning:
          {{- else if eq .CommonLabels.severity "info" -}}
          :information_source:
          {{- else -}}
          :question:
          {{- end }}
      {{- end }}

  ingress:
    enabled: false

    annotations: {}

    labels: {}

    ## Hosts must be provided if Ingress is enabled.
    ##
    hosts: []
      # - alertmanager.domain.com

    ## TLS configuration for Alertmanager Ingress
    ## Secret must be manually created in the namespace
    ##
    tls: []
    # - secretName: alertmanager-general-tls
    #   hosts:
    #   - alertmanager.example.com

  ## Configuration for Alertmanager service
  ##
  service:
    annotations: {}
    labels: {}
    clusterIP: ""

  ## Port to expose on each node
  ## Only used if service.type is 'NodePort'
  ##
    nodePort: 30903
  ## List of IP addresses at which the Prometheus server service is available
  ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
  ##
    externalIPs: []
    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    ## Service type
    ##
    type: ClusterIP

  ## If true, create a serviceMonitor for alertmanager
  ##
  serviceMonitor:
    selfMonitor: true

  ## Settings affecting alertmanagerSpec
  ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerspec
  ##
  alertmanagerSpec:
    ## Standard object’s metadata. More info: https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata
    ## Metadata Labels and Annotations gets propagated to the Alertmanager pods.
    ##
    podMetadata: {}

    ## Image of Alertmanager
    ##
    image:
      repository: quay.io/prometheus/alertmanager
      tag: v0.15.3

    ## Secrets is a list of Secrets in the same namespace as the Alertmanager object, which shall be mounted into the
    ## Alertmanager Pods. The Secrets are mounted into /etc/alertmanager/secrets/.
    ##
    secrets: []

    ## ConfigMaps is a list of ConfigMaps in the same namespace as the Alertmanager object, which shall be mounted into the Alertmanager Pods.
    ## The ConfigMaps are mounted into /etc/alertmanager/configmaps/.
    ##
    configMaps: []

    ## Log level for Alertmanager to be configured with.
    ##
    logLevel: info

    ## Size is the expected size of the alertmanager cluster. The controller will eventually make the size of the
    ## running cluster equal to the expected size.
    replicas: 1

    ## Time duration Alertmanager shall retain data for. Default is '120h', and must match the regular expression
    ## [0-9]+(ms|s|m|h) (milliseconds seconds minutes hours).
    ##
    retention: 120h

    ## Storage is the definition of how storage will be used by the Alertmanager instances.
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md
    ##
    storage:
    volumeClaimTemplate:
      spec:
        storageClassName: default
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
      selector: {}


    ## 	The external URL the Alertmanager instances will be available under. This is necessary to generate correct URLs. This is necessary if Alertmanager is not served from root of a DNS name.	string	false
    ##
    externalUrl: "${ alertmanager_ingress }"

    ## 	The route prefix Alertmanager registers HTTP handlers for. This is useful, if using ExternalURL and a proxy is rewriting HTTP routes of a request, and the actual ExternalURL is still true,
    ## but the server serves requests under a different route prefix. For example for use with kubectl proxy.
    ##
    routePrefix: /

    ## If set to true all actions on the underlying managed objects are not going to be performed, except for delete actions.
    ##
    paused: false

    ## Define which Nodes the Pods are scheduled on.
    ## ref: https://kubernetes.io/docs/user-guide/node-selection/
    ##
    nodeSelector: {}

    ## Define resources requests and limits for single Pods.
    ## ref: https://kubernetes.io/docs/user-guide/compute-resources/
    ##
    resources: {}
    # requests:
    #   memory: 400Mi

    ## Pod anti-affinity can prevent the scheduler from placing Prometheus replicas on the same node.
    ## The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided.
    ## The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node.
    ## The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured.
    ##
    podAntiAffinity: "soft"

    ## If anti-affinity is enabled sets the topologyKey to use for anti-affinity.
    ## This can be changed to, for example, failure-domain.beta.kubernetes.io/zone
    ##
    podAntiAffinityTopologyKey: kubernetes.io/hostname

    ## If specified, the pod's tolerations.
    ## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
    ##
    tolerations: []
    # - key: "key"
    #   operator: "Equal"
    #   value: "value"
    #   effect: "NoSchedule"

    ## SecurityContext holds pod-level security attributes and common container settings.
    ## This defaults to non root user with uid 1000 and gid 2000.	*v1.PodSecurityContext	false
    ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
    ##
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 2000

    ## ListenLocal makes the Alertmanager server listen on loopback, so that it does not bind against the Pod IP.
    ## Note this is only for the Alertmanager UI, not the gossip communication.
    ##
    listenLocal: false

    ## Containers allows injecting additional containers. This is meant to allow adding an authentication proxy to an Alertmanager pod.
    ##
    containers: []

    ## Priority class assigned to the Pods
    ##
    priorityClassName: ""

    ## AdditionalPeers allows injecting a set of additional Alertmanagers to peer with to form a highly available cluster.
    ##
    additionalPeers: []

## Using default values from https://github.com/helm/charts/blob/master/stable/grafana/values.yaml
##
grafana:
  enabled: true

  ## Deploy default dashboards.
  ##
  defaultDashboardsEnabled: true

  adminUser: "${ random_username }"
  adminPassword: "${ random_password }"

  ingress:
    ## If true, Prometheus Ingress will be created
    ##
    enabled: true

    ## Annotations for Prometheus Ingress
    ##
    annotations: {}
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"

    ## Labels to be added to the Ingress
    ##
    labels: {}

    ## Hostnames.
    ## Must be provided if Ingress is enable.
    ##
    # hosts:
    #   - prometheus.domain.com
    hosts:
    - "${ grafana_ingress }"

    ## TLS configuration for prometheus Ingress
    ## Secret must be manually created in the namespace
    ##
    tls:
    - secretName: prometheus-general-tls
      hosts:
      - "${ grafana_ingress }"

  env:
    GF_SERVER_ROOT_URL: "${ grafana_root }"
    GF_ANALYTICS_REPORTING_ENABLED: "false"
    GF_AUTH_DISABLE_LOGIN_FORM: "true"
    GF_USERS_ALLOW_SIGN_UP: "false"
    GF_USERS_AUTO_ASSIGN_ORG_ROLE: "Viewer"
    GF_USERS_VIEWERS_CAN_EDIT: "true"
    GF_AUTH_GITHUB_ENABLED: "true"
    GF_AUTH_GITHUB_ALLOW_SIGN_UP: "true"
    GF_SMTP_ENABLED: "false"
    GF_AUTH_GITHUB_ALLOWED_ORGANIZATIONS: "ministryofjustice"

  envFromSecret: "grafana-env"

  serverDashboardConfigmaps:
    - grafana-user-dashboards

  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      searchNamespace: ALL
    datasources:
      enabled: true
      label: grafana_datasource

  extraConfigmapMounts: []
  # - name: certs-configmap
  #   mountPath: /etc/grafana/ssl/
  #   configMap: certs-configmap
  #   readOnly: true


## Component scraping the kube api server
##
kubeApiServer:
  enabled: true
  tlsConfig:
    serverName: kubernetes
    insecureSkipVerify: false

  serviceMonitor:
    jobLabel: component
    selector:
      matchLabels:
        component: apiserver
        provider: kubernetes

## Component scraping the kubelet and kubelet-hosted cAdvisor
##
kubelet:
  enabled: true
  namespace: kube-system

  serviceMonitor:
    ## Enable scraping the kubelet over https. For requirements to enable this see
    ## https://github.com/coreos/prometheus-operator/issues/926
    ##
    https: true

## Component scraping the kube controller manager
##
kubeControllerManager:
  enabled: true

  ## If your kube controller manager is not deployed as a pod, specify IPs it can be found on
  ##
  endpoints: []
  # - 10.141.4.22
  # - 10.141.4.23
  # - 10.141.4.24

  ## If using kubeControllerManager.endpoints only the port and targetPort are used
  ##
  service:
    port: 10252
    targetPort: 10252
    selector:
      k8s-app: kube-controller-manager
## Component scraping coreDns. Use either this or kubeDns
##
coreDns:
  enabled: false
  service:
    port: 9153
    targetPort: 9153
    selector:
      k8s-app: coredns

## Component scraping kubeDns. Use either this or coreDns
##
kubeDns:
  enabled: true
  service:
    selector:
      k8s-app: kube-dns
## Component scraping etcd
##
kubeEtcd:
  enabled: true

  ## If your etcd is not deployed as a pod, specify IPs it can be found on
  ##
  endpoints: []
  # - 10.141.4.22
  # - 10.141.4.23
  # - 10.141.4.24

  ## Etcd service. If using kubeEtcd.endpoints only the port and targetPort are used
  ##
  service:
    port: 4001
    targetPort: 4001
    selector:
      k8s-app: etcd-server

  ## Configure secure access to the etcd cluster by loading a secret into prometheus and
  ## specifying security configuration below. For example, with a secret named etcd-client-cert
  ##
  ## serviceMonitor:
  ##   scheme: https
  ##   insecureSkipVerify: false
  ##   serverName: localhost
  ##   caFile: /etc/prometheus/secrets/etcd-client-cert/etcd-ca
  ##   certFile: /etc/prometheus/secrets/etcd-client-cert/etcd-client
  ##   keyFile: /etc/prometheus/secrets/etcd-client-cert/etcd-client-key
  ##
  serviceMonitor:
    scheme: http
    insecureSkipVerify: false
    serverName: ""
    caFile: ""
    certFile: ""
    keyFile: ""


## Component scraping kube scheduler
##
kubeScheduler:
  enabled: true

  ## If your kube scheduler is not deployed as a pod, specify IPs it can be found on
  ##
  endpoints: []
  # - 10.141.4.22
  # - 10.141.4.23
  # - 10.141.4.24

  ## If using kubeScheduler.endpoints only the port and targetPort are used
  ##
  service:
    port: 10251
    targetPort: 10251
    selector:
      k8s-app: kube-scheduler

## Component scraping kube state metrics
##
kubeStateMetrics:
  enabled: true

## Configuration for kube-state-metrics subchart
##
kube-state-metrics:
  rbac:
    create: true
  podSecurityPolicy:
    enabled: true

## Deploy node exporter as a daemonset to all nodes
##
nodeExporter:
  enabled: true
  ## Use the value configured in prometheus-node-exporter.podLabels
  ##
  jobLabel: jobLabel

## Configuration for prometheus-node-exporter subchart
##
prometheus-node-exporter:
  podLabels:
    ## Add the 'node-exporter' label to be used by serviceMonitor to match standard common usage in rules and grafana dashboards
    ##
    jobLabel: node-exporter
  extraArgs:
    - --collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+)($|/)
    - --collector.filesystem.ignored-fs-types=^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$

## Manages Prometheus and Alertmanager components
##
prometheusOperator:
  enabled: true

  ## Service account for Alertmanager to use.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
  ##
  serviceAccount:
    create: true
    name: ""

  ## Configuration for Prometheus operator service
  ##
  service:
    annotations: {}
    labels: {}
    clusterIP: ""

  ## Port to expose on each node
  ## Only used if service.type is 'NodePort'
  ##
    nodePort: 38080


  ## Loadbalancer IP
  ## Only use if service.type is "loadbalancer"
  ##
    loadBalancerIP: ""
    loadBalancerSourceRanges: []

  ## Service type
  ## NodepPort, ClusterIP, loadbalancer
  ##
    type: ClusterIP

    ## List of IP addresses at which the Prometheus server service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

  ## Deploy CRDs used by Prometheus Operator.
  ##
  createCustomResource: true

  ## Customize CRDs API Group
  crdApiGroup: monitoring.coreos.com

  ## Attempt to clean up CRDs created by Prometheus Operator.
  ##
  cleanupCustomResource: true

  ## Labels to add to the operator pod
  ##
  podLabels: {}

  ## Assign a PriorityClassName to pods if set
  # priorityClassName: ""

  ## If true, the operator will create and maintain a service for scraping kubelets
  ## ref: https://github.com/coreos/prometheus-operator/blob/master/helm/prometheus-operator/README.md
  ##
  kubeletService:
    enabled: true
    namespace: kube-system
  ## Create a servicemonitor for the operator
  ##
  serviceMonitor:
    selfMonitor: true

  ## Resource limits & requests
  ##
  resources: {}
  # limits:
  #   cpu: 200m
  #   memory: 200Mi
  # requests:
  #   cpu: 100m
  #   memory: 100Mi

  ## Define which Nodes the Pods are scheduled on.
  ## ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## Tolerations for use with node taints
  ## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  ##
  tolerations: []
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"

  ## Assign the prometheus operator to run on specific nodes
  ## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  ##
  affinity: {}
  # requiredDuringSchedulingIgnoredDuringExecution:
  #   nodeSelectorTerms:
  #   - matchExpressions:
  #     - key: kubernetes.io/e2e-az-name
  #       operator: In
  #       values:
  #       - e2e-az1
  #       - e2e-az2

  securityContext:
    runAsNonRoot: true
    runAsUser: 65534

  ## Prometheus-operator image
  ##
  image:
    repository: quay.io/coreos/prometheus-operator
    tag: v0.27.0
    pullPolicy: IfNotPresent

  ## Configmap-reload image to use for reloading configmaps
  ##
  configmapReloadImage:
    repository: quay.io/coreos/configmap-reload
    tag: v0.0.1

  ## Prometheus-config-reloader image to use for config and rule reloading
  ##
  prometheusConfigReloaderImage:
    repository: quay.io/coreos/prometheus-config-reloader
    tag: v0.27.0

  ## Hyperkube image to use when cleaning up
  ##
  hyperkubeImage:
    repository: k8s.gcr.io/hyperkube
    tag: v1.11.7
    pullPolicy: IfNotPresent

## Deploy a Prometheus instance
##
prometheus:

  enabled: true

  ## Service account for Prometheuses to use.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
  ##
  serviceAccount:
    create: true
    name: ""

  ## Configuration for Prometheus service
  ##
  service:
    annotations: {}
    labels: {}
    clusterIP: ""

    ## List of IP addresses at which the Prometheus server service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    ## Port to expose on each node
    ## Only used if service.type is 'NodePort'
    ##
    nodePort: 39090

    ## Loadbalancer IP
    ## Only use if service.type is "loadbalancer"
    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    ## Service type
    ##
    type: ClusterIP

  rbac:
    ## Create role bindings in the specified namespaces, to allow Prometheus monitoring
    ## a role binding in the release namespace will always be created.
    ##
    roleNamespaces:
      - monitoring

  ## Configure pod disruption budgets for Prometheus
  ## ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget
  ## This configuration is immutable once created and will require the PDB to be deleted to be changed
  ## https://github.com/kubernetes/kubernetes/issues/45398
  ##
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
    maxUnavailable: ""

  ingress:
    enabled: false
    annotations: {}
    labels: {}

    ## Hostnames.
    ## Must be provided if Ingress is enabled.
    ##
    # hosts:
    #   - prometheus.domain.com
    hosts: []

    ## TLS configuration for Prometheus Ingress
    ## Secret must be manually created in the namespace
    ##
    tls: []
      # - secretName: prometheus-general-tls
      #   hosts:
      #     - prometheus.example.com

  serviceMonitor:
    selfMonitor: true

  ## Settings affecting prometheusSpec
  ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusspec
  ##
  prometheusSpec:

    ## Interval between consecutive scrapes.
    ##
    scrapeInterval: ""

    ## Interval between consecutive evaluations.
    ##
    evaluationInterval: ""

    ## ListenLocal makes the Prometheus server listen on loopback, so that it does not bind against the Pod IP.
    ##
    listenLocal: false

    ## Image of Prometheus.
    ##
    image:
      repository: quay.io/prometheus/prometheus
      tag: v2.7.1

    ## Tolerations for use with node taints
    ## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
    ##
    tolerations: []
    #  - key: "key"
    #    operator: "Equal"
    #    value: "value"
    #    effect: "NoSchedule"

    ## Alertmanagers to which alerts will be sent
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerendpoints
    ##
    ## Default configuration will connect to the alertmanager deployed as part of this release
    ##
    alertingEndpoints: []
    # - name: ""
    #   namespace: ""
    #   port: http
    #   scheme: http

    ## External labels to add to any time series or alerts when communicating with external systems
    ##
    externalLabels: {}

    ## External URL at which Prometheus will be reachable.
    ##
    externalUrl: "${ prometheus_ingress }"

    ## Define which Nodes the Pods are scheduled on.
    ## ref: https://kubernetes.io/docs/user-guide/node-selection/
    ##
    nodeSelector: {}

    ## Secrets is a list of Secrets in the same namespace as the Prometheus object, which shall be mounted into the Prometheus Pods.
    ## The Secrets are mounted into /etc/prometheus/secrets/. Secrets changes after initial creation of a Prometheus object are not
    ## reflected in the running Pods. To change the secrets mounted into the Prometheus Pods, the object must be deleted and recreated
    ## with the new list of secrets.
    ##
    secrets: []

    ## ConfigMaps is a list of ConfigMaps in the same namespace as the Prometheus object, which shall be mounted into the Prometheus Pods.
    ## The ConfigMaps are mounted into /etc/prometheus/configmaps/.
    ##
    configMaps: []

    ## Namespaces to be selected for PrometheusRules discovery.
    ## If unspecified, only the same namespace as the Prometheus object is in is used.
    ##
    ruleNamespaceSelector:
      any: true

    ## If true, a nil or {} value for prometheus.prometheusSpec.ruleSelector will cause the
    ## prometheus resource to be created with selectors based on values in the helm deployment,
    ## which will also match the PrometheusRule resources created
    ##
    ruleSelectorNilUsesHelmValues: true

    ## Rules CRD selector
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md
    ## If unspecified the release `app` and `release` will be used as the label selector
    ## to load rules
    ##
    ruleSelector:
      any: true
    ## Example which select all prometheusrules resources
    ## with label "prometheus" with values any of "example-rules" or "example-rules-2"
    # ruleSelector:
    #   matchExpressions:
    #     - key: prometheus
    #       operator: In
    #       values:
    #         - example-rules
    #         - example-rules-2
    #
    ## Example which select all prometheusrules resources with label "role" set to "example-rules"
    # ruleSelector:
    #   matchLabels:
    #     role: example-rules

    ## If true, a nil or {} value for prometheus.prometheusSpec.serviceMonitorSelector will cause the
    ## prometheus resource to be created with selectors based on values in the helm deployment,
    ## which will also match the servicemonitors created
    ##
    serviceMonitorSelectorNilUsesHelmValues: true

    ## serviceMonitorSelector will limit which servicemonitors are used to create scrape
    ## configs in Prometheus. See serviceMonitorSelectorUseHelmLabels
    ##
    serviceMonitorSelector:
      any: true

    # serviceMonitorSelector: {}
    #   matchLabels:
    #     prometheus: somelabel

    ## serviceMonitorNamespaceSelector will limit namespaces from which serviceMonitors are used to create scrape
    ## configs in Prometheus. By default all namespaces will be used
    ##
    serviceMonitorNamespaceSelector:
      any: true

    ## How long to retain metrics
    ##
    retention: 30d

    ## If true, the Operator won't process any Prometheus configuration changes
    ##
    paused: false

    ## Number of Prometheus replicas desired
    ##
    replicas: 1

    ## Log level for Prometheus be configured in
    ##
    logLevel: info

    ## Prefix used to register routes, overriding externalUrl route.
    ## Useful for proxies that rewrite URLs.
    ##
    routePrefix: /

    ## Standard object’s metadata. More info: https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata
    ## Metadata Labels and Annotations gets propagated to the prometheus pods.
    ##
    podMetadata: {}
    # labels:
    #   app: prometheus
    #   k8s-app: prometheus

    ## Pod anti-affinity can prevent the scheduler from placing Prometheus replicas on the same node.
    ## The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided.
    ## The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node.
    ## The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured.
    podAntiAffinity: "soft"

    ## If anti-affinity is enabled sets the topologyKey to use for anti-affinity.
    ## This can be changed to, for example, failure-domain.beta.kubernetes.io/zone
    ##
    podAntiAffinityTopologyKey: kubernetes.io/hostname

    ## The remote_read spec configuration for Prometheus.
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#remotereadspec
    remoteRead: {}
    # - url: http://remote1/read

    ## The remote_write spec configuration for Prometheus.
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#remotewritespec
    remoteWrite: {}
      # remoteWrite:
      #   - url: http://remote1/push

    ## Resource limits & requests
    ##
    resources:
      requests:
        cpu: 1
        memory: 10Gi
      limits:
        cpu: 1
        memory: 10Gi

    ## Prometheus StorageSpec for persistent data
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md
    ##
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: default
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
        selector: {}

    ## AdditionalScrapeConfigs allows specifying additional Prometheus scrape configurations. Scrape configurations
    ## are appended to the configurations generated by the Prometheus Operator. Job configurations must have the form
    ## as specified in the official Prometheus documentation:
    ## https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<scrape_config>. As scrape configs are
    ## appended, the user is responsible to make sure it is valid. Note that using this feature may expose the possibility
    ## to break upgrades of Prometheus. It is advised to review Prometheus release notes to ensure that no incompatible
    ## scrape configs are going to break Prometheus after the upgrade.
    ##
    ## The scrape configuraiton example below will find master nodes, provided they have the name .*mst.*, relabel the
    ## port to 2379 and allow etcd scraping provided it is running on all Kubernetes master nodes
    ##
    additionalScrapeConfigs: []
    # - job_name: kube-etcd
    #   kubernetes_sd_configs:
    #     - role: node
    #   scheme: https
    #   tls_config:
    #     ca_file:   /etc/prometheus/secrets/etcd-client-cert/etcd-ca
    #     cert_file: /etc/prometheus/secrets/etcd-client-cert/etcd-client
    #     key_file:  /etc/prometheus/secrets/etcd-client-cert/etcd-client-key
    #   relabel_configs:
    #   - action: labelmap
    #     regex: __meta_kubernetes_node_label_(.+)
    #   - source_labels: [__address__]
    #     action: replace
    #     target_label: __address__
    #     regex: ([^:;]+):(\d+)
    #     replacement: ${1}:2379
    #   - source_labels: [__meta_kubernetes_node_name]
    #     action: keep
    #     regex: .*mst.*
    #   - source_labels: [__meta_kubernetes_node_name]
    #     action: replace
    #     target_label: node
    #     regex: (.*)
    #     replacement: ${1}
    #   metric_relabel_configs:
    #   - regex: (kubernetes_io_hostname|failure_domain_beta_kubernetes_io_region|beta_kubernetes_io_os|beta_kubernetes_io_arch|beta_kubernetes_io_instance_type|failure_domain_beta_kubernetes_io_zone)
    #     action: labeldrop


    ## AdditionalAlertManagerConfigs allows for manual configuration of alertmanager jobs in the form as specified
    ## in the official Prometheus documentation https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<alertmanager_config>.
    ## AlertManager configurations specified are appended to the configurations generated by the Prometheus Operator.
    ## As AlertManager configs are appended, the user is responsible to make sure it is valid. Note that using this
    ## feature may expose the possibility to break upgrades of Prometheus. It is advised to review Prometheus release
    ## notes to ensure that no incompatible AlertManager configs are going to break Prometheus after the upgrade.
    ##
    additionalAlertManagerConfigs: []
    # - consul_sd_configs:
    #   - server: consul.dev.test:8500
    #     scheme: http
    #     datacenter: dev
    #     tag_separator: ','
    #     services:
    #       - metrics-prometheus-alertmanager

    ## AdditionalAlertRelabelConfigs allows specifying Prometheus alert relabel configurations. Alert relabel configurations specified are appended
    ## to the configurations generated by the Prometheus Operator. Alert relabel configurations specified must have the form as specified in the
    ## official Prometheus documentation: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#alert_relabel_configs.
    ## As alert relabel configs are appended, the user is responsible to make sure it is valid. Note that using this feature may expose the
    ## possibility to break upgrades of Prometheus. It is advised to review Prometheus release notes to ensure that no incompatible alert relabel
    ## configs are going to break Prometheus after the upgrade.
    ##
    additionalAlertRelabelConfigs: []
    # - separator: ;
    #   regex: prometheus_replica
    #   replacement: $1
    #   action: labeldrop

    ## SecurityContext holds pod-level security attributes and common container settings.
    ## This defaults to non root user with uid 1000 and gid 2000.
    ## https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md
    ##
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 2000

    ## 	Priority class assigned to the Pods
    ##
    priorityClassName: ""

    ## Thanos configuration allows configuring various aspects of a Prometheus server in a Thanos environment.
    ## This section is experimental, it may change significantly without deprecation notice in any release.
    ## This is experimental and may change significantly without backward compatibility in any release.
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#thanosspec
    ##
    thanos: {}

    ## Containers allows injecting additional containers. This is meant to allow adding an authentication proxy to a Prometheus pod.
    ##
    containers: []

    ## Enable additional scrape configs that are managed externally to this chart. Note that the prometheus
    ## will fail to provision if the correct secret does not exist.
    ##
    additionalScrapeConfigsExternal: false

  additionalServiceMonitors: []
  ## Name of the ServiceMonitor to create
  ##
  # - name: ""

    ## Additional labels to set used for the ServiceMonitorSelector. Together with standard labels from
    ## the chart
    ##
    # additionalLabels: {}

    ## Service label for use in assembling a job name of the form <label value>-<port>
    ## If no label is specified, the service name is used.
    ##
    # jobLabel: ""

    ## Label selector for services to which this ServiceMonitor applies
    ##
    # selector: {}

    ## Namespaces from which services are selected
    ##
    # namespaceSelector:
      ## Match any namespace
      ##
      # any: false

      ## Explicit list of namespace names to select
      ##
      # matchNames: []

    ## Endpoints of the selected service to be monitored
    ##
    # endpoints: []
      ## Name of the endpoint's service port
      ## Mutually exclusive with targetPort
      # - port: ""

      ## Name or number of the endpoint's target port
      ## Mutually exclusive with port
      # - targetPort: ""

      ## File containing bearer token to be used when scraping targets
      ##
      #   bearerTokenFile: ""

      ## Interval at which metrics should be scraped
      ##
      #   interval: 30s

      ## HTTP path to scrape for metrics
      ##
      #   path: /metrics

      ## HTTP scheme to use for scraping
      ##
      #   scheme: http

      ## TLS configuration to use when scraping the endpoint
      ##
      #   tlsConfig:

          ## Path to the CA file
          ##
          # caFile: ""

          ## Path to client certificate file
          ##
          # certFile: ""

          ## Skip certificate verification
          ##
          # insecureSkipVerify: false

          ## Path to client key file
          ##
          # keyFile: ""

          ## Server name used to verify host name
          ##
          # serverName: ""
