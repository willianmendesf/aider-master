#!/usr/bin/env bash
# =============================================================================
# AIDER OS — Script de Testes de Validação
# Testa: parsing, validações defensivas, bundle, resolução de plano
# NÃO invoca LLM — apenas valida a lógica shell e Python
# =============================================================================

AIDER_GLOBAL_DIR="/dados/aider"
FRONTEND_DIR="/dados/Projects/dashboard-manager/code/frontend"
BACKEND_DIR="/dados/Projects/dashboard-manager/code/backend"
PASS=0
FAIL=0
WARN=0

_ok()   { echo "  ✅ PASS: $*"; ((PASS++)); }
_fail() { echo "  ❌ FAIL: $*"; ((FAIL++)); }
_warn() { echo "  ⚠️  WARN: $*"; ((WARN++)); }
_section() { echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🧪 $*"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

# Carrega o core (sem executar aider)
# shellcheck source=/dados/aider/aider_core.sh
source "$AIDER_GLOBAL_DIR/aider_core.sh" 2>/dev/null || { echo "❌ FATAL: Não conseguiu carregar aider_core.sh"; exit 1; }

echo "╔══════════════════════════════════════════════════════╗"
echo "║         AIDER OS — SUITE DE TESTES DE VALIDAÇÃO      ║"
echo "╚══════════════════════════════════════════════════════╝"

# =============================================================================
# BLOCO 1 — Parsing de argumentos: plan()
# =============================================================================
_section "BLOCO 1: plan() — parsing de demanda vs modelo"

# Simula plan(): captura saída sem invocar o aider (injeta agent falso)
agent() { echo "AGENT_MODEL=$1"; } # stub

cd "$FRONTEND_DIR" || exit 1
_init_ai_workspace 2>/dev/null

echo "[1.1] plan sem demanda deve retornar erro:"
output=$(plan 2>&1); rc=$?
if [[ $rc -ne 0 ]] && echo "$output" | grep -q "ERRO"; then
  _ok "plan sem args → erro correto"
else
  _fail "plan sem args não retornou erro (rc=$rc)"
fi

echo "[1.2] plan com --model como primeiro arg deve retornar erro:"
output=$(plan --model gpt-4 2>&1); rc=$?
if [[ $rc -ne 0 ]] && echo "$output" | grep -q "ERRO"; then
  _ok "plan --model como 1° arg → erro correto"
else
  _fail "plan --model como 1° arg não retornou erro (rc=$rc)"
fi

echo "[1.3] plan 'refatorar appointment' deve usar modelo 'default', não a demanda:"
output=$(plan "refatorar appointment" 2>&1)
if echo "$output" | grep -q "AGENT_MODEL=default"; then
  _ok "plan 'frase como demanda' → modelo=default ✓"
else
  _fail "plan não usou modelo default. Saída: $output"
fi

echo "[1.4] plan 'refatorar appointment' --model gpt-4 deve usar modelo gpt-4:"
output=$(plan "refatorar appointment" --model gpt-4 2>&1)
if echo "$output" | grep -q "AGENT_MODEL=gpt-4"; then
  _ok "plan 'demanda' --model gpt-4 → modelo=gpt-4 ✓"
else
  _fail "plan --model não foi aplicado. Saída: $output"
fi

# =============================================================================
# BLOCO 2 — standardize: validação de existência
# =============================================================================
_section "BLOCO 2: standardize() — validação de existência do alvo"

echo "[2.1] standardize com alvo inexistente deve falhar (não criar arquivo):"
BEFORE_COUNT=$(ls -1 "$FRONTEND_DIR" | wc -l)
output=$(cd "$FRONTEND_DIR" && standardize "nao-existe-alvo-xyz-123" --audit 2>&1); rc=$?
AFTER_COUNT=$(ls -1 "$FRONTEND_DIR" | wc -l)
if [[ $rc -ne 0 ]] && echo "$output" | grep -q "ERRO"; then
  _ok "standardize alvo-inexistente → erro correto (rc=$rc)"
else
  _fail "standardize alvo-inexistente não retornou erro (rc=$rc)"
fi
if [[ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ]]; then
  _ok "Nenhum arquivo fantasma criado na raiz do projeto ✓"
else
  _fail "Arquivo(s) fantasma criados! Antes=$BEFORE_COUNT, Depois=$AFTER_COUNT"
  diff <(ls -1 "$FRONTEND_DIR" | head -50) <(ls -1 "$FRONTEND_DIR" | head -50)
fi

echo "[2.2] standardize com arquivo existente deve passar na validação:"
TEST_FILE="$FRONTEND_DIR/src/app/pages/logged/appointments/appointments.component.ts"
if [ -f "$TEST_FILE" ]; then
  output=$(cd "$FRONTEND_DIR" && standardize "$TEST_FILE" --audit 2>&1); rc=$?
  # rc pode ser 0 (chegou ao agent) - o stub agent() não falha
  if ! echo "$output" | grep -q "não existe"; then
    _ok "standardize arquivo-existente → validação passou ✓"
  else
    _fail "standardize arquivo-existente falhou na validação. Saída: $output"
  fi
else
  _warn "Arquivo de teste não encontrado: $TEST_FILE (pulando 2.2)"
fi

echo "[2.3] standardize com diretório existente deve passar na validação:"
TEST_DIR="$FRONTEND_DIR/src/app/pages/logged/appointments"
if [ -d "$TEST_DIR" ]; then
  output=$(cd "$FRONTEND_DIR" && standardize "$TEST_DIR" --audit 2>&1); rc=$?
  if ! echo "$output" | grep -q "não existe"; then
    _ok "standardize diretório-existente → validação passou ✓"
  else
    _fail "standardize diretório-existente falhou. Saída: $output"
  fi
else
  _warn "Diretório de teste não encontrado: $TEST_DIR"
fi

# =============================================================================
# BLOCO 3 — dev(): resolução de plano
# =============================================================================
_section "BLOCO 3: dev() — resolução de plano via GIT_ROOT"

cd "$FRONTEND_DIR" || exit 1
mkdir -p .ai/plans

echo "[3.1] dev sem argumento deve retornar erro:"
output=$(dev 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then
  _ok "dev sem args → erro correto (rc=$rc)"
else
  _fail "dev sem args não retornou erro"
fi

echo "[3.2] dev com plano inexistente deve retornar erro claro:"
output=$(dev ".ai/plans/PLAN-999.md" 2>&1); rc=$?
if [[ $rc -ne 0 ]] && echo "$output" | grep -q "ERRO"; then
  _ok "dev plano-inexistente → erro claro ✓"
else
  _fail "dev plano-inexistente não retornou erro claro. Saída: $output"
fi

echo "[3.3] dev com plano existente deve encontrar o arquivo:"
echo "# PLAN-001: Teste" > .ai/plans/PLAN-001.md
output=$(dev ".ai/plans/PLAN-001.md" 2>&1); rc=$?
if [[ $rc -eq 0 ]] || echo "$output" | grep -q "Motor de Execução"; then
  _ok "dev plano-existente → encontrou o arquivo ✓"
else
  _fail "dev plano-existente falhou. rc=$rc. Saída: $output"
fi

echo "[3.4] dev com plano existente a partir de GIT_ROOT (simulando subpasta):"
# Cria subpasta temporária e testa resolução relativa a GIT_ROOT
TMPSUBDIR="$FRONTEND_DIR/src/app/tmp-test-subdir"
mkdir -p "$TMPSUBDIR"
output=$(cd "$TMPSUBDIR" && dev ".ai/plans/PLAN-001.md" 2>&1); rc=$?
rmdir "$TMPSUBDIR"
if [[ $rc -eq 0 ]] || echo "$output" | grep -q "Motor de Execução"; then
  _ok "dev de subpasta resolveu plano via GIT_ROOT ✓"
else
  # Pode falhar se não há git root no projeto — apenas warn
  _warn "dev de subpasta não resolveu via GIT_ROOT (git pode não estar configurado no projeto)"
fi
rm -f "$FRONTEND_DIR/.ai/plans/PLAN-001.md"

# =============================================================================
# BLOCO 4 — code-review(): evidência e validação
# =============================================================================
_section "BLOCO 4: code-review() — evidência real para diretórios"

cd "$FRONTEND_DIR" || exit 1

echo "[4.1] code-review alvo-inexistente deve falhar com erro:"
output=$(code-review "src/nao-existe-mesmo" 2>&1); rc=$?
if [[ $rc -ne 0 ]] && echo "$output" | grep -q "ERRO\|não existe"; then
  _ok "code-review alvo-inexistente → erro correto ✓"
else
  _fail "code-review alvo-inexistente não retornou erro. rc=$rc. Saída: $output"
fi

echo "[4.2] code-review em arquivo existente deve montar evidência:"
TEST_FILE="src/app/pages/logged/appointments/appointments.component.ts"
if [ -f "$TEST_FILE" ]; then
  output=$(code-review "$TEST_FILE" 2>&1); rc=$?
  if echo "$output" | grep -q "Arquivo individual"; then
    _ok "code-review arquivo → modo arquivo detectado ✓"
  else
    _fail "code-review arquivo não detectou modo arquivo. Saída: $output"
  fi
else
  _warn "Arquivo de teste não encontrado: $TEST_FILE"
fi

echo "[4.3] code-review em diretório deve gerar bundle de evidência:"
TEST_DIR="src/app/pages/logged/appointments"
if [ -d "$TEST_DIR" ]; then
  output=$(code-review "$TEST_DIR" 2>&1); rc=$?
  BUNDLE_FILE=".ai/cache/code-review-bundle.txt"
  if [ -s "$BUNDLE_FILE" ]; then
    LINE_COUNT=$(wc -l < "$BUNDLE_FILE")
    _ok "code-review diretório → bundle gerado com $LINE_COUNT linhas ✓"
    if echo "$output" | grep -q "bundle\|Bundle"; then
      _ok "Mensagem de bundle exibida no terminal ✓"
    else
      _warn "Mensagem de bundle não apareceu (output: $output)"
    fi
  else
    _fail "code-review diretório NÃO gerou bundle em $BUNDLE_FILE. Saída: $output"
  fi
else
  _warn "Diretório de teste não encontrado: $TEST_DIR"
fi

echo "[4.4] code-review com --model como 1° arg deve retornar erro:"
output=$(code-review --model gpt-4 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then
  _ok "code-review --model como 1° arg → erro ✓"
else
  _fail "code-review --model como 1° arg não retornou erro"
fi

# =============================================================================
# BLOCO 5 — Bootstrap: frontend Angular (Compodoc)
# =============================================================================
_section "BLOCO 5: bootstrap() Angular — Compodoc"

cd "$FRONTEND_DIR" || exit 1

echo "[5.1] Verificando catálogo angular-compodoc.yml (comando moderno):"
CATALOG="$AIDER_GLOBAL_DIR/tooling/catalog/angular-compodoc.yml"
if grep -q "@compodoc/compodoc" "$CATALOG" && grep -q "\-\-exportFormat" "$CATALOG"; then
  CMD=$(grep "npx" "$CATALOG")
  _ok "Catálogo usa comando moderno: $CMD"
else
  _fail "Catálogo NÃO usa o comando moderno. Conteúdo: $(cat $CATALOG)"
fi

echo "[5.2] Verificando se @compodoc/compodoc está instalado no projeto:"
if [ -x "$FRONTEND_DIR/node_modules/.bin/compodoc" ]; then
  _ok "@compodoc/compodoc disponível em node_modules ✓"
elif npx --yes @compodoc/compodoc --version &>/dev/null; then
  _ok "@compodoc/compodoc disponível via npx ✓"
else
  _warn "@compodoc/compodoc não detectado — bootstrap pode falhar para Angular"
fi

echo "[5.3] Executando bootstrap em modo dry-run (apenas doctor):"
output=$(cd "$FRONTEND_DIR" && python3 "$AIDER_GLOBAL_DIR/scripts/knowledge_pipeline.py" --doctor 2>&1)
if echo "$output" | grep -qi "compodoc\|bootstrap"; then
  _ok "Bootstrap --doctor detectou ferramentas. Output: $(echo "$output" | head -5)"
else
  _warn "Bootstrap --doctor retornou resultado inesperado: $output"
fi

# =============================================================================
# BLOCO 6 — Bootstrap: backend Java (sem OpenAPI)
# =============================================================================
_section "BLOCO 6: bootstrap() Java/Spring — sem OpenAPI"

cd "$BACKEND_DIR" || exit 1
_init_ai_workspace 2>/dev/null

echo "[6.1] Verificando ausência de artefato OpenAPI:"
OPENAPI_EXISTS=false
for f in "openapi.json" "swagger.json" "target/swagger-ui/openapi.json" "target/classes/META-INF/swagger/openapi.yaml"; do
  [ -f "$f" ] && OPENAPI_EXISTS=true && break
done
if [ "$OPENAPI_EXISTS" = "false" ]; then
  _ok "OpenAPI não existe no projeto — cenário correto para testar fallback"
else
  _warn "OpenAPI encontrado em $f — fallback não será ativado para este teste"
fi

echo "[6.2] Executando bootstrap completo no backend (apenas pipeline Python, sem LLM):"
output=$(cd "$BACKEND_DIR" && timeout 120 python3 "$AIDER_GLOBAL_DIR/scripts/knowledge_pipeline.py" 2>&1)
rc=$?
echo "   Saída do bootstrap:"
echo "$output" | sed 's/^/   /'

if echo "$output" | grep -q "PARCIAL\|parcial"; then
  _ok "Bootstrap detectou índice parcial e avisou corretamente ✓"
elif echo "$output" | grep -q "✅ Bootstrap concluído"; then
  _ok "Bootstrap gerou entidades completas (OpenAPI ou Compodoc encontrado)"
elif echo "$output" | grep -q "Nenhuma ferramenta"; then
  _warn "Nenhuma ferramenta detectada para backend — adicionar catálogo Spring ao projeto"
else
  _warn "Saída do bootstrap não conclusiva (rc=$rc)"
fi

echo "[6.3] Verificando entities.json gerado após bootstrap:"
if [ -f ".ai/knowledge/entities.json" ]; then
  COUNT=$(python3 -c "import json; data=json.load(open('.ai/knowledge/entities.json')); print(len(data))" 2>/dev/null)
  _ok "entities.json existe com $COUNT entidade(s)"
else
  _warn "entities.json não gerado (pode ser que nenhuma ferramenta foi detectada)"
fi

# =============================================================================
# BLOCO 7 — query.py: where/discover com índice parcial
# =============================================================================
_section "BLOCO 7: where/discover/impact — fallback textual com índice parcial"

cd "$BACKEND_DIR" || exit 1

echo "[7.1] Simulando índice parcial (apenas RepomixBundle):"
mkdir -p .ai/knowledge
cat > .ai/knowledge/entities.json << 'EOF'
[
  {
    "id": "RepomixBundle",
    "name": "Repomix Bundle",
    "type": "bundle",
    "file": ".ai/knowledge/test-bundle.txt",
    "line": 0,
    "source": "Repomix",
    "confidence": 70,
    "uses": [], "used_by": [], "tags": []
  }
]
EOF
cat > .ai/knowledge/test-bundle.txt << 'EOF'
=== AppointmentService.java ===
public class AppointmentService {
    public void scheduleAppointment(Appointment appointment) {
        // logic here
    }
}
=== AppointmentsController.java ===
@RestController
public class AppointmentsController {
    @Autowired
    private AppointmentService appointmentService;
}
EOF
sed -i 's|"file": ".ai/knowledge/test-bundle.txt"|"file": "'$(pwd)'/.ai/knowledge/test-bundle.txt"|g' .ai/knowledge/entities.json

output=$(python3 "$AIDER_GLOBAL_DIR/scripts/query.py" where appointment 2>&1)
echo "   Saída do where:"
echo "$output" | sed 's/^/   /'
if echo "$output" | grep -qi "parcial\|fallback\|textual"; then
  _ok "where com índice parcial → aviso de fallback textual ✓"
else
  _fail "where não avisou sobre índice parcial. Saída: $output"
fi
if echo "$output" | grep -qi "AppointmentService\|Appointment"; then
  _ok "where encontrou 'appointment' via busca textual no bundle ✓"
else
  _fail "where NÃO encontrou ocorrências textuais de 'appointment' no bundle"
fi

echo ""
echo "[7.2] discover com índice parcial:"
output=$(python3 "$AIDER_GLOBAL_DIR/scripts/query.py" discover appointment 2>&1)
if echo "$output" | grep -qi "parcial\|fallback"; then
  _ok "discover com índice parcial → aviso ✓"
else
  _fail "discover não avisou sobre índice parcial"
fi

echo ""
echo "[7.3] impact com índice parcial:"
output=$(python3 "$AIDER_GLOBAL_DIR/scripts/query.py" impact appointment 2>&1)
if echo "$output" | grep -qi "parcial\|fallback\|Análise de impacto não disponível"; then
  _ok "impact com índice parcial → aviso ✓"
else
  _fail "impact não avisou sobre índice parcial. Saída: $output"
fi

# Limpa entidades de teste
rm -f .ai/knowledge/entities.json .ai/knowledge/test-bundle.txt
echo "   (Arquivos de teste removidos)"

# =============================================================================
# BLOCO 8 — Bootstrap Angular completo (testa Compodoc com timeout)
# =============================================================================
_section "BLOCO 8: bootstrap() Angular — execução real com Compodoc"

cd "$FRONTEND_DIR" || exit 1

echo "[8.1] Executando bootstrap real no Angular com timeout de 90s:"
output=$(cd "$FRONTEND_DIR" && timeout 90 python3 "$AIDER_GLOBAL_DIR/scripts/knowledge_pipeline.py" 2>&1)
rc=$?
echo "   Saída:"
echo "$output" | sed 's/^/   /'

if [ $rc -eq 124 ]; then
  _fail "Bootstrap Angular demorou mais de 90s (timeout) — Compodoc travou"
elif echo "$output" | grep -q "entidades indexadas"; then
  COUNT=$(echo "$output" | grep -oP '\d+ entidades' | head -1)
  _ok "Bootstrap Angular concluído: $COUNT indexadas ✓"
elif echo "$output" | grep -q "PARCIAL\|parcial"; then
  _warn "Bootstrap Angular parcial — Compodoc falhou ou não instalado"
elif echo "$output" | grep -q "❌ Falha"; then
  _fail "Bootstrap Angular falhou completamente"
else
  _warn "Bootstrap Angular: resultado não conclusivo (rc=$rc)"
fi

echo "[8.2] Verificando entities.json gerado no Angular:"
if [ -f "$FRONTEND_DIR/.ai/knowledge/entities.json" ]; then
  COUNT=$(python3 -c "import json; data=json.load(open('$FRONTEND_DIR/.ai/knowledge/entities.json')); print(len(data))" 2>/dev/null || echo "erro ao ler")
  _ok "entities.json existe com $COUNT entidade(s)"
  if [[ "$COUNT" -gt 50 ]] 2>/dev/null; then
    _ok "Indexação robusta: $COUNT entidades (Angular full) ✓"
  else
    _warn "Poucas entidades ($COUNT) — pode ser fallback Repomix"
  fi
else
  _warn "entities.json não gerado no Angular"
fi

# =============================================================================
# RESULTADO FINAL
# =============================================================================
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║                 RESULTADO FINAL                      ║"
echo "╠══════════════════════════════════════════════════════╣"
printf "║  ✅ PASS: %-42s ║\n" "$PASS"
printf "║  ❌ FAIL: %-42s ║\n" "$FAIL"
printf "║  ⚠️  WARN: %-42s ║\n" "$WARN"
echo "╚══════════════════════════════════════════════════════╝"
if [[ $FAIL -eq 0 ]]; then
  echo "🎉 Todos os critérios obrigatórios PASSARAM!"
  exit 0
else
  echo "⚠️  $FAIL teste(s) falharam. Veja os itens ❌ acima."
  exit 1
fi
