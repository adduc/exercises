# Working with metrics using Prometheus, Grafana, and Alertmanager

This exercise showcases how a "metrics stack" can be built using
Prometheus, Grafana, and Alertmanager. The stack is deployed on a
Kubernetes cluster and can be accessed via a gateway API.

## Context

I am looking to improve observability of my homelab, and wanted to implement a metrics stack using Prometheus, Grafana, and Alertmanager.

## Usage

A Makefile is provided to deploy the stack. All supported recipes can be listed by using `make help`.

The stack can be deployed using the following command:

```bash
make up
```

To stop the k3s cluster, use:

```bash
make down
```

To destroy the k3s cluster and remove all data, use:

```bash
make clean
```

## Lessons Learned

Unrelated to the metrics stack, I ran into issues with HTTPRoute resources that used regular expressions when using Traefik and Gateway API. I switched to using Nginx Gateway Fabric instead, and it worked as expected.

## Opportunities for Improvement

Grafana kicks users out when it is recreated, which should be
investigated to see if it can be avoided. This might be an indication
that persistent storage is not configured for Grafana.
