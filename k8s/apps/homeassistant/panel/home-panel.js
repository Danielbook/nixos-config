// home-panel: a full-screen dashboard card. Entity IDs come from the card
// config in dashboards/glass.yaml. This file holds only layout and logic.
import { LitElement, html, css, nothing } from "./lit-core.min.js";

const ACTIVE = ["on", "open", "opening", "cleaning", "playing", "heating", "armed_home", "armed_away", "armed_night", "triggered"];
const ALERT = ["on", "open", "opening", "triggered", "problem"];
const OFFLINE = ["unavailable", "unknown"];
const WEATHER_ICONS = {
  "clear-night": "mdi:weather-night", cloudy: "mdi:weather-cloudy", fog: "mdi:weather-fog",
  hail: "mdi:weather-hail", lightning: "mdi:weather-lightning", "lightning-rainy": "mdi:weather-lightning-rainy",
  partlycloudy: "mdi:weather-partly-cloudy", pouring: "mdi:weather-pouring", rainy: "mdi:weather-rainy",
  snowy: "mdi:weather-snowy", "snowy-rainy": "mdi:weather-snowy-rainy", sunny: "mdi:weather-sunny",
  windy: "mdi:weather-windy", "windy-variant": "mdi:weather-windy-variant", exceptional: "mdi:alert-circle-outline",
};

// Tesla "T" from Simple Icons (CC0).
const TESLA_LOGO = html`<svg class="logo" viewBox="0 0 24 24" aria-label="Tesla" role="img"><path d="M12 5.362l2.475-3.026s4.245.09 8.471 2.054c-1.082 1.636-3.231 2.438-3.231 2.438-.146-1.439-1.154-1.79-4.354-1.79L12 24 8.619 5.034c-3.18 0-4.188.354-4.335 1.792 0 0-2.146-.795-3.229-2.43C5.28 2.431 9.525 2.34 9.525 2.34L12 5.362l-.004.002H12v-.002zm0-3.899c3.415-.03 7.326.528 11.328 2.28.535-.968.672-1.395.672-1.395C19.625.612 15.528.015 12 0 8.472.015 4.375.61 0 2.349c0 0 .195.525.672 1.396C4.674 1.989 8.585 1.435 12 1.46v.003z"/></svg>`;

const num = (v, d = 0) => (isNaN(parseFloat(v)) ? "–" : parseFloat(v).toFixed(d).replace(".", ","));
const slug = (r) => r.id ?? r.name.toLowerCase().replace(/[^a-z0-9]+/g, "-");
// Config lists accept "entity.id" or {entity, name, ...}.
const item = (x) => (typeof x === "string" ? { entity: x } : x);

class HomePanel extends LitElement {
  static properties = {
    hass: { attribute: false },
    _tab: { state: true },
    _room: { state: true },
    _expanded: { state: true },
    _player: { state: true },
    _forecast: { state: true },
    _prices: { state: true },
    _now: { state: true },
  };

  setConfig(config) {
    if (!config.rooms?.length) throw new Error("home-panel: rooms is required");
    this._config = config;
    this._tab = config.rooms[0].group;
    this._expanded = new Set();
    this._now = new Date();
  }

  getCardSize() {
    return 20;
  }

  connectedCallback() {
    super.connectedCallback();
    this._clock = setInterval(() => (this._now = new Date()), 10_000);
    window.addEventListener("popstate", this._syncRoom);
    this._syncRoom();
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    clearInterval(this._clock);
    window.removeEventListener("popstate", this._syncRoom);
    this._unsubForecast?.then((unsub) => unsub());
    this._unsubForecast = undefined;
  }

  updated() {
    if (!this.hass) return;
    const c = this._config;
    if (!this._unsubForecast && c.weather) {
      this._unsubForecast = this.hass.connection.subscribeMessage((ev) => (this._forecast = ev.forecast), {
        type: "weather/subscribe_forecast",
        forecast_type: "daily",
        entity_id: c.weather,
      });
    }
    this._loadPrices();
  }

  // Nord Pool prices for today, and for tomorrow when they are published.
  async _loadPrices() {
    const e = this._config.energy;
    const today = this._now.toLocaleDateString("sv-SE");
    const tomorrowReady = this._s(e?.tomorrow_available)?.state === "on";
    const key = `${today}/${tomorrowReady}`;
    if (!e?.nordpool_entry || this._pricesKey === key) return;
    this._pricesKey = key;
    const get = async (date) => {
      try {
        const { response } = await this.hass.callService("nordpool", "get_prices_for_date", { config_entry: e.nordpool_entry, date }, undefined, false, true);
        return Object.values(response)[0] ?? [];
      } catch (err) {
        console.warn(`home-panel: no Nord Pool prices for ${date}`, err);
        return [];
      }
    };
    const next = new Date(this._now.getTime() + 864e5).toLocaleDateString("sv-SE");
    this._prices = { today: await get(today), tomorrow: tomorrowReady ? await get(next) : [] };
  }

  // The open room lives in the URL hash, so the back gesture closes it.
  // "#el" is the electricity page, any other hash is a room.
  _syncRoom = () => {
    const hash = decodeURIComponent(location.hash.slice(1));
    this._room = hash === "el" ? "el" : this._config?.rooms.find((r) => slug(r) === hash);
  };

  _openPage(hash) {
    history.pushState({ homePanel: true }, "", `#${hash}`);
    this._syncRoom();
    this.scrollIntoView({ block: "start" });
  }

  _closeRoom() {
    if (history.state?.homePanel) history.back();
    else {
      history.replaceState(null, "", location.pathname + location.search);
      this._syncRoom();
    }
  }

  _s(id) {
    return this.hass.states[id];
  }

  _state(id) {
    const s = this._s(id);
    if (!s) return "–";
    return s.state === "unavailable" ? "Ej tillgänglig" : this.hass.formatEntityState(s);
  }

  _na(id) {
    return this._s(id)?.state === "unavailable" ? "na" : "";
  }

  _moreInfo(entityId) {
    this.dispatchEvent(new CustomEvent("hass-more-info", { detail: { entityId }, bubbles: true, composed: true }));
  }

  _call(service, data = {}) {
    const [domain, name] = service.split(".");
    return this.hass.callService(domain, name, data);
  }

  _tap(item) {
    if (item.service) {
      if (item.confirm && !confirm(item.confirm)) return;
      this._call(item.service, item.data);
    } else if (item.toggle) {
      this._call("homeassistant.toggle", { entity_id: item.entity });
    } else {
      this._moreInfo(item.entity);
    }
  }

  _name(id, room) {
    const n = this._s(id)?.attributes.friendly_name ?? id;
    return room && n.toLowerCase().startsWith(room.name.toLowerCase() + " ") ? n.slice(room.name.length + 1) : n;
  }

