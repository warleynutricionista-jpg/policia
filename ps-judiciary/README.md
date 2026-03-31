# ps-judiciary

Painel jurídico separado para RP de tribunal, integrado com `ps-mdt` e `ps-forensics`.

## Funcionalidades
- Painel NUI próprio (comando `/tribunal` opcional via `Config.EnableCommandOpen`).
- Abertura principal via item **`judiciary_tablet`** (tablet jurídico), igual ao conceito operacional do ps-forensics.
- 3 perfis de acesso:
  - **Juiz**: visão total + sentença + configuração do gatilho.
  - **Promotor**: cria processo e lança andamentos/audiência.
  - **Advogado**: visualiza e registra manifestações de defesa.
- Gatilho configurável (aba Configurações): acusado elegível após **N** casos criminais vinculados (padrão 3).
- Abrange **vara de família**, **vara trabalhista** e **processos gerais** (além de criminal), com abertura livre pelo advogado.
- Fluxo documental inicial: o **juiz aceita ou rejeita** a entrada do caso.
- Custas judiciais automáticas para a parte perdedora: **R$ 200.000**.
- Ordem de **prisão direta pelo juiz** com delay de **5 minutos** (tempo para conduzir o réu até cela/sala antes da execução automática).
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

## Grupo e cargos (para criar no servidor)
- **Grupo sugerido:** `juridico` (`Config.JudiciaryGroupName`)
- **Cargos sugeridos:** `juiz`, `promotor`, `advogado` (`Config.JudiciaryRoles`)
- Mapeamento padrão de job para role:
  - job `juiz` -> role `judge`
  - job `promotor` -> role `prosecutor`
  - job `advogado` -> role `lawyer`

## Item do tablet jurídico
- Nome do item: **`judiciary_tablet`** (`Config.TabletItem`)
- Arquivo de referência para cadastro do item: `items/items.lua`
- O painel valida a posse do tablet ao abrir.
- Modelo de item (ox_inventory) no mesmo padrão do forensics:

```lua
['judiciary_tablet'] = {
    label = 'Tablet Jurídico',
    weight = 700,
    stack = false,
    consume = 0,
    close = true,
    description = 'Tablet utilizado para consulta, tramitação e gestão jurídica no tribunal.',
    client = {
        image = 'judiciary_tablet.png',
        export = 'ps-judiciary.useJudiciaryTablet'
    }
},
```

- Export client implementado no recurso: `ps-judiciary.useJudiciaryTablet`.

## Instalação
1. Coloque a pasta `ps-judiciary` em `resources`.
2. Adicione no `server.cfg` após ps-mdt e ps-forensics:

```cfg
ensure ps-judiciary
```

3. Reinicie o servidor.

4. Cadastre o item `judiciary_tablet` no inventário que você usa (ou aproveite `items/items.lua` como base).

## Observações
- O schema é criado automaticamente no start.
- O painel foi construído para fluxo simples e completo, sem burocracia excessiva.
