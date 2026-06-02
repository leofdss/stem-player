# Makefile — atalhos do harness do Stem Player (duas stacks, um entrypoint).
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

.PHONY: help install verify verify-all quick fmt lint test cov spec

help: ## mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

install: ## ativa hooks e instala dependências
	@bash .harness/install.sh

verify: ## verificação com escopo automático (o que mudou)
	@bash .harness/verify.sh

verify-all: ## roda todas as checagens
	@bash .harness/verify.sh --all

quick: ## só os checks rápidos (sem build/cobertura)
	@bash .harness/verify.sh --quick

fmt: ## formata Rust e frontend
	@cargo fmt --all && npm run format

lint: ## lint das duas stacks
	@cargo clippy --workspace --all-targets -- -D warnings && npm run lint

test: ## testes Rust
	@cargo test --workspace

cov: ## cobertura de stem-core
	@bash .harness/gates/rust-coverage.sh

spec: ## valida specs OpenSpec
	@bash .harness/gates/openspec-validate.sh
