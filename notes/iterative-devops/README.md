# Iterative Approaches to DevOps

This document lists some iterative approaches to consider when implementing DevOps practices in your organization. The goal is to provide a roadmap for gradually improving your processes without overwhelming your team.

While each section lists multiple steps, it's important to note that you don't have to implement all of them. You can pick and choose based on your team's current maturity and needs. The key is to start small, iterate, and continuously improve.

## Deployment

- Moving from manual file transfer to individual commands (e.g. rsync)

- Moving from individual commands to a script (bash or otherwise)

- Moving from a script to a dispatchable CI job (e.g. Jenkins, GitHub Actions, GitLab CI)

- Moving from a dispatchable CI job to a tag-based deployment (e.g. only deploy on a specific tag)

- Moving from a tag-based deployment to a release branch-based deployment

- Moving from a release branch-based deployment to a main branch-based deployment (i.e. continuous deployment)


## Testing

- Moving from no tests to manual tests (e.g. a checklist)

- Define basic syntax checks (e.g. `php -l`) that offer a baseline of validation with minimal overhead and chance of disruption

- Define end-to-end tests for critical paths in your application (e.g. a simple test suite using Selenium, Cypress, or similar)

- Introduce unit tests for core components of your application (e.g. using PHPUnit, PyTest, etc.)

- Add load testing to ensure your application can handle expected traffic (e.g. using tools like JMeter, Locust, or k6)

- Add security testing to identify vulnerabilities in your code (e.g. using tools like OWASP ZAP, Snyk, or similar)
