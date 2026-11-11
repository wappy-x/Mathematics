// Support vector machines as a quadratic program -- the check behind the card.
// std only.  Three roads to the widest road between two estates:
// (1) the dual QP solved by SMO, written out; (2) every pair and triple of
// houses that could sit on the kerbs, listed; (3) the KKT certificate.
type P = (f64, f64);
struct Rng { s: u64 }                            // SplitMix64, seed 2026
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn houses(seed: u64) -> (Vec<P>, Vec<f64>) {    // 30 Northfield (+1), then 30 Southgate (-1), in metres
    let (mut r, mut pn, mut ps) = (Rng { s: seed }, vec![], vec![]);
    while pn.len() < 30 || ps.len() < 30 {
        let a = (1000.0 * r.u()).floor() / 10.0; let b = (1000.0 * r.u()).floor() / 10.0;   // to 10 cm
        let d = (3.0 * a + 4.0 * b - 300.0) / 5.0;   // metres from the surveyor's line 3x + 4y = 300
        if d >= 4.0 && pn.len() < 30 { pn.push((a, b)); } else if d <= -4.0 && ps.len() < 30 { ps.push((a, b)); }
    }
    pn.extend(ps);
    (pn, (0..60).map(|m| if m < 30 { 1.0 } else { -1.0 }).collect())
}
fn dot(p: P, q: P) -> f64 { p.0 * q.0 + p.1 * q.1 }
fn tot<I: Iterator<Item = f64>>(v: I) -> f64 { let mut t = 0.0; for a in v { t += a; } t }
fn sci(x: f64) -> String {                       // 1.62e-12, printed the same way in Python
    if x == 0.0 { return "0".to_string(); }
    let e = x.abs().log10().floor(); format!("{:.2}e{}", x / 10f64.powf(e), e as i64)
}
struct Fit { lam: Vec<f64>, w: P, b: f64, k: usize, viol: Vec<f64>, sv: Vec<usize> }
fn smo(x: &[P], y: &[f64], c: f64) -> Fit {      // minimise 1/2 lam'Q lam - sum lam, Q_ij = y_i y_j x_i.x_j
    let n = x.len();
    let kk: Vec<Vec<f64>> = x.iter().map(|&p| x.iter().map(|&q| dot(p, q)).collect()).collect();
    let (mut lam, mut g, mut k, mut viol) = (vec![0.0; n], vec![-1.0; n], 0, vec![]);
    loop {
        assert!(k < 10_000_000, "SMO must stop");   // a broken update fails here instead of looping for ever
        let (mut i, mut j) = (n, n);
        for t in 0..n {
            let s = -y[t] * g[t];
            if ((y[t] > 0.0 && lam[t] < c) || (y[t] < 0.0 && lam[t] > 0.0)) && (i == n || s > -y[i] * g[i]) { i = t; }
            if ((y[t] < 0.0 && lam[t] < c) || (y[t] > 0.0 && lam[t] > 0.0)) && (j == n || s < -y[j] * g[j]) { j = t; }
        }
        let v = -y[i] * g[i] + y[j] * g[j];      // how far the worst pair breaks the KKT conditions
        viol.push(v);
        if v < 1e-9 { break; }                   // stopping test
        let mut t = v / (kk[i][i] + kk[j][j] - 2.0 * kk[i][j]);   // exact step along the pair's line
        t = t.min(if y[i] > 0.0 { c - lam[i] } else { lam[i] }).min(if y[j] > 0.0 { lam[j] } else { c - lam[j] });
        lam[i] += y[i] * t; lam[j] -= y[j] * t;
        for m in 0..n { g[m] += y[m] * t * (kk[m][i] - kk[m][j]); }
        k += 1;
    }
    let w = (tot((0..n).map(|m| lam[m] * y[m] * x[m].0)), tot((0..n).map(|m| lam[m] * y[m] * x[m].1)));
    let sv: Vec<usize> = (0..n).filter(|&m| lam[m] > 1e-8).collect();
    let b = tot(sv.iter().map(|&m| y[m] - dot(w, x[m]))) / sv.len() as f64;
    Fit { lam, w, b, k, viol, sv }
}
fn enumerate_kerbs(x: &[P], y: &[f64]) -> (Option<(P, f64)>, usize, usize) {   // every road with 2 or 3 houses on its kerbs
    let n = x.len();
    let (mut best, mut cands, mut feas): (Option<(P, f64)>, usize, usize) = (None, 0, 0);
    let mut try_road = |w: Option<P>, b: f64| {
        cands += 1;
        let Some(w) = w else { return };
        if (0..n).map(|m| y[m] * (dot(w, x[m]) + b)).fold(f64::INFINITY, f64::min) < 1.0 - 1e-9 { return; }
        feas += 1;
        if best.map_or(true, |(bw, _)| dot(w, w) < dot(bw, bw)) { best = Some((w, b)); }
    };
    for p in 0..n {
        for q in 0..n {
            if y[p] > 0.0 && y[q] < 0.0 {        // one house on each kerb, road square to p - q
                let d = (x[p].0 - x[q].0, x[p].1 - x[q].1); let s = 2.0 / dot(d, d);
                let w = (s * d.0, s * d.1); try_road(Some(w), -dot(w, x[p]) + 1.0);
            }
        }
    }
    for p in 0..n {
        for r in p + 1..n {
            if y[p] != y[r] { continue; }
            let nrm = (x[p].1 - x[r].1, x[r].0 - x[p].0);   // square to the kerb through p and r
            for q in 0..n {
                if y[q] == y[p] { continue; }
                let den = y[p] * (dot(nrm, x[p]) - dot(nrm, x[q]));
                if den.abs() < 1e-12 { try_road(None, 0.0); continue; }   // p, r, q in a line: no road
                let w = (2.0 * nrm.0 / den, 2.0 * nrm.1 / den); try_road(Some(w), y[p] - dot(w, x[p]));
            }
        }
    }
    (best, cands, feas)
}
fn clear(x: &[P], y: &[f64], w: P, b: f64) -> Vec<f64> { (0..x.len()).map(|m| y[m] * (dot(w, x[m]) + b)).collect() }
fn lowest(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::INFINITY, f64::min) }
fn main() {
    let (x, y) = houses(2026); let n = x.len();
    let f = smo(&x, &y, f64::INFINITY); let (lam, w, b) = (&f.lam, f.w, f.b);
    let nw = dot(w, w).sqrt(); let s = clear(&x, &y, w, b);
    println!("houses: 30 Northfield (+1), 30 Southgate (-1), seed 2026");
    println!("road 1, dual by SMO: {} steps from lam = 0, stop when violation < 1e-9", f.k);
    println!("  w = ({:.6}, {:.6})   b = {:.6}   width 2/|w| = {:.4} m", w.0, w.1, b, 2.0 / nw);
    for &m in &f.sv {
        println!("  support vector {:2} at ({:4.1}, {:4.1}), y = {:+}, lam = {:.6}", m, x[m].0, x[m].1, y[m] as i64, lam[m]);
    }
    let sl = tot(lam.iter().cloned());
    println!("  houses with lam > 1e-8: {} of {}; sum of lam = {:.6}, |w|^2 = {:.6}", f.sv.len(), n, sl, nw * nw);
    let mut hist: Vec<f64> = f.viol.iter().step_by(20).cloned().collect(); hist.push(*f.viol.last().unwrap());
    let hs: Vec<String> = hist.iter().map(|v| format!("{:.2}", v.log10())).collect();
    println!("  log10 violation at k = 0, 20, .., 280, {}: {}", f.k, hs.join(" "));
    let (best, cands, feas) = enumerate_kerbs(&x, &y); let (we, be) = best.unwrap();
    let dk = (x[34].0 - x[57].0, x[34].1 - x[57].1); let up = (x[10].0 - x[57].0, x[10].1 - x[57].1);
    let cl = (11.0 * up.0 + 16.0 * up.1) / 377f64.sqrt();   // by hand: the climb from kerb to kerb along (11, 16)
    println!("by hand: kerb 57 to 34 = ({:.1}, {:.1}), 57 to 10 = ({:.1}, {:.1}), sqrt(377) = {:.4}, width {:.4} m, 2/width = {:.6}", dk.0, dk.1, up.0, up.1, 377f64.sqrt(), cl, 2.0 / cl);
    println!("road 2, every kerb pair and triple: {} roads tried, {} clear every house", cands, feas);
    println!("  best: w = ({:.6}, {:.6})   b = {:.6}   width {:.4} m", we.0, we.1, be, 2.0 / dot(we, we).sqrt());
    let (p_val, d_val) = (0.5 * nw * nw, sl - 0.5 * nw * nw);
    println!("road 3, the KKT certificate:");
    println!("  p* = 1/2|w|^2 = {:.9}   d* = q(lam) = {:.9}   |gap| {}", p_val, d_val, sci((p_val - d_val).abs()));
    println!("  smallest y_i(w.x_i + b) - 1 = {}   smallest lam = {}", sci(lowest(&s) - 1.0), sci(lowest(lam)));
    let cs = (0..n).map(|m| lam[m] * (s[m] - 1.0)).fold(f64::NEG_INFINITY, f64::max);
    println!("  |sum lam_i y_i| = {}   largest lam_i(s_i - 1) = {}", sci(tot((0..n).map(|m| lam[m] * y[m])).abs()), sci(cs));
    let l = sl / 2.0;                            // the dual's picture: nearest points of the two hulls
    let side = |sg: f64, c: usize| tot((0..n).filter(|&m| y[m] * sg > 0.0).map(|m| lam[m] * if c == 0 { x[m].0 } else { x[m].1 })) / l;
    let (pn, ps) = ((side(1.0, 0), side(1.0, 1)), (side(-1.0, 0), side(-1.0, 1)));
    let gapd = ((pn.0 - ps.0).powi(2) + (pn.1 - ps.1).powi(2)).sqrt();
    println!("  nearest points of the hulls ({:.2}, {:.2}) and ({:.2}, {:.2}), {:.4} m apart", pn.0, pn.1, ps.0, ps.1, gapd);
    println!("  Southgate's nearest point = {:.4} of house 57 + {:.4} of house 34", lam[57] / l, lam[34] / l);
    println!("  house 13 at ({:.1}, {:.1}): lam = {}, {:.4} m outside the kerb", x[13].0, x[13].1, sci(lam[13]), (s[13] - 1.0) / nw);
    let sc = dot(w, (60.0, 45.0)) + b;
    println!("lost record at (60.0, 45.0): score {:.4}, {:.2} m from the centre line: {}", sc, sc / nw, if sc > 0.0 { "Northfield" } else { "Southgate" });
    println!("what breaks:");
    println!("  width read as 1/|w|: {:.4} m", 1.0 / nw);
    let mean = |r: std::ops::Range<usize>, c: usize| tot(r.map(|m| if c == 0 { x[m].0 } else { x[m].1 })) / 30.0;
    let (cn, cs2) = ((mean(0..30, 0), mean(0..30, 1)), (mean(30..60, 0), mean(30..60, 1)));
    let wa = (cn.0 - cs2.0, cn.1 - cs2.1); let ba = -dot(wa, ((cn.0 + cs2.0) / 2.0, (cn.1 + cs2.1) / 2.0));
    let sa = clear(&x, &y, wa, ba); let wida = 2.0 * lowest(&sa) / dot(wa, wa).sqrt();
    let cut = sa.iter().filter(|&&v| v < 0.0).count();
    println!("  road through the estates' averages: width {:.4} m, {} houses on the wrong side", wida, cut);
    let bw = y[0] - dot(w, x[0]);
    let cutb = clear(&x, &y, w, bw).iter().filter(|&&v| v < 0.0).count();
    println!("  b taken from house 0 (lam = 0): b = {:.4}, {} houses on the wrong side", bw, cutb);
    let mut xb = x.clone(); xb[30] = (60.0, 45.0);   // one Southgate house moved into Northfield
    let (_, cb, fb) = enumerate_kerbs(&xb, &y);
    println!("  one Southgate house moved to (60.0, 45.0): {} of {} roads clear every house", fb, cb);
    for c in [1.0, 10.0, 100.0] {
        let fc = smo(&xb, &y, c);
        println!("    soft margin C = {:5.0}: dual value {:.4} after {} steps", c, tot(fc.lam.iter().cloned()) - 0.5 * dot(fc.w, fc.w), fc.k);
    }
    for (m, spot) in [(13usize, (42.0, 49.0)), (0, (0.0, 100.0))] {   // try changing: move one house
        let mut xt = x.clone(); xt[m] = spot; let ft = smo(&xt, &y, f64::INFINITY);
        println!("try: house {} moved to ({:.1}, {:.1}): width {:.4} m, support vectors {:?}, {} steps", m, spot.0, spot.1, 2.0 / dot(ft.w, ft.w).sqrt(), ft.sv, ft.k);
    }
    assert!(f.sv.len() == 3 && (2.0 / nw - 2.0 / dot(we, we).sqrt()).abs() < 1e-6);   // roads 1 and 2 agree
    assert!((w.0 - we.0).abs() < 1e-6 && (w.1 - we.1).abs() < 1e-6 && (b - be).abs() < 1e-5);
    assert!((p_val - d_val).abs() < 1e-9 && lowest(&s) > 1.0 - 1e-7);                 // certificate
    assert!((gapd - 2.0 / nw).abs() < 1e-6 && (cl - 2.0 / nw).abs() < 1e-9 && (sl - nw * nw).abs() < 1e-9);            // hull distance, sum lam
    assert!(fb == 0 && wida < 2.0 / nw && cutb > 0 && lam[13] < 1e-12 && 1e-12 < s[13] - 1.0);
    let fig: Vec<String> = [1.0, 0.0, -1.0].iter().flat_map(|&c| [0.0, 100.0].map(|xx| format!("{:.2}", (c - b - w.0 * xx) / w.1))).collect();
    println!("figure, kerb +1, centre, kerb -1 at x = 0 and 100: {}", fig.join(" "));
    println!("ALL CHECKS PASS");
}
