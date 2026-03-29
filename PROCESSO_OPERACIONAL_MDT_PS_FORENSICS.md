# SOP RP Investigativo — Fluxo completo no MDT + ps-forensics

Este guia descreve o **passo a passo operacional** para o policial, da prisão ao desfecho do caso, usando integração entre **ps-mdt** e **ps-forensics**.

> Objetivo: padronizar conduta RP, preservar cadeia de custódia e aumentar taxa de resolução com prova técnica.

---

## 1) Abordagem, contenção e prisão

### 1.1 Segurança da cena
1. Garantir segurança imediata da equipe e civis.
2. Conter suspeito(s), retirar da linha de risco e chamar apoio se necessário.
3. Isolar perímetro básico para evitar contaminação de vestígios.

**Itens recomendados nesta fase**
- `disposable_gloves` (antes de tocar em qualquer objeto/corpo)
- `forensic_flashlight` (cena noturna/baixa luz)
- `evidence_marker` (marcação visual inicial)

### 1.2 Prisão e procedimento legal inicial
1. Efetuar a prisão e busca pessoal conforme protocolo do servidor.
2. Registrar verbalmente motivo e contexto da prisão (RP).
3. Iniciar coleta de informações primárias (testemunhas, rota de fuga, veículo, horário).

**Itens recomendados nesta fase**
- `forensic_tablet` (consulta rápida e anotações operacionais)

---

## 2) Abertura de ocorrência no MDT

### 2.1 Cadastro imediato
1. Abrir ocorrência/caso no **ps-mdt** assim que a cena estiver estabilizada.
2. Vincular suspeito(s), vítima(s), oficiais e local.
3. Inserir narrativa cronológica curta da prisão.

### 2.2 Qualificação da ocorrência
1. Classificar tipo de crime e gravidade.
2. Adicionar evidências preliminares já observadas (sem conclusões técnicas ainda).
3. Definir oficial responsável e equipe de apoio.

**Itens recomendados nesta fase**
- `forensic_tablet`
- `mdtcitation` (se houver citação/notificação prevista no fluxo)

---

## 3) Coleta forense em cena (ps-forensics)

### 3.1 Preparação e cadeia de custódia
1. Equipar `disposable_gloves`.
2. Delimitar pontos de interesse com `evidence_marker`.
3. Cada vestígio coletado deve ir em `evidence_bag` + `evidence_seal` + `evidence_tag`.

### 3.2 Coleta por tipo de vestígio

#### A) Biológico (sangue/fluidos/DNA)
1. Aplicar reagente quando necessário.
2. Coletar amostra com swab estéril.
3. Lacrar e etiquetar imediatamente.

**Itens**
- `dna_swab`
- `blood_reagent`
- `evidence_bag`
- `evidence_seal`
- `evidence_tag`

#### B) Impressões digitais
1. Revelar superfície com pó.
2. Levantar impressão com fita apropriada.
3. Embalar e etiquetar.

**Itens**
- `fingerprint_kit`
- `fingerprint_powder`
- `fingerprint_tape`
- `evidence_bag`
- `evidence_seal`
- `evidence_tag`

#### C) Balística (cápsula/projétil/fragmento)
1. Localizar vestígios com inspeção visual + lanterna forense.
2. Retirar cápsula/projétil sem danificar marcas.
3. Acondicionar separadamente por ponto de coleta.

**Itens**
- `ballistic_kit`
- `forensic_tweezers`
- `evidence_bag`
- `evidence_seal`
- `evidence_tag`

#### D) Resíduos de disparo e drogas
1. Executar teste de GSR em suspeitos e/ou policiais envolvidos.
2. Executar teste preliminar de substâncias suspeitas.
3. Etiquetar com horário, local e coletor.

**Itens**
- `gsr_kit`
- `drug_test_kit`
- `evidence_bag`
- `evidence_seal`
- `evidence_tag`

