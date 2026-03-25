// ============================================================
// PS-FORENSICS - Frontend JavaScript
// ============================================================

let currentTab = 'scenes';
let playerRole = 'policial';
let playerPermissions = {};
let playerName = '';

// ============================================================
// NUI MESSAGE HANDLER
// ============================================================
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        document.getElementById('forensics-app').classList.remove('hidden');
        playerRole = data.role || 'policial';
        playerPermissions = data.permissions || {};
        playerName = data.playerName || 'Oficial';

        document.getElementById('playerInfo').textContent = `${playerName} | ${data.playerJob || ''} | Grade ${data.playerGrade || 0}`;
        document.getElementById('roleBadge').textContent = playerRole.toUpperCase();

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

        switchTab(data.tab || 'scenes');
    }

    if (data.action === 'close') {
        document.getElementById('forensics-app').classList.add('hidden');
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
    document.getElementById('forensics-app').classList.add('hidden');
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
    currentTab = tab;

    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));

    document.getElementById('tab-' + tab).classList.add('active');
    const navBtn = document.querySelector(`.nav-btn[data-tab="${tab}"]`);
    if (navBtn) navBtn.classList.add('active');

    // Load data for tab
    loadTabData(tab);
}

async function loadTabData(tab) {
    switch(tab) {
        case 'scenes': await loadScenes(); break;
        case 'evidence': await loadEvidence(); break;
        case 'lab': await loadLabTests(); break;
        case 'fingerprints': await loadFingerprints(); break;
        case 'dna': await loadDNA(); break;
        case 'ballistics': await loadBallistics(); break;
        case 'drugs': await loadDrugs(); break;
        case 'autopsy': await loadAutopsies(); break;
        case 'reports': await loadReports(); break;
        case 'crossref': await loadCrossRefDashboard(); break;
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
        await loadScenes();
        await viewScene(sceneId);
    }
}

function showCreateScene() {
    // Delegate to client-side ox_lib menu
    fetchNUI('close');
    // The actual menu is opened via client Lua
}

// ============================================================
// EVIDENCE
// ============================================================
async function loadEvidence() {
    const category = document.getElementById('evidenceCategoryFilter')?.value || '';
    const search = document.getElementById('evidenceSearch')?.value || '';

    const result = await fetchNUI('getEvidenceList', { category, search });
    const container = document.getElementById('evidenceList');

    if (!result || !result.success || !result.data || result.data.items.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-fingerprint"></i><p>Nenhuma evidência encontrada</p></div>';
        return;
    }

    container.innerHTML = result.data.items.map(ev => `
        <div class="card priority-${ev.priority || 'media'}" onclick="viewEvidence(${ev.id})">
            <div class="card-header">
                <span class="card-title">${ev.evidence_number || 'EV-???'}</span>
                ${getStatusBadge(ev.status)}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Tipo</span><span class="card-value">${ev.type || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Categoria</span><span class="card-value">${ev.category || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Lacre</span><span class="card-value">${ev.seal_number || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Coletada por</span><span class="card-value">${ev.collected_by_name || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Data</span><span class="card-value">${formatDate(ev.collection_time)}</span></div>
            </div>
        </div>
    `).join('');
}

function searchEvidence() { loadEvidence(); }
function filterEvidence() { loadEvidence(); }

async function loadFingerprints() {
    const citizenid = document.getElementById('fpSearch')?.value || '';
    const list = document.getElementById('fingerprintsList');
    const rows = citizenid ? await fetchNUI('searchFingerprintsByCitizen', { citizenid }) : [];
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-hand-dots"></i><p>Nenhuma digital encontrada</p></div>';
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
            </div>
        </div>
    `).join('');
}

async function loadDNA() {
    const citizenid = document.getElementById('dnaSearch')?.value || '';
    const list = document.getElementById('dnaList');
    const rows = citizenid ? await fetchNUI('searchDNAByCitizen', { citizenid }) : [];
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-dna"></i><p>Nenhuma análise de DNA encontrada</p></div>';
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
            </div>
        </div>
    `).join('');
}

