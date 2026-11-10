# Chamado — Liberar `dl.google.com` para o GitLab Runner (`golgit001`)

Texto pronto para abrir chamado na infraestrutura/redes. O bloqueio impede o job
`build_apk` do pipeline do **portal-frontend** de gerar o APK Android (coletor da
doca). Evidências e comandos de validação no final.

> Relacionado: [`CI_CERTIFICADO_SSL.md`](CI_CERTIFICADO_SSL.md) (a variável
> `SSL_CERTIFICATE_BAND` **não** resolve este caso — ver seção "Por que não é
> problema de certificado").

---

## Texto do chamado

**Assunto:** Liberar acesso HTTPS a `dl.google.com` para o servidor `golgit001` (GitLab Runner)

**Solicitação**

Liberar o acesso de saída **HTTPS (TCP 443)** ao host **`dl.google.com`** a partir
do servidor **`golgit001`**, incluindo os containers Docker que rodam nele (o
tráfego deles sai pelo IP do próprio servidor).

**Contexto**

O `golgit001` hospeda os runners do GitLab interno (`gitlab.rebic.com.br`):
`runner-java8` e `runner-java25`, executor Docker. O pipeline do projeto
`gja/portal/portal-frontend` (Portal GJA, app Flutter) ganhou um job que compila o
APK Android usado nos coletores da doca. Esse build precisa baixar o **Android
Gradle Plugin**, as bibliotecas **AndroidX** e componentes do **Android SDK**, e
todos vêm do repositório Maven do Google, servido exclusivamente em
`https://dl.google.com` (caminhos `/dl/android/maven2/` e `/android/repository/`).

**O que está acontecendo**

Hoje o filtro web bloqueia esse host para o `golgit001`. Na conexão TLS com
`dl.google.com:443`, em vez do certificado do Google, chega o certificado do
próprio proxy (`CN=192.168.30.20`, emitido pela CA `Refrescos Bandeirantes`) com a
página de bloqueio, e nenhum conteúdo HTTP é entregue. O build do Android falha
por não conseguir baixar o plugin do Gradle.

Da rede das estações de trabalho o mesmo endereço responde normalmente
(HTTP 200, certificado `CN=*.google.com` emitido por Google Trust Services), então
o bloqueio é específico do caminho de rede do `golgit001`.

Não há alternativa do lado da aplicação: `maven.google.com` apenas redireciona
(HTTP 301) para `dl.google.com`, e não existe espelho interno desse repositório.

**Já liberados a partir do mesmo servidor (funcionam)**

`pub.dev`, `storage.googleapis.com`, `repo.maven.apache.org`, `plugins.gradle.org`,
`services.gradle.org`, `ghcr.io`, `gcr.io`.

**Como validar após a liberação** (no `golgit001` ou dentro de um container dele)

```sh
curl -sS -o /dev/null -w '%{http_code}\n' \
  https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.11.1/gradle-8.11.1.pom
# esperado: 200

openssl s_client -connect dl.google.com:443 -servername dl.google.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer
# esperado: subject=CN=*.google.com / issuer=...Google Trust Services...
```

Depois disso basta reexecutar o job `build_apk` do pipeline; ele valida o acesso
antes do build e segue sozinho.

**Impacto**

Sem a liberação o APK de produção do Portal GJA não pode ser gerado pelo
pipeline. O deploy web do mesmo projeto não é afetado.

**Contato:** Igor Bittencourt (TI / Portal GJA)

---

## Evidências

Coletadas em **24/09/2026** pelo job `build_apk` (pipelines `#100`, `#102` e
`#104` do projeto, branch `main`, runners `runner-java25` e `runner-java8`, ambos
"via golgit001", imagem `ghcr.io/cirruslabs/flutter:stable`).

Cadeia TLS recebida de `dl.google.com:443` de dentro do container:

```
 0 s:ST = GO, L = Trindade, O = Refrescos Bandeirantes, OU = TI, CN = 192.168.30.20, emailAddress = suporte@rebic.com.br
   i:DC = br, DC = com, DC = rebic, CN = Refrescos Bandeirantes
 1 s:DC = br, DC = com, DC = rebic, CN = Refrescos Bandeirantes
   i:DC = br, DC = com, DC = rebic, CN = Refrescos Bandeirantes
```

Requisição HTTP ao POM do Android Gradle Plugin, do mesmo container:

```
curl -> HTTP 000 : https://dl.google.com/dl/android/maven2/com/android/application/com.android.application.gradle.plugin/8.11.1/com.android.application.gradle.plugin-8.11.1.pom
```

Mesmo host, a partir de uma estação de trabalho na rede corporativa:

```
 0 s:CN=*.google.com
   i:C=US, O=Google Trust Services, CN=WE2
HTTP 200
```

Sintoma no Gradle (o que aparecia antes do diagnóstico):

```
Plugin [id: 'com.android.application', version: '8.11.1', apply: false] was not found in any of the following sources:
- Plugin Repositories (could not resolve plugin artifact 'com.android.application:com.android.application.gradle.plugin:8.11.1')
  Searched in the following repositories: Google, MavenRepo, Gradle Central Plugin Repository
```

O "not found" no Maven Central e no Plugin Portal é legítimo (o artefato só existe
no repositório do Google); o Gradle lista os três porque a falha real, no Google,
é de rede e ele a esconde nessa mensagem.

## Por que não é problema de certificado

A variável de CI `SSL_CERTIFICATE_BAND` contém a CA intermediária do proxy e está
correta para os hosts que ele **inspeciona**. Aqui o proxy não inspeciona: ele
**bloqueia**, e usa o próprio certificado de CA como certificado de servidor da
página de bloqueio. Confiar nessa CA não muda nada, porque o nome do host
(`dl.google.com`) não bate com o do certificado (`192.168.30.20`) e o conteúdo
devolvido é a página de bloqueio, não o artefato. A única correção é liberar o
host.

## Onde isso está no pipeline

O job `build_apk` em [`.gitlab-ci.yml`](../.gitlab-ci.yml) sonda `dl.google.com`
antes de baixar qualquer coisa. Enquanto o bloqueio existir, ele falha em poucos
segundos com a mensagem `ERRO: dl.google.com esta BLOQUEADO pelo proxy/filtro web
do runner` e imprime a cadeia recebida. Quando o host for liberado, o mesmo job
segue para o build sem nenhuma alteração.
