const state = {
  visible: true,
  paused: false,
  low: { health: 25, hunger: 20, thirst: 20, stress: 80 },
  bleeding: { max: 4, pulseFromLevel: 2 },
  speedometer: { enabled: true, unit: 'KM/H' },
  values: {
    health: 100,
    hunger: 100,
    thirst: 100,
    stress: 0,
    speed: 0,
  },
};

const hud = document.getElementById('hud');
const voiceChip = document.getElementById('voiceChip');
const voiceIcon = document.getElementById('voiceIcon');
const voiceLabel = document.getElementById('voiceLabel');
const voiceRange = document.getElementById('voiceRange');
const bleedChip = document.getElementById('bleedChip');
const bleedText = document.getElementById('bleedText');
const bleedDots = document.getElementById('bleedDots');
const speedChip = document.getElementById('speedChip');
const speedValue = document.getElementById('speedValue');
const speedUnit = document.getElementById('speedUnit');

const rows = {
  health: document.querySelector(".stat-chip[data-key='health']"),
  hunger: document.querySelector(".stat-chip[data-key='hunger']"),
  thirst: document.querySelector(".stat-chip[data-key='thirst']"),
  stress: document.querySelector(".stat-chip[data-key='stress']"),
};

function setVar(name, value) {
  document.documentElement.style.setProperty(name, value);
}

function clamp(value) {
  return Math.max(0, Math.min(100, Number(value) || 0));
}

function renderVisibility() {
  hud.classList.toggle('hidden', !state.visible);
  hud.classList.toggle('paused', state.paused);
}

function updateStatus(key, value) {
  const safe = clamp(value);
  if (state.values[key] === safe) return;
  state.values[key] = safe;

  const fill = document.getElementById(`bar-${key}`);
  const valueEl = document.getElementById(`value-${key}`);
  if (!fill || !valueEl) return;

  fill.style.width = `${safe}%`;
  valueEl.textContent = `${Math.round(safe)}%`;

  if (!rows[key]) return;
  const threshold = state.low[key] ?? 0;
  const isLow = key === 'stress' ? safe >= threshold : safe <= threshold;
  rows[key].classList.toggle('low', isLow);
}

function updateSpeed(data) {
  const speed = Math.max(0, Math.floor(Number(data.value) || 0));
  const unit = data.unit || state.speedometer.unit;

  if (state.values.speed === speed && state.speedometer.unit === unit) return;
  state.values.speed = speed;
  state.speedometer.unit = unit;

  speedValue.textContent = `${speed}`;
  speedUnit.textContent = unit;
  speedChip.classList.toggle('active', speed > 0);
}

function buildBleedDots(max) {
  bleedDots.innerHTML = '';
  for (let i = 0; i < max; i += 1) {
    const dot = document.createElement('span');
    bleedDots.appendChild(dot);
  }
}

function updateBleeding(data) {
  const level = Math.max(0, Math.min(data.max ?? state.bleeding.max, Number(data.level) || 0));
  const max = Number(data.max) || state.bleeding.max;

  if (max !== state.bleeding.max || bleedDots.children.length !== max) {
    state.bleeding.max = max;
    buildBleedDots(max);
  }

  const labels = ['None', 'Minor', 'Light', 'Heavy', 'Critical'];
  bleedText.textContent = `Bleeding: ${labels[level] || `Level ${level}`}`;

  [...bleedDots.children].forEach((dot, index) => {
    dot.classList.toggle('active', index < level);
  });

  bleedChip.classList.toggle('active', level >= (state.bleeding.pulseFromLevel ?? 2));
}

function updateVoice(data) {
  const color = data.color || '#74ffc4';
  voiceLabel.textContent = data.label || 'Normal';
  voiceRange.textContent = `${Number(data.range || 8).toFixed(1)}m`;
  voiceIcon.src = data.icon || 'assets/icons/voice-normal.svg';

  voiceLabel.style.color = color;
  voiceIcon.style.filter = `drop-shadow(0 0 7px ${color})`;
  voiceChip.classList.toggle('talking', Boolean(data.talking));
}

function applyConfig(config) {
  if (config.position === 'bottom-left') hud.classList.add('bottom-left');

  if (config.offsetX !== undefined) hud.style.left = `${config.offsetX}vw`;
  if (config.offsetY !== undefined) hud.style.bottom = `${config.offsetY}vh`;

  if (config.barWidth) setVar('--bar-width', `${config.barWidth}px`);
  if (config.barHeight) setVar('--bar-height', `${config.barHeight}px`);
  if (config.barGap) setVar('--bar-gap', `${config.barGap}px`);
  if (config.animationSpeed) setVar('--anim', `${config.animationSpeed}ms`);
  if (config.panelOpacity !== undefined) setVar('--panel-opacity', String(config.panelOpacity));

  if (config.low) state.low = { ...state.low, ...config.low };
  if (config.bleeding) state.bleeding = { ...state.bleeding, ...config.bleeding };
  if (config.speedometer) state.speedometer = { ...state.speedometer, ...config.speedometer };

  if (config.theme) {
    if (config.theme.panel) setVar('--panel-bg', config.theme.panel);
    if (config.theme.chip) setVar('--chip-bg', config.theme.chip);
    if (config.theme.text) setVar('--txt', config.theme.text);
    if (config.theme.muted) setVar('--muted', config.theme.muted);
    if (config.theme.health) setVar('--health', config.theme.health);
    if (config.theme.hunger) setVar('--hunger', config.theme.hunger);
    if (config.theme.thirst) setVar('--thirst', config.theme.thirst);
    if (config.theme.stress) setVar('--stress', config.theme.stress);
    if (config.theme.bleeding) setVar('--bleeding', config.theme.bleeding);
    if (config.theme.speed) setVar('--speed', config.theme.speed);
  }

  speedChip.style.display = state.speedometer.enabled ? 'flex' : 'none';
  speedUnit.textContent = state.speedometer.unit;
  buildBleedDots(state.bleeding.max);
}

window.addEventListener('message', (event) => {
  const msg = event.data;
  if (!msg?.action) return;

  if (msg.action === 'status') updateStatus(msg.data.key, msg.data.value);
  if (msg.action === 'speed') updateSpeed(msg.data);
  if (msg.action === 'voice') updateVoice(msg.data);
  if (msg.action === 'bleeding') updateBleeding(msg.data);
  if (msg.action === 'config') applyConfig(msg.data);

  if (msg.action === 'toggle') {
    state.visible = Boolean(msg.data.visible);
    renderVisibility();
  }

  if (msg.action === 'pause') {
    state.paused = Boolean(msg.data.paused);
    renderVisibility();
  }

  if (msg.action === 'reset') {
    hud.style.left = '';
    hud.style.bottom = '';
  }
});

buildBleedDots(state.bleeding.max);
Object.keys(rows).forEach((key) => updateStatus(key, state.values[key]));
updateBleeding({ level: 0, max: state.bleeding.max });
updateSpeed({ value: 0, unit: state.speedometer.unit });
renderVisibility();
