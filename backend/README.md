# Sistema de Gestão de Produtos – Cada produto tem um dono

O projeto com login e migrações. O produto ganha **dono** (um usuário tem muitos produtos), cada pessoa enxerga e mexe só no próprio catálogo, a listagem tem **busca e filtro**, e o erro `422` explica o que está errado em português. A coluna nova entrou por uma **migração** — o `create_all` não existe mais.

## Como rodar

```bash
poetry install