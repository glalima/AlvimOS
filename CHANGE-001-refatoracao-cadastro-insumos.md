# CHANGE-001 — Refatoração do cadastro de insumos

**Status:** PLANEJADO / PRIORIDADE IMEDIATA  
**Domínio:** Insumos

## Problema
A tela de criação/edição apresenta problemas em Salvar, Anterior e Próximo, porém a causa estrutural é maior que navegação.

## Estado atual
- catálogo não retorna todas as chaves;
- formulário aplica defaults;
- metas não são carregadas;
- create/update duplicam regra;
- meta é atualizada fora de transação única;
- regra de volume atual conflita com casos reais.

## Estado alvo

### Banco
Criar:
- `vw_insumos_cadastro`
- RPC `salvar_insumo(...)`

RPC deve:
1. validar;
2. normalizar chaves;
3. persistir insumo;
4. persistir metas em transação;
5. retornar cadastro completo.

### Backend
Função fina:
- receber parâmetros;
- chamar RPC;
- retornar dados.

### Frontend
Responsável por:
- estado visual;
- validação de UX básica;
- Salvar;
- Salvar e Anterior;
- Salvar e Próximo.

## Meta
Evitar qualquer salvamento que modifique silenciosamente chaves/metas não carregadas.

## Critérios de aceite
- [ ] edição abre exatamente os valores do banco;
- [ ] gatilho aparece corretamente;
- [ ] metas existentes aparecem;
- [ ] salvar não zera meta não alterada;
- [ ] anterior/próximo salva e navega;
- [ ] erro de persistência impede navegação;
- [ ] create/update usam mesma regra;
- [ ] transação cobre insumo + metas.