#### E) Documentação fotográfica e contextual
1. Fotografar cena geral e close de cada evidência antes da remoção.
2. Fotografar posição relativa (evidence markers no quadro).
3. Registrar observações contextuais no relatório.

**Itens**
- `forensic_camera`
- `evidence_marker`
- `forensic_tablet`

---

## 4) Pós-cena: custódia e processamento

### 4.1 Recebimento e conferência
1. Conferir se cada amostra está lacrada e etiquetada.
2. Validar cadeia de custódia (quem coletou, horário, local, transferência).
3. Armazenar conforme prioridade e sensibilidade.

**Itens recomendados**
- `evidence_bag`
- `evidence_seal`
- `evidence_tag`
- `medical_exam_case` (para exames e organização de materiais sensíveis)

### 4.2 Processamento técnico
1. Rodar análises de DNA/fingerprint/ballística conforme material disponível.
2. Cruzar resultados com banco de cidadãos/armas/casos anteriores.
3. Atualizar cada resultado no caso correspondente no MDT.

**Itens recomendados**
- `forensic_kit`
- `fingerprint_kit`
- `ballistic_kit`
- `forensic_tablet`

---

## 5) Integração no caso (MDT)

### 5.1 Consolidação probatória
1. Vincular cada evidência processada ao caso no **ps-mdt**.
2. Anexar laudos técnicos e fotos.
3. Relacionar evidência ↔ suspeito ↔ dinâmica do crime.

### 5.2 Qualificação jurídica e sentença
1. Ajustar tipificações com base na prova consolidada.
2. Preencher relatório final com narrativa objetiva + técnica.
3. Aplicar prisão/multa/citação conforme decisão operacional.

**Itens recomendados**
- `mdtcitation` (quando aplicável)
- `forensic_tablet`

---

## 6) Desfecho do caso

### 6.1 Possíveis desfechos
- **Indiciamento robusto**: múltiplas provas convergentes.
- **Arquivamento fundamentado**: insuficiência técnica ou contradição material.
- **Reabertura investigativa**: surgimento de nova prova.

### 6.2 Checklist de fechamento
1. Caso no MDT com status final atualizado.
2. Todas as evidências com destino registrado (depósito, descarte, retenção judicial).
3. Cadeia de custódia sem lacunas.
4. Relatório final assinado pelo responsável.

---

## 7) Matriz rápida: fase x item

| Fase | Itens principais |
|---|---|
| Contenção e prisão | `disposable_gloves`, `forensic_flashlight`, `forensic_tablet` |
| Abertura no MDT | `forensic_tablet`, `mdtcitation` |
| Coleta biológica | `dna_swab`, `blood_reagent`, `evidence_bag`, `evidence_seal`, `evidence_tag` |
| Impressões digitais | `fingerprint_kit`, `fingerprint_powder`, `fingerprint_tape`, `evidence_bag`, `evidence_seal`, `evidence_tag` |
| Balística | `ballistic_kit`, `forensic_tweezers`, `evidence_bag`, `evidence_seal`, `evidence_tag` |
| GSR e drogas | `gsr_kit`, `drug_test_kit`, `evidence_bag`, `evidence_seal`, `evidence_tag` |
| Registro visual | `forensic_camera`, `evidence_marker`, `forensic_tablet` |
| Custódia e laboratório | `forensic_kit`, `medical_exam_case`, `body_bag` (quando houver óbito), `forensic_tablet` |
| Fechamento do caso | `mdtcitation` (se aplicável), documentação no MDT |

---

## 8) Boas práticas RP (recomendado)

1. Nunca coletar sem luvas em cena ativa.
2. Nunca misturar evidências de pontos diferentes no mesmo pacote.
3. Sempre fotografar antes de remover vestígio.
4. Sempre vincular prova no MDT no mesmo plantão.
5. Evitar conclusões sem laudo técnico quando o caso exigir perícia.

