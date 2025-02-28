#!/bin/bash
docker pull ryukzak/wrench:latest
docker run --rm -it --mount type=bind,source=.,target=/mnt/files ryukzak/wrench bash

