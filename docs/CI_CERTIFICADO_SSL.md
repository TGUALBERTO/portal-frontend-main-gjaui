# CI/CD — Certificado SSL corporativo (`SSL_CERTIFICATE_BAND`)

Guia de referência para o pipeline do **portal-frontend** (Flutter) no GitLab CI
quando aparecem erros de **SSL/handshake** ao baixar pacotes (`flutter pub get`)
ou artefatos durante o `flutter build web`.

> Existe um guia equivalente no **portal-backend** (`docs/CI_CERTIFICADO_SSL.md`).
> A causa é a mesma; a **forma de confiar na CA muda**, porque o Dart/Flutter
> **não** usam o `cacerts`/`keytool` do Java (ver seção 1).

---

## 1. Contexto do problema

A rede corporativa usa um **proxy que inspeciona o tráfego TLS** (MITM): ele
intercepta as conexões HTTPS de saída e **reassina o certificado** com a **CA
interna** (`band`/rebic). Ferramentas que só confiam nas CAs públicas passam;
ferramentas cujo trust store não conhece a CA interna, **não**.

Sintoma típico durante o `flutter pub get`:

```
Got TlsException ... HandshakeException: Handshake error in client
(OS Error: CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate ...)
```

### A diferença em relação ao backend Java

| | Backend (Java) | Frontend (Flutter/Dart) |
| --- | --- | --- |
| Como confia na CA | `keytool -importcert ... -cacerts` | `update-ca-certificates` + variável `SSL_CERT_FILE` |
| Onde busca as CAs | `$JAVA_HOME/lib/security/cacerts` | Bundle do sistema apontado por `SSL_CERT_FILE` |

O Dart/Flutter localizam as CAs confiáveis pela variável de ambiente
**`SSL_CERT_FILE`** (e `SSL_CERT_DIR`). A correção é:

1. **Adicionar a CA interna ao bundle do sistema** — gravar o certificado da
   variável `SSL_CERTIFICATE_BAND` em `/usr/local/share/ca-certificates/` e rodar
   `update-ca-certificates`, que regenera `/etc/ssl/certs/ca-certificates.crt`
   com a CA interna **+** todas as CAs públicas.
2. **Apontar o Dart para esse bundle** — definir
   `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt`.

> Não existe aqui o erro de `tar`/`openat2` do backend: as imagens Flutter já
> trazem a toolchain instalada, então nada é baixado+extraído por um wrapper.

---

## 2. A variável `SSL_CERTIFICATE_BAND`

É uma variável **CI/CD do GitLab** (não fica no repositório) com o **certificado
da CA interna** em **PEM**. É **por projeto** — precisa existir no
`portal-frontend`, mesmo que já exista no `portal-backend`.

Configuração em **Settings → CI/CD → Variables**:

| Campo               | Valor recomendado                                            |
| ------------------- | ----------------------------------------------------------- |
| **Key**             | `SSL_CERTIFICATE_BAND` (nome exato, sem espaços/sufixos)     |
| **Value**           | Conteúdo PEM da CA (ou o arquivo, se tipo *File*)            |
| **Type**            | `File` (recomendado) ou `Variable`                           |
| **Protected**       | **Desmarcado** (ver ⚠️ abaixo)                              |
| **Masked**          | Desmarcado (PEM multi-linha não pode ser mascarado)         |
| **Environment scope** | `*` (All)                                                 |

O pipeline trata **os dois tipos** automaticamente:
- **File** → a variável expande para o **caminho** de um arquivo → o script copia.
- **Variable** → a variável expande para o **conteúdo PEM** → o script grava.

> ⚠️ **Protected**: variáveis *Protected* só existem em **branches/tags protegidas**.
> Um pipeline de **Merge Request numa branch comum** recebe a variável **vazia** e
> o erro de handshake volta. Se precisar rodar em MRs, **desmarque Protected** ou
> torne a branch protegida em *Settings → Repository → Protected branches*.

---

## 3. Onde a variável é usada no `.gitlab-ci.yml`

### Template `.flutter_job` (`before_script` + `variables`) — jobs `analyze` e `build_apk`
Adiciona a CA ao trust store antes de qualquer download. O bloco vive no template
oculto `.flutter_job`, que os dois jobs estendem:

```yaml
.flutter_job:
  variables:
    SSL_CERT_FILE: /etc/ssl/certs/ca-certificates.crt
  before_script:
    - |
      if [ -n "${SSL_CERTIFICATE_BAND:-}" ]; then
        # grava o PEM em /tmp/band-ca.pem (tipo File: cp; tipo Variable: printf)
        # e separa cada bloco BEGIN CERTIFICATE em band-ca-1.crt, band-ca-2.crt, ...
        awk -v dir=/usr/local/share/ca-certificates '/BEGIN CERTIFICATE/{n++; f=sprintf("%s/band-ca-%d.crt", dir, n)} n>0{print > f}' /tmp/band-ca.pem
        update-ca-certificates
        # Gradle roda na JVM e NAO le o SSL_CERT_FILE: cada .crt entra tambem no cacerts do JDK
        for crt in /usr/local/share/ca-certificates/band-ca-*.crt; do
          keytool -importcert -noprompt -trustcacerts -cacerts -storepass changeit -alias "$(basename "$crt" .crt)" -file "$crt"
        done
      fi
```

Dois detalhes que só importam para o `build_apk` (APK Android):

- **JDK também.** O Gradle roda na JVM e ignora o `SSL_CERT_FILE`; por isso cada
  certificado entra no `cacerts` do JDK via `keytool` (mesmo truque do backend).
