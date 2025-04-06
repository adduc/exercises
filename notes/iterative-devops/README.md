# Iterative Approaches to DevOps

This document lists some iterative approaches to consider when implementing DevOps practices in your organization. The goal is to provide a roadmap for gradually improving your processes without overwhelming your team.

While each section lists multiple steps, it's important to note that you don't have to implement all of them. You can pick and choose based on your team's current maturity and needs. The key is to start small, iterate, and continuously improve.

## Context

I have worked for a number of companies at varying stages of their DevOps journey, from manually deploying code via FTP to fully automated continuous deployment pipelines. In my experience, trying to implement a full DevOps transformation in one go is often overwhelming and can lead to teams rejecting the changes altogether. Instead, I have found that taking an iterative approach allows teams to gradually adopt new practices, build confidence, and ultimately achieve a more efficient and reliable software delivery process.

## Deployment

It is commonly suggested that you should "deploy early and often," but this can be daunting to teams that are early in their DevOps journey. Instead, consider what workflow you would like to achieve and consider steps that move you closer to that goal. Here are some examples of how you can iteratively improve your deployment process:

- Are you deploying by manually copying files up or editing files on server? Consider moving to command-based solutions like `rsync` or `scp` to automate the process.

- If your deployment process involves following a series of manual commands, consider creating a simple script (e.g. a bash script) that encapsulates those commands. This will reduce the chance of human error and make it easier to repeat the deployment process.

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
