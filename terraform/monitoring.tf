resource "google_monitoring_uptime_check_config" "cloud1_web" {
  display_name       = "cloud-1-web-uptime"
  timeout            = "10s"
  period             = "60s"
  log_check_failures = true

  http_check {
    path           = "/"
    port           = 80
    request_method = "GET"
    use_ssl        = false

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"

    labels = {
      project_id = var.project_id
      host       = google_compute_address.cloud1_static_ip.address
    }
  }

  checker_type = "STATIC_IP_CHECKERS"
}

resource "google_monitoring_dashboard" "cloud1" {
  dashboard_json = jsonencode({
    displayName = "cloud-1-terraform"

    mosaicLayout = {
      columns = 12

      tiles = [
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4

          widget = {
            title = "CPU - cloud-1-vm"

            xyChart = {
              dataSets = [
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"agent.googleapis.com/cpu/utilization\" AND resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\""

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                }
              ]

              yAxis = {
                label = "CPU"
                scale = "LINEAR"
              }
            }
          }
        },

        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4

          widget = {
            title = "Memory - cloud-1-vm"

            xyChart = {
              dataSets = [
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = join(" AND ", [
                        "resource.type=\"gce_instance\"",
                        "resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\"",
                        "metric.type=\"agent.googleapis.com/memory/percent_used\"",
                        "metric.labels.state=\"used\""
                      ])

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                }
              ]
            }
          }
        },

        {
          xPos   = 0
          yPos   = 4
          width  = 6
          height = 4

          widget = {
            title = "Disk Usage - cloud-1-vm"

            xyChart = {
              dataSets = [
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = join(" AND ", [
                        "resource.type=\"gce_instance\"",
                        "resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\"",
                        "metric.type=\"agent.googleapis.com/disk/percent_used\"",
                        "metric.labels.device=\"/dev/sda1\"",
                        "metric.labels.state=\"used\""
                      ])

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                }
              ]
            }
          }
        },

        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4

          widget = {
            title = "Network Traffic - cloud-1-vm"

            xyChart = {
              dataSets = [
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\" AND resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\""

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                },
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/network/sent_bytes_count\" AND resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\""

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                }
              ]
            }
          }
        },

        {
          xPos   = 0
          yPos   = 8
          width  = 12
          height = 4

          widget = {
            title = "Disk Read/Write - cloud-1-vm"

            xyChart = {
              dataSets = [
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/disk/read_bytes_count\" AND resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\""

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                },
                {
                  plotType = "LINE"

                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/disk/write_bytes_count\" AND resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.cloud1_vm.instance_id}\""

                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_NONE"
                      }
                    }
                  }
                }
              ]
            }
          }
        },

        {
          xPos   = 0
          yPos   = 12
          width  = 6
          height = 4

          widget = {
            title = "Containers - Running"

            timeSeriesTable = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    prometheusQuery    = "cloud1_container_running"
                    outputFullDuration = true
                  }

                  tableDisplayOptions = {
                    shownColumns = [
                      "name",
                      "value"
                    ]
                  }
                }
              ]

              metricVisualization = "NUMBER"

              columnSettings = [
                {
                  column      = "name"
                  displayName = "Container"
                  visible     = true
                },
                {
                  column      = "value"
                  displayName = "Running (1=UP, 0=DOWN)"
                  visible     = true
                }
              ]
            }
          }
        },

        {
          xPos   = 6
          yPos   = 12
          width  = 6
          height = 4

          widget = {
            title = "Containers - Health"

            timeSeriesTable = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    prometheusQuery    = "cloud1_container_healthy"
                    outputFullDuration = true
                  }

                  tableDisplayOptions = {
                    shownColumns = [
                      "name",
                      "value"
                    ]
                  }
                }
              ]

              metricVisualization = "NUMBER"

              columnSettings = [
                {
                  column      = "name"
                  displayName = "Container"
                  visible     = true
                },
                {
                  column      = "value"
                  displayName = "Healthy (1=YES, 0=NO)"
                  visible     = true
                }
              ]
            }
          }
        },

        {
          xPos   = 0
          yPos   = 16
          width  = 6
          height = 5

          widget = {
            title = "CPU by container"

            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    prometheusQuery = <<-EOT
                      sum by (name) (
                        rate(container_cpu_usage_seconds_total{name=~"cloud1_.*"}[5m])
                      )
                    EOT
                  }

                  plotType = "LINE"
                }
              ]

              yAxis = {
                label = "CPU"
                scale = "LINEAR"
              }
            }
          }
        },

        {
          xPos   = 6
          yPos   = 16
          width  = 6
          height = 5

          widget = {
            title = "Memory by container"

            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    prometheusQuery = <<-EOT
                      sum by (name) (
                        container_memory_usage_bytes{name=~"cloud1_.*"}
                      )
                    EOT
                  }

                  plotType = "LINE"
                }
              ]

              yAxis = {
                label = "Bytes"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}

resource "google_monitoring_alert_policy" "container_unhealthy" {
  display_name = "Cloud-1 - Container unhealthy"

  combiner = "OR"

  conditions {
    display_name = "Container healthcheck failed"

    condition_prometheus_query_language {
      query = <<-EOT
        cloud1_container_healthy == 0
      EOT

      duration = "60s"
    }
  }

  documentation {
    content = <<-EOT
      One or more Cloud-1 containers failed their Docker healthcheck.

      Checks:
      - docker ps
      - docker inspect <container>
      - make health-cloud1
    EOT

    mime_type = "text/markdown"
  }

  enabled = true
}

resource "google_monitoring_alert_policy" "container_down" {
  display_name = "Cloud-1 - Container down"

  combiner = "OR"

  conditions {
    display_name = "Container stopped"

    condition_prometheus_query_language {
      query = <<-EOT
        cloud1_container_running == 0
      EOT

      duration = "60s"
    }
  }

  documentation {
    content = <<-EOT
      One or more Cloud-1 containers are not running.

      Checks:
      - docker ps
      - docker inspect <container>
      - make health-cloud1
    EOT

    mime_type = "text/markdown"
  }

  enabled = true
}
