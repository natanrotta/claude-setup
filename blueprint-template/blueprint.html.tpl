<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>{{PROJECT_NAME}} — Claude Setup Blueprint</title>
<style>
  :root {
    --bg: #0a0d12;
    --bg-elev-1: #11151c;
    --bg-elev-2: #161b24;
    --bg-elev-3: #1e2530;
    --border: #2a3340;
    --border-strong: #3a4555;
    --text: #e6edf3;
    --text-muted: #8b96a5;
    --text-faint: #5f6976;
    --accent: #6e8cff;
    --accent-glow: rgba(110, 140, 255, 0.18);
    --success: #34c69b;
    --warning: #d4a017;
    --danger: #e5484d;
    --mono: ui-monospace, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
    --sans: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, "Inter", sans-serif;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { background: var(--bg); color: var(--text); font-family: var(--sans); font-size: 15px; line-height: 1.55; -webkit-font-smoothing: antialiased; }
  body { padding: 48px 24px 96px; max-width: 1080px; margin: 0 auto; }

  /* HERO */
  .hero { position: relative; padding: 56px 48px; border-radius: 18px; background: linear-gradient(135deg, var(--bg-elev-2) 0%, var(--bg-elev-1) 100%); border: 1px solid var(--border); overflow: hidden; margin-bottom: 32px; }
  .hero::before { content: ""; position: absolute; top: -120px; right: -120px; width: 360px; height: 360px; background: radial-gradient(circle, var(--accent-glow), transparent 65%); pointer-events: none; }
  .hero .eyebrow { font-family: var(--mono); font-size: 11px; letter-spacing: 0.12em; text-transform: uppercase; color: var(--accent); margin-bottom: 12px; }
  .hero h1 { font-size: 40px; font-weight: 700; letter-spacing: -0.02em; margin-bottom: 14px; }
  .hero .one-liner { font-size: 19px; color: var(--text-muted); max-width: 720px; line-height: 1.4; margin-bottom: 32px; }
  .hero .meta-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 16px; }
  .meta-cell { padding: 14px 18px; background: var(--bg-elev-3); border: 1px solid var(--border); border-radius: 10px; }
  .meta-cell .label { font-family: var(--mono); font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--text-faint); margin-bottom: 4px; }
  .meta-cell .value { font-size: 15px; font-weight: 500; }

  /* SECTIONS */
  section { margin-top: 48px; }
  section h2 { font-size: 13px; font-family: var(--mono); letter-spacing: 0.15em; text-transform: uppercase; color: var(--text-muted); margin-bottom: 16px; display: flex; align-items: center; gap: 12px; }
  section h2::before { content: ""; width: 4px; height: 4px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 12px var(--accent); }

  /* MVP FEATURES */
  .mvp-list { display: flex; flex-direction: column; gap: 10px; }
  .mvp-list .item { padding: 14px 18px; background: var(--bg-elev-1); border: 1px solid var(--border); border-left: 3px solid var(--accent); border-radius: 8px; font-size: 14px; }

  /* STACK BADGES */
  .stack-badges { display: flex; flex-wrap: wrap; gap: 8px; }
  .badge { font-family: var(--mono); font-size: 12px; padding: 6px 12px; border-radius: 6px; background: var(--bg-elev-3); border: 1px solid var(--border-strong); color: var(--text); }
  .badge .label { color: var(--text-faint); margin-right: 8px; }

  /* DIAGRAMS / PRE BLOCKS */
  pre.diagram, pre.tree { font-family: var(--mono); font-size: 12.5px; line-height: 1.65; padding: 20px 22px; background: var(--bg-elev-1); border: 1px solid var(--border); border-radius: 10px; color: var(--text); overflow-x: auto; white-space: pre; }

  /* TABLES */
  table { width: 100%; border-collapse: collapse; background: var(--bg-elev-1); border: 1px solid var(--border); border-radius: 10px; overflow: hidden; }
  thead { background: var(--bg-elev-3); }
  th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border); }
  th { font-family: var(--mono); font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--text-muted); font-weight: 600; }
  td { font-size: 13.5px; }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: rgba(110, 140, 255, 0.04); }
  td code, th code { font-family: var(--mono); font-size: 12px; padding: 2px 6px; background: var(--bg-elev-3); border-radius: 4px; color: var(--accent); }
  td .sev-critical { color: var(--danger); font-weight: 600; }
  td .sev-high { color: var(--warning); font-weight: 600; }
  td .sev-medium { color: var(--accent); }
  td .sev-low { color: var(--text-muted); }

  /* SPECIALIST CARDS */
  .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 14px; }
  .card { padding: 18px 20px; background: var(--bg-elev-1); border: 1px solid var(--border); border-radius: 10px; transition: border-color 0.15s; }
  .card:hover { border-color: var(--accent); }
  .card .card-title { font-family: var(--mono); font-size: 14px; color: var(--accent); margin-bottom: 8px; }
  .card .card-body { font-size: 13px; color: var(--text-muted); line-height: 1.5; }

  /* PIPELINE */
  .pipeline { display: flex; flex-direction: column; gap: 10px; padding: 24px; background: var(--bg-elev-1); border: 1px solid var(--border); border-radius: 10px; }
  .pipeline-step { display: flex; align-items: center; gap: 16px; }
  .pipeline-step .num { font-family: var(--mono); font-size: 12px; color: var(--text-faint); width: 28px; text-align: right; }
  .pipeline-step .body { flex: 1; padding: 12px 16px; background: var(--bg-elev-3); border: 1px solid var(--border); border-radius: 8px; font-size: 13.5px; }
  .pipeline-step .body code { font-family: var(--mono); color: var(--accent); }
  .pipeline-arrow { padding-left: 28px; color: var(--text-faint); font-family: var(--mono); font-size: 12px; }

  /* NEXT STEPS / CALLOUTS */
  .callout { padding: 20px 24px; border-radius: 10px; background: linear-gradient(135deg, rgba(110, 140, 255, 0.08) 0%, transparent 100%); border: 1px solid var(--accent); border-left-width: 3px; }
  .callout h3 { font-size: 14px; margin-bottom: 8px; color: var(--accent); font-family: var(--mono); letter-spacing: 0.05em; text-transform: uppercase; }
  .callout ul { list-style: none; padding: 0; }
  .callout li { padding: 6px 0; font-size: 13.5px; }
  .callout code { font-family: var(--mono); padding: 2px 6px; background: var(--bg-elev-3); border-radius: 4px; color: var(--accent); }

  /* FOOTER */
  footer { margin-top: 64px; padding-top: 24px; border-top: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; font-size: 12px; color: var(--text-faint); font-family: var(--mono); }
  footer .right { display: flex; gap: 18px; }

  /* SCROLLBAR */
  pre::-webkit-scrollbar, table::-webkit-scrollbar { height: 8px; }
  pre::-webkit-scrollbar-thumb { background: var(--border-strong); border-radius: 4px; }
