# Expects a the ingress template to exist at fixture_name
def create_ingress(namespace, ingress_name, fixture_name)
  apply_template_file(
    namespace: namespace,
    file: fixture_name,
    binding: binding
  )
  wait_for(namespace, "ingress", ingress_name, 60)
end

# delete ingress if namespace and ingress exist
def delete_ingress(namespace, ingress_name)
  if namespace_exists?(namespace) && object_exists?(namespace, "ingress", ingress_name)
    execute("kubectl delete ingress #{ingress_name} -n #{namespace}")
  end
end

# Returns an ingress endpoint (ELB enpoint)
def get_ingress_endpoint(namespace, ingress_name)
  stdout, _, _ = execute("kubectl get ingress #{ingress_name} -n #{namespace} -o json -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'")
  stdout
end

# Dedicated to A record created by External DNS
# TODO: sleep added to avoid AWS Route53 API throttling errors. Remove once that issue is resolved.
def delete_a_record(zone_id, zone_name, domain_name, namespace, ingress_name)
  sleep 1
  client = Aws::Route53::Client.new

  a_record = {
    action: "DELETE",
    resource_record_set: {
      name: domain_name,
      alias_target: {
        # ZD4D7Y8KGAS4G this zone is the default AWS zone for ELB records, in eu-west-2
        "hosted_zone_id": "ZD4D7Y8KGAS4G",
        "dns_name": get_ingress_endpoint(namespace, ingress_name) + ".",
        "evaluate_target_health": true,
      },
      type: "A",
    },
  }

  client.change_resource_record_sets({
    hosted_zone_id: zone_id,
    change_batch: {
      changes: [a_record],
    },
  })
end

# Dedicated to deleting TXT records created by external-dns
# TODO: sleep added to avoid AWS Route53 API throttling errors. Remove once that issue is resolved.
def delete_txt_record(zone_id, zone_name, domain_name, namespace)
  sleep 1
  client = Aws::Route53::Client.new
  txt_record = {
    action: "DELETE",
    resource_record_set: {
      name: "_external_dns.#{domain_name}",
      ttl: 300,
      resource_records: [
        {
          value: %("heritage=external-dns,external-dns/owner=default,external-dns/resource=ingress/#{namespace}/#{domain_name}"),
        },
      ],
      type: "TXT",
    },
  }

  client.change_resource_record_sets({
    hosted_zone_id: zone_id,
    change_batch: {
      changes: [txt_record],
    },
  })
end

# Checks if the zone is empty, then deletes
# if not empty, it will assume it contains one A record and one TXT record created by external-dns
def cleanup_zone(zone, domain, namespace, ingress_name)
  if is_zone_empty?(zone.hosted_zone.id)
    delete_zone(zone.hosted_zone.id)
  else
    delete_a_record(zone.hosted_zone.id, zone.hosted_zone.name, domain, namespace, ingress_name)
    delete_txt_record(zone.hosted_zone.id, zone.hosted_zone.name, domain, namespace)
    delete_zone(zone.hosted_zone.id)
  end
end

# Checks if a zone is empty
# A zone is considered empty if it only contains one SOA and one NS record
# TODO: sleep added to avoid AWS Route53 API throttling errors. Remove once that issue is resolved.
def is_zone_empty?(zone_id)
  sleep 1
  records = get_zone_records(zone_id)
  # If there is any more than 2 records, the zone is not empty
  !(records.size > 2)
end
