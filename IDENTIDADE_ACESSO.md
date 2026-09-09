# DOMÍNIO — IDENTIDADE E ACESSO

## Estado atual
Frontend possui regras de acesso em `frontend/utils/accessControl.ts`.

Papéis observados/planejados:
- DEV
- ADMIN
- CD
- LOJA

## Risco
Bloqueio visual não é segurança suficiente.

## Estado alvo
- validar autorização no backend/RPC;
- RLS coerente no banco;
- auditoria por usuário;
- princípio de menor privilégio.
