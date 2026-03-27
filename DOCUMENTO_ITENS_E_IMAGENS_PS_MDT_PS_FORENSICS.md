# Documento de Itens e Imagens — ps-mdt + ps-forensics

Este documento lista **tudo que você precisa criar** para os scripts `ps-mdt` e `ps-forensics`, com foco em:

1. Itens de inventário.
2. Nomes de imagens.
3. Local exato onde cada imagem deve ficar.

---

## 1) Itens para criar no inventário

## 1.1 ps-mdt

O `ps-mdt` usa explicitamente o item abaixo (entrega de citação no fluxo de sentença):

- `mdtcitation`

> Observação: não há, no `config.lua` do `ps-mdt`, uma lista dedicada de itens obrigatórios além dos fluxos que referenciam este item de citação.

---

## 1.2 ps-forensics

No `ps-forensics`, você deve criar os itens abaixo no seu inventário (ox_inventory/qb equivalente), conforme `Config.Items` e `data/items.lua`:

1. `forensic_kit`
2. `disposable_gloves`
3. `evidence_bag`
4. `evidence_seal`
5. `dna_swab`
6. `fingerprint_kit`
7. `fingerprint_powder`
8. `fingerprint_tape`
9. `blood_reagent`
10. `gsr_kit`
11. `drug_test_kit`
12. `forensic_tweezers`
13. `forensic_camera`
14. `evidence_marker`
15. `evidence_tag`
16. `medical_exam_case`
17. `body_bag`
18. `forensic_flashlight`
19. `ballistic_kit`
20. `forensic_tablet`

---

## 2) Imagens dos itens de inventário

Para os itens de inventário acima, o padrão mais comum é usar o nome do item como nome da imagem:

- Exemplo: item `forensic_kit` → imagem `forensic_kit.png`

### Pasta recomendada

Se você usa **ox_inventory**, coloque em:

- `ox_inventory/web/images/`

### Imagens para criar (inventário)

#### ps-mdt
- `mdtcitation.png`

#### ps-forensics
- `forensic_kit.png`
- `disposable_gloves.png`
- `evidence_bag.png`
- `evidence_seal.png`
- `dna_swab.png`
- `fingerprint_kit.png`
- `fingerprint_powder.png`
- `fingerprint_tape.png`
- `blood_reagent.png`
- `gsr_kit.png`
- `drug_test_kit.png`
- `forensic_tweezers.png`
- `forensic_camera.png`
- `evidence_marker.png`
- `evidence_tag.png`
- `medical_exam_case.png`
- `body_bag.png`
- `forensic_flashlight.png`
- `ballistic_kit.png`
- `forensic_tablet.png`

---

## 3) Imagens de evidências da interface do ps-forensics (NUI)

O `ps-forensics` tem um mapeamento próprio para imagens de evidência e define que elas devem ficar em:

- `ps-forensics/html/images/evidence/`

As imagens são resolvidas por `data/evidence_images.lua`.

### 3.1 Arquivo padrão (fallback)

- `evidence_generic.svg`

### 3.2 Imagens por tipo (TypeMap)

- `shell_casing.png`
- `bullet.png`
- `firearm.png`
- `ammo.png`
- `bullet_fragment.png`
- `blood.png`
- `saliva.png`
- `hair.png`
- `sweat.png`
- `biological_tissue.png`
- `biological_fluid.png`
- `fingerprint.png`
- `footprint.png`
- `tire_mark.png`
- `gunshot_residue.png`
- `drug_residue.png`
- `powder.png`
- `liquid.png`
- `pill.png`
- `syringe.png`
- `package.png`
- `chemical.png`
- `document.png`
- `phone.png`
- `electronic.png`
- `digital_media.png`
- `clothing.png`
- `shoe.png`
- `vehicle.png`
- `knife.png`
- `blade.png`
- `sharp_object.png`
- `blunt_object.png`
- `burned_object.png`

### 3.3 Imagens por categoria (CategoryMap)

- `category_ballistics.png`
- `blood.png`
- `fingerprint.png`
- `chemical.png`
- `document.png`
- `electronic.png`
- `clothing.png`
- `vehicle.png`
- `knife.png`
- `blunt_object.png`
- `evidence_generic.svg`

---

## 4) Status rápido para você aplicar

## 4.1 Criar no inventário

- [ ] `mdtcitation`
- [ ] 20 itens do `ps-forensics`

## 4.2 Criar imagens no inventário (ox_inventory)

Pasta:

- [ ] `ox_inventory/web/images/`

Arquivos:

- [ ] `mdtcitation.png`
- [ ] 20 PNGs com os nomes dos itens forenses

## 4.3 Garantir imagens da NUI do ps-forensics

Pasta:

- [ ] `ps-forensics/html/images/evidence/`

Arquivos:

- [ ] `evidence_generic.svg`
- [ ] Todos os arquivos de `TypeMap`
- [ ] Todos os arquivos de `CategoryMap`

---

## 5) Dica de padronização

Para evitar erro de imagem quebrada:

- Use **nomes exatamente iguais** (maiúsculas/minúsculas importam no Linux).
- Prefira **PNG** para ícones de item do inventário.
- Mantenha os arquivos de evidência exatamente como mapeados no `evidence_images.lua`.