async function loadBallistics() {
    const serial = document.getElementById('ballisticSearch')?.value || '';
    const list = document.getElementById('ballisticsList');
    const rows = serial ? await fetchNUI('getWeaponBallisticHistory', { serial }) : [];
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-crosshairs"></i><p>Nenhum histórico balístico encontrado</p></div>';
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
            </div>
        </div>
    `).join('');
}

async function loadDrugs() {
    const list = document.getElementById('drugsList');
    const result = await fetchNUI('getDrugAnalyses', {});
    const rows = result?.data || [];
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty-state"><i class="fas fa-pills"></i><p>Nenhuma análise de substância encontrada</p></div>';
        return;
    }
    list.innerHTML = rows.map(d => `
        <div class="card">
            <div class="card-header">
                <span class="card-title">${d.confirmed_substance || d.preliminary_classification || 'Substância não definida'}</span>
                ${getStatusBadge(d.test_result || 'suspeita')}
            </div>
            <div class="card-body">
                <div class="card-row"><span class="card-label">Categoria</span><span class="card-value">${d.substance_category || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Caso</span><span class="card-value">${d.case_id || 'N/D'}</span></div>
                <div class="card-row"><span class="card-label">Relatório</span><span class="card-value">${d.report_id || 'N/D'}</span></div>
            </div>
        </div>
    `).join('');
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

// ============================================================
// AUTOPSIES
// ============================================================
async function loadAutopsies() {
    const result = await fetchNUI('getAutopsies', {});
    const container = document.getElementById('autopsyList');

    if (!result || !result.success || !result.data || result.data.length === 0) {
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

    container.innerHTML = result.data.map(autopsy => `
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
        await viewAutopsy(autopsyId);
    }
}

async function completeAutopsy(autopsyId) {
    const result = await fetchNUI('updateAutopsy', { id: autopsyId, status: 'concluido' });
    if (result && result.success) {
        await loadAutopsies();
        await viewAutopsy(autopsyId);
    }
}

// ============================================================
// REPORTS (LAUDOS)
// ============================================================
async function loadReports() {
    const type = document.getElementById('reportTypeFilter')?.value || '';
    const result = await fetchNUI('getReports', { type });
    const container = document.getElementById('reportsList');

    if (!result || !result.success || !result.data || result.data.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-file-medical"></i><p>Nenhum laudo encontrado</p></div>';
        return;
    }

    container.innerHTML = result.data.map(report => `
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

function filterReports() { loadReports(); }

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
        await loadReports();
        await viewReport(reportId);
    }
}

async function attachToMDT(reportId) {
    const result = await fetchNUI('attachReportToMDT', { id: reportId });
    if (result && result.success) {
        await loadReports();
        await viewReport(reportId);
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

function showRegisterFingerprint() {
    showModal('Cadastrar Impressão Digital', `
        <div class="form-group"><label>CitizenID</label><input type="text" id="fpCitizenId" placeholder="CitizenID do cidadão"></div>
        <div class="form-group"><label>Nome do Cidadão</label><input type="text" id="fpCitizenName" placeholder="Nome completo"></div>
    `, `<button class="btn-primary" onclick="doRegisterFingerprint()">Cadastrar</button>`);
}

async function doRegisterFingerprint() {
    const citizenid = document.getElementById('fpCitizenId').value;
    const name = document.getElementById('fpCitizenName').value;
    if (!citizenid) return;

    const result = await fetchNUI('registerFingerprint', { citizenid, name });
    if (result && result.success) {
        closeModal();
    }
}

function showRegisterDNA() {
    showModal('Cadastrar Perfil Genético', `
        <div class="form-group"><label>CitizenID</label><input type="text" id="dnaCitizenId" placeholder="CitizenID do cidadão"></div>
        <div class="form-group"><label>Nome do Cidadão</label><input type="text" id="dnaCitizenName" placeholder="Nome completo"></div>
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
}

async function doRegisterDNA() {
    const citizenid = document.getElementById('dnaCitizenId').value;
    const name = document.getElementById('dnaCitizenName').value;
    const bloodType = document.getElementById('dnaBloodType').value;
    if (!citizenid) return;

    const result = await fetchNUI('registerDNA', { citizenid, name, bloodType });
    if (result && result.success) {
        closeModal();
    }
}

function showCreateAutopsy() {
    fetchNUI('close');
}

function showCreateReport() {
    fetchNUI('close');
}
