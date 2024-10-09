variable "region" {
    default     = "us-west-2"
    type = string
    description = "AWS Region to deploy to"
}

variable "bucket_name" {
  default = "metronome-webhook-events"
  type=string
}

variable "events_delete_from_s3_in_days" {
  default = 3
  type = number
}