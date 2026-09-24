# aws-exam-questions-to-labs

[![ci](https://github.com/jhermesn/aws-exam-questions-to-labs/actions/workflows/ci.yml/badge.svg)](https://github.com/jhermesn/aws-exam-questions-to-labs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

🇺🇸 [Read in English](README.md)

Errou uma questão de simulado de certificação AWS? Diga ao seu agente qual é a
prova e cole a questão. Esta [Agent Skill](https://agentskills.io/specification)
transforma a questão em um **laboratório prático** no estilo das
[AWS Microcredentials](https://aws.amazon.com/blogs/training-and-certification/microcredentials-from-aws-are-now-free-heres-why-that-matters/):
um cenário de negócio, um ambiente em CloudFormation, desafios resolvidos no
Console sem passo a passo e um corretor automático.

Temas caros demais ou impossíveis de reproduzir numa conta de estudo (Direct
Connect, Outposts, Shield Advanced...) viram material de estudo com a
documentação oficial, em vez de laboratório.

```text
$ bash check.sh lab-saa-c03-s3-accidental-delete
  ✅ [1] Deleted or overwritten reports can be restored
  ✅ [2] Rule expire-noncurrent-30d is enabled
  ✅ [2] Old versions are permanently deleted after 30 days

Score: 3/3
```

O texto dos labs sai no idioma em que você conversa com o agente.

## Por que é seguro rodar os labs

O LLM escreve o lab, mas são as ferramentas que decidem se ele sai:

| Gate | Ferramenta | O que garante |
|---|---|---|
| Custo | regras [cfn-guard](https://github.com/aws-cloudformation/cloudformation-guard) | Bloqueia recursos caros, só aceita tamanhos pequenos (t3/t4g, db.t*), proíbe recursos retidos após a exclusão |
| Segurança | regras cfn-guard | Sem SSH/RDP aberto para a internet, IMDSv2, sem `Action: *`, S3 privado, senha de banco gerenciada |
| Template | [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) | CloudFormation válido e boas práticas |
| Scripts | [ShellCheck](https://www.shellcheck.net/) | Corretor e limpeza sem erros |
| Links | curl | Todo link de documentação e preço existe (detecta o "soft 404" da doc AWS) |
| Execução real | `selftest.sh` | Deploy → corretor dá 0/N → solução de referência → N/N → limpeza |

Todo lab vem com `cleanup.sh`, que esvazia os buckets e apaga a stack.

## Instalação

**Claude Code (plugin):**

```text
/plugin marketplace add jhermesn/aws-exam-questions-to-labs
/plugin install aws-exam-questions-to-labs@jhermesn
```

**Qualquer agente compatível com Agent Skills:** copie
`skills/aws-exam-questions-to-labs/` para o diretório de skills do agente (no
Claude Code: `~/.claude/skills/`).

Depois é só pedir:

> Estou estudando para a SAA-C03. Estas são as questões que errei: ...

### Requisitos

| Ferramenta | Instalação |
|---|---|
| cfn-lint | `pipx install cfn-lint` |
| cfn-guard | `brew install cloudformation-guard` ou [binário da release](https://github.com/aws-cloudformation/cloudformation-guard/releases) |
| ShellCheck | `brew install shellcheck` / `apt install shellcheck` |
| jq, curl | geralmente já instalados |
| Checkov (opcional) | `pipx install checkov` |
| AWS CLI v2 | só para subir os labs e rodar o `selftest.sh` |

## Custo

Os labs rodam na **sua** conta AWS. A política de custo mira menos de US$1 por
lab, desde que você rode a limpeza no final, e cada lab mostra o custo estimado
com link para a página oficial de preços. Use uma conta de estudo, nunca de
produção, e configure um [AWS Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html).

## Contribuindo

Achou um recurso caro que as regras deixam passar, ou um lab que saiu errado?
Veja o [CONTRIBUTING.md](CONTRIBUTING.md). Issues e PRs em português são bem-vindos.

## Aviso

Projeto sem afiliação, endosso ou patrocínio da Amazon Web Services. AWS e AWS
Certification são marcas da Amazon.com, Inc. ou afiliadas. O formato dos labs é
inspirado nas AWS Microcredentials; os labs gerados aqui não são avaliações
oficiais. Você é responsável por qualquer cobrança na sua conta AWS.

## Licença

[MIT](LICENSE)