  _isActive(id) {
    const s = this._s(id);
    if (!s) return false;
    if (ACTIVE.includes(s.state)) return true;
    return id.startsWith("sensor.") && parseFloat(s.state) > 0;
  }

  // Header

  _header() {
    const c = this._config;
    const h = this._now.getHours();
    const greeting = h < 5 ? "God natt" : h < 10 ? "God morgon" : h < 12 ? "God förmiddag" : h < 18 ? "God eftermiddag" : "God kväll";
    const w = this._s(c.weather);
    const alerts = (c.alerts ?? []).map((id) => this._s(id)).filter((s) => s && ALERT.includes(s.state));
    // A smoke detector that is offline cannot report fire.
    const offline = (c.offline_alerts ?? []).map((id) => this._s(id)).filter((s) => s && OFFLINE.includes(s.state));
    const first = alerts[0] ?? offline[0];
    const status = alerts.length
      ? `${alerts[0].attributes.friendly_name}${alerts.length > 1 ? ` +${alerts.length - 1}` : ""}`
      : offline.length
        ? offline.length === 1 ? "Brandvarnare offline" : `${offline.length} brandvarnare offline`
        : "Allt är normalt";
    return html`
      <header>
        <div class="hello">
          <h1>${greeting}, ${this.hass.user?.name?.split(" ")[0] ?? ""}</h1>
          <p>${this._now.toLocaleDateString("sv-SE", { weekday: "long", day: "numeric", month: "long" })}</p>
        </div>
        <div class="pills">
          <button class="pill people" @click=${() => this._moreInfo(c.people[0])}>
            ${c.people.map((id) => {
              const p = this._s(id);
              const home = p?.state === "home";
              return p?.attributes.entity_picture
                ? html`<img class=${home ? "" : "away"} src=${p.attributes.entity_picture} title=${p.attributes.friendly_name} />`
                : html`<span class="avatar ${home ? "" : "away"}">${p?.attributes.friendly_name?.[0] ?? "?"}</span>`;
            })}
          </button>
          ${w
            ? html`<button class="pill" @click=${() => this._moreInfo(c.weather)}>
                <ha-icon class="sun" .icon=${WEATHER_ICONS[w.state] ?? "mdi:weather-cloudy"}></ha-icon>
                <b>${num(this._s(c.outside)?.state ?? w.attributes.temperature)}°</b>
                <span class="dim">${this._state(c.weather)}</span>
              </button>`
            : nothing}
          <button class="pill" @click=${() => first && this._moreInfo(first.entity_id)}>
            <span class="dot ${alerts.length ? "bad" : offline.length ? "warn" : ""}"></span>
            ${status}
          </button>
          <div class="clock">${this._now.toLocaleTimeString("sv-SE", { hour: "2-digit", minute: "2-digit" })}</div>
        </div>
      </header>
    `;
  }

  // Energy

  // Daily average in kr/kWh, from today's prices (SEK/MWh).
  _avg(prices) {
    return prices?.length ? prices.reduce((a, x) => a + x.price, 0) / prices.length / 1000 : NaN;
  }

  // Cheapest third of today's prices is "cheap", most expensive third is "expensive".
  _priceLevel() {
    const e = this._config.energy;
    const price = parseFloat(this._s(e.price)?.state);
    const prices = this._prices?.today ?? [];
    const now = this._now.getTime();
    const cur = prices.find((x) => new Date(x.start).getTime() <= now && now < new Date(x.end).getTime());
    const rank = cur ? prices.filter((x) => x.price < cur.price).length / prices.length : NaN;
    const level = isNaN(rank) ? "" : rank < 1 / 3 ? "cheap" : rank >= 2 / 3 ? "expensive" : "normal";
    return { price, level, text: { cheap: "Billigt nu", normal: "Normalpris nu", expensive: "Dyrt nu" }[level] ?? "" };
  }

  _energySummary() {
    const { price, level, text } = this._priceLevel();
    return html`
      <section class="card" style="order:3">
        <button class="summary" @click=${() => this._openPage("el")}>
          <div class="head"><h2>El</h2><span class="tag ${level}">${text} <ha-icon class="chev" icon="mdi:chevron-right"></ha-icon></span></div>
          <b class="temp ${level}">${num(price, 2)}<sup>kr/kWh</sup></b>
          ${this._chart(this._prices?.today)}
        </button>
      </section>
    `;
  }

  _statButtons(list) {
    return html`<div class="stats">
      ${list.map(item).map(
        (t) => html`<button class="stat ${this._na(t.entity)}" @click=${() => this._moreInfo(t.entity)}>
          <small>${t.name ?? this._name(t.entity)}</small>
          <b>${t.decimals === undefined || this._na(t.entity) ? this._state(t.entity) : html`${num(this._s(t.entity)?.state, t.decimals)}<i>${this._s(t.entity)?.attributes.unit_of_measurement ?? ""}</i>`}</b>
        </button>`
      )}
    </div>`;
  }

  _energyPage() {
    const e = this._config.energy;
    const { price, level, text } = this._priceLevel();
    const consumers = (e.consumers ?? []).map(item).filter((c) => this._s(c.entity));
    const watts = consumers.map((c) => parseFloat(this._s(c.entity).state) || 0);
    const maxW = Math.max(1, ...watts);
    return html`
      <div class="wrap page">
        <header class="room-head">
          <button class="back" aria-label="Tillbaka" @click=${() => this._closeRoom()}><ha-icon icon="mdi:chevron-left"></ha-icon></button>
          <span class="ico on"><ha-icon icon="mdi:flash"></ha-icon></span>
          <div class="hello"><h1>El</h1><p>${text || "Spotpris SE3"}</p></div>
        </header>
        <div class="room-grid">
          <section class="card">
            <div class="head"><h2>Pris idag</h2><span class="tag ${level}">${text}</span></div>
            <button class="price" @click=${() => this._moreInfo(e.price)}>
              <div class="ring ${level}">
                <ha-icon icon="mdi:flash"></ha-icon>
                <b>${num(price, 2)}</b>
                <small>kr/kWh</small>
              </div>
            </button>
            ${this._chart(this._prices?.today)}
            ${this._statButtons([
              { name: "Lägst", entity: e.low, decimals: 2 },
              { name: "Högst", entity: e.high, decimals: 2 },
              { name: "Nästa", entity: e.next, decimals: 2 },
            ])}
            <div class="stats"><div class="stat"><small>Snitt idag</small><b>${num(this._avg(this._prices?.today), 2)}</b></div></div>
          </section>
          <section class="card">
            <div class="head"><h2>Pris imorgon</h2></div>
            ${this._prices?.tomorrow?.length
              ? html`${this._chart(this._prices.tomorrow)}
                  <div class="stats">
                    ${[
                      ["Lägst", Math.min(...this._prices.tomorrow.map((x) => x.price))],
                      ["Snitt", this._avg(this._prices.tomorrow) * 1000],
                      ["Högst", Math.max(...this._prices.tomorrow.map((x) => x.price))],
                    ].map(([label, v]) => html`<div class="stat"><small>${label}</small><b>${num(v / 1000, 2)}</b></div>`)}
                  </div>`
              : html`<p class="dim">Nord Pool publicerar morgondagens priser runt kl. 13.</p>`}
          </section>
          ${e.heatpump?.length ? html`<section class="card"><div class="head"><h2>Värmepump</h2></div>${this._statButtons(e.heatpump)}</section>` : nothing}
          ${consumers.length
            ? html`<section class="card">
                <div class="head"><h2>Mätta enheter</h2><span class="dim">just nu</span></div>
                <div class="consumers">
                  ${consumers.map(
                    (c, n) => html`<button class="consumer" @click=${() => this._moreInfo(c.entity)}>
                      <span><b>${c.name ?? this._name(c.entity)}</b><small>${num(watts[n])} W</small></span>
                      <span class="bar"><span style="width:${(watts[n] / maxW) * 100}%"></span></span>
                    </button>`
                  )}
                </div>
              </section>`
            : nothing}
          ${e.stats?.length ? html`<section class="card"><div class="head"><h2>Kostnad</h2></div>${this._statButtons(e.stats)}</section>` : nothing}
          ${this._charger(true)} ${this._car()}
        </div>
      </div>
    `;
  }

