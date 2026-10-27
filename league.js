// League table maths, shared by the website (index.html) and the organiser portal (admin.html), so both show the same table.
// matches: a season's matches as { home, away, score: [home, away] or null, won: "home" | "away" (result without a score), stage, live }
//   Only group-stage matches (no stage) count. A live match counts with its score so far.
// cfg: the season's league settings from the organiser portal (seasons.league):
//   { hidden: true, add: ["Team"], remove: ["Team"], adj: { "Team": { p, w, d, l, gf, ga, pts, note } } }
//   "add" puts teams in before they've played, "remove" takes them out, "adj" numbers are added on.
// Order: points (3 a win, 1 a draw), then goal difference, goals scored and name.
window.YP_LEAGUE = {
  KEYS: ["p", "w", "d", "l", "gf", "ga", "pts"],
  table(matches, cfg) {
    cfg = cfg || {};
    const rows = {};
    const row = n => rows[n] = rows[n] || { n, p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, form: [], live: false, adj: null };
    matches.filter(m => !m.stage).forEach(m => {
      row(m.home); row(m.away);
      const sc = m.score;
      if (!sc && !m.won) return;
      [[m.home, 0], [m.away, 1]].forEach(([n, i]) => {
        const r = row(n);
        const o = sc ? (sc[i] > sc[1 - i] ? "w" : sc[i] < sc[1 - i] ? "l" : "d") : (m.won === "home") === (i === 0) ? "w" : "l";
        r.p++; r[o]++; r.form.push(o);
        if (sc) { r.gf += sc[i]; r.ga += sc[1 - i]; }
        if (m.live) r.live = true;
      });
    });
    (cfg.add || []).forEach(row);
    Object.entries(cfg.adj || {}).forEach(([n, a]) => {
      const r = row(n);
      ["p", "w", "d", "l", "gf", "ga"].forEach(k => { r[k] += Number(a[k]) || 0; });
      r.adj = a;
    });
    const removed = new Set(cfg.remove || []);
    const list = Object.values(rows).filter(r => !removed.has(r.n));
    list.forEach(r => { r.pts = r.w * 3 + r.d + (Number((r.adj || {}).pts) || 0); });
    return list.sort((a, b) => b.pts - a.pts || (b.gf - b.ga) - (a.gf - a.ga) || b.gf - a.gf || a.n.localeCompare(b.n));
  },
  // True when a team's numbers were changed by hand
  changed: a => !!a && (window.YP_LEAGUE.KEYS.some(k => Number(a[k])) || !!a.note)
};
