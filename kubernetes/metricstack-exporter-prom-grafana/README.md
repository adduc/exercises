# Working with metrics using Prometheus, Grafana, and Alertmanager

This exercise showcases how a "metrics stack" can be built using
Prometheus, Grafana, and Alertmanager. The stack is deployed on a
Kubernetes cluster and can be accessed via a gateway API.


## Lessons Learned

Unrelated to the metrics stack, I ran into issues with HTTPRoute resources that used regular expressions when using Traefik and Gateway API. I switched to using Nginx Gateway Fabric instead, and it worked as expected.
