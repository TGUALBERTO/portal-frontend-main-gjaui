# Configuração do App Registration no Azure — `gjamobile`

Este documento descreve as alterações necessárias no registro de aplicativo do Azure AD / Entra ID para que o aplicativo **gjamobile** consiga autenticar usuários via OAuth2.

Atualmente o login falha com o erro:

```text
AADSTS900971: No reply address provided.
```

Porque o app registrado ainda **não possui nenhum URI de redirecionamento** nem está habilitado como **cliente público**.

---

## Dados do aplicativo

| Campo | Valor |
| --- | --- |
| Nome | `gjamobile` |
| ID do aplicativo (cliente) | `2ad10533-fc70-4047-80dc-281ca6dd9d83` |
| ID do diretório (locatário) | `eae4ae33-655b-4234-88d6-56e5cc13e38c` |
| Tipos de conta | Várias organizações (multi-tenant) |

---

## O que precisa ser configurado

O app é um **cliente público** (mobile + desktop + web, sem backend intermediário), então usa **OAuth2 Authorization Code + PKCE**. Isso exige:

1. Cadastrar **URIs de redirecionamento** para cada plataforma (móvel/desktop **e** web).
2. Habilitar **fluxos de cliente público**.

Nenhum *client secret* é necessário (e não deve ser criado — apps públicos não podem proteger segredos).

---

## Passo 1 — Adicionar a plataforma "Aplicativos móveis e de desktop"

1. Acessar: **Portal do Azure** → **Registros de aplicativo** → **gjamobile**.
2. No menu lateral, em *Gerenciar*, clicar em **Autenticação**.
3. Clicar em **+ Adicionar uma plataforma**.
4. Escolher **Aplicativos móveis e de desktop** (NÃO "Web" nem "Aplicativos de página única").
5. No painel que abrir, na seção **URIs de Redirecionamento Personalizados**, adicionar os dois URIs abaixo (um por linha):

   ```text
   http://localhost
   com.gja.gjamobile://oauth2redirect
   ```

   | URI | Plataforma | Observação |
   | --- | --- | --- |
   | `http://localhost` | Windows Desktop | A Microsoft aceita qualquer porta dinâmica quando o URI é `http://localhost` sem porta explícita. |
   | `com.gja.gjamobile://oauth2redirect` | Android | Esquema próprio (reverse-domain), capturado pelo intent-filter do app. Evitamos `msauth://` de propósito: aquele esquema colide com o broker do Microsoft Authenticator e impede o retorno ao app. |

6. Clicar em **Configurar**.

---

## Passo 2 — Adicionar a plataforma "Aplicativo de página única (SPA)"

A versão **web** do Portal roda como SPA Flutter Web. Use o tipo **Aplicativo de página única (SPA)** — NÃO "Web". O tipo "Web" pressupõe *client secret* (cliente confidencial); o SPA habilita CORS no endpoint de token e suporta PKCE, que é o que um app público no navegador precisa.

1. Ainda na tela de **Autenticação**, clicar em **+ Adicionar uma plataforma**.
2. Escolher **Aplicativos de página única**.
3. Adicionar os URIs de redirecionamento abaixo (um por vez):

   ```text
   https://portal.rebic.com.br/auth.html
   https://portal-qas.rebic.com.br/auth.html
   ```

   | URI | Ambiente | Observação |
   | --- | --- | --- |
   | `https://portal.rebic.com.br/auth.html` | Produção | Origem da versão web em produção. |
   | `https://portal-qas.rebic.com.br/auth.html` | QAS | Origem da versão web de homologação. |

   > **Path `/auth.html` é obrigatório.** No web o login abre um popup que retorna para a página de callback [`web/auth.html`](../web/auth.html); ela repassa o `code` para o app via `postMessage` e fecha o popup. O match do redirect URI no Azure é exato (protocolo + host + porta + path), então o `/auth.html` precisa estar no URI cadastrado.

   > Para desenvolvimento local da web, adicionar também `http://localhost:<porta>/auth.html` (ex.: `http://localhost:5000/auth.html`) com a porta usada pelo `flutter run -d chrome` (a config `portal-frontend (web :5000)` do `.vscode/launch.json` fixa a porta em 5000). Opcional — só necessário para testar o login web na máquina do dev.

