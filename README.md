# dockeresmon

**dockeresmon** is a shell script for monitoring docker container resource usage (currently only memory and CPU).

It is intended to be used with a job scheduler like [cron](https://en.wikipedia.org/wiki/Cron) to run a certain command when some docker container is seen using more resources than it should a certain number of times. I highly suggest you take a look at the source code if you're interested (it's only around 100 lines). The following diagram briefly explains how this tool works:

<div align="center">
<img src="https://github.com/NULLHE4D/dockeresmon/blob/master/images/diagram.png?raw=true">
</div>

## Table of contents

  * [Usage](#usage)
     * [Configuration](#configuration)
     * [Example](#example)
  * [Dependencies](#dependencies)
  * [Gotchas](#gotchas)
  * [License](#license)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

## Usage

### Configuration

**dockeresmon** accepts a JSON configuration file that determines how it should behave (see [example.json](example.json)). It should contain an array of objects where each object represents a set of rules meant for a single docker container. The following table lists the available keys of these objects:

| Key | Description |
| --- | --- |
| container | name of the container |
| cpu_threshold | CPU usage threshold (percentage) |
| cpu_command | callback command to run when the 'CPU counter' is one of the *cpu_intervals* |
| cpu_intervals | |
| memory_threshold | memory usage threshold (percentage) |
| memory_command | callback command to run when the 'memory counter' is one of the *memory_intervals* |
| memory_intervals | |

### Example

Assuming you're configuration file is all set, you can put the following cronjob entry in the crontab of a user with the right permissions (see [Gotchas](#gotchas)):

```
* * * * * /home/foo/scripts/dockeresmon/dockeresmon.sh -c /home/foo/scripts/dockeresmon/config.json
```

Note that the configuration file is provided using the `-c` flag.

## Dependencies

- docker
- [jq](https://stedolan.github.io/jq/)

## Gotchas

- Make sure that the user to run this script is either *root* or is in the [*docker group*](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)
- If you haven't guessed already, **dockeresmon** is prone to false-positives and false-negatives when scheduled to run in minutes intervals since containers' resource usage can coincidentally spike/drop just when **dockeresmon** executes. This can be mitigated if you use a job scheduler that is able to schedule jobs to run in seconds intervals (cron can't do this AFAIK) with high *xxx_intervals* values.

## License

This project is unworthy of a license. Do anything you like with it. :wink:

