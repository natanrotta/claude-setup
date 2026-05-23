<div align="center">

<sub>· TEMPLATE PARA CLAUDE CODE ·</sub>

# claude-setup

**Um bootstrap conversacional para o Claude Code.**
Coloca o `.claude/` num repo zerado, conversa com ele por dez minutos, e você tem um workspace inteiro afinado — task lifecycle, self-audit loop, pattern docs, hooks, specialists, telemetria. Tudo moldado pro projeto que você descreveu.

[Início rápido](#início-rápido) · [Como funciona](#como-funciona) · [O que você ganha](#o-que-você-ganha) · [A conversa em 5 fases](#a-conversa-em-5-fases) · [Lifecycle](#lifecycle-depois-do-bootstrap) · [Mantendo vivo](#mantendo-o-setup-vivo)

</div>

---

## Por que isso existe

Configurar o Claude Code direito leva uma semana de tentativa e erro. Você escreve o primeiro agente, descobre que ficou genérico demais. Adiciona hooks, percebe que as regexes de grep precisam casar com o seu stack. Monta o checklist de code review, transforma em BASELINE, configura os comandos de lifecycle. Quando tá bom, você gastou quarenta horas.

Aí começa o próximo projeto. Nada disso aproveita direto — as regexes apontam pra paths errados, os patterns docs referenciam módulos que não existem, os specialists conhecem o stack errado. Então você copia, edita à mão, e perde mais meia semana.

O `claude-setup` reduz isso a uma conversa de dez minutos. A espinha portável — triage, audit loop, comandos de lifecycle — vem intacta. As partes específicas do projeto — códigos de anti-pattern, regexes de hook, regras do BASELINE, roteamento dos specialists — são preenchidas por uma meta-skill que te entrevista sobre o projeto e renderiza os templates.

---

## Início rápido

### Setup uma vez por máquina (5 segundos)

Clone o template num cache local — qualquer projeto futuro reusa esse clone:

```bash
git clone git@github.com:natanrotta/claude-setup.git ~/.claude-setup
```

Adiciona um alias no seu shell (`~/.zshrc` / `~/.bashrc`):

```bash
alias claude-install='bash ~/.claude-setup/scripts/install.sh'
```

Pronto.

### Em qualquer projeto novo (3 comandos)

```bash
cd meu-projeto-novo
claude-install      # copia .claude/ do cache (auto-atualiza via git pull)
claude              # abre o Claude Code
```

Dentro do Claude Code:

```
/bootstrap-claude
```

A skill te cumprimenta, escaneia o repo procurando pistas (`package.json`, `Cargo.toml`, etc.) e abre uma conversa. Cinco fases. Por volta de dez minutos. No fim você confirma um blueprint visual em HTML, o bootstrap escreve os arquivos renderizados, e você já tá trabalhando.

<details>
<summary><b>Por que não <code>npx degit</code>?</b></summary>

`degit` não autentica em repos privados — ele baixa tarballs anônimos do GitHub. Se o `claude-setup` for público, esses comandos funcionam:

```bash
npx degit natanrotta/claude-setup/.claude .claude
# ou
curl -L https://github.com/natanrotta/claude-setup/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=2 -C . claude-setup-main/.claude
```

O `install.sh` foi feito pra funcionar nas duas situações (público e privado), porque ele usa `git clone` com a autenticação que você já tem configurada (gh CLI, chaves SSH ou credential helper HTTPS).

</details>

<details>
<summary><b>Acompanhar updates do template em vários projetos (git submodule)</b></summary>

```bash
git submodule add git@github.com:natanrotta/claude-setup .claude-upstream
ln -s .claude-upstream/.claude .claude
```

Aí `git submodule update --remote` em cada projeto consumidor puxa as mudanças do template.

</details>

---

## Como funciona

```mermaid
flowchart LR
    A[Repo vazio] -->|degit .claude/| B[Template copiado]
    B -->|/bootstrap-claude| C{Fase 1<br/>Produto}
    C -->|fecha| D{Fase 2<br/>Stack}
    D -->|fecha| E{Fase 3<br/>Padrões}
    E -->|fecha| F{Fase 4<br/>Estilos}
    F -->|fecha| G{Fase 5<br/>Quality}
    G -->|/preview-blueprint| H[HTML no browser]
    H -->|aprovado| I[arquivos .tpl renderizados<br/>.claude/ real escrito]
    I --> J[Primeira task:<br/>/triage]
    J -.->|meses depois| K[/evolve-claude]
    K -.-> I

    style B fill:#1e2530,stroke:#6e8cff,color:#e6edf3
    style H fill:#1e2530,stroke:#6e8cff,color:#e6edf3
    style I fill:#1e2530,stroke:#34c69b,color:#e6edf3
    style J fill:#1e2530,stroke:#34c69b,color:#e6edf3
```

Três peças móveis trabalhando juntas:

| Peça | O que é | Onde mora |
|---|---|---|
| **Espinha portável** | Agentes e comandos agnósticos de stack — triage, code-auditor, code-reviewer, duck-debug, comandos de lifecycle. Copiados como estão pro seu projeto. | `.claude/agents/`, maior parte de `.claude/commands/` |
| **Templates** | Arquivos `.tpl` com placeholders `{{MUSTACHE}}` pra códigos de anti-pattern, regexes de hook, regras do BASELINE, roteamento dos specialists. Renderizados no bootstrap. | `.claude/patterns/*.tpl`, `.claude/hooks/*.tpl`, `.claude/CLAUDE.md.tpl`, `.claude/settings.json.tpl` |
| **Meta-skills** | O cérebro. `/bootstrap-claude` conduz a conversa, `/preview-blueprint` renderiza o HTML de confirmação, `/evolve-claude` refina o setup ao longo do tempo. | `.claude/commands/{bootstrap-claude,preview-blueprint,evolve-claude}.md` |

---

## O que você ganha

Depois que o bootstrap termina, o seu projeto tem um `.claude/` parecido com isso — mas o **conteúdo** tá afinado pro seu stack específico:

```
seu-projeto/
├── .claude/
│   ├── CLAUDE.md                       Contrato de lifecycle + roteamento
│   ├── agents/
│   │   ├── code-auditor.md             Reviewer mecânico L1 (grep + códigos)
│   │   ├── code-reviewer.md            Reviewer semântico L2 (julgamento)
│   │   ├── duck-explainer.md           Verbaliza a mudança em prosa
│   │   ├── duck-challenger.md          Questiona a explicação, cego ao código
│   │   ├── triage-architect.md         Perspectiva arquitetural
│   │   ├── triage-engineer.md          Perspectiva DRY + testes
│   │   └── triage-product.md           Perspectiva valor pro usuário + MVP
│   ├── commands/
│   │   ├── start-task.md               Criação de worktree + branch
│   │   ├── triage.md                   Gate pré-dev com 3 perspectivas
│   │   ├── code-review.md              Wrapper → subagent code-reviewer
│   │   ├── normalize.md                Dispatcher de auditoria read-only
│   │   ├── duck-debug.md               Orquestrador do rubber-duck
│   │   ├── check.md                    Loop de type + lint + format + test
│   │   ├── finish-task.md              Cobertura → review → check → PR
│   │   ├── finish.md                   Criação do PR
│   │   ├── cleanup-task.md             Remove worktree + branch local
│   │   ├── brainstorm.md               Design divergente
│   │   ├── architect.md                Spec pesada pra features L
│   │   ├── evolve-claude.md            Skill de refinamento do setup
│   │   └── <specialists>.md            /backend, /frontend, /fullstack, ...
│   ├── hooks/
│   │   ├── post-edit-backend.sh        Regexes de anti-pattern por camada
│   │   ├── post-edit-frontend.sh       Regexes de anti-pattern por camada
│   │   └── check-test-coverage.sh      Gate de cobertura (se ativado)
│   ├── patterns/
│   │   ├── BASELINE.md                 Não-negociáveis (R1–Rn) do seu stack
│   │   └── code-review-checklist.md    Catálogo completo de anti-patterns
│   ├── knowledge/                      Cresce conforme os agentes aprendem
│   ├── learning/
│   │   ├── protocol.md                 Contrato de telemetria + knowledge
│   │   └── violations.md               Ledger append-only
│   └── settings.json                   Hooks wired + permissions allow-list
```

Os arquivos `.tpl` somem depois do bootstrap — são renderizados na forma final e removidos.

<details>
<summary><b>Exemplo: como ficam as regras do BASELINE geradas</b></summary>

Pra um projeto `Node + Express + Prisma + Postgres` com modelo multi-tenant, o bootstrap gera regras tipo:

> **R1** — Toda query Prisma (read E write) em tabela multi-tenant filtra pela coluna de tenant.  Âncora: `B-C1`.
> **R2** — Toda read filtra rows soft-deletadas (`deleted_at: null`).  Âncora: `B-C2`.
> **R4** — Erros usam subclasses de `AppError` com `ErrorCode`. Nunca `throw new Error(...)`.  Âncora: `B-C4`.

Pra um frontend `React + Chakra + TanStack Query`:

> **R10** — Só tokens semânticos (`bg.*`, `text.*`, `border.*`). Sem hex hardcoded.  Âncora: `F-C2`.
> **R14** — Toda mutation tem `onError`. `invalidateQueries` é seletivo — nunca `queryKeys.X.all` a menos que todas as sub-keys sejam genuinamente afetadas.  Âncora: `F-C5`, `F-C6`.

Os códigos (`B-C1`, `F-C2`) são citados pelo auditor, pelo reviewer e pelos hooks — um vocabulário só por toda a stack de qualidade.

</details>

---

## A conversa em 5 fases

O bootstrap é estruturado como diálogo, não formulário. Cada fase discute um tópico por vez, fecha com uma síntese de uma linha, pede permissão antes de avançar.

| # | Fase | O que captura | Pula quando… |
|---|---|---|---|
| 1 | **Produto** | One-liner, persona primária, domínio, top 3–5 features do MVP, idioma da UI | Nunca — sempre roda |
| 2 | **Stack** | Linguagem, frameworks, camada de dados, package manager, formato monorepo, deploy target | Nunca |
| 3 | **Padrões** | Estilo arquitetural, validação, error handling, DI | Stack opinionado já decide (Next.js, NestJS, Rails) |
| 4 | **Estilos & UI** | Design system, disciplina de cor, tema, i18n, forms | Projetos só de backend |
| 5 | **Quality gates** | Specialists, branch base, política de cobertura, pre-commit, ticket tracker | Nunca |

O bot abre com o que detectou (do `package.json`, `README.md`, estrutura de arquivos) e toma posição: *"vi Node + TS + React no `package.json`; backend Express, ou prefere NestJS?"*. Você corrige numa frase. A conversa anda.

O idioma em que você responder a primeira vez fica travado pra entrevista inteira **e** pra todo artefato renderizado — `CLAUDE.md`, `BASELINE.md`, blueprint HTML, mensagens de commit, descrições de PR. Sem mistura.

---

## Lifecycle depois do bootstrap

```mermaid
flowchart TD
    A[Usuário descreve a task em linguagem natural] --> B{Worktree?}
    B -->|"crie um worktree"| C[/start-task]
    B -->|default| D[Modo inline]
    C --> E[/triage]
    E --> F[Architect + Engineer + Product<br/>em paralelo]
    F --> G[Pre-dev brief unificado]
    G --> H[Specialist implementador<br/>/backend, /frontend, etc.]
    D --> H
    H --> I[BABYSIT loop]
    I --> J[L1 code-auditor<br/>grep mecânico]
    J --> K[L2 code-reviewer<br/>julgamento semântico]
    K --> L{Task M/L?}
    L -->|sim| M[L3 /duck-debug<br/>diálogo rubber-duck]
    L -->|não| N[Handoff]
    M --> N
    N -->|inline| O[Para. Usuário decide o próximo passo.]
    N -->|worktree| P[/finish-task]
    P --> Q[Gate de cobertura → /code-review →<br/>/check → /finish → PR]
    Q --> R[Após merge: /cleanup-task]

    style F fill:#1e2530,stroke:#6e8cff,color:#e6edf3
    style J fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style K fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style M fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style Q fill:#1e2530,stroke:#34c69b,color:#e6edf3
```

**Três níveis de self-audit rodam automaticamente.** L1 (`code-auditor`) é mecânico — passa grep no diff procurando códigos de anti-pattern conhecidos. L2 (`code-reviewer`) é semântico — lê o diff como um engenheiro sênior leria, pega o que regex não pega. L3 (`/duck-debug`) é verbalização — força o implementador a explicar a mudança em prosa pra um pato que não enxerga o código; a falha na explicação é a falha do design.

Todo achado Critical/High vai pro `learning/violations.md`. Esse é o combustível pra próxima fase.

---

## Mantendo o setup vivo

O setup apodrece se nada atualiza ele. Módulos novos aparecem. Bibliotecas novas entram. A mesma violação aparece toda semana no `violations.md` e ninguém promove. O `/evolve-claude` é o antídoto.

```bash
/evolve-claude
```

Ele roda três pesquisas em paralelo:

- **Violações recorrentes.** Qualquer código com ≥5 hits nos últimos 30 dias vira candidato a virar regex de hook (enforcement em tempo de escrita) ou regra nova do BASELINE.
- **Módulos novos.** Commits recentes adicionaram pastas que ainda não têm entrada em `knowledge/<modulo>.md`.
- **Drift de stack.** O `package.json` (ou equivalente do seu stack) ganhou uma dependência top-level que muda arquitetura — ORM novo, biblioteca de estado nova, runner de testes novo.

Apresenta tudo numa proposta batched. Você escolhe o que promover, o que ignorar, o que adiar. O setup fica mais afiado.

Pra refinamentos pontuais tem os modos:

```bash
/evolve-claude --promote-hook B-C99       # wira um código específico nos hooks
/evolve-claude --add-knowledge payments   # cria knowledge file pra um módulo
/evolve-claude --refine-stage padroes     # reabre uma fase do bootstrap
/evolve-claude --reset                    # re-bootstrap completo (preserva knowledge/ + violations.md)
```

---

## Filosofia de design

**Front-load do entendimento, depois sai do caminho.** Todas as decisões arquiteturais capturadas em 5 rodadas de conversa no início. Depois disso, o usuário descreve tasks em linguagem natural e o lifecycle dirige sozinho. Sem micro-decisões, sem "você quer usar X ou Y aqui?".

**Toma posição, não entrevista.** O bootstrap abre com o que detectou: *"vi Node + Express no `apps/api`; continua Prisma ou prefere Drizzle?"*. Usuário corrige mais rápido do que origina. Pergunta aberta multiplica trabalho.

**Confirmação visual antes de escrever.** O blueprint HTML é o contrato. Você vê o setup inteiro numa página — stack, códigos, hooks, specialists, árvore de arquivos — antes de qualquer arquivo cair no disco. Screenshots são compartilháveis; o blueprint vira artefato do time.

**Espinha portável + preenchimento específico do projeto.** Os agentes e o lifecycle são universais — funcionam igual no Cuidda, numa crate Rust, numa pipeline Python. Os códigos, hooks, regras do BASELINE são afinados por projeto. Por isso as duas metades atualizam independente — bumpa a espinha via `degit --force`, refina as partes do projeto via `/evolve-claude`.

**Evolução orientada por telemetria.** Toda violação Critical/High logada num ledger estruturado. Padrões recorrentes promovidos pra hooks ou BASELINE. O setup não chuta o que enforcar — ele observa o que tá quebrando e aperta exatamente essas regras.

---

## FAQ

<details>
<summary><b>Funciona pra projetos que não são TypeScript / Node?</b></summary>

A espinha portável (agentes, comandos de lifecycle, gate de triage, BABYSIT loop) é totalmente agnóstica de linguagem. A entrevista do bootstrap pergunta sobre o seu stack e renderiza os templates conforme.

O catálogo built-in de anti-patterns hoje tem cobertura melhor pra Node + TS + React + Prisma + Postgres (stack de onde esse template foi destilado). Outros stacks (Python, Go, Rust, Ruby) funcionam mas vêm com menos códigos pré-construídos — você vai crescer o catálogo mais rápido via `/evolve-claude`. PRs adicionando cobertura de catálogo pra stacks novos são bem-vindos.

</details>

<details>
<summary><b>E se eu já tenho um `.claude/` no projeto?</b></summary>

O `degit` se recusa a sobrescrever. Duas opções:

1. Faz backup do seu `.claude/` existente, roda o `degit`, depois porta suas customizações pra espinha portável nova.
2. Usa `degit --force` se tiver certeza — mas perde qualquer agente ou comando customizado que você escreveu.

O modo `/evolve-claude --reset` foi feito pra esse caso — preserva `knowledge/` e `learning/violations.md` enquanto regenera o resto. Se você rodou o bootstrap original, prefere isso ao `degit --force`.

</details>

<details>
<summary><b>Dá pra compartilhar o mesmo setup entre vários repos?</b></summary>

Dá, via importação por `git submodule` (Opção C do Início rápido). O submódulo acompanha o upstream do `claude-setup` — quando você puxa updates upstream, todo projeto consumidor que rodar `git submodule update` recebe a espinha portável nova.

Os arquivos específicos do projeto (`patterns/BASELINE.md`, os hooks renderizados) continuam dentro do repo de cada consumidor, então podem divergir por projeto sem poluir a espinha compartilhada.

</details>

<details>
<summary><b>O blueprint HTML é compartilhável?</b></summary>

É. Arquivo único self-contained — sem CSS externo, sem fontes, sem imagens. Você pode screenshotar, anexar o arquivo numa thread do Slack, ou commitar temporariamente pra compartilhar com o time. O bootstrap deleta ele depois da confirmação final, mas você pode guardar cópia se for útil.

</details>

<details>
<summary><b>Qual a relação com o Cuidda?</b></summary>

Esse template foi destilado do `.claude/` em produção do [Cuidda](https://cuidda.com), um SaaS clínico. O setup original evoluiu ao longo de meses de PRs reais — hooks adicionados quando anti-patterns grepáveis seguiam passando, duck loop adicionado quando bugs latentes sobreviviam ao auditor + reviewer, ledger de telemetria adicionado quando a gente quis evoluir regras a partir de evidência em vez de feeling.

O template aqui é a arquitetura sem o conteúdo específico do Cuidda. A espinha portável é idêntica; o conteúdo por projeto (regras do BASELINE atreladas a PHI de paciente, hooks que grepam paths de `apps/api`, knowledge entries sobre módulos específicos) foi substituído por templates e um bootstrap que re-deriva equivalentes pra qualquer projeto que você apontar.

</details>

---

<div align="center">

<sub>Licença MIT · mantido por <a href="https://github.com/natanrotta">@natanrotta</a></sub>

</div>