  // Bars for one day of Nord Pool prices (SEK/MWh), the current period highlighted.
  _chart(p) {
    if (!p?.length) return nothing;
    const max = Math.max(...p.map((x) => x.price));
    const now = this._now.getTime();
    return html`
      <div class="chart">
        ${p.map((x, i) => {
          const cur = new Date(x.start).getTime() <= now && now < new Date(x.end).getTime();
          const past = new Date(x.end).getTime() <= now;
          return html`<span class="${cur ? "cur" : past ? "past" : ""}" style="height:${Math.max(4, (x.price / max) * 100)}%;--n:${i}"></span>`;
        })}
      </div>
      <div class="axis"><span>00</span><span>06</span><span>12</span><span>18</span><span>24</span></div>
    `;
  }

  // Quick actions

  _quick() {
    return html`
      <section class="card" style="order:1">
        <div class="head"><h2>Snabbval</h2></div>
        <div class="tiles">
          ${this._config.quick.map((q) => this._tile(q))}
        </div>
      </section>
    `;
  }

  // {state} or {attribute} in a label is replaced by its value.
  _tile(q, room) {
    const s = this._s(q.entity);
    if (!s) return nothing;
    const label = q.label?.replace(/\{(\w+)\}/g, (_, k) => (k === "state" ? s.state : (s.attributes[k] ?? "–")));
    return html`<button class="tile ${this._isActive(q.entity) ? "on" : ""} ${this._na(q.entity)}" style="--c:${q.color ?? "#facc15"}" @click=${() => this._tap(q)} @contextmenu=${(ev) => (ev.preventDefault(), this._moreInfo(q.entity))}>
      <span class="ico"><ha-icon .icon=${q.icon ?? s.attributes.icon}></ha-icon></span>
      <b>${q.name ?? this._name(q.entity, room)}</b>
      <small>${label ?? this._state(q.entity)}</small>
    </button>`;
  }

  // Rooms

  _roomStatus(r) {
    const temp = r.temp && this._s(r.temp) ? `${num(this._s(r.temp).state)}°` : "";
    if (!r.light) return [temp, this._state(r.status)].filter(Boolean).join(" · ");
    if (this._na(r.light)) return [temp, "Ej tillgänglig"].filter(Boolean).join(" · ");
    const n = this._lightsOn(r);
    return [temp, n ? `${n} ${n === 1 ? "lampa" : "lampor"} tända` : "Släckt"].filter(Boolean).join(" · ");
  }

  // Counts the lights that the room page lists.
  _lightsOn(r) {
    if (!r.lights?.length) return this._s(r.light)?.state === "on" ? 1 : 0;
    return r.lights
      .map(item)
      .flatMap((l) => (l.members ? l.members.map(item) : [l]))
      .filter((l) => this._s(l.entity)?.state === "on").length;
  }

  _rooms() {
    const rooms = this._config.rooms;
    const groups = [...new Set(rooms.map((r) => r.group))];
    const lit = rooms.filter((r) => this._s(r.light)?.state === "on").length;
    return html`
      <section class="card" style="order:2">
        <div class="head"><h2>Rum</h2><span class="dim">${lit} rum tända</span></div>
        <div class="tabs">
          ${groups.map((g) => {
            const n = rooms.filter((r) => r.group === g && this._s(r.light)?.state === "on").length;
            return html`<button class=${g === this._tab ? "sel" : ""} @click=${() => (this._tab = g)}>${g}${n ? html`<span class="count">${n}</span>` : nothing}</button>`;
          })}
        </div>
        <div class="rooms">
          ${rooms
            .filter((r) => r.group === this._tab)
            .map((r) => {
              const on = this._s(r.light)?.state === "on";
              return html`<div class="room ${on ? "on" : ""}">
                <button class="room-main" @click=${() => this._openPage(slug(r))}>
                  <span class="ico"><ha-icon .icon=${r.icon}></ha-icon></span>
                  <span><b>${r.name}</b><small>${this._roomStatus(r)}</small></span>
                </button>
                ${r.light ? this._bulb(r) : html`<ha-icon class="chev" icon="mdi:chevron-right"></ha-icon>`}
              </div>`;
            })}
        </div>
      </section>
    `;
  }

  _bulb(r) {
    const on = this._s(r.light)?.state === "on";
    return html`<button class="bulb" aria-label="Tänd eller släck ${r.name}" @click=${() => this._call("light.toggle", { entity_id: r.light })}>
      <ha-icon .icon=${on ? "mdi:lightbulb-on" : "mdi:lightbulb-outline"}></ha-icon>
    </button>`;
  }