</style>
</head>
<body>

<div class="hero">
  <div class="eyebrow">Claude Setup · Blueprint</div>
  <h1>{{PROJECT_NAME}}</h1>
  <div class="one-liner">{{PRODUCT_ONELINER}}</div>
  <div class="meta-grid">
    <div class="meta-cell"><div class="label">Persona</div><div class="value">{{PRIMARY_PERSONA}}</div></div>
    <div class="meta-cell"><div class="label">Domínio</div><div class="value">{{DOMAIN}}</div></div>
    <div class="meta-cell"><div class="label">Idioma</div><div class="value">{{DEFAULT_LANGUAGE}}</div></div>
    <div class="meta-cell"><div class="label">Base branch</div><div class="value"><code style="font-family:var(--mono);font-size:13px;">{{BASE_BRANCH}}</code></div></div>
  </div>
</div>

<section>
  <h2>MVP — features que entram no v1</h2>
  <div class="mvp-list">
    {{MVP_FEATURES_LIST}}
    <!-- example item:
    <div class="item">Cadastro e listagem de pacientes</div>
    -->
  </div>
</section>

<section>
  <h2>Stack pinned</h2>
  <div class="stack-badges">
    {{STACK_BADGES}}
    <!-- example badge:
    <span class="badge"><span class="label">backend</span>Node + Express + TS</span>
    -->
  </div>
</section>

<section>
  <h2>Arquitetura</h2>
  <pre class="diagram">{{ARCHITECTURE_DIAGRAM}}</pre>
