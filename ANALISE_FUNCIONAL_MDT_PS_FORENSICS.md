# Análise funcional detalhada — ps-mdt + ps-forensics

## Objetivo desta análise
Mapear **o que já funciona**, **o que ainda tem risco funcional** e **quais ajustes seguros** devem ser aplicados para evoluir o sistema sem quebrar o que já está estável.

---

## 1) O que está funcionando hoje (base técnica)

### 1.1 Fluxo de ações por item está estruturado
- Existe uma matriz central de ações (`ForensicItemActions`) com regras de item obrigatório + consumo por ação.
- Existe mapeamento de uso (`ForensicItemUsageMap`) ligando item → ação → contexto (target, tipos permitidos, efeito).
- Há validação server-side antes de concluir ação crítica (`ValidateAndConsumeForensicAction`).

**Conclusão:** a arquitetura de consumo e validação está correta em conceito (evita trust no client).

### 1.2 Controle de permissões/autorização está presente
- Uso de callback/eventos sensíveis passa por `CheckForensicAuth`.
- Isso reduz abuso por job indevido e garante governança do fluxo.

**Conclusão:** o gate de acesso está adequado para RP policial/pericial.

### 1.3 Pipeline de evidência de foto existe
- Cliente registra foto com metadados (coords, heading, timestamp).
- Servidor persiste evidência na base (`forensic_evidence`) e audita ação.

**Conclusão:** o pilar de documentação fotográfica já existe e está próximo do ideal.

---

## 2) Pontos que NÃO estavam totalmente funcionais (e por quê)

### 2.1 Item de foto era adicionado como `photo` e não como item forense
**Risco identificado:** o servidor tentava adicionar `photo`, enquanto a base de itens do recurso define `forensic_photo`.

**Impacto prático:**
- foto podia falhar ao entrar no inventário;
- inconsistência entre item exibido e item registrado no recurso;
- quebra de UX e rastreabilidade.

### 2.2 Configuração não declarava explicitamente `forensic_photo` em `Config.Items`
**Risco identificado:** integrações e futuras chamadas que dependem de `Config.Items` podem não resolver o item de foto corretamente.

**Impacto prático:**
- aumento de fragilidade em integrações futuras;
- necessidade de hardcode em pontos isolados.

### 2.3 Itens descartáveis com `consume = 1` + consumo server-side
**Risco identificado:** havia chance de consumo duplicado em alguns cenários de inventário (auto-consumo do item + remoção por ação no servidor).

**Impacto prático:**
- consumo em duplicidade;
- perda indevida de itens;
- experiência inconsistente entre ações.

---

## 3) Ajustes aplicados para melhorar sem quebrar

### 3.1 Padronização do item de foto no inventário
- Inventário agora usa item configurável (`Config.Items.forensic_photo`) com fallback para `forensic_photo`.
- Mensagem de sucesso também passou a refletir o item correto.

### 3.2 Inclusão explícita de `forensic_photo` em `Config.Items`
- Evita hardcode e melhora compatibilidade para integrações futuras.

### 3.3 Consumo centralizado no servidor para descartáveis
- Itens descartáveis foram ajustados para `consume = 0` em `data/items.lua`.
- O consumo real agora fica centralizado em `ForensicItemActions` + `ValidateAndConsumeForensicAction`.

**Resultado esperado:** item descartável passa a ser consumido **uma única vez por ação válida**, com menor risco de perda indevida.

---

## 4) Critérios para “totalmente funcional” (checklist de aceite)

## 4.1 Uso e consumo de itens
- [ ] Cada ação consome somente os itens previstos pela action.
- [ ] Nenhum item descartável é removido em duplicidade.
- [ ] Ações bloqueadas por falta de item não consomem nada.

## 4.2 Coleta e processamentos
- [ ] Evidência biológica, digital e balística coleta quando tipo é compatível.
- [ ] Testes (GSR, droga, sangue) respeitam item e autorização.
- [ ] Marcadores, tags e lacres funcionam dentro do fluxo de custódia.

## 4.3 Fotografia forense
- [ ] Foto gera evidência no banco.
- [ ] Foto gera item `forensic_photo` no inventário.
- [ ] Metadados (coords, horário, coletor) permanecem íntegros.

## 4.4 MDT e governança
- [ ] Evidências são vinculáveis ao caso sem erro.
- [ ] Fluxo de relatório/desfecho não perde referência da prova.
- [ ] Auditoria registra ações-chave com consistência.

---

## 5) Plano de validação segura (sem quebrar o legado)

1. Validar em ambiente de homologação com 1 cenário por tipo de evidência.
2. Rodar testes de regressão focados em ações já usadas pelo servidor (coleta, foto, lacre, tag, GSR).
3. Conferir logs/auditoria para garantir ausência de consumo duplo.
4. Só depois promover para produção.

---

## 6) Próximos aprimoramentos recomendados

1. Criar testes automatizados de regressão para `ValidateAndConsumeForensicAction`.
2. Criar comando administrativo de diagnóstico de inventário/itens faltantes.
3. Implementar dashboard de saúde operacional (taxa de falha por ação/item).
4. Adicionar telemetria por ação para detectar gargalos reais de gameplay.

