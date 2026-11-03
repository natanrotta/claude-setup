# DevOps / Deploy Knowledge

> **Fonte única (single source of truth)** da infra de produção do projeto: arquitetura + runbook +
> backlog + gotchas verificados contra o código. Os **artefatos reais** (composes, Caddyfile, WireGuard,
> scripts de backup, `.env.prod.example`) vivem em **`infra/`** — este doc descreve e **aponta** para eles
> (sem duplicar YAML, evita drift). Operações do dia a dia: **`Makefile`** (`make help`). Guia enxuto do
> deploy (comandos): **`DEPLOY.md`** na raiz.

## Status

- (none yet)

## Topologia (resumo)

- (none yet)

## Por que VPS e não serverless (verificado no código)

- (none yet)

## O processo da API (verificado em `apps/api/src/main.ts`)

- (none yet)

## Inventário de serviços e portas

- (none yet)

## Variáveis de ambiente

- (none yet)

## Versão & verificação ("a versão certa subiu?") — o ativo central

- (none yet)

## Dockerfile.prod — gotchas (verificados)

- (none yet)

## Frontends (Cloudflare Pages)

- (none yet)

## VPS-APP — Caddy + Cloudflare (gotchas)

- (none yet)

## VPS-DATA — Postgres + pgvector + Redis

- (none yet)

## CI/CD (GHCR — build manual + boot-smoke + deploy 1-clique com verify + auto-rollback)

- (none yet)

## Monitoramento

- (none yet)

## Backup 3-2-1

- (none yet)

## Custos (mensal estimado)

- (none yet)

## Decisões travadas

- (none yet)

## Gaps / backlog

- (none yet)

## Dead ends / open questions

- (none yet)

## Provisionar do zero (runbook condensado)

- (none yet)
