# TulipaBuilder.jl

A graph-based constructive user interface for TulipaEnergyModel.jl that provides the simplest possible way to build energy system models.

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://TulipaEnergy.github.io/TulipaBuilder.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://TulipaEnergy.github.io/TulipaBuilder.jl/dev)
[![Test workflow status](https://github.com/TulipaEnergy/TulipaBuilder.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/TulipaEnergy/TulipaBuilder.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/TulipaEnergy/TulipaBuilder.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/TulipaEnergy/TulipaBuilder.jl)
[![Docs workflow Status](https://github.com/TulipaEnergy/TulipaBuilder.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/TulipaEnergy/TulipaBuilder.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

## Overview

TulipaBuilder.jl provides a graph-based approach to building energy system models compatible with TulipaEnergyModel.jl. The package uses assets (producers, consumers) as vertices and flows as edges, built on MetaGraphsNext.jl as the underlying data structure.

## Key Features

- **Graph-based modeling**: Intuitive representation of energy systems as connected assets
- **Schema-driven design**: Dynamically compatible with different TulipaEnergyModel.jl versions
- **Simplified workflow**: Streamlined process from model creation to optimization

## Target Users

- **End-users** looking to create Tulipa models with maximum convenience
- **Developers** generating case studies for benchmarking, testing, and validation

## AI Coding Assistant Attribution

We use and accepts pull requests with AI coding assistants to help with development, but we expect the committers to understand and be responsible for the code that they introduce.
All commits that receive AI assistance should be signed off with:

```plaintextt
Co-authored-by: MODEL NAME (FULL MODEL VERSION) <EMAIL>
```

For example:

```plaintextt
Co-authored-by: Claude Code (claude-sonnet-4-20250514) <noreply@anthropic.com>
```
