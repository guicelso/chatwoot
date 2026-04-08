# Chatwoot em Docker para Desenvolvimento

Este guia documenta o passo a passo para subir o Chatwoot localmente em Docker no ambiente de desenvolvimento deste repositório.

Importante:
- Este projeto foi ajustado para rodar localmente nas portas `3006`, `3036`, `55432`, `56379`, `11025` e `18025`.
- Use `localhost` e nao `127.0.0.1` para acessar a aplicacao.
- O login padrao de desenvolvimento funciona em `http://localhost:3006/auth/sign_in`.

## 1. Pre-requisitos

Voce precisa ter:
- Docker instalado
- Docker Compose instalado

Para conferir:

```bash
docker --version
docker compose version
```

## 2. Arquivos usados pelo ambiente

Os principais arquivos deste setup sao:
- `.env`
- `docker-compose.yaml`

As portas ja estao configuradas neste repositório para evitar conflito com outros servicos locais.

## 3. Primeira subida do ambiente

Entre na pasta do projeto:

```bash
cd /home/ti/projetos/lumia-project/chatwoot
```

Suba a infraestrutura base:

```bash
docker compose up -d postgres redis mailhog
```

Construa a imagem base de desenvolvimento:

```bash
docker build -f docker/Dockerfile -t chatwoot:development \
  --build-arg BUNDLE_WITHOUT='' \
  --build-arg EXECJS_RUNTIME=Node \
  --build-arg RAILS_ENV=development \
  --build-arg RAILS_SERVE_STATIC_FILES=false \
  .
```

Observacao:
- Esta etapa pode demorar bastante na primeira vez.
- Ela instala gems Ruby e dependencias Node dentro da imagem.

Depois suba a aplicacao:

```bash
docker compose up -d rails sidekiq vite
```

Prepare o banco:

```bash
docker compose exec rails bundle exec rails db:prepare
```

Se quiser popular dados de desenvolvimento:

```bash
docker compose exec rails bundle exec rails db:seed
```

Observacoes sobre o seed:
- Na primeira execucao ele cria dados de exemplo.
- Em execucoes posteriores ele pode falhar se o usuario padrao ja existir.
- Isso nao impede o ambiente de funcionar se o banco ja tiver sido preparado antes.

## 4. Subidas do dia a dia

Depois que o ambiente ja foi preparado uma vez, o fluxo normal costuma ser:

```bash
cd /home/ti/projetos/lumia-project/chatwoot
docker compose up -d postgres redis mailhog rails sidekiq vite
```

Se houver mudancas de schema ou se voce acabou de limpar volumes, rode:

```bash
docker compose exec rails bundle exec rails db:prepare
```

## 5. Como acessar

Aplicacao:

```text
http://localhost:3006
```

Tela de login:

```text
http://localhost:3006/auth/sign_in
```

Login de desenvolvimento:
- Email: `john@acme.inc`
- Senha: `Password1!`

Mailhog:

```text
http://localhost:18025
```

Vite dev server:

```text
http://localhost:3036
```

## 6. Como verificar se tudo subiu

Ver status dos containers:

```bash
docker compose ps
```

Ver logs:

```bash
docker compose logs -f rails
docker compose logs -f vite
docker compose logs -f sidekiq
```

Checagem rapida da UI:

```bash
curl -I http://localhost:3006/auth/sign_in
curl -I http://localhost:3006/app/login
```

Quando estiver tudo certo, voce deve ver resposta HTTP `302` ou `200`.

## 7. Como parar

Para parar os containers sem apagar dados:

```bash
docker compose stop
```

Para derrubar tudo mantendo volumes:

```bash
docker compose down
```

Para derrubar tudo e apagar os dados locais do banco e caches:

```bash
docker compose down -v
```

Cuidado:
- `down -v` apaga banco, redis, bundles e caches do ambiente local.
- Se usar `down -v`, sera preciso rodar `db:prepare` novamente.

## 8. Quando reconstruir imagens

Rebuild completo da imagem base:

```bash
docker build -f docker/Dockerfile -t chatwoot:development \
  --build-arg BUNDLE_WITHOUT='' \
  --build-arg EXECJS_RUNTIME=Node \
  --build-arg RAILS_ENV=development \
  --build-arg RAILS_SERVE_STATIC_FILES=false \
  .
```

Faca isso quando:
- o `Dockerfile` mudar
- as gems mudarem
- o `package.json` ou `pnpm-lock.yaml` mudar
- a imagem local `chatwoot:development` tiver sido removida

Depois disso, suba novamente:

```bash
docker compose up -d rails sidekiq vite
```

## 9. Troubleshooting

### 9.1 A UI nao abre

Confira:

```bash
docker compose ps
docker compose logs -f rails
docker compose logs -f vite
```

Verifique tambem se voce esta usando:

```text
http://localhost:3006
```

Nao use `127.0.0.1`, porque o app esta configurado com:

```text
FRONTEND_URL=http://localhost:3006
```

### 9.2 O Vite cai ou demora para responder

O `vite` instala dependencias no boot. Na primeira subida isso pode levar alguns minutos.

Se quiser reiniciar apenas o `vite`:

```bash
docker compose up -d --force-recreate vite
docker compose logs -f vite
```

### 9.3 O banco nao existe

Rode:

```bash
docker compose exec rails bundle exec rails db:prepare
```

### 9.4 O seed falha com email ja existente

Isso costuma acontecer porque o usuario de desenvolvimento ja foi criado.

Voce pode:
- ignorar o erro se o usuario ja existir
- ou resetar o banco inteiro

Para resetar:

```bash
docker compose down -v
docker compose up -d postgres redis mailhog rails sidekiq vite
docker compose exec rails bundle exec rails db:prepare
docker compose exec rails bundle exec rails db:seed
```

### 9.5 Aviso de `dubious ownership in repository at '/app'`

Esse aviso aparece dentro dos containers quando algum comando Ruby chama Git.

Ele normalmente nao impede o ambiente de subir, mas voce pode ajustar assim:

```bash
docker compose exec rails git config --global --add safe.directory /app
docker compose exec sidekiq git config --global --add safe.directory /app
docker compose exec vite git config --global --add safe.directory /app
```

### 9.6 Quero ver os dados de desenvolvimento criados

Usuario padrao:
- `john@acme.inc`
- `Password1!`

Esse usuario fica associado aos accounts de exemplo:
- `Acme Inc`
- `Acme Org`

## 10. Comandos uteis

Entrar no console Rails:

```bash
docker compose exec rails bundle exec rails console
```

Executar um runner:

```bash
docker compose exec rails bundle exec rails runner "puts User.count"
```

Abrir shell no container Rails:

```bash
docker compose exec rails sh
```

Ver logs em tempo real de tudo:

```bash
docker compose logs -f
```

## 11. Fluxo resumido

Primeira vez:

```bash
cd /home/ti/projetos/lumia-project/chatwoot
docker compose up -d postgres redis mailhog
docker build -f docker/Dockerfile -t chatwoot:development \
  --build-arg BUNDLE_WITHOUT='' \
  --build-arg EXECJS_RUNTIME=Node \
  --build-arg RAILS_ENV=development \
  --build-arg RAILS_SERVE_STATIC_FILES=false \
  .
docker compose up -d rails sidekiq vite
docker compose exec rails bundle exec rails db:prepare
docker compose exec rails bundle exec rails db:seed
```

Uso diario:

```bash
cd /home/ti/projetos/lumia-project/chatwoot
docker compose up -d postgres redis mailhog rails sidekiq vite
docker compose exec rails bundle exec rails db:prepare
```
