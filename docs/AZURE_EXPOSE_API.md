# Configuração — Expor a API do Portal no Azure AD

Complementa o tutorial existente (`docs/entradoc/manual.jpeg`). Necessário para
que o backend valide o `aud` do access token.

## Pré-requisitos

- App registration `gjamobile` (Client ID `2ad10533-fc70-4047-80dc-281ca6dd9d83`)
- Tenant `eae4ae33-655b-4234-88d6-56e5cc13e38c`
- Steps 1–3 do `manual.jpeg` já executados

## Passo 4 — Expor a API

1. **Portal do Azure → Microsoft Entra ID → Registros de aplicativo → gjamobile**
2. Menu lateral em **Gerenciar → Expor uma API**
3. Ao lado de **URI da ID do aplicativo**, clicar em **Definir**
   - Aceitar o default `api://2ad10533-fc70-4047-80dc-281ca6dd9d83`
   - **Salvar**

## Passo 5 — Criar o escopo `access`

Ainda em **Expor uma API**:

1. **+ Adicionar um escopo**
2. Preencher:
   | Campo | Valor |
   |---|---|
   | Nome do escopo | `access` |
   | Quem pode consentir | Admins e usuários |
   | Nome de exibição (admin) | Acessar Portal API |
   | Descrição (admin) | Permite que o app chame a API do Portal em nome do usuário |
   | Nome de exibição (usuário) | Acessar Portal API |
   | Descrição (usuário) | Permite que o aplicativo acesse a API do Portal como você |
   | Estado | Habilitado |
3. **Adicionar escopo**

Scope final: `api://2ad10533-fc70-4047-80dc-281ca6dd9d83/access`

## Passo 6 — Autorizar o próprio app como cliente

Ainda em **Expor uma API**, seção **Aplicativos cliente autorizados**:

1. **+ Adicionar um aplicativo cliente**
2. **ID do cliente:** `2ad10533-fc70-4047-80dc-281ca6dd9d83` (o próprio app reg)
3. Marcar o checkbox do escopo `access` recém-criado
4. **Adicionar aplicativo**

Self-authorize evita o prompt de consent no primeiro login.

## Passo 7 — Adicionar a permissão delegada

1. Menu lateral **Permissões de API → + Adicionar uma permissão**
2. Aba **Minhas APIs → gjamobile**
3. **Permissões delegadas → access → Adicionar permissões**
4. Voltar à tela de Permissões de API e clicar em
   **Conceder consentimento de administrador para Grupo José Alves**

## Passo 8 — Optional claims no access token

Por padrão o access token v2 (audience = sua API) **não inclui** `email` nem
`preferred_username`. Sem essas claims o backend grava o usuário sem email e a
checagem de admin (`portal.admin.emails`) falha silenciosamente.

1. Menu lateral **Configuração de token** (Token configuration)
2. **+ Adicionar declaração opcional**
3. **Tipo de token:** marcar **Access**
4. Selecionar as claims:
   - `email`
   - `upn`
   - `preferred_username`
5. **Adicionar**
6. Se aparecer o aviso *"Ativar permissão do Microsoft Graph email"*, marcar a
   caixa e confirmar — adiciona automaticamente a permissão `email` ao app.
7. Voltar em **Permissões de API** → **Conceder consentimento de administrador
   para Grupo José Alves** (refaz, agora cobrindo a permissão `email` se foi
   adicionada).

### Validação

Decodificar `accessToken` em https://jwt.ms após novo login — deve conter pelo
menos uma das claims:

```json
{
  "email": "usuario@dominio.com",
  "preferred_username": "usuario@dominio.com"
}
```

O backend faz fallback na ordem `email` → `preferred_username` → `upn` →
`unique_name` em `UserService.syncFromClaims`, então qualquer uma delas resolve.

## Variáveis a usar

**Frontend `.env`:**
```
AZURE_API_SCOPE=api://2ad10533-fc70-4047-80dc-281ca6dd9d83/access
```

**Backend `.env`:**
```
PORTAL_API_AUDIENCES=api://2ad10533-fc70-4047-80dc-281ca6dd9d83,2ad10533-fc70-4047-80dc-281ca6dd9d83
```

A audiência do access token chega como Application ID URI por padrão no
manifesto v2, mas configuramos ambos para tolerar manifests legados.

## Validação rápida

Após login bem-sucedido, decodifique o `accessToken` em https://jwt.ms — deve
conter:
```json
{
  "aud": "api://2ad10533-fc70-4047-80dc-281ca6dd9d83",
  "iss": "https://login.microsoftonline.com/eae4ae33-655b-4234-88d6-56e5cc13e38c/v2.0",
  "scp": "access",
  "tid": "eae4ae33-655b-4234-88d6-56e5cc13e38c"
}
```