4. Clicar em **Configurar**.

---

## Passo 3 — Habilitar fluxos de cliente público

Ainda na tela de **Autenticação**:

1. Rolar até a seção **Configurações avançadas**.
2. Localizar a opção **Permitir fluxos de cliente público**.
3. Marcar como **Sim**.
4. Clicar em **Salvar** no topo da página.

---

## Passo 4 — Permissões de API e Admin Consent

Como o tenant do Grupo José Alves exige consentimento administrativo (usuários comuns não conseguem autorizar apps por conta própria), é **obrigatório** conceder "Admin Consent" uma vez.

### 4.1 — Conferir/adicionar as permissões

1. No menu lateral do app registrado, clicar em **Permissões de API**.
2. Garantir que as seguintes **permissões delegadas** do **Microsoft Graph** estejam listadas:
   - `openid`
   - `profile`
   - `email`
   - `offline_access`
3. Caso alguma não esteja, clicar em **+ Adicionar uma permissão** → **Microsoft Graph** → **Permissões delegadas** → buscar cada nome acima e marcar.

### 4.2 — Conceder consentimento de administrador

Ainda na tela **Permissões de API**:

1. Clicar no botão **"Conceder consentimento de administrador para Grupo José Alves"** (fica no topo da lista de permissões).
2. Confirmar na caixa de diálogo.
3. Verificar que a coluna **Status** de todas as permissões mude para **"Concedido para Grupo José Alves"** (com ícone verde ✔).

**Sem esse passo**, o usuário vê a tela *"Aprovação necessária — Este aplicativo exige aprovação do seu administrador"* e não consegue fazer login.

---

## Resultado esperado

Após as alterações, a tela de **Autenticação** deve mostrar:

- **Aplicativos móveis e de desktop** com os 2 URIs cadastrados.
- **Aplicativos de página única (SPA)** com os URIs `https://portal.rebic.com.br/auth.html` e `https://portal-qas.rebic.com.br/auth.html`.
- **Permitir fluxos de cliente público**: **Sim**.

A partir daí, o fluxo de login no aplicativo gjamobile deve funcionar normalmente:

1. Usuário abre o app → clica em "Entrar com Microsoft".
2. Microsoft abre na página de login:
   - **Desktop (Windows)**: no navegador padrão; retorno para `http://localhost:<porta>`.
   - **Android**: no navegador/broker; retorno para `com.gja.gjamobile://oauth2redirect?...`.
   - **Web**: em um popup; retorno para `.../auth.html`, que repassa o código ao app via `postMessage` e fecha o popup.
3. App captura o código, troca por tokens (PKCE, sem client secret) e autentica o usuário.

> **Web — popups:** o navegador precisa permitir popups para a origem do Portal, senão o login falha com "Popup bloqueado pelo navegador".

---

## Erros comuns

| Código | Significado | Correção |
| --- | --- | --- |
| `AADSTS900971` | Nenhum URI de redirecionamento cadastrado. | Fazer os Passos 1–2. |
| `AADSTS50011` | O redirect URI enviado não bate com nenhum cadastrado. | Conferir match exato (protocolo + host + porta + path). No web tem que ser `.../auth.html`. |
| `AADSTS7000218` | Azure exige `client_secret`/`client_assertion` — app tratado como cliente confidencial. | O `http://localhost` está na plataforma **Web** em vez de **Móveis e desktop** (desktop) ou **SPA** (web). Mover para a plataforma certa e habilitar fluxos de cliente público (Passo 3). |
| `AADSTS65001` | Falta consentimento de administrador. | Fazer o Passo 4.2. |

## Em caso de erro

Se após a configuração ainda aparecer `AADSTS900971` ou outro erro `AADSTSxxxxxx`, copiar do painel de erro da Microsoft os campos:

- **Request Id**
- **Correlation Id**
- **Timestamp**
- **Message**

…e enviar ao time de desenvolvimento para correlação nos logs do Azure.
