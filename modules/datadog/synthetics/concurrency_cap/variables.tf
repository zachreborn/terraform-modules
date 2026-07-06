###########################
# Resource Variables
###########################
variable "on_demand_concurrency_cap" {
  description = "Value of the on-demand concurrency cap, customizing the number of Synthetic tests run in parallel. Value must be at least 1."
  type        = number

  validation {
    condition     = var.on_demand_concurrency_cap >= 1
    error_message = "on_demand_concurrency_cap must be at least 1."
  }
}
