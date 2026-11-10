# Android — Assinatura de release do APK (`gjamobile`)

Como o APK do Portal GJA é assinado, onde fica o keystore e o que configurar no
GitLab para o job `build_apk` assinar com ele.

---

## 1. Por que isso existe

O Android só instala uma atualização **por cima** do app se ela vier assinada com
o **mesmo certificado** da versão instalada. Com certificado diferente o sistema
recusa ("App não instalado") e a única saída é desinstalar antes — o que apaga os
dados locais do app.

A chave de **debug** é gerada por máquina: a do runner do CI é diferente da de
cada desenvolvedor. Um APK assinado com ela instala num aparelho limpo, mas não
atualiza por cima de um build feito em outro lugar. Para distribuir atualização
(manual ou automática) o release precisa de **um keystore fixo**.

---

## 2. Como funciona

```
keystore (.jks) + senha
      │
      ├── CI:    variáveis ANDROID_KEYSTORE_*  ──►  job build_apk escreve android/key.properties
      └── local: scripts/gen-android-keystore.ps1 -WriteKeyProperties
                                                        │
                                android/app/build.gradle.kts lê o key.properties
                                                        │
                              existe  ──► signingConfig "release" (keystore fixo)
                              não existe ──► signingConfig "debug" (como era antes)
```

- [`android/app/build.gradle.kts`](../android/app/build.gradle.kts) lê
  `android/key.properties`. **Sem o arquivo nada muda**: o release continua assinado
  com a chave de debug, e `flutter run --release` funciona em qualquer máquina.
- `android/key.properties`, `*.jks` e `*.keystore` já são ignorados em
  [`android/.gitignore`](../android/.gitignore). **Nenhum segredo vai para o repositório.**
- O job `build_apk` em [`.gitlab-ci.yml`](../.gitlab-ci.yml) monta o `key.properties`
  a partir das variáveis, valida senha e alias com `keytool -list` antes do build,
  e ao final imprime quem assinou o APK (`apksigner verify --print-certs`). Com o
  keystore configurado, sair assinado com a chave de debug **falha o job**.

Formato do `key.properties`:

```properties
storeFile=C:/Users/fulano/.gja-keys/gjamobile-release.jks
storePassword=<senha>
keyAlias=gjamobile
keyPassword=<senha>
```

> Em `.properties` a barra invertida é escape: o caminho vai sempre com `/`.
> O keystore é PKCS12, que tem **uma senha só** (a da chave é a do store).

---

## 3. Gerar o keystore (uma vez)

```powershell
pwsh scripts\gen-android-keystore.ps1                      # só o keystore + base64
pwsh scripts\gen-android-keystore.ps1 -WriteKeyProperties  # + android\key.properties local
```

O script:

1. gera uma senha aleatória de 32 caracteres alfanuméricos;
2. cria `%USERPROFILE%\.gja-keys\gjamobile-release.jks` (PKCS12, RSA 2048, validade
   de ~27 anos, alias `gjamobile`);
3. grava `gjamobile-release.base64.txt` (o keystore em base64, uma linha);
4. mostra **a senha** (uma única vez), o **SHA-256** do certificado e as variáveis a
   criar no GitLab.

Ele **nunca sobrescreve** um keystore existente.

> ⚠️ **Guarde o `.jks` e a senha em local seguro da empresa.** Quem perde
> qualquer um dos dois nunca mais consegue atualizar o app já instalado nos
> coletores — só desinstalando um por um. Não existe recuperação.

### Onde está o keystore em uso

Gerado em **01/10/2026** e guardado no servidor da empresa:

```
Y:\AMS\AMS APLICAÇÕES\gjamobile-release.jks
```

- Alias `gjamobile`, PKCS12, RSA 2048.
- A **senha não fica nessa pasta nem no repositório**: está na variável
  `ANDROID_KEYSTORE_PASSWORD` do GitLab. Mantenha uma cópia também fora do GitLab.
- O `gjamobile-release.base64.txt` que está ao lado é o próprio keystore em base64
  (o valor da variável `ANDROID_KEYSTORE_BASE64`). Criada a variável, pode ser apagado.
- O SHA-256 do certificado aparece no log de todo `build_apk`
  (`Signer #1 certificate SHA-256 digest`). É a identidade do app: enquanto for o
  mesmo, as atualizações instalam por cima.

---

## 4. Variáveis no GitLab

**Settings → CI/CD → Variables** do projeto `portal-frontend`:

| Key | Value | Type | Protected | Masked |
| --- | ----- | ---- | --------- | ------ |
| `ANDROID_KEYSTORE_BASE64` | **todo** o conteúdo do arquivo `gjamobile-release.base64.txt` (uma linha, ~3,7 mil caracteres) | Variable | **Sim** | **Sim** |
| `ANDROID_KEYSTORE_PASSWORD` | a senha mostrada pelo script | Variable | **Sim** | **Sim** |
| `ANDROID_KEY_ALIAS` | `gjamobile` (opcional; é o padrão) | Variable | Sim | Não |

