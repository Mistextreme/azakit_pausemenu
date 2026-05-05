const DEBUG_MODE = false;

let LANG = {};
let pendingAction = null;
let escBound = false;

const log = (...args) => {
    if (DEBUG_MODE) console.log(...args);
};

// ================= UI HELPERS =================

const el = (q) => document.querySelector(q);

const write = (q, val) => {
    const e = el(q);
    if (e) e.textContent = val;
};

const clearPopups = () => {
    $('.confirmation-popup').hide();
    $('#overlay').hide();
};

// ================= LOCALE =================

function applyLocale(data) {
    if (!data?.mainpage) return;

    LANG = data;
    const m = LANG.mainpage;

    write('#discord-url', m.discord_display);
    write('#website-url', m.website_display);

    write('#map-h2', m.map.title);
    write('#map-p', m.map.description);

    write('#settings-h2', m.settings.title);
    write('#settings-p', m.settings.description);

    write('#exit-h2', m.exit.title);
    write('#exit-p', m.exit.description);

    write('#rules-h2', m.rules.title);

    const list = el('#rules-div');
    if (list && m.rules.rules) {
        list.innerHTML = '';
        m.rules.rules.forEach(r => {
            const p = document.createElement('p');
            p.textContent = `• ${r}`;
            list.appendChild(p);
        });
    }

    write('#rules-popup-title', m.rules.title);
    write('#close-rules', m.rules.closeButton || 'CLOSE');

    const stats = document.querySelectorAll('.stat-label');
    if (stats.length >= 3 && m.stats) {
        stats[0].textContent = m.stats.name;
        stats[1].textContent = m.stats.job;
        stats[2].textContent = m.stats.cash;
    }

    write('.footer-text', m.resume);

    if (LANG.confirm) {
        write('#confirmationPopup h2', LANG.confirm.title);
        write('#confirmAction', LANG.confirm.yes);
        write('#cancelAction', LANG.confirm.no);
    }
}

// ================= PLAYER =================

function renderPlayer(p) {
    if (!p) return;

    const id = p.playerID || p.source || "0";
    const label = LANG.player_id || "ID";

    write('#player-id', `${label}: ${id}`);
    write('#stat-name', p.name || "Unknown");
    write('#stat-job', p.job || "N/A");

    const symbol = LANG.mainpage?.stats?.currencySymbol || "$";
    write('#stat-cash', `${symbol} ${(p.cash || 0).toLocaleString()}`);

    if (el('#stat-bank')) {
        write('#stat-bank', `$ ${(p.bank || 0).toLocaleString()}`);
    }
}

// ================= TIME =================

function getClock() {
    const d = new Date();
    let h = d.getHours();
    const m = d.getMinutes().toString().padStart(2, '0');

    const ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12 || 12;

    return `${h}:${m} ${ampm}`;
}

setInterval(() => {
    write('#current-time', getClock());
}, 1000);

// ================= MENU =================

function showMenu() {
    document.body.style.display = 'block';

    if (!escBound) {
        document.addEventListener('keydown', e => {
            if (e.key === 'Escape') hideMenu();
        });
        escBound = true;
    }
}

function hideMenu() {
    clearPopups();
    $('#rules-popup').hide();

    document.body.classList.add('closing');

    fetch(`https://${GetParentResourceName()}/closePauseMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: "{}"
    })
    .finally(() => {
        setTimeout(() => {
            document.body.style.display = 'none';
            document.body.classList.remove('closing');
        }, 500);
    });
}

// ================= CONFIRM =================

function confirmBox(msg, action, cb) {
    clearPopups();

    pendingAction = action;
    write('#popup-text', msg);

    $('#confirmationPopup').fadeIn(200);
    $('#overlay').show();

    $('#confirmAction').off().on('click', () => {
        $.post(`https://${GetParentResourceName()}/actionPauseMenu`, JSON.stringify(pendingAction));
        pendingAction = null;
        cb();
        clearPopups();
    });

    $('#cancelAction').off().on('click', clearPopups);
}

// ================= EVENTS =================

$(function () {

    $('#discord-copy-btn').on('click', () => {
        const link = LANG.mainpage?.discord_url || '';
        log("Discord:", link);

        window.invokeNative("openUrl", link);

        const t = document.createElement('textarea');
        t.value = link;
        document.body.appendChild(t);
        t.select();
        document.execCommand('copy');
        document.body.removeChild(t);
    });

    $('#website-btn').on('click', () => {
        const link = LANG.mainpage?.website_url || '';
        log("Website:", link);
        window.invokeNative("openUrl", link);
    });

    $('#announcement').on('click', () => {
        clearPopups();

        const box = el('#rules-list-container');
        if (!box || !LANG.mainpage?.rules) return;

        box.innerHTML = '';
        LANG.mainpage.rules.fullRules.forEach(r => {
            const p = document.createElement('p');
            p.textContent = r;
            box.appendChild(p);
        });

        $('#rules-popup').fadeIn(300).css('display', 'flex');
    });

    $('#close-rules').on('click', clearPopups);

    $('#map').on('click', () => {
        $.post(`https://${GetParentResourceName()}/actionPauseMenu`, JSON.stringify('maps'));
        hideMenu();
    });

    $('#settings').on('click', () => {
        $.post(`https://${GetParentResourceName()}/actionPauseMenu`, JSON.stringify('settings'));
        hideMenu();
    });

    $('#quit').on('click', () => {
        confirmBox(LANG.confirm.exit_confirmation, 'quit', hideMenu);
    });

    const id = $('#player-identifier');
    id.css({ filter: 'blur(1.8px)', cursor: 'pointer' });

    id.on('click', function () {
        $(this).css('filter', $(this).css('filter') === 'blur(1.8px)' ? 'none' : 'blur(1.8px)');
    });
});

// ================= MESSAGE =================

window.addEventListener('message', (e) => {
    const d = e.data;

    if (d.colors) {
        const root = document.documentElement;
        root.style.setProperty('--accent', d.colors.accentColor);
        root.style.setProperty('--accent-glow', d.colors.accentGlow);
        root.style.setProperty('--bg-dark', d.colors.bgDark);
    }

    if (d.translations) applyLocale(d.translations);
    if (d.DataPlayer) renderPlayer(d.DataPlayer);

    if (d.nameServer) write('.menu-header h1', d.nameServer);

    showMenu();
});