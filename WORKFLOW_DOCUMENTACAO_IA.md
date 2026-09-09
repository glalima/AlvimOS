# WORKFLOW — Documentação rápida com IA

## Objetivo
Evitar reanalisar ZIP + dump + toda a conversa a cada alteração.

---

## 1. As cinco camadas

### Camada 1 — START HERE
Contexto mínimo e roteador.

Atualize apenas quando:
- muda arquitetura;
- muda prioridade;
- nasce domínio importante.

### Camada 2 — Arquitetura / ADR
Registra **por que** uma decisão foi tomada.

Atualize quando:
- regra estrutural é aprovada;
- uma decisão anterior é substituída.

### Camada 3 — Domínios
Registra **como o domínio funciona**.

Atualize quando:
- regra de negócio muda;
- schema/RPC/view oficial muda.

### Camada 4 — CHANGE
Registra **como atravessar do atual para o alvo**.

É o arquivo mais usado no dia a dia.

### Camada 5 — CURRENT STATE
Registro curto da sessão/projeto:
- o que está sendo feito;
- último erro;
- próxima etapa;
- bloqueios.

---

## 2. Procedimento rápido para uma mudança

### Antes de programar
Peça à IA:

> Leia `00_START_HERE`, `CURRENT_STATE`, o domínio X e os ADRs relacionados.  
> Crie/atualize o CHANGE-Y com estado atual, alvo, gap, arquivos, migration, testes e critérios de aceite.  
> Não escreva código ainda.

Leia e corrija o CHANGE.

### Durante a implementação
A cada etapa importante:

> Atualize apenas a seção "Implementação realizada" do CHANGE-Y com o que efetivamente foi alterado. Não altere decisões arquiteturais.

### Quando surgir um problema
Envie:
- CHANGE;
- erro;
- arquivo afetado;
- schema/view/RPC relevante.

Prompt:

> Estou na etapa N do CHANGE-Y. O esperado é X, mas ocorre Y. Analise somente o necessário para diagnosticar e proponha correção mantendo os ADRs.

### Ao concluir
Peça:

> Compare implementação final com critérios de aceite. Marque o que foi validado. Atualize o domínio, CURRENT_STATE e CHANGE. Se alguma decisão mudou, proponha novo ADR; não edite ADR aceito silenciosamente.

---

## 3. Como criar documentação dos cinco níveis rapidamente

Faça em ciclos pequenos.

### Ciclo A — extração
Dê à IA:
- dump atual;
- pasta/ZIP relevante;
- docs atuais.

Peça:
1. o que existe;
2. gaps;
3. regras duplicadas;
4. objetos envolvidos.

### Ciclo B — decisão
Discuta apenas os pontos ambíguos.

Quando concordar:
> Converta a decisão em ADR.

### Ciclo C — domínio
> Atualize o documento de domínio incorporando apenas ADRs aceitos.

### Ciclo D — mudança
> Crie CHANGE implementável com checklist.

### Ciclo E — fechamento
> Atualize CURRENT_STATE em no máximo uma página.

---

## 4. Regra de eficiência

Não enviar o repositório inteiro para toda pergunta.

### Pergunta localizada
Enviar/indicar:
- `00_START_HERE`
- CHANGE ativo
- domínio afetado
- arquivos específicos

### Revisão arquitetural
Enviar:
- START HERE
- ADRs
- domínio
- dump/schema
- arquivos relevantes

### Auditoria geral
Aí sim:
- ZIP completo
- dump
- docs

---

## 5. Uso com NotebookLM

Crie um notebook "ALVIM OS — Arquitetura".

Fontes principais:
1. `00_START_HERE`
2. `VISAO_ALVIM_OS`
3. `MAPA_TECNICO_MASTER`
4. ADRs
5. docs de domínio
6. CHANGE concluídos

Evite lotar o notebook principal com cada versão do ZIP.

Para código atual, mantenha outro conjunto/notebook se necessário.

---

## 6. Regra de versionamento

Cada CHANGE:
- PLANEJADO
- EM_IMPLEMENTAÇÃO
- EM_TESTE
- CONCLUÍDO
- CANCELADO

ADR:
- PROPOSTO
- ACEITO
- SUBSTITUÍDO
- REJEITADO

Nunca reescrever o passado silenciosamente.

Se uma decisão aceita mudou:
- criar novo ADR;
- marcar o antigo como SUBSTITUÍDO.

---

## 7. Prompt padrão de encerramento de sessão

> Faça o fechamento da sessão do ALVIM OS.  
> 1. Atualize o CHANGE ativo apenas com alterações realmente feitas.  
> 2. Atualize CURRENT_STATE com estado, erro atual, próximo passo e bloqueios.  
> 3. Liste documentos de domínio que ficaram desatualizados.  
> 4. Se houve nova decisão arquitetural, proponha ADR separado.  
> 5. Não marque como concluído nada que não foi testado.

Esse prompt reduz drasticamente a perda de contexto.
