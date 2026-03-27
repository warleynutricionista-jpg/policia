window.ForensicsUI = (function () {
    function escapeHTML(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function sanitizeHTML(raw) {
        const tpl = document.createElement('template');
        tpl.innerHTML = String(raw ?? '');

        tpl.content.querySelectorAll('script, iframe, object, embed').forEach((n) => n.remove());
        tpl.content.querySelectorAll('*').forEach((node) => {
            [...node.attributes].forEach((attr) => {
                const name = attr.name.toLowerCase();
                const value = String(attr.value || '').trim().toLowerCase();
                if (name.startsWith('on')) node.removeAttribute(attr.name);
                if ((name === 'src' || name === 'href') && value.startsWith('javascript:')) {
                    node.removeAttribute(attr.name);
                }
            });
        });

        return tpl.innerHTML;
    }

    function setHTML(el, raw) {
        if (!el) return;
        el.innerHTML = sanitizeHTML(raw);
    }

    function renderLoadingCards(count = 6) {
        return `<div class="skeleton-grid">${Array.from({ length: count }).map(() => `
            <div class="skeleton-card">
                <div class="skeleton-line w-60"></div>
                <div class="skeleton-line w-100"></div>
                <div class="skeleton-line w-80"></div>
            </div>
        `).join('')}</div>`;
    }

    function renderEmpty(icon, text) {
        return `<div class="empty-state"><i class="fas ${escapeHTML(icon)}"></i><p>${escapeHTML(text)}</p></div>`;
    }

    return {
        escapeHTML,
        sanitizeHTML,
        setHTML,
        renderLoadingCards,
        renderEmpty,
    };
})();