- **Vários certificados.** Se a variável trouxer mais de um bloco PEM (raiz +
  intermediária), cada um vai num `.crt` e num alias próprio: o `keytool` só importa
  o primeiro certificado de um PEM. O log mostra, para cada um, se é CA
  (`[CA]`, `basicConstraints CA:TRUE`) ou certificado de servidor.

### Job `build_web` e o `docker_build`
O site também é compilado por um job que estende o `.flutter_job` (`build_web`), então
recebe a CA pelo mesmo `before_script`. O `docker_build` **não precisa mais do
certificado**: ele só empacota o `build/web` pronto num nginx
([`Dockerfile.ci`](../Dockerfile.ci)), sem `flutter pub get` nem nenhuma chamada HTTPS
de build.

### `Dockerfile` multi-stage (só build local)
O pipeline não usa mais este arquivo, mas ele continua servindo para `docker build .`
na máquina. Como o `flutter build web` roda **dentro** dele, atrás do proxy a CA
precisa entrar no estágio de build, via build-arg em base64 (evita quebra de
linha/aspas):

```sh
CA_CERT_B64="$(base64 -w0 band-ca.crt)"
docker build --build-arg CA_CERT_B64="$CA_CERT_B64" .
```

```dockerfile
# Dockerfile (estágio de build)
ARG CA_CERT_B64=""
RUN if [ -n "$CA_CERT_B64" ]; then \
      echo "$CA_CERT_B64" | base64 -d > /usr/local/share/ca-certificates/band-ca.crt && \
      update-ca-certificates; \
    fi
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
```

O estágio de runtime (`nginx:alpine`) **não** recebe o certificado — ele só serve
os estáticos e não faz chamadas HTTPS de saída no build.

---

## 4. Como confirmar no log do pipeline

**Sucesso** (job `analyze`):
```
SSL_CERTIFICATE_BAND presente (tamanho=NNNN)
-> tipo File; copiando de /builds/.../SSL_CERTIFICATE_BAND
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.
CA 'band-ca' adicionada ao trust store do sistema.
```

**Variável não chegou** (causa mais comum do erro de handshake):
```
AVISO: SSL_CERTIFICATE_BAND vazio/ausente neste job.
  Confira o nome EXATO da variavel e se ela NAO esta marcada como 'Protected' ...
```

---

## 5. Diagnóstico rápido (tabela)

| Sintoma no log | Causa provável | Como resolver |
| -------------- | -------------- | ------------- |
| `CERTIFICATE_VERIFY_FAILED` / `HandshakeException` + `AVISO: ... vazio/ausente` | Variável ausente, nome errado, marcada como *Protected* ou fora do *environment scope* | Criar/renomear a variável; **desmarcar Protected**; scope `*` (seção 2) |
| `CERTIFICATE_VERIFY_FAILED` **sem** o `AVISO` (variável presente) | Certificado **errado** ou faltando o **root CA** da cadeia | Exportar a CA correta do proxy e atualizar a variável (seção 6) |
| `update-ca-certificates: not found` | Imagem sem o pacote `ca-certificates` | Instalar o pacote na imagem, ou usar `SSL_CERT_FILE` apontando direto p/ um bundle que você mesmo monte |
| `update-ca-certificates`: `0 added` | O arquivo não terminou em `.crt` ou não é PEM válido | Garantir extensão `.crt` em `/usr/local/share/ca-certificates/` e PEM válido (seção 6) |
| `build_apk`: `ERRO: dl.google.com esta BLOQUEADO pelo proxy` — a cadeia mostra o certificado do **próprio proxy** (`CN=192.168.30.20`) no lugar do do site, e `curl -> HTTP 000` | **Não é problema de CA**: o filtro web bloqueia o host e devolve a página de bloqueio. Nenhuma CA na variável resolve, porque o nome do host não bate | Abrir chamado para liberar o host no proxy — texto pronto em [`CHAMADO_LIBERACAO_DL_GOOGLE.md`](CHAMADO_LIBERACAO_DL_GOOGLE.md) |

---

## 6. Como obter/atualizar o certificado da CA

Extrair a cadeia que o proxy apresenta (o **último** certificado costuma ser o
**root CA** a confiar):

```sh
openssl s_client -connect pub.dev:443 -showcerts </dev/null
```

Validar um PEM antes de subir para o GitLab:

```sh
openssl x509 -in band-ca.crt -noout -subject -issuer -dates
```

> **Cadeia com vários certificados:** o `update-ca-certificates` processa cada
> arquivo `.crt` como **um** certificado. Se o PEM tiver mais de um bloco
> `BEGIN CERTIFICATE`, separe-os em arquivos distintos (`band-ca-root.crt`,
> `band-ca-intermediate.crt`, …) ou garanta que o **root CA** esteja presente.

Depois de atualizar a variável em *Settings → CI/CD → Variables*, **rode o
pipeline novamente**.

---

## 7. Arquivos relacionados

- [`.gitlab-ci.yml`](../.gitlab-ci.yml) — template `.flutter_job` (jobs `analyze`, `build_web` e `build_apk`).
- [`Dockerfile.ci`](../Dockerfile.ci) — imagem do pipeline: nginx + site pronto, sem certificado.
- [`CHAMADO_LIBERACAO_DL_GOOGLE.md`](CHAMADO_LIBERACAO_DL_GOOGLE.md) — bloqueio do `dl.google.com` no runner (não é CA; é liberação de host).
- [`Dockerfile`](../Dockerfile) — build local; estágio de build (`ARG CA_CERT_B64`, `ENV SSL_CERT_FILE`).
