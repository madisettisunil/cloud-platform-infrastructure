# Default values for opa.
# -----------------------
#
# The 'opa' key embeds an OPA configuration file. See
# https://www.openpolicyagent.org/docs/configuration.html for more details.
opa:
  # services:
  #   controller:
  #     url: "https://www.openpolicyagent.org"
  # bundle:
  #   service: controller
  #   name: "helm-kubernetes-quickstart"
  # default_decision: "/helm_kubernetes_quickstart/main"

# To enforce mutating policies, change to MutatingWebhookConfiguration.
admissionControllerKind: ValidatingWebhookConfiguration

# To _fail closed_ on failures, change to Fail. During initial testing, we
# recommend leaving the failure policy as Ignore.
admissionControllerFailurePolicy: Fail
# Adds a namespace selector to the admission controller webhook
admissionControllerNamespaceSelector:
  matchExpressions:
    - {key: openpolicyagent.org/webhook, operator: NotIn, values: [ignore]}
# To restrict the kinds of operations and resources that are subject to OPA
# policy checks, see the settings below. By default, all resources and
# operations are subject to OPA policy checks.
admissionControllerRules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["extensions"]
    apiVersions: ["*"]
    resources: ["ingresses"]
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["services"]
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]

# Controls a PodDisruptionBudget for the OPA pod. Suggested use if having opa
# always running for admission control is important
podDisruptionBudget:
  enabled: false
  minAvailable: 1
# maxUnavailable: 1

# The helm Chart will automatically generate a CA and server certificate for
# the OPA. If you want to supply your own certificates, set the field below to
# false and add the PEM encoded CA certificate and server key pair below.
#
# WARNING: The common name name in the server certificate MUST match the
# hostname of the service that exposes the OPA to the apiserver. For example.
# if the service name is created in the "default" nanamespace with name "opa"
# the common name MUST be set to "opa.default.svc".
#
# If the common name is not set correctly, the apiserver will refuse to
# communicate with the OPA.
generateAdmissionControllerCerts: true
admissionControllerCA: ""
admissionControllerCert: ""
admissionControllerKey: ""

authz:
  # Disable if you don't want authorization.
  # Mostly useful for debugging.
  enabled: true

# Docker image and tag to deploy.
image: openpolicyagent/opa
imageTag: 0.10.7
imagePullPolicy: IfNotPresent

mgmt:
  enabled: true
  image: openpolicyagent/kube-mgmt
  imageTag: 0.8
  imagePullPolicy: IfNotPresent
  extraArgs: []
  resources: {}
  configmapPolicies:
    enabled: true
    namespaces: [opa] # kube-mgmt automatically discovers policies stored in ConfigMaps,created in a namespace listed here.
    requireLabel: true
  replicate:
# NOTE IF you use these, remember to update the RBAC rules above to allow
#      permissions to replicate these things
    cluster:
      - "v1/namespaces"
    namespace:
      - "extensions/v1beta1/ingresses"
    path: kubernetes

# Log level for OPA ('debug', 'info', 'error') (app default=info)
logLevel: info

# Log format for OPA ('text', 'json') (app default=text)
logFormat: text

# Number of OPA replicas to deploy. OPA maintains an eventually consistent
# cache of policies and data. If you want high availability you can deploy two
# or more replicas.
replicas: 2

# To control how the OPA is scheduled on the cluster, set the tolerations and
# nodeSelector values below. For example, to deploy OPA onto the master nodes:
#
# tolerations: [{key: "node-role.kubernetes.io/master", effect: NoSchedule, operator: Exists}]
# nodeSelector: {"kubernetes.io/role": "master"}
tolerations: []
nodeSelector: {}

# To control the CPU and memory resource limits and requests for OPA, set the
# field below.
resources: {}

rbac:
  # If true, create & use RBAC resources
  #
  create: true
  rules:
    cluster:
    - apiGroups:
        - ""
      resources:
      - configmaps
      verbs:
      - update
      - patch
      - get
      - list
      - watch
    - apiGroups:
        - ""
      resources:
      - namespaces
      verbs:
      - get
      - list
      - watch
    - apiGroups:
        - extensions
      resources:
      - ingresses
      verbs:
      - get
      - list
      - watch

serviceAccount:
  # Specifies whether a ServiceAccount should be created
  create: true
  # The name of the ServiceAccount to use.
  # If not set and create is true, a name is generated using the fullname template
  name:

# This proxy allows opa to make Kubernetes SubjectAccessReview checks against the
# Kubernetes API. You can get a rego function at github.com/open-policy-agent/library
sar:
  enabled: false
  image: lachlanevenson/k8s-kubectl
  imageTag: latest
  imagePullPolicy: IfNotPresent
  resources: {}

# To control the liveness and readiness probes change the fields below.
readinessProbe:
  httpGet:
    path: /
    scheme: HTTPS
    port: 443
    initialDelaySeconds: 3
    periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    scheme: HTTPS
    port: 443
    initialDelaySeconds: 3
    periodSeconds: 5