  // A row with "members" is a group. Its chevron opens the single lights.
  _lightRow({ entity: id, name: label, members }, room) {
    const s = this._s(id);
    if (!s) return nothing;
    const on = s.state === "on";
    const pct = on ? Math.round((s.attributes.brightness ?? 255) / 2.55) : 0;
    const rgb = s.attributes.rgb_color;
    const dimmable = (s.attributes.supported_color_modes ?? []).some((m) => m !== "onoff");
    const name = label ?? this._name(id, room);
    const na = s.state === "unavailable";
    return html`<div class="light ${on ? "on" : ""} ${na ? "na" : ""}" style="--c:${on && rgb ? `rgb(${rgb.join(",")})` : "var(--amber)"};--p:${pct}%">
      <button class="ico" aria-label="Tänd eller släck ${name}" @click=${() => this._call("light.toggle", { entity_id: id })}>
        <ha-icon .icon=${s.attributes.icon ?? (on ? "mdi:lightbulb-on" : "mdi:lightbulb-outline")}></ha-icon>
      </button>
      <button class="lname" @click=${() => this._moreInfo(id)}><b>${name}</b><small>${na ? "Ej tillgänglig" : on ? (dimmable ? `${pct} %` : "Tänd") : "Släckt"}</small></button>
      ${members
        ? html`<button class="expand ${this._expanded.has(id) ? "open" : ""}" aria-label="Visa lampor i ${name}" aria-expanded=${this._expanded.has(id) ? "true" : "false"}
            @click=${() => {
              const next = new Set(this._expanded);
              next.has(id) ? next.delete(id) : next.add(id);
              this._expanded = next;
            }}><ha-icon icon="mdi:chevron-down"></ha-icon></button>`
        : nothing}
      ${dimmable && !na
        ? html`<input type="range" min="1" max="100" aria-label="Ljusstyrka ${name}" .value=${String(pct || 1)}
            @input=${(ev) => ev.target.parentElement.style.setProperty("--p", `${ev.target.value}%`)}
            @change=${(ev) => this._call("light.turn_on", { entity_id: id, brightness_pct: Number(ev.target.value) })} />`
        : nothing}
    </div>`;
  }

  _mediaRow(id, room) {
    const m = this._s(id);
    if (!m) return nothing;
    const playing = m.state === "playing";
    const vol = m.attributes.volume_level;
    return html`<div class="media ${this._na(id)}" style="--c:#a78bfa;--p:${Math.round((vol ?? 0) * 100)}%">
      <button class="art" style=${m.attributes.entity_picture ? `background-image:url(${m.attributes.entity_picture})` : ""} @click=${() => this._moreInfo(id)}>
        ${m.attributes.entity_picture ? nothing : html`<ha-icon icon="mdi:speaker"></ha-icon>`}
      </button>
      <button class="lname" @click=${() => this._moreInfo(id)}>
        <b>${m.attributes.media_title ?? this._name(id, room)}</b>
        <small>${m.attributes.media_artist ?? this._state(id)}</small>
      </button>
      <div class="controls">
        <button @click=${() => this._call("media_player.media_play_pause", { entity_id: id })}><ha-icon .icon=${playing ? "mdi:pause" : "mdi:play"}></ha-icon></button>
        <button @click=${() => this._call("media_player.media_next_track", { entity_id: id })}><ha-icon icon="mdi:skip-next"></ha-icon></button>
      </div>
      ${vol !== undefined
        ? html`<input type="range" min="0" max="100" aria-label="Volym" .value=${String(Math.round(vol * 100))}
            @input=${(ev) => ev.target.parentElement.style.setProperty("--p", `${ev.target.value}%`)}
            @change=${(ev) => this._call("media_player.volume_set", { entity_id: id, volume_level: Number(ev.target.value) / 100 })} />`
        : nothing}
    </div>`;
  }

  // Night mode: one switch for every Adaptive Lighting sleep-mode switch of
  // the room. It shows on when any of them is on.
  _sleep(r) {
    const ids = [r.sleep].flat();
    const on = ids.some((id) => this._s(id)?.state === "on");
    return html`<button class="sleep ${on ? "on" : ""}" role="switch" aria-checked=${on ? "true" : "false"}
      @click=${() => this._call(on ? "switch.turn_off" : "switch.turn_on", { entity_id: ids })}>
      <ha-icon icon="mdi:weather-night"></ha-icon>
      <span><b>Nattläge</b><small>${on ? "På · dämpat, varmt ljus" : "Av"}</small></span>
      <span class="knob"></span>
    </button>`;
  }

  _roomPage(r) {
    const lights = r.lights ?? [];
    const on = this._s(r.light)?.state === "on";
    const cam = this._s(r.camera);
    return html`
      <div class="wrap page">
        <header class="room-head">
          <button class="back" aria-label="Tillbaka" @click=${() => this._closeRoom()}><ha-icon icon="mdi:chevron-left"></ha-icon></button>
          <span class="ico ${on ? "on" : ""}"><ha-icon .icon=${r.icon}></ha-icon></span>
          <div class="hello"><h1>${r.name}</h1><p>${this._roomStatus(r)}</p></div>
          ${r.light ? html`<div class="room ${on ? "on" : ""}">${this._bulb(r)}</div>` : nothing}
        </header>
        ${r.sleep ? this._sleep(r) : nothing}
        <div class="room-grid">
          ${lights.length || r.scenes?.length
            ? html`<section class="card">
                <div class="head"><h2>Belysning</h2></div>
                <div class="lights">
                  ${r.light && lights.length > 1 ? this._lightRow({ entity: r.light, name: "Alla" }, r) : nothing}
                  ${lights.map(item).map(
                    (l) => html`${this._lightRow(l, r)}
                    ${l.members && this._expanded.has(l.entity) ? html`<div class="members">${l.members.map((m) => this._lightRow(item(m), r))}</div>` : nothing}`
                  )}
                </div>
                ${r.scenes?.length
                  ? html`<div class="scenes">
                      ${r.scenes.map(item).map(
                        (sc) => html`<button class="chip" @click=${() => this._call("scene.turn_on", { entity_id: sc.entity })}>
                          <ha-icon icon="mdi:palette"></ha-icon> ${sc.name ?? this._name(sc.entity, r)}
                        </button>`
                      )}
                    </div>`
                  : nothing}
              </section>`
            : nothing}
          ${r.devices?.length
            ? html`<section class="card"><div class="head"><h2>Enheter</h2></div><div class="tiles">${r.devices.map(item).map((d) => this._tile(d, r))}</div></section>`
            : nothing}
          ${r.sensors?.length
            ? html`<section class="card">
                <div class="head"><h2>Sensorer</h2></div>
                <div class="stats">
                  ${r.sensors.map(item).map(
                    (t) => html`<button class="stat ${ALERT.includes(this._s(t.entity)?.state) && t.entity.startsWith("binary_sensor.") ? "warn" : ""}" @click=${() => this._moreInfo(t.entity)}>
                      <small>${t.name ?? this._name(t.entity, r)}</small><b>${this._state(t.entity)}</b>
                    </button>`
                  )}
                </div>
              </section>`
            : nothing}
          ${r.media?.length ? html`<section class="card"><div class="head"><h2>Media</h2></div>${r.media.map((x) => this._mediaRow(item(x).entity, r))}</section>` : nothing}
          ${cam
            ? html`<section class="card">
                <div class="head"><h2>Kamera</h2></div>
                <img class="cam" alt=${this._name(r.camera)} src="/api/camera_proxy/${r.camera}?token=${cam.attributes.access_token}" @click=${() => this._moreInfo(r.camera)} />
              </section>`
            : nothing}
        </div>
      </div>
    `;
  }

  // Weather

