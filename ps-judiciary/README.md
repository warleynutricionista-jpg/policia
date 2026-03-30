# ps-judiciary

Painel jurídico separado para RP de tribunal, integrado com `ps-mdt` e `ps-forensics`.

## Funcionalidades
- Painel NUI próprio (comando `/tribunal`).
- 3 perfis de acesso:
  - **Juiz**: visão total + sentença + configuração do gatilho.
  - **Promotor**: cria processo e lança andamentos/audiência.
  - **Advogado**: visualiza e registra manifestações de defesa.
- Gatilho configurável (aba Configurações): acusado elegível após **N** casos criminais vinculados (padrão 3).
- Busca dados do acusado:
  - Identificação (`mdt_profiles`)
  - Ficha criminal resumida (prisões + mandados)
  - Indicadores de suspeição/cena via forense (`forensic_investigative_subjects` + `forensic_evidence`).

## Permissões (ACE)
Configure no `server.cfg`:

```cfg
add_ace group.admin judiciary.role.judge allow
add_ace identifier.license:xxxx judiciary.role.promotor allow
add_ace identifier.license:yyyy judiciary.role.advogado allow
```

Também existe fallback por job em `config.lua` (`Config.RoleByJob`).

## Instalação
1. Coloque a pasta `ps-judiciary` em `resources`.
2. Adicione no `server.cfg` após ps-mdt e ps-forensics:

```cfg
ensure ps-judiciary
```

3. Reinicie o servidor.

## Observações
- O schema é criado automaticamente no start.
- O painel foi construído para fluxo simples e completo, sem burocracia excessiva.
