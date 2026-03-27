# Análise técnica: ps-mdt + ps-forensics

## Objetivo
Melhorar a **fluidez de jogabilidade** sem sacrificar profundidade de **RP investigativo**.

## Diagnóstico rápido

### ps-forensics
- O loop de detecção de disparo/cápsula estava com polling fixo e sem ajuste por configuração.
- A leitura de munição no client usava `GetAmmoInClip` de forma incompleta; em armas/contextos sem clip isso prejudica a detecção de queda de munição e pode reduzir geração de cápsulas.
- O sistema de evidência de mundo já está robusto (cooldowns, chances, blacklist, linha de trajetória), mas pode ser tunado por perfil do servidor.

### ps-mdt
- A estrutura de permissões e hierarquia está forte para progressão RP.
- Já existem trilhas de auditoria e integrações de evidência/caso/laudo.
- O maior ganho de fluidez vem de **governança operacional** (SOP) e ajustes de cache/paginação por volume, não de grande refatoração imediata.

---

## Melhorias aplicadas neste ciclo

1. **Polling de cápsulas configurável** (`CasingPollIntervalMs`) para equilibrar responsividade x uso de CPU.
2. **Correção de coleta de munição** na detecção de disparo:
   - usa retorno correto de `GetAmmoInClip` (`hasClip, ammo`)
   - fallback para `GetAmmoInPedWeapon` quando necessário.

Impacto esperado:
- geração de cápsulas mais consistente;
- menos falso-negativo em tiroteios;
- melhor narrativa pericial (balística/linha temporal).

---

## Roadmap recomendado (alto impacto de RP)

### Fase 1 (rápida, 1-2 dias)
- Revisar `Config.WorldEvidence.Chances` por tipo de ocorrência (urbano/rural).
- Ajustar `Cooldowns` para evitar poluição visual em confrontos longos.
- Definir SOP: quem coleta, quem processa, quem assina laudo.

### Fase 2 (operacional, 3-5 dias)
- Vincular obrigatoriamente evidência -> caso -> relatório antes de arquivamento.
- Criar checklist de cadeia de custódia com dupla validação em provas críticas (DNA/arma).
- Padronizar templates de laudo por tipo (balística, toxicológico, necropsia).

### Fase 3 (imersão RP, 1 semana)
- Implementar “hipóteses investigativas” por caso (linhas de investigação concorrentes).
- Criar prioridade automática no MDT para casos com múltiplos matches (DNA + digital + balística).
- Rotinas de briefing/debriefing com métricas de resolução e qualidade da prova.

---

## Tuning sugerido para servidor com boa fluidez

### ps-forensics
- `ExpirationTime`: 2400-3600 (mapa limpo sem perder RP)
- `CasingPollIntervalMs`: 180-250
- `FlashlightRange`: 12-15
- `Cooldowns.capsula`: 500-700
- `Cooldowns.buraco_de_bala`: 300-450

### ps-mdt
- `CacheTTL.ReportStats`: 20-30
- `CacheTTL.ActiveUnits`: 5-10
- `Pagination.Cases`: 20
- `Pagination.CitizenSearch`: 15-20

---

## Indicadores para medir se melhorou
- Tempo médio entre ocorrência e abertura de caso.
- % de casos com cadeia de custódia completa.
- % de laudos com vínculo a evidência física.
- Taxa de condenação (ou fechamento) com múltiplas provas convergentes.
- Feedback dos players: “investigação trava?” e “foi burocrático demais?”.