  _weather() {
    const id = this._config.weather;
    const w = this._s(id);
    if (!w) return nothing;
    const today = this._forecast?.[0];
    const sunset = this._s("sun.sun")?.attributes.next_setting;
    return html`
      <section class="card" style="order:4">
        <div class="head">
          <h2>Väder</h2>
          ${sunset ? html`<span class="chip">Solnedgång ${new Date(sunset).toLocaleTimeString("sv-SE", { hour: "2-digit", minute: "2-digit" })}</span>` : nothing}
        </div>
        <button class="now" @click=${() => this._moreInfo(id)}>
          <ha-icon class="big sun" .icon=${WEATHER_ICONS[w.state] ?? "mdi:weather-cloudy"}></ha-icon>
          <div>
            <b class="temp">${num(this._s(this._config.outside)?.state ?? w.attributes.temperature)}<sup>°</sup></b>
            <div>${this._state(id)}</div>
            ${today ? html`<small class="dim">Max ${num(today.temperature)}° · Min ${num(today.templow)}°</small><br />` : nothing}
            <small class="dim">Luftfuktighet ${num(w.attributes.humidity)} % · vind ${num(w.attributes.wind_speed)} ${w.attributes.wind_speed_unit ?? ""}</small>
          </div>
        </button>
        <div class="days">
          ${(this._forecast ?? []).slice(0, 5).map(
            (d, i) => html`<div class="day">
              <small>${i === 0 ? "Idag" : new Date(d.datetime).toLocaleDateString("sv-SE", { weekday: "short" })}</small>
              <ha-icon class="sun" .icon=${WEATHER_ICONS[d.condition] ?? "mdi:weather-cloudy"}></ha-icon>
              <b>${num(d.temperature)}°</b>
              <small class="dim">${num(d.templow)}°</small>
              ${d.precipitation ? html`<small class="rain">${num(d.precipitation, 1)} mm</small>` : nothing}
            </div>`
          )}
        </div>
      </section>
    `;
  }

  // Charger

  _charger(details = false) {
    const ch = this._config.charger;
    if (!ch) return nothing;
    const kw = (parseFloat(this._s(ch.power)?.state) || 0) / 1000;
    return html`
      <section class="card" style="order:5">
        <div class="head"><h2>${ch.name ?? "Laddbox"}</h2><span class="dim">${this._state(ch.status)}</span></div>
        <button class="ev" @click=${() => this._moreInfo(ch.status)}>
          <b class="temp">${num(kw, 1)}<sup>kW</sup></b>
          <div class="dim">${num(this._s(ch.session)?.state, 1)} kWh denna laddning</div>
          <div class="bar ${kw > 0 ? "charging" : ""}"><span style="width:${Math.min(100, (kw / (ch.max_kw ?? 11)) * 100)}%"></span></div>
        </button>
        ${this._statButtons(ch.stats ?? [])}
        ${details && ch.details ? this._statButtons(ch.details) : nothing}
      </section>
    `;
  }

  // Car

  _car() {
    const c = this._config.car;
    if (!c || !this._s(c.battery)) return nothing;
    const pct = parseFloat(this._s(c.battery).state);
    const limit = parseFloat(this._s(c.limit)?.state);
    const charging = this._s(c.charging)?.state === "charging";
    const locked = this._s(c.lock)?.state === "locked";
    const climateOn = this._s(c.climate) && this._s(c.climate).state !== "off";
    return html`
      <section class="card car" style="order:5">
        <div class="head"><h2>${c.name}</h2><span class="dim">${charging ? `Laddar · ${this._state(c.power)}` : this._state(c.location)}</span></div>
        <button class="ev" @click=${() => this._moreInfo(c.battery)}>
          <div class="car-top">
            <b class="temp">${num(pct)}<sup>%</sup></b>
            ${TESLA_LOGO}
          </div>
          <div class="dim">${num(this._s(c.range)?.state)} km räckvidd</div>
          <div class="bar ${charging ? "charging" : ""}">
            <span style="width:${pct || 0}%"></span>
            ${limit ? html`<i class="limit" style="left:${limit}%"></i>` : nothing}
          </div>
        </button>
        <div class="scenes">
          <button class="chip ${locked ? "ok" : "bad"}" @click=${() => this._moreInfo(c.lock)}>
            <ha-icon .icon=${locked ? "mdi:lock" : "mdi:lock-open-variant"}></ha-icon> ${locked ? "Låst" : "Olåst"}
          </button>
          ${limit ? html`<button class="chip" @click=${() => this._moreInfo(c.limit)}><ha-icon icon="mdi:battery-charging-80"></ha-icon> Gräns ${num(limit)} %</button>` : nothing}
          ${this._s(c.climate)
            ? html`<button class="chip ${climateOn ? "ok" : ""}" @click=${() => this._moreInfo(c.climate)}>
                <ha-icon icon="mdi:fan"></ha-icon> ${climateOn ? "Klimat på" : "Klimat av"} · ${num(this._s(c.inside)?.state)}°
              </button>`
            : nothing}
        </div>
      </section>
    `;
  }

  // Music

  _music() {
    const players = this._config.media ?? [];
    if (!players.length) return nothing;
    const id = this._player ?? players.find((p) => this._s(p)?.state === "playing") ?? players[0];
    const m = this._s(id);
    const playing = m?.state === "playing";
    const art = m?.attributes.entity_picture;
    return html`
      <section class="card music" style="order:6">
        <div class="head"><h2>Musik</h2></div>
        <div class="player">
          <div class="disc ${playing ? "spin" : ""}" style=${art ? `background-image:url(${art})` : ""}>
            ${art ? nothing : html`<ha-icon icon="mdi:music-note"></ha-icon>`}
          </div>
          <div class="meta">
            <b>${m?.attributes.media_title ?? "Inget spelas"}</b>
            <small class="dim">${m?.attributes.media_artist ?? this._state(id)}</small>
            <div class="sources">
              ${players.map(
                (p) => html`<button class="chip ${p === id ? "sel" : ""}" @click=${() => (this._player = p)}>${this._s(p)?.attributes.friendly_name ?? p}</button>`
              )}
            </div>
            <div class="controls">
              <button @click=${() => this._call("media_player.media_previous_track", { entity_id: id })}><ha-icon icon="mdi:skip-previous"></ha-icon></button>
              <button class="play" @click=${() => this._call("media_player.media_play_pause", { entity_id: id })}><ha-icon .icon=${playing ? "mdi:pause" : "mdi:play"}></ha-icon></button>
              <button @click=${() => this._call("media_player.media_next_track", { entity_id: id })}><ha-icon icon="mdi:skip-next"></ha-icon></button>
            </div>
          </div>
        </div>
      </section>
    `;
  }

