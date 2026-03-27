// ============================================================
// PS-FORENSICS - Frontend JavaScript
// ============================================================

let currentTab = 'scenes';
let playerRole = 'policial';
let playerPermissions = {};
let playerName = '';
let availableTabs = [];

// ============================================================
// IMAGENS DE EVIDÊNCIA
// Mapeamento tipo → arquivo SVG/PNG em html/images/evidence/
// Fallback: evidence_generic.svg se a imagem não existir
// ============================================================
const EVIDENCE_IMAGE_BASE = 'nui://ps-forensics/html/images/evidence/';
const EVIDENCE_IMAGE_FALLBACK = EVIDENCE_IMAGE_BASE + 'evidence_generic.svg';

const evidenceTypeImageMap = {
    sangue:                'blood.svg',
    capsula:               'shell_casing.svg',
    projetil:              'bullet.svg',
    arma_fogo:             'firearm.svg',
    municao:               'ammo.svg',
    fragmento_projetil:    'bullet_fragment.svg',
    saliva:                'saliva.svg',
    cabelo:                'hair.svg',
    tecido_biologico:      'biological_tissue.svg',
    fluido_biologico:      'biological_fluid.svg',
    impressao_digital:     'fingerprint.svg',
    pegada:                'footprint.svg',
    marca_pneu:            'tire_mark.svg',
    residuo_polvora:       'gunshot_residue.svg',
    residuo_droga:         'drug_residue.svg',
    substancia_po:         'powder.svg',
    substancia_liquida:    'liquid.svg',
    comprimido:            'pill.svg',
    seringa:               'syringe.svg',
    embalagem:             'package.svg',
    residuo_quimico:       'chemical.svg',
    documento:             'document.svg',
    celular:               'phone.svg',
    dispositivo_eletronico:'electronic.svg',
    midia_digital:         'digital_media.svg',
    roupa:                 'clothing.svg',
    calcado:               'shoe.svg',
    veiculo_cena:          'vehicle.svg',
    faca:                  'knife.svg',
    lamina:                'blade.svg',
    objeto_perfurante:     'sharp_object.svg',
    objeto_contundente:    'blunt_object.svg',
    objeto_queimado:       'burned_object.svg',
};

const evidenceCategoryImageMap = {
    balistica:         'shell_casing.svg',
    biologica:         'blood.svg',
    digital_impressao: 'fingerprint.svg',
    quimica:           'gunshot_residue.svg',
    documental:        'document.svg',
    eletronica:        'electronic.svg',
    vestimenta:        'clothing.svg',
    veiculo:           'vehicle.svg',
    objeto_cortante:   'knife.svg',
    objeto_contundente:'blunt_object.svg',
};

function getEvidenceImageURL(type, category) {
    const file = evidenceTypeImageMap[type]
        || evidenceCategoryImageMap[category]
        || 'evidence_generic.svg';
    return EVIDENCE_IMAGE_BASE + file;
}

function evidenceThumb(type, category) {
    const url = getEvidenceImageURL(type, category);
    return `<img class="evidence-thumb" src="${url}" alt="${type || 'evidência'}"
        onerror="this.onerror=null;this.src='${EVIDENCE_IMAGE_FALLBACK}'">`;
}

function getEl(id) {
    return document.getElementById(id);
}

function safeClassList(id) {
    const el = getEl(id);
    if (!el) {
        console.warn(`[ps-forensics] Elemento não encontrado: #${id}`);
        return null;
    }
    return el.classList;
}

function resolveTab(tab) {
    const preferred = tab || currentTab || 'scenes';
    if (getEl('tab-' + preferred)) return preferred;

    const firstAvailableExisting = (availableTabs || []).find((t) => !!getEl('tab-' + t));
    if (firstAvailableExisting) return firstAvailableExisting;

    const fallbackBtn = document.querySelector('.nav-btn[data-tab]');
    if (fallbackBtn?.dataset?.tab && getEl('tab-' + fallbackBtn.dataset.tab)) {
        return fallbackBtn.dataset.tab;
    }

    return 'scenes';
}

function asArrayResponse(response) {
    if (Array.isArray(response)) return response;
    if (response && Array.isArray(response.data)) return response.data;
    if (response && response.success && response.data && Array.isArray(response.data.items)) return response.data.items;
    return [];
}

// ============================================================
// NUI MESSAGE HANDLER
// ============================================================
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        safeClassList('forensics-app')?.remove('hidden');
        playerRole = data.role || 'policial';
        playerPermissions = data.permissions || {};
        playerName = data.playerName || 'Oficial';
        availableTabs = Array.isArray(data.availableTabs) ? data.availableTabs : [];

        const playerInfo = getEl('playerInfo');
        if (playerInfo) playerInfo.textContent = `${playerName} | ${data.playerJob || ''} | Grade ${data.playerGrade || 0}`;
        const roleBadge = getEl('roleBadge');
        if (roleBadge) roleBadge.textContent = playerRole.toUpperCase();

        // Verificar permissões de legista
        if (!playerPermissions.canPerformAutopsy) {
            const btnAutopsy = document.getElementById('btnNewAutopsy');
            if (btnAutopsy) btnAutopsy.style.display = 'none';
        }

        // Restringir abas por permissão
        const tabRules = {
            lab: !!playerPermissions.canRunBasicTests,
            fingerprints: !!playerPermissions.canCollectEvidence,
            dna: !!playerPermissions.canCollectEvidence,
            ballistics: !!playerPermissions.canCollectEvidence,
            drugs: !!playerPermissions.canRunBasicTests,
            autopsy: !!playerPermissions.canPerformAutopsy,
            reports: !!playerPermissions.canEmitReport,
            crossref: !!playerPermissions.canRunLabTests || !!playerPermissions.canEmitReport,
        };
        document.querySelectorAll('.nav-btn').forEach((btn) => {
            const tab = btn.dataset.tab;
            if (tabRules[tab] === false) {
                btn.style.display = 'none';
            } else {
                btn.style.display = '';
            }
        });

        switchTab(resolveTab(data.tab));
    }

    if (data.action === 'close') {
        safeClassList('forensics-app')?.add('hidden');
    }
});

