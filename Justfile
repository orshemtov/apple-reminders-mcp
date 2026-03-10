set shell := ["zsh", "-cu"]

default:
  just --list

build:
  swift build

run:
  swift run apple-reminders-mcp

test:
  swift test

format:
  swift format format --in-place --recursive Sources Tests Package.swift

lint:
  swift format lint --strict --recursive Sources Tests Package.swift

check: lint test
