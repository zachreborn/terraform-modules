#cloud-config 
velocloud:
  vce:
    vco: ${velocloud_orchestrator}
    activation_code: ${velocloud_activation_key}
    vco_ignore_cert_errors: ${velocloud_ignore_cert_errors}