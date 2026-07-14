# Regression coverage for a typo fix in the configurations output: the map
# previously exported insider_cidr_blocks instead of inside_cidr_blocks. The
# corrected key is added, and the misspelled key is kept as a deprecated
# backward-compatible alias so existing callers are not broken.
#
# NOTE: this file intentionally has a unique name so it does not collide with
# the comprehensive tests/connect.tftest.hcl added by the separate native-
# test-coverage PR. Once that PR merges, its own coverage for these outputs
# supersedes this file, and this file can be removed.
mock_provider "aws" {}

run "configurations_output_exposes_both_the_corrected_key_and_the_deprecated_alias" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers = {
      sdwan_vedge_1 = {
        inside_cidr_blocks = ["169.254.6.0/29"]
        peer_address       = "203.0.113.11"
      }
    }
  }

  assert {
    condition     = length(output.configurations["sdwan_vedge_1"].inside_cidr_blocks) == 1
    error_message = "configurations output should expose the corrected inside_cidr_blocks key."
  }

  assert {
    condition     = output.configurations["sdwan_vedge_1"].insider_cidr_blocks == output.configurations["sdwan_vedge_1"].inside_cidr_blocks
    error_message = "The deprecated insider_cidr_blocks alias should still be exported and match inside_cidr_blocks, so existing callers relying on the misspelled key are not broken."
  }
}