  render() {
    if (!this.hass || !this._config) return nothing;
    if (this._room === "el") return this._energyPage();
    if (this._room) return this._roomPage(this._room);
    return html`
      <div class="wrap home">
        ${this._header()}
        <div class="grid">
          <div class="col">${this._energySummary()} ${this._charger()} ${this._car()}</div>
          <div class="col">${this._quick()} ${this._rooms()}</div>
          <div class="col">${this._weather()} ${this._music()}</div>
        </div>
      </div>
    `;
  }

  static styles = css`
    :host {
      display: block;
      container-type: inline-size;
      --bg: #0d0f14;
      --panel: rgba(255, 255, 255, 0.035);
      --line: rgba(255, 255, 255, 0.07);
      --tile: rgba(255, 255, 255, 0.05);
      --text: #f4f4f5;
      --dim: #8b8f98;
      --amber: #facc15;
      --green: #22c55e;
      --red: #f87171;
      --blue: #38bdf8;
      font-family: "SF Pro Display", -apple-system, "Inter", "Segoe UI", Roboto, sans-serif;
      color: var(--text);
    }
    * { box-sizing: border-box; }
    button { font: inherit; color: inherit; background: none; border: 0; padding: 0; cursor: pointer; text-align: left; -webkit-tap-highlight-color: transparent; }
    ha-icon { --mdc-icon-size: 22px; }
    .wrap {
      min-height: 100vh;
      padding: 20px 14px 40px;
      background:
        radial-gradient(60% 40% at 0% 0%, rgba(250, 204, 21, 0.13), transparent 70%),
        radial-gradient(50% 40% at 100% 100%, rgba(34, 197, 94, 0.1), transparent 70%),
        var(--bg);
    }
    .dim { color: var(--dim); }
    small { font-size: 13px; }

    /* Header */
    header { display: flex; flex-direction: column; gap: 14px; margin-bottom: 18px; }
    h1 { margin: 0; font-size: 30px; font-weight: 800; letter-spacing: -0.02em; line-height: 1.1; }
    .hello p { margin: 4px 0 0; color: var(--dim); font-size: 15px; }
    .pills { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
    .pill { display: flex; align-items: center; gap: 8px; height: 44px; padding: 0 16px; border-radius: 16px; background: var(--panel); border: 1px solid var(--line); font-size: 15px; white-space: nowrap; }
    .pill b { font-size: 18px; }
    .people { padding: 0 8px; }
    .people img, .avatar { width: 30px; height: 30px; border-radius: 50%; object-fit: cover; margin-left: -10px; border: 2px solid var(--bg); display: grid; place-items: center; font-weight: 700; font-size: 13px; background: #f97316; }
    .people :first-child { margin-left: 0; }
    .away { filter: grayscale(1); opacity: 0.45; }
    .sun { color: var(--amber); }
    .dot { width: 10px; height: 10px; border-radius: 50%; background: var(--green); box-shadow: 0 0 10px var(--green); }
    .dot.bad { background: var(--red); box-shadow: 0 0 10px var(--red); }
    .dot.warn { background: var(--amber); box-shadow: 0 0 10px var(--amber); }
    .na { opacity: 0.45; }
    .clock { display: none; font-size: 54px; font-weight: 800; letter-spacing: -0.03em; margin-left: 8px; }

    /* Layout: one column on a phone, three columns on a wide screen */
    .grid { display: flex; flex-direction: column; gap: 14px; }
    .col { display: contents; }
    .card { container-type: inline-size; background: var(--panel); border: 1px solid var(--line); border-radius: 28px; padding: 20px; backdrop-filter: blur(20px); }
    .head { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 16px; min-height: 24px; }
    h2 { margin: 0; font-size: 13px; font-weight: 700; letter-spacing: 0.12em; text-transform: uppercase; color: var(--dim); }

    @container (min-width: 900px) {
      .wrap { padding: 28px 28px 40px; }
      header { flex-direction: row; justify-content: space-between; align-items: center; }
      h1 { font-size: 42px; }
      .clock { display: block; }
      .grid { display: grid; grid-template-columns: 1fr 1.25fr 1fr; align-items: start; gap: 22px; }
      .col { display: flex; flex-direction: column; gap: 22px; }
    }

    /* Energy */
    .price { display: grid; place-items: center; width: 100%; margin: 4px 0 18px; }
    .ring { width: 150px; height: 150px; border-radius: 50%; display: grid; place-content: center; justify-items: center; border: 3px solid var(--blue); box-shadow: 0 0 30px rgba(56, 189, 248, 0.35), inset 0 0 30px rgba(56, 189, 248, 0.15); }
    .ring.cheap { border-color: var(--green); box-shadow: 0 0 30px rgba(34, 197, 94, 0.35), inset 0 0 30px rgba(34, 197, 94, 0.15); }
    .ring.expensive { border-color: var(--red); box-shadow: 0 0 30px rgba(248, 113, 113, 0.35), inset 0 0 30px rgba(248, 113, 113, 0.15); }
    .ring b { font-size: 36px; font-weight: 800; letter-spacing: -0.02em; }
    .ring small { color: var(--dim); letter-spacing: 0.08em; }
    .tag { font-size: 14px; font-weight: 600; color: var(--blue); }
    .tag.cheap { color: var(--green); }
    .tag.expensive { color: var(--red); }
    .chart { display: flex; align-items: flex-end; gap: 1px; height: 70px; }
    .chart span { flex: 1; border-radius: 2px 2px 0 0; background: rgba(56, 189, 248, 0.45); }
    .chart span.past { background: rgba(255, 255, 255, 0.1); }
    .chart span.cur { background: var(--amber); box-shadow: 0 0 10px var(--amber); }
    .axis { display: flex; justify-content: space-between; color: var(--dim); font-size: 11px; margin: 6px 0 14px; }
    .stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(105px, 1fr)); gap: 8px; margin-top: 8px; }
    .stat { background: var(--tile); border-radius: 16px; padding: 10px 12px; display: flex; flex-direction: column; gap: 2px; }
    .stat small { color: var(--dim); font-size: 11px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; }
    .stat b { font-size: 20px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .stat i { font-style: normal; font-size: 12px; color: var(--dim); margin-left: 2px; }

    /* Quick actions */
    .tiles { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
    @container (min-width: 520px) { .tiles { grid-template-columns: repeat(4, 1fr); } }
    .tile { background: var(--tile); border: 1.5px solid transparent; border-radius: 22px; padding: 14px; display: flex; flex-direction: column; gap: 2px; transition: border-color 0.2s, background 0.2s; }
    .tile .ico { width: 42px; height: 42px; border-radius: 13px; display: grid; place-items: center; background: rgba(255, 255, 255, 0.06); color: var(--c); margin-bottom: 10px; }
    .tile b { font-size: 16px; }
    .tile small { color: var(--dim); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .tile.on { border-color: color-mix(in srgb, var(--c) 70%, transparent); background: color-mix(in srgb, var(--c) 9%, transparent); }
    .tile.on .ico { background: var(--c); color: #111; box-shadow: 0 0 18px color-mix(in srgb, var(--c) 60%, transparent); }
    .tile.on small { color: var(--c); }

    /* Rooms */
    .tabs { display: flex; background: rgba(255, 255, 255, 0.04); border-radius: 16px; padding: 4px; margin-bottom: 14px; }
    .tabs button { flex: 1; text-align: center; white-space: nowrap; padding: 10px 4px; border-radius: 12px; color: var(--dim); font-weight: 600; font-size: 15px; }
    .tabs button.sel { background: rgba(255, 255, 255, 0.07); color: var(--text); }
    .count { display: inline-grid; place-items: center; width: 20px; height: 20px; margin-left: 6px; border-radius: 50%; background: rgba(250, 204, 21, 0.2); color: var(--amber); font-size: 12px; }
    .rooms { display: grid; grid-template-columns: 1fr; gap: 10px; }
    @container (min-width: 520px) { .rooms { grid-template-columns: 1fr 1fr; } }
    .room { display: flex; align-items: center; gap: 10px; padding: 12px; border-radius: 22px; background: var(--tile); border: 1.5px solid transparent; }
    .room.on { border-color: rgba(250, 204, 21, 0.55); background: linear-gradient(135deg, rgba(250, 204, 21, 0.12), rgba(250, 204, 21, 0.02)); }
    .room-main { flex: 1; display: flex; align-items: center; gap: 12px; min-width: 0; }
    .room-main > span:last-child { display: flex; flex-direction: column; min-width: 0; }
    .room b { font-size: 17px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .room small { color: var(--dim); }
    .room.on small { color: var(--amber); }
    .room .ico { flex: none; width: 44px; height: 44px; border-radius: 14px; display: grid; place-items: center; background: rgba(255, 255, 255, 0.06); color: var(--dim); }
    .room.on .ico { color: var(--amber); background: rgba(250, 204, 21, 0.12); }
    .bulb { flex: none; width: 48px; height: 48px; border-radius: 16px; display: grid; place-items: center; border: 1px solid var(--line); color: var(--dim); }
    .room.on .bulb { background: var(--amber); color: #111; border-color: transparent; box-shadow: 0 0 20px rgba(250, 204, 21, 0.45); }

    /* Weather */
    .now { display: flex; align-items: center; gap: 18px; width: 100%; margin-bottom: 16px; }
    .now > div { flex: 1; }
    .big { --mdc-icon-size: 64px; }
    .temp { font-size: 52px; font-weight: 800; letter-spacing: -0.03em; line-height: 1; }
    .temp sup { font-size: 0.4em; font-weight: 600; margin-left: 2px; }
    .chip { padding: 8px 12px; border-radius: 12px; background: var(--tile); font-size: 14px; font-weight: 600; white-space: nowrap; align-self: flex-start; }
    .chip.sel { background: rgba(167, 139, 250, 0.18); color: #c4b5fd; }
    .days { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; }
    .day { display: flex; flex-direction: column; align-items: center; gap: 4px; padding: 10px 4px; border-radius: 16px; background: var(--tile); }
    .day b { font-size: 18px; }
    .rain { color: var(--blue); font-size: 12px; }

    /* Charger */
    .ev { display: block; width: 100%; }
    .bar { height: 10px; border-radius: 5px; background: rgba(255, 255, 255, 0.08); margin: 16px 0 8px; overflow: hidden; }
    .bar span { display: block; height: 100%; border-radius: 5px; background: linear-gradient(90deg, var(--green), #4ade80); box-shadow: 0 0 12px var(--green); }

    /* Music */
    .music { background: linear-gradient(160deg, var(--panel), rgba(34, 197, 94, 0.06)); }
    .player { display: flex; gap: 18px; align-items: center; }
    .disc { flex: none; width: 120px; height: 120px; border-radius: 50%; display: grid; place-items: center; background: radial-gradient(circle, #3b2a6b 0 22%, #15161c 23% 100%); background-size: cover; background-position: center; box-shadow: 0 0 0 6px rgba(255, 255, 255, 0.03), 0 0 0 12px rgba(255, 255, 255, 0.02); color: #c4b5fd; --mdc-icon-size: 30px; }
    @container (max-width: 520px) { .disc { width: 88px; height: 88px; } }
    .disc.spin { animation: spin 8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .meta { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
    .meta b { font-size: 19px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .sources { display: flex; gap: 6px; overflow-x: auto; margin: 6px 0; scrollbar-width: none; }
    .sources .chip { font-size: 12px; padding: 6px 10px; }
    .controls { display: flex; align-items: center; gap: 10px; }
    .controls button { width: 44px; height: 44px; border-radius: 50%; display: grid; place-items: center; background: var(--tile); }
    .controls .play { width: 56px; height: 56px; background: #a78bfa; color: #111; box-shadow: 0 0 24px rgba(167, 139, 250, 0.5); }

    /* Room page */
    .room-head { flex-direction: row !important; align-items: center; gap: 14px; }
    .room-head .hello { flex: 1; min-width: 0; }
    .room-head h1 { font-size: 30px; }
    .room-head > .ico { flex: none; width: 52px; height: 52px; border-radius: 16px; display: grid; place-items: center; background: var(--tile); color: var(--dim); --mdc-icon-size: 28px; }
    .room-head > .ico.on { color: var(--amber); background: rgba(250, 204, 21, 0.12); }
    .room-head .room { padding: 0; background: none; border: 0; }
    .back { flex: none; width: 44px; height: 44px; border-radius: 14px; display: grid; place-items: center; background: var(--panel); border: 1px solid var(--line); --mdc-icon-size: 28px; }
    .room-grid { display: grid; grid-template-columns: 1fr; gap: 14px; align-items: start; }
    @container (min-width: 900px) { .room-grid { grid-template-columns: 1fr 1fr; gap: 22px; } }
    @container (min-width: 1400px) { .room-grid { grid-template-columns: 1fr 1fr 1fr; } }
    .chev { color: var(--dim); vertical-align: middle; }
    .car-top { display: flex; justify-content: space-between; align-items: center; }
    .logo { width: 52px; height: 52px; fill: #e82127; filter: drop-shadow(0 0 14px rgba(232, 33, 39, 0.45)); }
    .car .bar { position: relative; overflow: visible; }
    .car .bar > span { background: linear-gradient(90deg, var(--blue), #7dd3fc); box-shadow: 0 0 12px var(--blue); }
    .car .bar.charging > span { background: linear-gradient(90deg, var(--green), #4ade80); box-shadow: 0 0 12px var(--green); }
    .car .limit { position: absolute; top: -4px; width: 2px; height: 18px; border-radius: 1px; background: #fff; opacity: 0.7; }
    .chip.ok { background: rgba(34, 197, 94, 0.15); color: #4ade80; }
    .chip.bad { background: rgba(248, 113, 113, 0.15); color: var(--red); }
    .summary { display: block; width: 100%; }
    .summary .temp { display: block; margin-bottom: 14px; color: var(--blue); }
    .summary .temp.cheap { color: var(--green); }
    .summary .temp.expensive { color: var(--red); }
    .summary .temp sup { color: var(--dim); }
    .consumers { display: grid; gap: 12px; }
    .consumer { display: grid; gap: 6px; width: 100%; }
    .consumer > span:first-child { display: flex; justify-content: space-between; }
    .consumer small { color: var(--dim); }
    .consumer .bar { margin: 0; height: 8px; }
    .sleep { display: flex; align-items: center; gap: 12px; width: 100%; margin: -4px 0 16px; padding: 12px 16px; border-radius: 20px; background: var(--panel); border: 1px solid var(--line); color: var(--dim); }
    .sleep > span:first-of-type { flex: 1; display: flex; flex-direction: column; }
    .sleep b { color: var(--text); font-size: 16px; }
    .sleep .knob { width: 50px; height: 30px; border-radius: 15px; background: rgba(255, 255, 255, 0.12); position: relative; transition: background 0.2s; }
    .sleep .knob::after { content: ""; position: absolute; top: 3px; left: 3px; width: 24px; height: 24px; border-radius: 50%; background: #fff; transition: transform 0.2s; }
    .sleep.on { border-color: rgba(129, 140, 248, 0.5); background: rgba(129, 140, 248, 0.1); color: #a5b4fc; }
    .sleep.on .knob { background: #818cf8; }
    .sleep.on .knob::after { transform: translateX(20px); }
    @container (min-width: 900px) { .sleep { width: auto; max-width: 420px; } }
    .lights { display: grid; gap: 10px; }
    .light, .media { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 4px 12px; padding: 12px; border-radius: 20px; background: var(--tile); border: 1.5px solid transparent; }
    .light.on { border-color: color-mix(in srgb, var(--c) 50%, transparent); background: color-mix(in srgb, var(--c) 7%, transparent); }
    .light .ico { width: 44px; height: 44px; border-radius: 14px; display: grid; place-items: center; background: rgba(255, 255, 255, 0.06); color: var(--dim); }
    .light.on .ico { background: var(--c); color: #111; box-shadow: 0 0 16px color-mix(in srgb, var(--c) 55%, transparent); }
    .lname { display: flex; flex-direction: column; min-width: 0; }
    .expand { width: 40px; height: 40px; border-radius: 12px; display: grid; place-items: center; background: rgba(255, 255, 255, 0.06); color: var(--dim); transition: transform 0.2s; }
    .expand.open { transform: rotate(180deg); }
    .members { display: grid; gap: 8px; margin: -2px 0 4px 22px; padding-left: 12px; border-left: 2px solid var(--line); }
    .lname b { font-size: 16px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .lname small { color: var(--dim); }
    .light.on .lname small { color: var(--c); }
    input[type="range"] { grid-column: 1 / -1; -webkit-appearance: none; appearance: none; width: 100%; height: 34px; margin: 6px 0 0; border-radius: 12px; cursor: pointer;
      background: linear-gradient(90deg, color-mix(in srgb, var(--c) 75%, transparent) var(--p), rgba(255, 255, 255, 0.06) var(--p)); }
    input[type="range"]::-webkit-slider-thumb { -webkit-appearance: none; width: 6px; height: 22px; border-radius: 3px; background: #fff; box-shadow: 0 0 6px rgba(0, 0, 0, 0.5); }
    input[type="range"]::-moz-range-thumb { width: 6px; height: 22px; border: 0; border-radius: 3px; background: #fff; }
    .scenes { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
    .scenes .chip { display: flex; align-items: center; gap: 6px; --mdc-icon-size: 18px; }
    .stat.warn { background: rgba(248, 113, 113, 0.15); color: var(--red); }
    .media { margin-bottom: 10px; }
    .media .art { width: 52px; height: 52px; border-radius: 14px; display: grid; place-items: center; background: rgba(167, 139, 250, 0.15) center / cover; color: #c4b5fd; }
    .media .controls button { width: 40px; height: 40px; }
    .cam { width: 100%; border-radius: 18px; display: block; cursor: pointer; }

    /* Animations */
    @keyframes rise { from { opacity: 0; transform: translateY(14px); } }
    @keyframes slide-in { from { opacity: 0; transform: translateX(28px); } }
    @keyframes fade { from { opacity: 0; } }
    @keyframes pop { 40% { transform: scale(1.15); } }
    @keyframes grow { from { transform: scaleY(0); } }
    @keyframes pulse { 50% { opacity: 0.55; } }
    @keyframes ping { to { transform: scale(2.6); opacity: 0; } }
    @keyframes shimmer { from { transform: translateX(-100%); } to { transform: translateX(250%); } }
    @keyframes unfold { from { opacity: 0; transform: translateY(-8px); } }
    .wrap.home { animation: fade 0.3s ease-out; }
    .wrap.page { animation: slide-in 0.35s cubic-bezier(0.2, 0.8, 0.2, 1); }
    .card { animation: rise 0.5s cubic-bezier(0.2, 0.8, 0.2, 1) both; }
    .col:nth-child(2) .card { animation-delay: 0.06s; }
    .col:nth-child(3) .card { animation-delay: 0.12s; }
    .card + .card { animation-delay: 0.14s; }
    .col:nth-child(2) .card + .card { animation-delay: 0.2s; }
    .col:nth-child(3) .card + .card { animation-delay: 0.26s; }
    .card + .card + .card { animation-delay: 0.3s; }
    button { transition: transform 0.15s ease, background 0.2s, border-color 0.2s, color 0.2s; }
    button:active { transform: scale(0.96); }
    .room.on .bulb, .light.on .ico, .tile.on .ico { animation: pop 0.35s ease-out; }
    .chart span { transform-origin: bottom; animation: grow 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) both; animation-delay: calc(var(--n) * 4ms); }
    .chart span.cur { animation: grow 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) both, pulse 2s ease-in-out 0.8s infinite; }
    .dot { position: relative; }
    .dot.bad::after, .dot.warn::after { content: ""; position: absolute; inset: 0; border-radius: 50%; background: inherit; animation: ping 1.6s ease-out infinite; }
    .bar.charging > span { position: relative; overflow: hidden; }
    .bar.charging > span::after { content: ""; position: absolute; inset: 0; width: 40%; background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.55), transparent); animation: shimmer 1.8s ease-in-out infinite; }
    .members { animation: unfold 0.25s ease-out; }

    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { animation: none !important; transition: none !important; }
    }
    button:focus-visible { outline: 2px solid var(--blue); outline-offset: 2px; }
  `;
}

customElements.define("home-panel", HomePanel);
