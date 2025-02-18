#!/bin/sh
set -e

mix deps.get

mix setup

mix phx.server