- O valor de `ANDROID_KEYSTORE_BASE64` é o **arquivo**, não o SHA-256 que o script
  mostra para conferência. Para copiar sem erro:
  `Get-Content -Raw "<pasta>\gjamobile-release.base64.txt" | Set-Clipboard`.
  Um SHA-256 colado ali passa pelo `base64 -d` (64 caracteres hexadecimais são base64
  válido) e só falha no `keytool`; o log denuncia com
  `ANDROID_KEYSTORE_BASE64: 64 caracteres -> keystore de 48 bytes`.
- **Protected = Sim**, ao contrário da `SSL_CERTIFICATE_BAND`: o `build_apk` só roda
  na `main`, que é protegida, e pipeline de Merge Request não pode enxergar a chave
  de assinatura.
- **Masked = Sim**: o valor não aparece no log mesmo que algum comando o imprima.
- Depois de criar as variáveis, apague o `gjamobile-release.base64.txt`.

---

## 5. Conferir no log do `build_apk`

Com as variáveis:

```
Assinatura: keystore de release (alias 'gjamobile').
...
Signer #1 certificate DN: CN=Portal GJA, OU=TI, O=Refrescos Bandeirantes, L=Trindade, ST=GO, C=BR
Signer #1 certificate SHA-256 digest: <o "SHA-256 no CI" que o script mostrou>
```

O `apksigner` imprime o digest em minúsculas e sem `:`; o script mostra o SHA-256
nos dois formatos para a comparação ser direta.

Sem as variáveis (comportamento antigo, com aviso):

```
AVISO: ANDROID_KEYSTORE_BASE64 / ANDROID_KEYSTORE_PASSWORD ausentes neste job.
...
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
```

| Sintoma | Causa provável | Como resolver |
| ------- | -------------- | ------------- |
| `AVISO: ... ausentes neste job` mesmo com as variáveis criadas | Variável *Protected* e a branch do pipeline não é protegida; nome errado; *environment scope* diferente de `*` | Conferir o nome exato e que a `main` é protegida |
| `ERRO: o keystore montado a partir das variaveis nao abriu` + `keytool: ... keystore password was incorrect` | Senha errada na variável, ou colada com espaço/quebra de linha (o log diz o tamanho e se há caractere fora de letras e dígitos; o esperado é 32, só letras e dígitos). Se o tamanho ou o sha256 do keystore não baterem com o `.jks` guardado, o problema é a variável do base64 | Corrigir a variável indicada e reexecutar o job |
| `ERRO: ...` + `keytool: ... Alias <x> does not exist` | `ANDROID_KEY_ALIAS` diferente do alias do keystore | Remover a variável (padrão `gjamobile`) ou corrigir |
| `ERRO: ANDROID_KEYSTORE_BASE64 ... nao e um base64 valido` | Valor da variável com espaço, quebra de linha ou truncado | Colar o conteúdo inteiro do `.base64.txt` |

Para testar a senha **antes** de mexer na variável, na sua máquina (o `keytool` pede a
senha; se listar a entrada `gjamobile`, a senha está certa):

```powershell
keytool -list -keystore "Y:\AMS\AMS APLICAÇÕES\gjamobile-release.jks" -alias gjamobile
Get-FileHash "Y:\AMS\AMS APLICAÇÕES\gjamobile-release.jks"   # compara com o sha256 do log
```
| `ERRO: keystore de release configurado, mas o APK saiu assinado com a chave de debug` | O Gradle não leu o `key.properties` | Conferir o bloco de assinatura no `build.gradle.kts` |

---

## 6. A primeira instalação com a chave nova

Os coletores que hoje têm o app instalado a partir de um build com chave de debug
**não** aceitam o APK assinado com o keystore de release por cima. Na primeira
vez é preciso **desinstalar** e instalar o APK novo. Dali em diante todo APK do
pipeline atualiza por cima.

---

## 7. Arquivos relacionados

- [`android/app/build.gradle.kts`](../android/app/build.gradle.kts) — leitura do `key.properties` e `signingConfigs`.
- [`.gitlab-ci.yml`](../.gitlab-ci.yml) — job `build_apk` (keystore, conferência da assinatura).
- [`scripts/gen-android-keystore.ps1`](../scripts/gen-android-keystore.ps1) — gera keystore, base64 e `key.properties`.
- [`CI_CERTIFICADO_SSL.md`](CI_CERTIFICADO_SSL.md) — a outra variável do pipeline (`SSL_CERTIFICATE_BAND`).
