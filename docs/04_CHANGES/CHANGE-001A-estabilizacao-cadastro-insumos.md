# CHANGE-001A — Estabilização do cadastro de insumos

**Status:** PRONTO PARA IMPLEMENTAÇÃO  
**Data:** 09/09/2026  
**Domínio:** Insumos  
**Prioridade:** P0

## Problema
O cadastro/edição atual pode carregar estado incompleto e ainda contém regras baseadas em `compra_diaria`. Antes da migração para contexto por local, o fluxo atual precisa ser seguro para leitura, edição e navegação.

## Comportamento atual identificado
- `getInsumosCatalog.ts` não retorna todos os campos necessários ao formulário, incluindo `gatilho_pedido`, chaves logísticas e metas.
- `createInsumo.ts` e `updateInsumo.ts` usam `requiresVolume = !compra_diaria && !produzido_internamente`.
- criação de metas está acoplada a `enviado_loja`/`compra_diaria`;
- edição pode trabalhar com defaults em vez do estado persistido;
- Salvar / Próximo / Anterior precisam ser estabilizados.

## Comportamento desejado
1. Abrir um insumo deve reproduzir fielmente o estado persistido.
2. Salvar deve persistir antes de qualquer navegação.
3. Salvar + Próximo e Salvar + Anterior só navegam após sucesso confirmado.
4. Erro de persistência mantém o usuário no registro e mostra erro.
5. Nenhuma configuração existente pode ser apagada por default do frontend.
6. Não introduzir novas regras dependentes de `compra_diaria`.
7. Não criar ainda o novo schema de contexto por local.

## Escopo de implementação
### Backend
- revisar/corrigir `getInsumosCatalog.ts`;
- revisar `createInsumo.ts`;
- revisar `updateInsumo.ts`;
- retornar estado necessário para edição, inclusive metas atuais;
- preferir banco/RPC/SQL como fonte da regra e reduzir lógica duplicada.

### Frontend
- revisar `InsumoFormDialog.tsx`;
- revisar `NewInsumoDialog.tsx`;
- corrigir hidratação do formulário;
- corrigir Salvar;
- corrigir Salvar + Próximo;
- corrigir Salvar + Anterior;
- impedir navegação durante salvamento;
- navegar somente após confirmação de sucesso.

## Fora de escopo
- remover `compra_diaria`;
- remover colunas legadas;
- criar `insumo_contexto_estoque`;
- redesenhar definitivamente metas;
- reconstruir contagens;
- reconstruir Painel de Compras.

## Testes mínimos
- abrir e salvar sem alteração não muda dados;
- editar campo e reabrir mostra valor correto;
- metas existentes permanecem intactas;
- Salvar + Próximo salva o item atual e abre o próximo;
- Salvar + Anterior salva o item atual e abre o anterior;
- erro SQL não navega;
- duplo clique não gera gravação inconsistente.

## Critério de aceite
Cadastro atual confiável para uso até a migração do CHANGE-002A, sem perda silenciosa de configuração.
