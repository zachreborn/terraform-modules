output "digest_algorithm_mnemonic" {
  value = aws_route53_key_signing_key.dnssec.digest_algorithm_mnemonic
}

output "digest_algorithm_type" {
  value = aws_route53_key_signing_key.dnssec.digest_algorithm_type
}

output "digest_value" {
  value = aws_route53_key_signing_key.dnssec.digest_value
}

output "dnskey_record" {
  value = aws_route53_key_signing_key.dnssec.dnskey_record
}

output "ds_record" {
  value = aws_route53_key_signing_key.dnssec.ds_record
}

output "flag" {
  value = aws_route53_key_signing_key.dnssec.flag
}

output "key_tag" {
  value = aws_route53_key_signing_key.dnssec.key_tag
}

output "public_key" {
  value = aws_route53_key_signing_key.dnssec.public_key
}

output "signing_algorithm_mnemonic" {
  value = aws_route53_key_signing_key.dnssec.signing_algorithm_mnemonic
}

output "signing_algorithm_type" {
  value = aws_route53_key_signing_key.dnssec.signing_algorithm_type
}
