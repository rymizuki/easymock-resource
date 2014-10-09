# easymock-resource [![Build Status](https://secure.travis-ci.org/rymizuki/easymock-resource.png?branch=master)](https://travis-ci.org/rymizuki/easymock-resource) 

UI variation management extension for [node-easymock](https://github.com/CyberAgent/node-easymock).

**This repository is still under development!**

## Installation

```shell
npm install --save 'git://github.com/rymizuki/easymock-resource.git'
```

## Get started

Write variation definition.

```json:easymock-resource.config.json
{
  "cwd": "easymock/resrouce/",
  "dest": "easymock/",
  "variations": {
    "default":      "api/**/*.default.json",
    "unauthorized": "api/**/*.unauthorized.json"
  }
}
```

and launch easymock.

```shell
easymock --port 3000 --variation unauthorized --config easymock-resource.config.json
```

## Documantation

### Configure

#### cwd

#### dest

#### variations
