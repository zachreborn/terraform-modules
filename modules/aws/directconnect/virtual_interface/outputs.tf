output "arn" {
  description = "The ARN of the transit virtual interface."
  value       = aws_dx_transit_virtual_interface.this.arn
}

output "id" {
  description = "The ID of the transit virtual interface."
  value       = aws_dx_transit_virtual_interface.this.id
}

output "amazon_side_asn" {
  description = "The Amazon-side ASN for the BGP session (inherited from the Direct Connect gateway)."
  value       = aws_dx_transit_virtual_interface.this.amazon_side_asn
}

output "aws_device" {
  description = "The Direct Connect endpoint on which the virtual interface terminates."
  value       = aws_dx_transit_virtual_interface.this.aws_device
}

output "jumbo_frame_capable" {
  description = "Whether jumbo frames (8500 MTU) are supported on this virtual interface."
  value       = aws_dx_transit_virtual_interface.this.jumbo_frame_capable
}
