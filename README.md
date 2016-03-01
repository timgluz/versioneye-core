
# versioneye-core

This project contains the core elements of VersionEye.

 - Models & Persistence
 - Services
 - Mailers
 - Parsers
 - RabbitMQ Producers & Workers

This project is used as a dependency in all other VersionEye Ruby projects!

This project is setup and managed with [jeweler](https://www.versioneye.com/ruby/jeweler).

## Tests

The tests for this project are running after each `git push` on [CircleCI](https://circleci.com/gh/versioneye/versioneye-core)!
First of all a Docker image is build for this project and the tests are executed in a Docker container.
For more details take a look to the Dockerfile and the circle.yml file in the root directory!

If the Docker containers for the backend systems are running locally, the tests can be executed locally
with this command:

```
./scripts/runtests_local.sh
```

For that the ENV variables in the `runtests_local.sh` script need to be adjusted that way, that they point
to the backend systems.