</section>

<section>
  <h2>Códigos de anti-pattern gerados pra essa stack</h2>
  <table>
    <thead>
      <tr><th style="width: 90px;">Código</th><th style="width: 90px;">Severidade</th><th>O que pega</th><th>Onde aplica</th></tr>
    </thead>
    <tbody>
      {{ANTI_PATTERN_TABLE}}
      <!-- example row:
      <tr><td><code>B-C1</code></td><td><span class="sev-critical">Critical</span></td><td>Query Prisma em tabela multi-tenant sem filtro account_id</td><td>apps/api/src/**</td></tr>
      -->
    </tbody>
  </table>
</section>

<section>
  <h2>Hooks ativos (advisory, write-time)</h2>
  <table>
    <thead>
      <tr><th>Script</th><th>Trigger glob</th><th>Códigos checados</th></tr>
    </thead>
    <tbody>
      {{HOOKS_TABLE}}
      <!-- example row:
      <tr><td><code>post-edit-backend.sh</code></td><td><code>apps/api/src/**/*.ts</code></td><td><code>B-C4</code>, <code>B-H12</code>, <code>B-C13</code></td></tr>
      -->
    </tbody>
  </table>
</section>

<section>
  <h2>Specialists configurados</h2>
  <div class="cards">
    {{SPECIALISTS_CARDS}}
    <!-- example card:
    <div class="card"><div class="card-title">/backend</div><div class="card-body">Engenheiro back especializado em Node + Express + Prisma. Roteado quando a task toca apps/api/**.</div></div>
    -->
  </div>
</section>

<section>
  <h2>Pipeline de qualidade</h2>
  <div class="pipeline">
    <div class="pipeline-step"><div class="num">1</div><div class="body"><code>/triage</code> &mdash; Architect + Engineer + Product em paralelo. Produz pre-dev brief.</div></div>
    <div class="pipeline-arrow">↓</div>
    <div class="pipeline-step"><div class="num">2</div><div class="body">Specialist implementa &mdash; <code>/backend</code>, <code>/frontend</code>, <code>/fullstack</code>, etc.</div></div>
    <div class="pipeline-arrow">↓</div>
    <div class="pipeline-step"><div class="num">3</div><div class="body">BABYSIT loop &mdash; <code>code-auditor</code> (L1 mecânico) → <code>code-reviewer</code> (L2 semântico) → <code>/duck-debug</code> (L3 verbalização, só M/L).</div></div>
    <div class="pipeline-arrow">↓</div>
    <div class="pipeline-step"><div class="num">4</div><div class="body"><code>/finish-task</code> &mdash; cobertura de testes → <code>/code-review</code> independente → <code>/check</code> (3 retries) → <code>/finish</code> abre PR.</div></div>
    <div class="pipeline-arrow">↓</div>
    <div class="pipeline-step"><div class="num">5</div><div class="body">Após merge: <code>/cleanup-task</code> remove worktree + branch local. Telemetria em <code>learning/violations.md</code> evolui o setup via <code>/evolve-claude</code>.</div></div>
  </div>
</section>

<section>
  <h2>Árvore de arquivos que será escrita</h2>
  <pre class="tree">{{FILE_TREE}}</pre>
</section>

<section>
  <div class="callout">
    <h3>Próximos passos</h3>
    <ul>
      <li>Volte ao terminal e responda <code>aprovado</code> para que o <code>/bootstrap-claude</code> escreva os arquivos reais em <code>.claude/</code>.</li>
      <li>Quer ajustar algo? Responda descrevendo o que mudar (ex: <code>muda o stage 3</code>, <code>remove i18n</code>). O bot regenera só o afetado.</li>
      <li>Após aprovação, sua primeira task: <code>/triage "implementar X"</code> ou descreva direto em linguagem natural.</li>
      <li>Para manter o setup vivo conforme o projeto cresce, rode <code>/evolve-claude</code> periodicamente.</li>
    </ul>
  </div>
</section>

<footer>
  <div>{{PROJECT_NAME}} · bootstrap em {{BOOTSTRAP_DATE}}</div>
  <div class="right">
    <span>claude-setup · template v1</span>
    <span>self-contained · pode ser compartilhado por screenshot</span>
  </div>
</footer>

</body>
</html>