// ============================================================
// FETCH NUI
// ============================================================
async function fetchNUI(event, data = {}) {
    try {
        const resp = await fetch(`https://ps-forensics/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
        });
        return await resp.json();
    } catch (e) {
        console.error('NUI Fetch error:', e);
        return null;
    }
}

// ============================================================
// CLOSE UI
// ============================================================
function closeUI() {
    safeClassList('forensics-app')?.add('hidden');
    fetchNUI('close');
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeUI();
    }
});

// ============================================================
// TAB SWITCHING
// ============================================================
function switchTab(tab) {
    const resolvedTab = resolveTab(tab);
    currentTab = resolvedTab;

    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));

    const tabEl = getEl('tab-' + resolvedTab);
    if (!tabEl) {
        console.error(`[ps-forensics] Aba inválida recebida: "${tab}" (resolvida: "${resolvedTab}")`);
        return;
    }

    tabEl.classList.add('active');
    const navBtn = document.querySelector(`.nav-btn[data-tab="${resolvedTab}"]`);
    if (navBtn) navBtn.classList.add('active');

    // Load data for tab
    loadTabData(resolvedTab);
}

async function loadTabData(tab) {
    switch(tab) {
        case 'dashboard':    await loadDashboard(); break;
        case 'scenes':       await loadScenes(); break;
        case 'evidence':     await loadEvidence(); break;
        case 'lab':          await loadLabTests(); break;
        case 'fingerprints': await loadFingerprints(); break;
        case 'dna':          await loadDNA(); break;
        case 'ballistics':   await loadBallistics(); break;
        case 'drugs':        await loadDrugs(); break;
        case 'autopsy':      await loadAutopsies(); break;
        case 'reports':      await loadReports(); break;
        case 'crossref':     await loadCrossRefDashboard(); break;
    }
}

// ============================================================
// DASHBOARD
// ============================================================
async function loadDashboard() {
    const statsEl  = getEl('dashboardStats');
    const recentEl = getEl('dashboardRecent');
    if (!statsEl) return;

    statsEl.innerHTML = '<div class="dashboard-loading"><i class="fas fa-spinner fa-spin"></i> Carregando...</div>';

    const result = await fetchNUI('getForensicStats', {});

    if (!result) {
        statsEl.innerHTML = '<div class="empty-state"><i class="fas fa-chart-line"></i><p>Erro ao carregar estatísticas</p></div>';
        return;
    }

    const stats = [
        { icon: 'fa-map-marked-alt',    color: '#3b82f6', label: 'Cenas',               value: result.total_scenes     || 0 },
        { icon: 'fa-box-archive',        color: '#00b4d8', label: 'Evidências',           value: result.total_evidence   || 0 },
        { icon: 'fa-flask',              color: '#f59e0b', label: 'Testes Pendentes',     value: result.pending_tests    || 0 },
        { icon: 'fa-file-medical',       color: '#22c55e', label: 'Laudos',               value: result.total_reports    || 0 },
        { icon: 'fa-fingerprint',        color: '#8b5cf6', label: 'Perfis Digitais',      value: result.total_fingerprints || 0 },
        { icon: 'fa-dna',                color: '#ec4899', label: 'Perfis de DNA',        value: result.total_dna        || 0 },
        { icon: 'fa-gun',                color: '#ef4444', label: 'Registros Balísticos', value: result.total_ballistics || 0 },
        { icon: 'fa-skull-crossbones',   color: '#6b7280', label: 'Necropsias',           value: result.total_autopsies  || 0 },
    ];

    statsEl.innerHTML = stats.map(s => `
        <div class="stat-card" style="--stat-color: ${s.color}">
            <div class="stat-icon"><i class="fas ${s.icon}" style="color:${s.color}"></i></div>
            <div class="stat-content">
                <div class="stat-value" style="color:${s.color}">${s.value}</div>
                <div class="stat-label">${s.label}</div>
            </div>
        </div>
    `).join('');

    // Seção de alertas de inteligência ou evidências recentes
    if (recentEl) {
        const alerts = result.active_alerts || [];
        const openScenes = result.open_scenes || 0;
        const pendingTests = result.pending_tests || 0;

        let alertsHTML = '';
        if (openScenes > 0) {
            alertsHTML += `<div class="dashboard-alert alert-warning"><i class="fas fa-exclamation-triangle"></i> ${openScenes} cena(s) de crime ainda aberta(s)</div>`;
        }
        if (pendingTests > 0) {
            alertsHTML += `<div class="dashboard-alert alert-info"><i class="fas fa-flask"></i> ${pendingTests} teste(s) laboratorial(is) aguardando processamento</div>`;
        }
        if (alerts.length > 0) {
            alerts.slice(0, 3).forEach(alert => {
                alertsHTML += `<div class="dashboard-alert alert-danger"><i class="fas fa-exclamation-circle"></i> ${alert.message || 'Alerta de inteligência'}</div>`;
            });
        }
        if (!alertsHTML) {
            alertsHTML = '<div class="dashboard-alert alert-success"><i class="fas fa-check-circle"></i> Nenhum alerta ativo no momento</div>';
        }

        recentEl.innerHTML = `<div class="detail-section"><h3><i class="fas fa-bell"></i> Alertas e Pendências</h3>${alertsHTML}</div>`;
    }
}

// ============================================================
// STATUS HELPERS
// ============================================================
const statusLabels = {
    aberta: 'Aberta', isolada: 'Isolada', em_processamento: 'Em Processamento',
    finalizada: 'Finalizada', reaberta: 'Reaberta',
    coletada: 'Coletada', lacrada: 'Lacrada', em_analise: 'Em Análise',
    analisada: 'Analisada', armazenada: 'Armazenada', descartada: 'Descartada',
    devolvida: 'Devolvida', em_julgamento: 'Em Julgamento',
    solicitado: 'Solicitado', em_andamento: 'Em Andamento', concluido: 'Concluído',
    cancelado: 'Cancelado',
    pendente: 'Pendente', presumido: 'Presumido', inconclusivo: 'Inconclusivo',
    compativel: 'Compatível', confirmado: 'Confirmado', negativo: 'Negativo', suspeita: 'Suspeita',
    rascunho: 'Rascunho', em_revisao: 'Em Revisão', finalizado: 'Finalizado',
    anexado_mdt: 'Anexado ao MDT',
    sem_correspondencia: 'Sem Correspondência', parcial: 'Parcial',
    positiva: 'Positiva', parcialmente_compativel: 'Parcialmente Compatível',
};

function getStatusBadge(status) {
    const label = statusLabels[status] || status;
    return `<span class="status-badge status-${status}">${label}</span>`;
}

function formatDate(dateStr) {
    if (!dateStr) return 'N/D';
    const d = new Date(dateStr);
    return d.toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

// ============================================================
// SCENES
// ============================================================
async function loadScenes() {
    const status = document.getElementById('sceneStatusFilter')?.value || '';
    const search = document.getElementById('sceneSearch')?.value || '';

    const result = await fetchNUI('getScenes', { status, search });
    const container = document.getElementById('scenesList');

    if (!result || !result.success || !result.data || result.data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-map-marked-alt"></i><p>Nenhuma cena encontrada</p></div>';
        return;
    }

    container.innerHTML = result.data.items.map(scene => `
        <div class="card" onclick="viewScene(${scene.id})">
            <div class="card-header">
                <span class="card-title">${scene.scene_number || 'Cena'}</span>
                ${getStatusBadge(scene.status)}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Classificação</span><span class="card-value">${scene.classification || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Local</span><span class="card-value">${scene.location_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Criada por</span><span class="card-value">${scene.created_by_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(scene.created_at)}</span></div>
            </div>
        </div>
    `).join('');
}

function searchScenes() { loadScenes(); }
function filterScenes() { loadScenes(); }

async function viewScene(sceneId) {
    const scene = await fetchNUI('getScene', { id: sceneId });
    if (!scene) return;

    const detail = document.getElementById('sceneDetail');
    detail.classList.remove('hidden');

    detail.innerHTML = `
        <div class="detail-header">
            <span class="detail-title"><i class="fas fa-map-marked-alt"></i> ${scene.scene_number}</span>
            <div style="display:flex;gap:8px;">
                ${scene.status !== 'finalizada' ? `
                    <button class="btn-secondary" onclick="updateSceneStatus(${scene.id}, 'isolada')">Isolar</button>
                    <button class="btn-secondary" onclick="updateSceneStatus(${scene.id}, 'em_processamento')">Processar</button>
                    <button class="btn-success" onclick="updateSceneStatus(${scene.id}, 'finalizada')">Finalizar</button>
                ` : ''}
                <button class="btn-secondary" onclick="document.getElementById('sceneDetail').classList.add('hidden')"><i class="fas fa-times"></i></button>
            </div>
        </div>
        <div class="detail-grid">
            <div class="detail-field"><label>Status</label>${getStatusBadge(scene.status)}</div>
            <div class="detail-field"><label>Classificação</label><span>${scene.classification}</span></div>
            <div class="detail-field"><label>Local</label><span>${scene.location_name || 'N/D'}</span></div>
            <div class="detail-field"><label>Departamento</label><span>${scene.department || 'N/D'}</span></div>
            <div class="detail-field"><label>Criada por</label><span>${scene.created_by_name || 'N/D'}</span></div>
            <div class="detail-field"><label>Data</label><span>${formatDate(scene.created_at)}</span></div>
            <div class="detail-field"><label>Início Perícia</label><span>${formatDate(scene.processing_start)}</span></div>
            <div class="detail-field"><label>Fim Perícia</label><span>${formatDate(scene.processing_end)}</span></div>
            <div class="detail-field"><label>Clima</label><span>${scene.weather_conditions || 'N/D'}</span></div>
            <div class="detail-field"><label>Iluminação</label><span>${scene.lighting_conditions || 'N/D'}</span></div>
            <div class="detail-field"><label>Perímetro</label><span>${scene.perimeter_radius || 50}m</span></div>
            <div class="detail-field"><label>Evidências</label><span>${scene.evidence_count || 0}</span></div>
        </div>
        ${scene.description ? `<div class="detail-field"><label>Descrição</label><p>${scene.description}</p></div>` : ''}
        ${scene.personnel && scene.personnel.length > 0 ? `
            <div class="detail-section">
                <h3><i class="fas fa-users"></i> Equipe na Cena</h3>
                ${scene.personnel.map(p => `
                    <div class="card-row" style="padding:4px 0;">
                        <span class="card-value">${p.name || 'N/D'}</span>
                        <span class="card-label">${p.role} | ${formatDate(p.arrival_time)}</span>
                    </div>
                `).join('')}
            </div>
        ` : ''}
    `;
}

async function updateSceneStatus(sceneId, status) {
    const result = await fetchNUI('updateScene', { id: sceneId, status });
    if (result && result.success) {
        showNotification(`Status da cena atualizado para: ${statusLabels[status] || status}`, 'success');
        await loadScenes();
        await viewScene(sceneId);
    } else {
        showNotification(result?.error || 'Erro ao atualizar status da cena', 'error');
    }
}

function showCreateScene() {
    showModal('Nova Cena de Crime', `
        <div class="form-group"><label>Classificação</label>
            <select id="sceneClassification">
                <option value="homicidio">Homicídio</option>
                <option value="tentativa_homicidio">Tentativa de Homicídio</option>
                <option value="latrocinio">Latrocínio</option>
                <option value="roubo">Roubo</option>
                <option value="furto">Furto</option>
                <option value="trafico">Tráfico</option>
                <option value="confronto">Confronto</option>
                <option value="acidente">Acidente</option>
                <option value="sequestro">Sequestro</option>
                <option value="violencia_domestica">Violência Doméstica</option>
                <option value="ocultacao_cadaver">Ocultação de Cadáver</option>
                <option value="incendio_criminoso">Incêndio Criminoso</option>
                <option value="explosao">Explosão</option>
                <option value="envenenamento">Envenenamento</option>
                <option value="estupro">Estupro</option>
                <option value="outros" selected>Outros</option>
            </select>
        </div>
        <div class="form-group"><label>Descrição</label><textarea id="sceneDescription" rows="3" placeholder="Descreva a cena..."></textarea></div>
        <div class="form-group"><label>Raio do Perímetro (m)</label><input type="number" id="scenePerimeter" value="50" min="10" max="500"></div>
        <div class="form-group"><label>Condições Climáticas</label><input type="text" id="sceneWeather" placeholder="Ex: Chuvoso, Ensolarado..."></div>
        <div class="form-group"><label>Iluminação</label><input type="text" id="sceneLighting" placeholder="Ex: Boa, Precária, Noturna..."></div>
        <div class="form-group"><label>ID do Caso (MDT) - opcional</label><input type="number" id="sceneCaseId" placeholder="Número do caso no MDT"></div>
    `, `<button class="btn-primary" onclick="doCreateScene()"><i class="fas fa-plus"></i> Criar Cena</button>`);
}

async function doCreateScene() {
    const data = {
        classification: getEl('sceneClassification')?.value || 'outros',
        description: getEl('sceneDescription')?.value || '',
        perimeter_radius: parseFloat(getEl('scenePerimeter')?.value) || 50,
        weather: getEl('sceneWeather')?.value || '',
        lighting: getEl('sceneLighting')?.value || '',
        case_id: getEl('sceneCaseId')?.value || null,
    };
    const result = await fetchNUI('createScene', data);
    if (result && result.success) {
        closeModal();
        showNotification('Cena de crime criada: ' + (result.sceneNumber || ''), 'success');
        await loadScenes();
    } else {
        showNotification(result?.error || 'Erro ao criar cena', 'error');
    }
}

// ============================================================
// EVIDENCE
// ============================================================
async function loadEvidence() {
    const category = document.getElementById('evidenceCategoryFilter')?.value || '';
    const status   = document.getElementById('evidenceStatusFilter')?.value || '';
    const search   = document.getElementById('evidenceSearch')?.value || '';

    const result = await fetchNUI('getEvidenceList', { category, status, search });
    const container = document.getElementById('evidenceList');

    if (!result || !result.success || !result.data || !result.data.items || result.data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-fingerprint"></i><p>Nenhuma evidência encontrada</p></div>';
        return;
    }

    container.innerHTML = result.data.items.map(ev => `
        <div class="card card-with-thumb priority-${ev.priority || 'media'}" onclick="viewEvidence(${ev.id})">
            ${evidenceThumb(ev.type, ev.category)}
            <div class="card-main">
                <div class="card-header">
                    <span class="card-title">${ev.evidence_number || 'EV-???'}</span>
                    ${getStatusBadge(ev.status)}
                </div>
                <div class="card-body">
                    <div class="card-row"><span class="card-label">Tipo</span><span class="card-value">${ev.type || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Categoria</span><span class="card-value">${ev.category || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Lacre</span><span class="card-value" style="font-family:'Share Tech Mono',monospace;color:#00b4d8">${ev.seal_number || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Coletada por</span><span class="card-value">${ev.collected_by_name || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(ev.collection_time || ev.created_at)}</span></div>
                    ${ev.collection_source === 'campo' ? '<div class="card-row"><span class="card-label" style="color:#f59e0b"><i class="fas fa-map-marker-alt"></i> Campo</span></div>' : ''}
                </div>
            </div>
        </div>
    `).join('');
}

function searchEvidence() { loadEvidence(); }
function filterEvidence() { loadEvidence(); }

async function loadFingerprints() {
    const citizenid = document.getElementById('fpSearch')?.value || '';
    const list = document.getElementById('fingerprintsList');
    let rows = [];
    if (citizenid) {
        rows = asArrayResponse(await fetchNUI('searchFingerprintsByCitizen', { citizenid }));
    } else {
        // Load all recent fingerprints when no search term
        const result = await fetchNUI('getLabTests', { test_type: 'comparacao_digital' });
        rows = (result && result.data && result.data.items) ? result.data.items : [];
        // Map lab test fields to fingerprint display format
        rows = rows.map(t => ({
            evidence_number: t.evidence_id ? `EV-${t.evidence_id}` : 'N/D',
            match_status: t.result_level || 'pendente',
            source_description: t.test_name || 'Comparação Digital',
            matched_name: t.target_name || 'N/D',
            match_confidence: t.result_level === 'confirmado' ? 95 : (t.result_level === 'compativel' ? 75 : 0),
            result_details: t.result_details || '',
            created_at: t.created_at,
        }));
    }
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-hand-dots"></i><p>' + (citizenid ? 'Nenhuma digital encontrada para este cidadão' : 'Digite um CitizenID para buscar digitais ou cadastre uma nova') + '</p></div>';
        return;
    }
    list.innerHTML = rows.map(fp => `
        <div class="card">
            <div class="card-header">
                <span class="card-title">${fp.evidence_number || 'Sem evidência'}</span>
                ${getStatusBadge(fp.match_status || 'pendente')}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Origem</span><span class="card-value">${fp.source_description || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Compatível</span><span class="card-value">${fp.matched_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Confiança</span><span class="card-value">${fp.match_confidence || 0}%</span></div>
                ${fp.result_details ? `<div class="card-row"><span class="card-value" style="font-size:11px;color:#9ca3af;">${fp.result_details}</span></div>` : ''}
            </div>
        </div>
    `).join('');
}

async function loadDNA() {
    const citizenid = document.getElementById('dnaSearch')?.value || '';
    const list = document.getElementById('dnaList');
    let rows = [];
    if (citizenid) {
        rows = asArrayResponse(await fetchNUI('searchDNAByCitizen', { citizenid }));
    } else {
        const result = await fetchNUI('getLabTests', { test_type: 'comparacao_dna' });
        rows = (result && result.data && result.data.items) ? result.data.items : [];
        rows = rows.map(t => ({
            evidence_number: t.evidence_id ? `EV-${t.evidence_id}` : 'N/D',
            match_status: t.result_level || 'pendente',
            source_type: t.test_name || 'Comparação DNA',
            matched_name: t.target_name || 'N/D',
            match_confidence: t.result_level === 'confirmado' ? 94 : (t.result_level === 'compativel' ? 78 : 0),
            result_details: t.result_details || '',
            created_at: t.created_at,
        }));
    }
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-dna"></i><p>' + (citizenid ? 'Nenhuma análise de DNA encontrada para este cidadão' : 'Digite um CitizenID para buscar DNA ou cadastre um novo perfil') + '</p></div>';
        return;
    }
    list.innerHTML = rows.map(dna => `
        <div class="card">
            <div class="card-header">
                <span class="card-title">${dna.evidence_number || 'Sem evidência'}</span>
                ${getStatusBadge(dna.match_status || 'pendente')}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Fonte</span><span class="card-value">${dna.source_type || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Compatível</span><span class="card-value">${dna.matched_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Confiança</span><span class="card-value">${dna.match_confidence || 0}%</span></div>
                ${dna.result_details ? `<div class="card-row"><span class="card-value" style="font-size:11px;color:#9ca3af;">${dna.result_details}</span></div>` : ''}
            </div>
        </div>
    `).join('');
}

async function loadBallistics() {
    const serial = document.getElementById('ballisticSearch')?.value || '';
    const list = document.getElementById('ballisticsList');
    let rows = [];
    if (serial) {
        rows = asArrayResponse(await fetchNUI('getWeaponBallisticHistory', { serial }));
    } else {
        // Load recent ballistic lab tests as overview
        const result = await fetchNUI('getLabTests', { test_type: 'confronto_balistico' });
        rows = (result && result.data && result.data.items) ? result.data.items : [];
        rows = rows.map(t => ({
            weapon_serial: t.target_weapon_serial || 'N/D',
            matched_weapon_serial: t.target_weapon_serial,
            rifling_match: t.result_level || 'pendente',
            item_type: 'Confronto',
            caliber: 'N/D',
            scene_number: t.scene_id ? `Cena #${t.scene_id}` : 'N/D',
            case_id: 'N/D',
            result_details: t.result_details || '',
            created_at: t.created_at,
        }));
    }
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-crosshairs"></i><p>' + (serial ? 'Nenhum histórico balístico encontrado para este serial' : 'Digite um serial de arma para buscar histórico balístico') + '</p></div>';
        return;
    }
    list.innerHTML = rows.map(b => `
        <div class="card">
            <div class="card-header">
                <span class="card-title">${b.matched_weapon_serial || b.weapon_serial || 'N/D'}</span>
                ${getStatusBadge(b.rifling_match || 'pendente')}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Item</span><span class="card-value">${b.item_type || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Calibre</span><span class="card-value">${b.caliber || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Cena</span><span class="card-value">${b.scene_number || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Caso</span><span class="card-value">${b.case_id || 'N/D'}</span></div>
                ${b.result_details ? `<div class="card-row"><span class="card-value" style="font-size:11px;color:#9ca3af;">${b.result_details}</span></div>` : ''}
            </div>
        </div>
    `).join('');
}

async function loadDrugs() {
    const list       = document.getElementById('drugsList');
    const statusVal  = document.getElementById('drugStatusFilter')?.value || '';
    const result     = await fetchNUI('getDrugAnalyses', { status: statusVal || undefined });

    // Suportar resposta como array direto ou objeto paginado
    let rows = [];
    if (Array.isArray(result?.data)) {
        rows = result.data;
    } else if (result?.data?.items && Array.isArray(result.data.items)) {
        rows = result.data.items;
    } else if (Array.isArray(result)) {
        rows = result;
    }

    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-pills"></i><p>Nenhuma análise de substância encontrada</p></div>';
        return;
    }

    list.innerHTML = rows.map(d => `
        <div class="card card-with-thumb" onclick="viewDrug(${d.id})">
            ${evidenceThumb('substancia_po', 'quimica')}
            <div class="card-main">
                <div class="card-header">
                    <span class="card-title">${d.confirmed_substance || d.preliminary_classification || 'Substância não definida'}</span>
                    ${getStatusBadge(d.test_result || 'suspeita')}
                </div>
                <div class="card-body">
                    <div class="card-row"><span class="card-label">Categoria</span><span class="card-value">${d.substance_category || 'N/D'}</span></div>
                    ${d.purity_percentage ? `<div class="card-row"><span class="card-label">Pureza</span><span class="card-value">${d.purity_percentage}%</span></div>` : ''}
                    <div class="card-row"><span class="card-label">Caso</span><span class="card-value">${d.case_id || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(d.created_at)}</span></div>
                </div>
            </div>
        </div>
    `).join('');
}

function filterDrugs() { loadDrugs(); }

async function viewDrug(drugId) {
    if (!drugId) return;
    showModal('Análise de Substância', `
        <div class="detail-field"><label>Carregando dados...</label>
        <p style="color:#6b7280">ID: ${drugId}</p></div>
    `, playerPermissions.canRunLabTests ? `
        <button class="btn-primary" onclick="confirmDrugDialog(${drugId})">
            <i class="fas fa-check"></i> Confirmar Substância
        </button>
    ` : '');
}

async function confirmDrugDialog(drugId) {
    closeModal();
    showModal('Confirmar Substância', `
        <div class="form-group"><label>Substância Confirmada</label>
            <input type="text" id="drugSubstance" placeholder="Nome da substância"></div>
        <div class="form-group"><label>Pureza (%)</label>
            <input type="number" id="drugPurity" min="0" max="100" placeholder="Ex: 75"></div>
        <div class="form-group"><label>Resultado</label>
            <select id="drugResult">
                <option value="confirmado">Confirmado Positivo</option>
                <option value="negativo">Negativo</option>
                <option value="inconclusivo">Inconclusivo</option>
            </select>
        </div>
    `, `<button class="btn-primary" onclick="doConfirmDrug(${drugId})">Confirmar</button>`);
}

async function doConfirmDrug(drugId) {
    const substance = getEl('drugSubstance')?.value || '';
    const purity    = getEl('drugPurity')?.value || null;
    const reslt     = getEl('drugResult')?.value || 'confirmado';
    if (!substance) { showNotification('Substância é obrigatória', 'error'); return; }
    const result = await fetchNUI('confirmDrug', { id: drugId, substance, purity, result: reslt });
    if (result?.success) {
        closeModal();
        showNotification('Substância confirmada com sucesso', 'success');
        await loadDrugs();
    } else {
        showNotification(result?.error || 'Erro ao confirmar substância', 'error');
    }
}

function showRegisterDrugAnalysis() {
    showModal('Nova Análise de Substância', `
        <div class="form-group"><label>Classificação Preliminar</label>
            <input type="text" id="drugPreliminary" placeholder="Ex: Cocaína, Maconha..."></div>
        <div class="form-group"><label>Categoria</label>
            <select id="drugCategory">
                <option value="entorpecentes">Entorpecentes</option>
                <option value="psicotrópicos">Psicotrópicos</option>
                <option value="estimulantes">Estimulantes</option>
                <option value="depressores">Depressores</option>
                <option value="outros">Outros</option>
            </select>
        </div>
        <div class="form-group"><label>ID da Evidência (opcional)</label>
            <input type="number" id="drugEvidenceId" placeholder="ID da evidência associada"></div>
        <div class="form-group"><label>ID do Caso MDT (opcional)</label>
            <input type="number" id="drugCaseId" placeholder="Número do caso"></div>
        <div class="form-group"><label>Observações</label>
            <textarea id="drugNotes" rows="2" placeholder="Observações iniciais..."></textarea></div>
    `, `<button class="btn-primary" onclick="doRegisterDrugAnalysis()"><i class="fas fa-plus"></i> Registrar</button>`);
}

async function doRegisterDrugAnalysis() {
    const data = {
        preliminary_classification: getEl('drugPreliminary')?.value || '',
        substance_category: getEl('drugCategory')?.value || 'outros',
        evidence_id: getEl('drugEvidenceId')?.value || null,
        case_id: getEl('drugCaseId')?.value || null,
        notes: getEl('drugNotes')?.value || '',
    };
    if (!data.preliminary_classification) {
        showNotification('Classificação preliminar é obrigatória', 'error');
        return;
    }
    const result = await fetchNUI('registerDrugAnalysis', data);
    if (result?.success) {
        closeModal();
        showNotification('Análise de substância registrada', 'success');
        await loadDrugs();
    } else {
        showNotification(result?.error || 'Erro ao registrar análise', 'error');
    }
}

async function viewEvidence(evidenceId) {
    const ev = await fetchNUI('getEvidence', { id: evidenceId });
    if (!ev) return;

    const detail = document.getElementById('evidenceDetail');
    detail.classList.remove('hidden');

    let custodyHTML = '';
    if (ev.custody && ev.custody.length > 0) {
        custodyHTML = `
            <div class="detail-section">
                <h3><i class="fas fa-link"></i> Cadeia de Custódia</h3>
                <div class="custody-timeline">
                    ${ev.custody.map(c => `
                        <div class="custody-item">
                            <div class="custody-action">${c.action}</div>
                            <div class="custody-info">${c.to_name || c.from_name || 'N/D'} | ${formatDate(c.created_at)}</div>
                            ${c.notes ? `<div class="custody-info">${c.notes}</div>` : ''}
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    let testsHTML = '';
    if (ev.tests && ev.tests.length > 0) {
        testsHTML = `
            <div class="detail-section">
                <h3><i class="fas fa-flask"></i> Testes Realizados</h3>
                ${ev.tests.map(t => `
                    <div class="card" style="margin-bottom:8px;cursor:default;">
                        <div class="card-header">
                            <span class="card-title">${t.test_name}</span>
                            ${getStatusBadge(t.result_level)}
                        </div>
                        <div class="card-body">
                            <div class="card-row"><span class="card-label">Tipo</span><span class="card-value">${t.test_type}</span></div>
                            ${t.result_details ? `<div class="card-row"><span class="card-value" style="color:#9ca3af;font-size:11px;">${t.result_details}</span></div>` : ''}
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    detail.innerHTML = `
        <div class="detail-header">
            <span class="detail-title"><i class="fas fa-fingerprint"></i> ${ev.evidence_number}</span>
            <button class="btn-secondary" onclick="document.getElementById('evidenceDetail').classList.add('hidden')"><i class="fas fa-times"></i></button>
        </div>
        <div class="detail-grid">
            <div class="detail-field"><label>Status</label>${getStatusBadge(ev.status)}</div>
            <div class="detail-field"><label>Tipo</label><span>${ev.type}</span></div>
            <div class="detail-field"><label>Categoria</label><span>${ev.category}</span></div>
            <div class="detail-field"><label>Subtipo</label><span>${ev.subtype || 'N/D'}</span></div>
            <div class="detail-field"><label>Lacre</label><span style="color:#00b4d8;font-family:'Share Tech Mono';">${ev.seal_number || 'N/D'}</span></div>
            <div class="detail-field"><label>Prioridade</label><span>${ev.priority || 'media'}</span></div>
            <div class="detail-field"><label>Local</label><span>${ev.collection_location || 'N/D'}</span></div>
            <div class="detail-field"><label>Método</label><span>${ev.collection_method || 'N/D'}</span></div>
            <div class="detail-field"><label>Coletada por</label><span>${ev.collected_by_name || 'N/D'}</span></div>
            <div class="detail-field"><label>Data Coleta</label><span>${formatDate(ev.collection_time)}</span></div>
            <div class="detail-field"><label>Armazenamento</label><span>${ev.storage_location || 'N/D'}</span></div>
            <div class="detail-field"><label>Cena</label><span>${ev.scene_id || 'N/D'}</span></div>
            ${ev.linked_citizenid ? `<div class="detail-field"><label>Cidadão Vinculado</label><span>${ev.linked_citizenid}</span></div>` : ''}
            ${ev.linked_weapon_serial ? `<div class="detail-field"><label>Arma Vinculada</label><span>${ev.linked_weapon_serial}</span></div>` : ''}
            ${ev.linked_vehicle_plate ? `<div class="detail-field"><label>Veículo Vinculado</label><span>${ev.linked_vehicle_plate}</span></div>` : ''}
        </div>
        ${ev.description ? `<div class="detail-field"><label>Descrição</label><p>${ev.description}</p></div>` : ''}
        ${custodyHTML}
        ${testsHTML}
    `;
}

// ============================================================
// LAB TESTS
// ============================================================
async function loadLabTests() {
    const status = document.getElementById('labStatusFilter')?.value || '';
    const result = await fetchNUI('getLabTests', { status });
    const container = document.getElementById('labTestsList');

    if (!result || !result.success || !result.data || result.data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-flask"></i><p>Nenhum teste encontrado</p></div>';
        return;
    }

    container.innerHTML = result.data.items.map(test => `
        <div class="card" onclick="viewLabTest(${test.id})">
            <div class="card-header">
                <span class="card-title">${test.test_name || 'Teste'}</span>
                ${getStatusBadge(test.status)}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Tipo</span><span class="card-value">${test.test_type}</span></div>
                <div class="card-row"><span class="card-label">Resultado</span>${getStatusBadge(test.result_level)}</div>
                <div class="card-row"><span class="card-label">Solicitado por</span><span class="card-value">${test.requested_by_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(test.created_at)}</span></div>
                ${test.result_details ? `<div style="margin-top:6px;font-size:11px;color:#9ca3af;border-top:1px solid #1e293b;padding-top:6px;">${test.result_details}</div>` : ''}
            </div>
        </div>
    `).join('');
}

function filterLabTests() { loadLabTests(); }

async function viewLabTest(testId) {
    // Show test details in a modal
    const result = await fetchNUI('getLabTests', { test_id: testId });
    const tests = (result && result.data && result.data.items) ? result.data.items : [];
    const test = tests.find(t => t.id === testId) || tests[0];
    if (!test) {
        showNotification('Teste não encontrado', 'error');
        return;
    }

    const canProcess = test.status !== 'concluido' && playerPermissions.canRunLabTests;

    showModal(`Teste: ${test.test_name || 'Detalhes'}`, `
        <div class="detail-grid">
            <div class="detail-field"><label>Status</label>${getStatusBadge(test.status)}</div>
            <div class="detail-field"><label>Tipo</label><span>${test.test_type || 'N/D'}</span></div>
            <div class="detail-field"><label>Resultado</label>${getStatusBadge(test.result_level || 'pendente')}</div>
            <div class="detail-field"><label>Solicitado por</label><span>${test.requested_by_name || 'N/D'}</span></div>
            <div class="detail-field"><label>Executado por</label><span>${test.performed_by_name || 'Pendente'}</span></div>
            <div class="detail-field"><label>Data Solicitação</label><span>${formatDate(test.created_at)}</span></div>
            ${test.completed_at ? `<div class="detail-field"><label>Data Conclusão</label><span>${formatDate(test.completed_at)}</span></div>` : ''}
            ${test.evidence_id ? `<div class="detail-field"><label>Evidência</label><span>#${test.evidence_id}</span></div>` : ''}
            ${test.scene_id ? `<div class="detail-field"><label>Cena</label><span>#${test.scene_id}</span></div>` : ''}
            ${test.target_citizenid ? `<div class="detail-field"><label>Alvo</label><span>${test.target_name || test.target_citizenid}</span></div>` : ''}
            ${test.target_weapon_serial ? `<div class="detail-field"><label>Arma</label><span>${test.target_weapon_serial}</span></div>` : ''}
            ${test.target_vehicle ? `<div class="detail-field"><label>Veículo</label><span>${test.target_vehicle}</span></div>` : ''}
        </div>
        ${test.description ? `<div class="detail-field"><label>Descrição</label><p>${test.description}</p></div>` : ''}
        ${test.result_details ? `<div class="detail-section"><h3>Resultado Detalhado</h3><p style="white-space:pre-wrap;">${test.result_details}</p></div>` : ''}
    `, canProcess ? `<button class="btn-primary" onclick="doPerformLabTest(${test.id})"><i class="fas fa-flask"></i> Processar Teste</button>` : '');
}

async function doPerformLabTest(testId) {
    closeModal();
    const result = await fetchNUI('performLabTest', { id: testId });
    if (result && result.success) {
        if (result.pending) {
            showNotification(result.message || 'Teste em processamento...', 'info');
        } else {
            showNotification('Teste concluído: ' + (result.resultLevel || ''), 'success');
        }
        await loadLabTests();
    } else {
        showNotification(result?.error || 'Erro ao processar teste', 'error');
    }
}

// ============================================================
// AUTOPSIES
// ============================================================
function filterAutopsies() { loadAutopsies(); }

async function loadAutopsies() {
    const statusVal = document.getElementById('autopsyStatusFilter')?.value || '';
    const result    = await fetchNUI('getAutopsies', { status: statusVal || undefined });
    const container = document.getElementById('autopsyList');

    // Normalizar resposta: aceita array direto ou objeto paginado
    let autopsies = [];
    if (Array.isArray(result?.data)) {
        autopsies = result.data;
    } else if (result?.data?.items && Array.isArray(result.data.items)) {
        autopsies = result.data.items;
    } else if (Array.isArray(result)) {
        autopsies = result;
    }

    if (!autopsies || autopsies.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-skull-crossbones"></i><p>Nenhuma necropsia encontrada</p></div>';
        return;
    }

    const causeLabels = {
        arma_de_fogo: 'Arma de Fogo', arma_branca: 'Arma Branca',
        trauma_contundente: 'Trauma Contundente', asfixia: 'Asfixia',
        queimadura: 'Queimadura', overdose: 'Overdose', envenenamento: 'Envenenamento',
        afogamento: 'Afogamento', multiplos_ferimentos: 'Múltiplos Ferimentos',
        indeterminado: 'Indeterminado', causa_natural: 'Causa Natural',
    };

    container.innerHTML = autopsies.map(autopsy => `
        <div class="card" onclick="viewAutopsy(${autopsy.id})">
            <div class="card-header">
                <span class="card-title">${autopsy.victim_name || 'Desconhecido'}</span>
                ${getStatusBadge(autopsy.status)}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Causa da Morte</span><span class="card-value">${causeLabels[autopsy.cause_of_death] || autopsy.cause_of_death}</span></div>
                <div class="card-row"><span class="card-label">Legista</span><span class="card-value">${autopsy.examiner_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(autopsy.created_at)}</span></div>
                <div class="card-row"><span class="card-label">Ferimentos</span><span class="card-value">${autopsy.wounds_count || 0}</span></div>
            </div>
        </div>
    `).join('');
}

async function viewAutopsy(autopsyId) {
    const autopsy = await fetchNUI('getAutopsy', { id: autopsyId });
    if (!autopsy) return;

    const detail = document.getElementById('autopsyDetail');
    detail.classList.remove('hidden');

    const causeLabels = {
        arma_de_fogo: 'Perfuração por Arma de Fogo', arma_branca: 'Ferimento por Arma Branca',
        trauma_contundente: 'Trauma Contundente', asfixia: 'Asfixia',
        queimadura: 'Queimadura', overdose: 'Overdose', envenenamento: 'Envenenamento',
        afogamento: 'Afogamento', multiplos_ferimentos: 'Múltiplos Ferimentos',
        indeterminado: 'Indeterminado', causa_natural: 'Causa Natural',
    };

    detail.innerHTML = `
        <div class="detail-header">
            <span class="detail-title"><i class="fas fa-skull-crossbones"></i> Necropsia - ${autopsy.victim_name || 'Desconhecido'}</span>
            <div style="display:flex;gap:8px;">
                ${autopsy.status !== 'concluido' && playerPermissions.canPerformAutopsy ? `
                    <button class="btn-primary" onclick="performToxicology(${autopsy.id})"><i class="fas fa-vial"></i> Toxicológico</button>
                    <button class="btn-success" onclick="completeAutopsy(${autopsy.id})"><i class="fas fa-check"></i> Concluir</button>
                ` : ''}
                <button class="btn-secondary" onclick="document.getElementById('autopsyDetail').classList.add('hidden')"><i class="fas fa-times"></i></button>
            </div>
        </div>
        <div class="detail-grid">
            <div class="detail-field"><label>Status</label>${getStatusBadge(autopsy.status)}</div>
            <div class="detail-field"><label>Vítima</label><span>${autopsy.victim_name || 'Desconhecido'}</span></div>
            <div class="detail-field"><label>Identificação</label><span>${autopsy.victim_status}</span></div>
            <div class="detail-field"><label>Causa da Morte</label><span>${causeLabels[autopsy.cause_of_death] || autopsy.cause_of_death}</span></div>
            <div class="detail-field"><label>Modo da Morte</label><span>${autopsy.manner_of_death}</span></div>
            <div class="detail-field"><label>Hora Estimada</label><span>${formatDate(autopsy.estimated_time_of_death)}</span></div>
            <div class="detail-field"><label>Temperatura Corporal</label><span>${autopsy.body_temperature || 'N/D'}°C</span></div>
            <div class="detail-field"><label>Rigor Mortis</label><span>${autopsy.rigor_mortis || 'N/D'}</span></div>
            <div class="detail-field"><label>Ferimentos</label><span>${autopsy.wounds_count || 0}</span></div>
            <div class="detail-field"><label>DNA Coletado</label><span>${autopsy.dna_collected ? 'Sim' : 'Não'}</span></div>
            <div class="detail-field"><label>Digitais Coletadas</label><span>${autopsy.fingerprints_collected ? 'Sim' : 'Não'}</span></div>
            <div class="detail-field"><label>Legista</label><span>${autopsy.examiner_name || 'N/D'}</span></div>
        </div>
        ${autopsy.trauma_description ? `<div class="detail-field"><label>Descrição do Trauma</label><p>${autopsy.trauma_description}</p></div>` : ''}
        ${autopsy.wounds_description ? `<div class="detail-field"><label>Descrição dos Ferimentos</label><p>${autopsy.wounds_description}</p></div>` : ''}
        ${autopsy.external_exam_notes ? `<div class="detail-field"><label>Exame Externo</label><p>${autopsy.external_exam_notes}</p></div>` : ''}
        ${autopsy.internal_exam_notes ? `<div class="detail-field"><label>Exame Interno</label><p>${autopsy.internal_exam_notes}</p></div>` : ''}
        ${autopsy.toxicology_result ? `<div class="detail-section"><h3><i class="fas fa-vial"></i> Resultado Toxicológico</h3><p>${autopsy.toxicology_result}</p></div>` : ''}
        ${autopsy.conclusion ? `<div class="detail-section"><h3><i class="fas fa-clipboard-check"></i> Conclusão</h3><p>${autopsy.conclusion}</p></div>` : ''}
    `;
}

async function performToxicology(autopsyId) {
    const result = await fetchNUI('performToxicology', { id: autopsyId });
    if (result && result.success) {
        showNotification('Exame toxicológico concluído: ' + (result.result || ''), 'success');
        await viewAutopsy(autopsyId);
    } else {
        showNotification(result?.error || 'Erro ao realizar toxicológico', 'error');
    }
}

async function completeAutopsy(autopsyId) {
    const result = await fetchNUI('updateAutopsy', { id: autopsyId, status: 'concluido' });
    if (result && result.success) {
        showNotification('Necropsia concluída com sucesso. Laudo gerado automaticamente.', 'success');
        await loadAutopsies();
        await viewAutopsy(autopsyId);
    } else {
        showNotification(result?.error || 'Erro ao concluir necropsia', 'error');
    }
}

// ============================================================
// REPORTS (LAUDOS)
// ============================================================
function filterReports() { loadReports(); }

async function loadReports() {
    const type   = document.getElementById('reportTypeFilter')?.value || '';
    const status = document.getElementById('reportStatusFilter')?.value || '';
    const result = await fetchNUI('getReports', { type: type || undefined, status: status || undefined });
    const container = document.getElementById('reportsList');

    // Normalizar resposta
    let reports = [];
    if (Array.isArray(result?.data)) {
        reports = result.data;
    } else if (result?.data?.items && Array.isArray(result.data.items)) {
        reports = result.data.items;
    } else if (Array.isArray(result)) {
        reports = result;
    }

    if (!reports || reports.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-file-medical"></i><p>Nenhum laudo encontrado</p></div>';
        return;
    }

    container.innerHTML = reports.map(report => `
        <div class="card" onclick="viewReport(${report.id})">
            <div class="card-header">
                <span class="card-title">${report.report_number || 'LAUDO'}</span>
                ${getStatusBadge(report.status)}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Título</span><span class="card-value">${report.title || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Tipo</span><span class="card-value">${report.type}</span></div>
                <div class="card-row"><span class="card-label">Autor</span><span class="card-value">${report.author_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(report.created_at)}</span></div>
            </div>
        </div>
    `).join('');
}

async function viewReport(reportId) {
    const report = await fetchNUI('getReport', { id: reportId });
    if (!report) return;

    const detail = document.getElementById('reportDetail');
    detail.classList.remove('hidden');

    detail.innerHTML = `
        <div class="detail-header">
            <span class="detail-title"><i class="fas fa-file-medical"></i> ${report.report_number}</span>
            <div style="display:flex;gap:8px;">
                ${report.status === 'rascunho' && playerPermissions.canFinalizeReport ? `
                    <button class="btn-success" onclick="finalizeReport(${report.id})"><i class="fas fa-check"></i> Finalizar</button>
                ` : ''}
                ${report.status === 'finalizado' ? `
                    <button class="btn-primary" onclick="attachToMDT(${report.id})"><i class="fas fa-link"></i> Anexar ao MDT</button>
                ` : ''}
                <button class="btn-secondary" onclick="document.getElementById('reportDetail').classList.add('hidden')"><i class="fas fa-times"></i></button>
            </div>
        </div>
        <div class="detail-grid">
            <div class="detail-field"><label>Status</label>${getStatusBadge(report.status)}</div>
            <div class="detail-field"><label>Tipo</label><span>${report.type}</span></div>
            <div class="detail-field"><label>Autor</label><span>${report.author_name || 'N/D'} (${report.author_role || 'N/D'})</span></div>
            <div class="detail-field"><label>Data</label><span>${formatDate(report.created_at)}</span></div>
            ${report.finalized_at ? `<div class="detail-field"><label>Finalizado em</label><span>${formatDate(report.finalized_at)}</span></div>` : ''}
            ${report.reviewer_name ? `<div class="detail-field"><label>Revisado por</label><span>${report.reviewer_name}</span></div>` : ''}
        </div>
        <div class="detail-field"><label>Título</label><p style="font-size:16px;font-weight:700;">${report.title}</p></div>
        ${report.summary ? `<div class="detail-field"><label>Resumo</label><p>${report.summary}</p></div>` : ''}
        ${report.body ? `<div class="detail-section"><h3>Corpo do Laudo</h3><p style="white-space:pre-wrap;">${report.body}</p></div>` : ''}
        ${report.conclusion ? `<div class="detail-section"><h3><i class="fas fa-clipboard-check"></i> Conclusão</h3><p>${report.conclusion}</p></div>` : ''}
    `;
}

async function finalizeReport(reportId) {
    const result = await fetchNUI('finalizeReport', { id: reportId });
    if (result && result.success) {
        showNotification('Laudo finalizado com sucesso', 'success');
        await loadReports();
        await viewReport(reportId);
    } else {
        showNotification(result?.error || 'Erro ao finalizar laudo', 'error');
    }
}

async function attachToMDT(reportId) {
    const result = await fetchNUI('attachReportToMDT', { id: reportId });
    if (result && result.success) {
        showNotification('Laudo anexado ao MDT com sucesso', 'success');
        await loadReports();
        await viewReport(reportId);
    } else {
        showNotification(result?.error || 'Erro ao anexar ao MDT', 'error');
    }
}

// ============================================================
// CROSSREF
// ============================================================
async function searchCrossRefCitizen() {
    const citizenid = document.getElementById('crossrefCitizenId').value;
    if (!citizenid) return;

    const result = await fetchNUI('getInvestigationDashboard', { citizenid });
    if (!result) return;

    renderCrossRefResults(result);
}

async function loadCrossRefDashboard() {
    const result = await fetchNUI('getForensicStats', {});
    const container = document.getElementById('crossrefResults');
    if (!result) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-project-diagram"></i><p>Sem dados de integração forense</p></div>';
        return;
    }
    container.innerHTML = `
        <div class="card">
            <div class="card-header"><span class="card-title">Painel de Integração MDT</span></div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Cenas</span><span class="card-value">${result.total_scenes || 0}</span></div>
                <div class="card-row"><span class="card-label">Evidências</span><span class="card-value">${result.total_evidence || 0}</span></div>
                <div class="card-row"><span class="card-label">Exames pendentes</span><span class="card-value">${result.pending_tests || 0}</span></div>
                <div class="card-row"><span class="card-label">Laudos</span><span class="card-value">${result.total_reports || 0}</span></div>
            </div>
        </div>
    `;
}

async function searchCrossRefWeapon() {
    const serial = document.getElementById('crossrefWeaponSerial').value;
    if (!serial) return;

    const result = await fetchNUI('getCrossRefByWeapon', { serial });
    renderCrossRefList(result || []);
}

async function searchCrossRefVehicle() {
    const plate = document.getElementById('crossrefVehiclePlate').value;
    if (!plate) return;

    const result = await fetchNUI('getCrossRefByVehicle', { plate });
    renderCrossRefList(result || []);
}

function renderCrossRefResults(dashboard) {
    const container = document.getElementById('crossrefResults');

    let html = `<div style="grid-column:1/-1;">`;

    // Fingerprints
    if (dashboard.fingerprints && dashboard.fingerprints.length > 0) {
        html += `<div class="detail-section"><h3><i class="fas fa-hand-dots"></i> Digitais Encontradas (${dashboard.fingerprints.length})</h3>`;
        dashboard.fingerprints.forEach(fp => {
            html += `<div class="card" style="margin-bottom:8px;cursor:default;">
                <div class="card-body">
                    <div class="card-row"><span class="card-label">Fonte</span><span class="card-value">${fp.source_description || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Cena</span><span class="card-value">${fp.scene_number || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Correspondência</span>${getStatusBadge(fp.match_status)}</div>
                    <div class="card-row"><span class="card-label">Confiança</span><span class="card-value">${fp.match_confidence || 0}%</span></div>
                </div>
            </div>`;
        });
        html += `</div>`;
    }

    // DNA
    if (dashboard.dna_matches && dashboard.dna_matches.length > 0) {
        html += `<div class="detail-section"><h3><i class="fas fa-dna"></i> DNA Encontrado (${dashboard.dna_matches.length})</h3>`;
        dashboard.dna_matches.forEach(dna => {
            html += `<div class="card" style="margin-bottom:8px;cursor:default;">
                <div class="card-body">
                    <div class="card-row"><span class="card-label">Fonte</span><span class="card-value">${dna.source_type || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Cena</span><span class="card-value">${dna.scene_number || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Correspondência</span>${getStatusBadge(dna.match_status)}</div>
                    <div class="card-row"><span class="card-label">Confiança</span><span class="card-value">${dna.match_confidence || 0}%</span></div>
                </div>
            </div>`;
        });
        html += `</div>`;
    }

    // Scenes involved
    if (dashboard.scenes_involved && dashboard.scenes_involved.length > 0) {
        html += `<div class="detail-section"><h3><i class="fas fa-map-marked-alt"></i> Cenas Envolvidas (${dashboard.scenes_involved.length})</h3>`;
        dashboard.scenes_involved.forEach(scene => {
            html += `<div class="card" style="margin-bottom:8px;cursor:default;">
                <div class="card-body">
                    <div class="card-row"><span class="card-label">Cena</span><span class="card-value">${scene.scene_number}</span></div>
                    <div class="card-row"><span class="card-label">Classificação</span><span class="card-value">${scene.classification}</span></div>
                    <div class="card-row"><span class="card-label">Status</span>${getStatusBadge(scene.status)}</div>
                </div>
            </div>`;
        });
        html += `</div>`;
    }

    // Cross references
    if (dashboard.cross_references && dashboard.cross_references.length > 0) {
        html += `<div class="detail-section"><h3><i class="fas fa-project-diagram"></i> Referências Cruzadas (${dashboard.cross_references.length})</h3>`;
        dashboard.cross_references.forEach(ref => {
            html += `<div class="card" style="margin-bottom:8px;cursor:default;">
                <div class="card-body">
                    <div class="card-row"><span class="card-label">Tipo</span><span class="card-value">${ref.source_type} → ${ref.target_type}</span></div>
                    <div class="card-row"><span class="card-label">Relação</span><span class="card-value">${ref.relationship || 'N/D'}</span></div>
                    <div class="card-row"><span class="card-label">Confiança</span>${getStatusBadge(ref.confidence)}</div>
                    ${ref.notes ? `<div class="card-row"><span class="card-value" style="font-size:11px;color:#9ca3af;">${ref.notes}</span></div>` : ''}
                </div>
            </div>`;
        });
        html += `</div>`;
    }

    if (!html.includes('detail-section')) {
        html += `<div class="empty-state"><i class="fas fa-search"></i><p>Nenhum dado forense encontrado para este cidadão</p></div>`;
    }

    html += `</div>`;
    container.innerHTML = html;
}

function renderCrossRefList(refs) {
    const container = document.getElementById('crossrefResults');

    if (!refs || refs.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-search"></i><p>Nenhuma referência encontrada</p></div>';
        return;
    }

    container.innerHTML = `<div style="grid-column:1/-1;">` + refs.map(ref => `
        <div class="card" style="margin-bottom:8px;cursor:default;">
            <div class="card-body">
                <div class="card-row"><span class="card-label">Fonte</span><span class="card-value">${ref.source_type} #${ref.source_id}</span></div>
                <div class="card-row"><span class="card-label">Alvo</span><span class="card-value">${ref.target_type}: ${ref.target_id}</span></div>
                <div class="card-row"><span class="card-label">Relação</span><span class="card-value">${ref.relationship || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Confiança</span>${getStatusBadge(ref.confidence)}</div>
                <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(ref.created_at)}</span></div>
                ${ref.notes ? `<div style="margin-top:4px;font-size:11px;color:#9ca3af;">${ref.notes}</div>` : ''}
            </div>
        </div>
    `).join('') + `</div>`;
}

// ============================================================
// MODAL HELPERS
// ============================================================
function showModal(title, bodyHTML, footerHTML) {
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('modalBody').innerHTML = bodyHTML;
    document.getElementById('modalFooter').innerHTML = footerHTML || '';
    document.getElementById('modal-overlay').classList.remove('hidden');
}

function closeModal() {
    document.getElementById('modal-overlay').classList.add('hidden');
}

function showNotification(message, type) {
    const colors = {
        success: '#22c55e',
        error: '#ef4444',
        info: '#3b82f6',
        warning: '#f59e0b',
    };
    const icons = {
        success: 'fa-check-circle',
        error: 'fa-exclamation-circle',
        info: 'fa-info-circle',
        warning: 'fa-exclamation-triangle',
    };
    const notif = document.createElement('div');
    notif.style.cssText = `
        position:fixed;top:20px;right:20px;z-index:99999;
        background:#1e293b;border:1px solid ${colors[type] || '#3b82f6'};
        color:#e2e8f0;padding:12px 20px;border-radius:8px;
        font-size:13px;display:flex;align-items:center;gap:10px;
        box-shadow:0 4px 12px rgba(0,0,0,0.4);
        animation:slideIn 0.3s ease;max-width:400px;
    `;
    notif.innerHTML = `<i class="fas ${icons[type] || 'fa-info-circle'}" style="color:${colors[type] || '#3b82f6'}"></i><span>${message}</span>`;
    document.body.appendChild(notif);
    setTimeout(() => {
        notif.style.opacity = '0';
        notif.style.transition = 'opacity 0.3s';
        setTimeout(() => notif.remove(), 300);
    }, 4000);
}

function debounce(fn, delay = 300) {
    let timer = null;
    return (...args) => {
        if (timer) clearTimeout(timer);
        timer = setTimeout(() => fn(...args), delay);
    };
}

function updateLookupHint(el, text, isError = false) {
    if (!el) return;
    el.textContent = text || '';
    el.style.color = isError ? '#fca5a5' : '#93c5fd';
}

function initCitizenAutofill(citizenInputId, nameInputId, hintId) {
    const citizenInput = getEl(citizenInputId);
    const nameInput = getEl(nameInputId);
    const hint = getEl(hintId);
    if (!citizenInput || !nameInput || !hint) return;

    const doLookup = debounce(async () => {
        const query = citizenInput.value?.trim();
        if (!query || query.length < 2) {
            updateLookupHint(hint, 'Digite pelo menos 2 caracteres para busca automática.');
            return;
        }

        updateLookupHint(hint, 'Buscando cidadão no MDT...');
        const result = await fetchNUI('lookupCitizenProfile', { query });
        if (!result || !result.citizenid) {
            updateLookupHint(hint, 'Nenhum cidadão encontrado para este identificador.', true);
            return;
        }

        citizenInput.value = result.citizenid;
        if (!nameInput.value || nameInput.value.trim() === '') {
            nameInput.value = result.name || '';
        }
        const phone = result.phone ? ` | Tel: ${result.phone}` : '';
        updateLookupHint(hint, `Auto-fill: ${result.name || result.citizenid}${phone}`);
    }, 280);

    citizenInput.addEventListener('input', doLookup);
}

function initWeaponSerialAutofill(serialInputId, hintId) {
    const serialInput = getEl(serialInputId);
    const hint = getEl(hintId);
    if (!serialInput || !hint) return;

    const doLookup = debounce(async () => {
        const serial = serialInput.value?.trim();
        if (!serial || serial.length < 3) {
            updateLookupHint(hint, 'Digite pelo menos 3 caracteres do serial.');
            return;
        }

        updateLookupHint(hint, 'Consultando registro de arma...');
        const result = await fetchNUI('lookupWeaponRegistry', { serial });
        if (!result || !result.serial) {
            updateLookupHint(hint, 'Serial não encontrado no registro legal.', true);
            return;
        }

        serialInput.value = result.serial;
        const owner = result.owner_name || result.owner_citizenid || 'Sem proprietário';
        const model = result.weapon_model || 'Modelo não informado';
        updateLookupHint(hint, `Auto-fill: ${model} | Proprietário: ${owner}`);
    }, 280);

    serialInput.addEventListener('input', doLookup);
}

function showRegisterFingerprint() {
    showModal('Cadastrar Impressão Digital', `
        <div class="form-group"><label>CitizenID</label><input type="text" id="fpCitizenId" placeholder="CitizenID do cidadão"></div>
        <div class="form-group"><label>Nome do Cidadão</label><input type="text" id="fpCitizenName" placeholder="Nome completo"></div>
        <div id="fpCitizenLookupHint" class="lookup-hint">Digite CitizenID ou nome para auto-preenchimento.</div>
    `, `<button class="btn-primary" onclick="doRegisterFingerprint()">Cadastrar</button>`);
    initCitizenAutofill('fpCitizenId', 'fpCitizenName', 'fpCitizenLookupHint');
}

async function doRegisterFingerprint() {
    const citizenid = document.getElementById('fpCitizenId').value;
    const name = document.getElementById('fpCitizenName').value;
    if (!citizenid) {
        showNotification('CitizenID é obrigatório', 'error');
        return;
    }

    const result = await fetchNUI('registerFingerprint', { citizenid, name });
    if (result && result.success) {
        closeModal();
        const msg = result.reused ? 'Digital já cadastrada (reutilizada)' : `Digital cadastrada: ${result.code || ''}`;
        if (result.retroMatches > 0) {
            showNotification(`${msg} | ${result.retroMatches} correspondência(s) retroativa(s) encontrada(s)!`, 'success');
        } else {
            showNotification(msg, 'success');
        }
        await loadFingerprints();
    } else {
        showNotification(result?.error || 'Erro ao cadastrar digital', 'error');
    }
}

function showRegisterDNA() {
    showModal('Cadastrar Perfil Genético', `
        <div class="form-group"><label>CitizenID</label><input type="text" id="dnaCitizenId" placeholder="CitizenID do cidadão"></div>
        <div class="form-group"><label>Nome do Cidadão</label><input type="text" id="dnaCitizenName" placeholder="Nome completo"></div>
        <div id="dnaCitizenLookupHint" class="lookup-hint">Digite CitizenID ou nome para auto-preenchimento.</div>
        <div class="form-group"><label>Tipo Sanguíneo</label>
            <select id="dnaBloodType">
                <option value="Desconhecido">Desconhecido</option>
                <option value="A+">A+</option><option value="A-">A-</option>
                <option value="B+">B+</option><option value="B-">B-</option>
                <option value="AB+">AB+</option><option value="AB-">AB-</option>
                <option value="O+">O+</option><option value="O-">O-</option>
            </select>
        </div>
    `, `<button class="btn-primary" onclick="doRegisterDNA()">Cadastrar</button>`);
    initCitizenAutofill('dnaCitizenId', 'dnaCitizenName', 'dnaCitizenLookupHint');
}

async function doRegisterDNA() {
    const citizenid = document.getElementById('dnaCitizenId').value;
    const name = document.getElementById('dnaCitizenName').value;
    const bloodType = document.getElementById('dnaBloodType').value;
    if (!citizenid) {
        showNotification('CitizenID é obrigatório', 'error');
        return;
    }

    const result = await fetchNUI('registerDNA', { citizenid, name, bloodType });
    if (result && result.success) {
        closeModal();
        const msg = result.reused ? 'Perfil de DNA já cadastrado (reutilizado)' : `Perfil de DNA cadastrado: ${result.code || ''}`;
        if (result.retroMatches > 0) {
            showNotification(`${msg} | ${result.retroMatches} correspondência(s) retroativa(s) encontrada(s)!`, 'success');
        } else {
            showNotification(msg, 'success');
        }
        await loadDNA();
    } else {
        showNotification(result?.error || 'Erro ao cadastrar perfil de DNA', 'error');
    }
}

function showCreateAutopsy() {
    showModal('Nova Necropsia', `
        <div class="form-group"><label>Nome da Vítima</label><input type="text" id="autopsyVictimName" placeholder="Nome ou Desconhecido"></div>
        <div class="form-group"><label>CitizenID da Vítima (se identificada)</label><input type="text" id="autopsyVictimCid" placeholder="CitizenID"></div>
        <div id="autopsyVictimLookupHint" class="lookup-hint">Digite CitizenID ou nome para auto-preenchimento.</div>
        <div class="form-group"><label>Status da Identificação</label>
            <select id="autopsyVictimStatus">
                <option value="nao_identificado">Não Identificado</option>
                <option value="identificado">Identificado</option>
                <option value="parcialmente_identificado">Parcialmente Identificado</option>
            </select>
        </div>
        <div class="form-group"><label>Causa da Morte</label>
            <select id="autopsyCauseOfDeath">
                <option value="indeterminado">Indeterminado</option>
                <option value="arma_de_fogo">Arma de Fogo</option>
                <option value="arma_branca">Arma Branca</option>
                <option value="trauma_contundente">Trauma Contundente</option>
                <option value="asfixia">Asfixia</option>
                <option value="queimadura">Queimadura</option>
                <option value="overdose">Overdose</option>
                <option value="envenenamento">Envenenamento</option>
                <option value="afogamento">Afogamento</option>
                <option value="multiplos_ferimentos">Múltiplos Ferimentos</option>
                <option value="causa_natural">Causa Natural</option>
            </select>
        </div>
        <div class="form-group"><label>Maneira da Morte</label>
            <select id="autopsyMannerOfDeath">
                <option value="indeterminado">Indeterminado</option>
                <option value="homicidio">Homicídio</option>
                <option value="suicidio">Suicídio</option>
                <option value="acidente">Acidente</option>
                <option value="natural">Natural</option>
            </select>
        </div>
        <div class="form-group"><label>Temperatura Corporal (°C)</label><input type="number" id="autopsyBodyTemp" placeholder="Ex: 32.5" step="0.1"></div>
        <div class="form-group"><label>Rigor Mortis</label>
            <select id="autopsyRigor">
                <option value="">Não avaliado</option>
                <option value="ausente">Ausente</option>
                <option value="inicial">Inicial</option>
                <option value="completo">Completo</option>
                <option value="resolvendo">Resolvendo</option>
            </select>
        </div>
        <div class="form-group"><label>Nº de Ferimentos</label><input type="number" id="autopsyWoundsCount" value="0" min="0"></div>
        <div class="form-group"><label>Descrição dos Ferimentos</label><textarea id="autopsyWoundsDesc" rows="2" placeholder="Descreva os ferimentos..."></textarea></div>
        <div class="form-group"><label>Descrição do Trauma</label><textarea id="autopsyTraumaDesc" rows="2" placeholder="Descreva o trauma..."></textarea></div>
        <div class="form-group"><label>ID da Cena (opcional)</label><input type="number" id="autopsySceneId" placeholder="ID da cena de crime"></div>
        <div class="form-group"><label>ID do Caso MDT (opcional)</label><input type="number" id="autopsyCaseId" placeholder="Número do caso"></div>
    `, `<button class="btn-primary" onclick="doCreateAutopsy()"><i class="fas fa-plus"></i> Criar Necropsia</button>`);
    initCitizenAutofill('autopsyVictimCid', 'autopsyVictimName', 'autopsyVictimLookupHint');
}

window.addEventListener('load', function() {
    initWeaponSerialAutofill('ballisticSearch', 'ballisticLookupHint');
});

async function doCreateAutopsy() {
    const data = {
        victim_name: getEl('autopsyVictimName')?.value || 'Desconhecido',
        victim_citizenid: getEl('autopsyVictimCid')?.value || null,
        victim_status: getEl('autopsyVictimStatus')?.value || 'nao_identificado',
        cause_of_death: getEl('autopsyCauseOfDeath')?.value || 'indeterminado',
        manner_of_death: getEl('autopsyMannerOfDeath')?.value || 'indeterminado',
        body_temperature: parseFloat(getEl('autopsyBodyTemp')?.value) || null,
        rigor_mortis: getEl('autopsyRigor')?.value || null,
        wounds_count: parseInt(getEl('autopsyWoundsCount')?.value) || 0,
        wounds_description: getEl('autopsyWoundsDesc')?.value || '',
        trauma_description: getEl('autopsyTraumaDesc')?.value || '',
        scene_id: getEl('autopsySceneId')?.value || null,
        case_id: getEl('autopsyCaseId')?.value || null,
    };
    const result = await fetchNUI('createAutopsy', data);
    if (result && result.success) {
        closeModal();
        showNotification('Necropsia criada com sucesso', 'success');
        await loadAutopsies();
    } else {
        showNotification(result?.error || 'Erro ao criar necropsia', 'error');
    }
}

function showCreateReport() {
    showModal('Novo Laudo Técnico', `
        <div class="form-group"><label>Tipo de Laudo</label>
            <select id="reportType">
                <option value="laudo_pericial">Laudo Pericial</option>
                <option value="laudo_balistico">Laudo Balístico</option>
                <option value="laudo_toxicologico">Laudo Toxicológico</option>
                <option value="laudo_dna">Laudo DNA</option>
                <option value="laudo_digital">Laudo Digital</option>
                <option value="laudo_necropsia">Laudo Necropsia</option>
                <option value="laudo_drogas">Laudo Drogas</option>
            </select>
        </div>
        <div class="form-group"><label>Título</label><input type="text" id="reportTitle" placeholder="Título do laudo"></div>
        <div class="form-group"><label>Resumo</label><textarea id="reportSummary" rows="2" placeholder="Resumo executivo..."></textarea></div>
        <div class="form-group"><label>Corpo do Laudo</label><textarea id="reportBody" rows="5" placeholder="Detalhamento técnico..."></textarea></div>
        <div class="form-group"><label>Conclusão</label><textarea id="reportConclusion" rows="3" placeholder="Conclusão técnica..."></textarea></div>
        <div class="form-group"><label>ID da Cena (opcional)</label><input type="number" id="reportSceneId" placeholder="ID da cena"></div>
        <div class="form-group"><label>ID do Caso MDT (opcional)</label><input type="number" id="reportCaseId" placeholder="Número do caso"></div>
        <div class="form-group"><label>ID do Relatório MDT (opcional)</label><input type="number" id="reportMdtId" placeholder="ID do relatório no MDT"></div>
    `, `<button class="btn-primary" onclick="doCreateReport()"><i class="fas fa-plus"></i> Criar Laudo</button>`);
}

async function doCreateReport() {
    const title = getEl('reportTitle')?.value;
    if (!title) {
        showNotification('Título do laudo é obrigatório', 'error');
        return;
    }
    const data = {
        type: getEl('reportType')?.value || 'laudo_pericial',
        title: title,
        summary: getEl('reportSummary')?.value || '',
        body: getEl('reportBody')?.value || '',
        conclusion: getEl('reportConclusion')?.value || '',
        scene_id: getEl('reportSceneId')?.value || null,
        case_id: getEl('reportCaseId')?.value || null,
        mdt_report_id: getEl('reportMdtId')?.value || null,
    };
    const result = await fetchNUI('createReport', data);
    if (result && result.success) {
        closeModal();
        showNotification('Laudo criado: ' + (result.reportNumber || ''), 'success');
        await loadReports();
    } else {
        showNotification(result?.error || 'Erro ao criar laudo', 'error');
    }
}
