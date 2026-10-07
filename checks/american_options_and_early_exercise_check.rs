// American put: the price is the best stopping rule, found by working backwards.
// Rust std only, no crates. Same three roads as the Python check: (1) CRR tree
// with a max at every node, (2) a Crank-Nicolson grid solved by Brennan-Schwartz,
// (3) fixed stopping rules on the same tree. Own normal CDF (Simpson), no erf.
use std::f64::consts::PI;

fn ncdf(x: f64) -> f64 {                     // area under the bell curve left of x
    if x < 0.0 { return 1.0 - ncdf(-x); }
    let n = 2000; let h = x / n as f64;
    let f = |z: f64| (-0.5 * z * z).exp();
    let mut acc = 0.0;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h); }
    0.5 + (f(0.0) + f(x) + acc) * h / 3.0 / (2.0 * PI).sqrt()
}

fn bs(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    let c = s * (-q * t).exp() * ncdf(d1) - k * (-r * t).exp() * ncdf(d2);
    let p = k * (-r * t).exp() * ncdf(-d2) - s * (-q * t).exp() * ncdf(-d1);
    (c, p)
}

#[derive(Clone, Copy, PartialEq)]
enum Rule { Best, Never, Level(f64) }

fn tree(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, n: usize, call: bool, rule: Rule) -> f64 {
    let dt = t / n as f64; let u = (sig * dt.sqrt()).exp();
    let p = (((r - q) * dt).exp() - 1.0 / u) / (u - 1.0 / u);
    let (a, b) = ((-r * dt).exp() * p, (-r * dt).exp() * (1.0 - p));
    let w = if call { 1.0 } else { -1.0 };
    let node = |j: usize, m: usize| s * u.powf(2.0 * j as f64 - m as f64);
    let mut v: Vec<f64> = (0..=n).map(|j| (w * (node(j, n) - k)).max(0.0)).collect();
    for m in (0..n).rev() {
        v = (0..=m).map(|j| b * v[j] + a * v[j + 1]).collect();
        if rule == Rule::Never { continue; }
        for j in 0..=m {
            let sn = node(j, m); let g = w * (sn - k);
            match rule {
                Rule::Best => { if g > v[j] { v[j] = g; } }
                Rule::Level(l) => { if sn <= l && g > 0.0 { v[j] = g; } }
                Rule::Never => {}
            }
        }
    }
    v[0]
}

fn grid(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, american: bool) -> f64 {
    // Crank-Nicolson in x = ln S (two implicit first steps), Brennan-Schwartz for the max
    let (m, nt) = (2400usize, 2000usize);
    let (dx, dt) = (3.0 / m as f64, t / nt as f64); let x0 = s.ln() - 1.5;
    let sx: Vec<f64> = (0..=m).map(|i| (x0 + i as f64 * dx).exp()).collect();
    let g: Vec<f64> = sx.iter().map(|&y| (k - y).max(0.0)).collect();
    let mut v = g.clone();
    let nu = r - q - 0.5 * sig * sig;
    let al = 0.5 * sig * sig / dx / dx - 0.5 * nu / dx;
    let ga = 0.5 * sig * sig / dx / dx + 0.5 * nu / dx;
    let be = -sig * sig / dx / dx - r;
    for step in 1..=nt {
        let th = if step <= 2 { 1.0 } else { 0.5 }; let tau = step as f64 * dt;
        let (aa, bb, cc) = (-th * dt * al, 1.0 - th * dt * be, -th * dt * ga);
        let mut rr = vec![0.0; m + 1];
        for i in 1..m { rr[i] = v[i] + (1.0 - th) * dt * (al * v[i - 1] + be * v[i] + ga * v[i + 1]); }
        let lo = if american { g[0] } else { k * (-r * tau).exp() - sx[0] * (-q * tau).exp() };
        let (mut bp, mut rp) = (vec![0.0; m + 1], vec![0.0; m + 1]);
        bp[m - 1] = bb; rp[m - 1] = rr[m - 1];
        for i in (1..m - 1).rev() { let f = cc / bp[i + 1]; bp[i] = bb - f * aa; rp[i] = rr[i] - f * rp[i + 1]; }
        let mut new = vec![0.0; m + 1]; new[0] = lo;
        for i in 1..m {
            new[i] = (rp[i] - aa * new[i - 1]) / bp[i];
            if american && g[i] > new[i] { new[i] = g[i]; }
        }
        v = new;
    }
    v[m / 2]
}

fn main() {
    let (s, k, r, q, sig, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let n = 2000;
    let (ce, pe) = bs(s, k, r, q, sig, t);
    let tr = |r: f64, q: f64, sig: f64, n: usize, call: bool, rule: Rule| tree(s, k, r, q, sig, t, n, call, rule);
    let (pa, pet) = (tr(r, q, sig, n, false, Rule::Best), tr(r, q, sig, n, false, Rule::Never));
    let (ca, cet) = (tr(r, q, sig, n, true, Rule::Best), tr(r, q, sig, n, true, Rule::Never));
    let (pag, peg) = (grid(s, k, r, q, sig, t, true), grid(s, k, r, q, sig, t, false));
    let (pa1, pe1) = (tr(r, q, sig, 1000, false, Rule::Best), tr(r, q, sig, 1000, false, Rule::Never));
    let (lo, hi) = (s * (-q * t).exp() - k, s - k * (-r * t).exp());
    let dt = t / 2.0; let u = (sig * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d); let dd = (-r * dt).exp();
    let (sd, sdd) = (s * d, s * d * d);
    let hold_d = dd * (1.0 - p) * (k - sdd);     // after a rise, every later node pays nothing
    let rows: Vec<(&str, f64)> = vec![
        ("European put, closed form", pe), ("European call, closed form", ce),
        ("1 American put, tree 2000", pa), ("  European put, same tree", pet),
        ("  limit, 2 x tree 2000 - tree 1000", 2.0 * pa - pa1), ("  same for the European", 2.0 * pet - pe1),
        ("2 American put, grid", pag), ("  European put, same grid", peg),
        ("premium, tree 2000 - closed form", pa - pe), ("premium, like for like on tree", pa - pet),
        ("premium, like for like on grid", pag - peg),
        ("American call, tree 2000", ca), ("  European call, same tree", cet),
        ("  call difference x 1e6", (ca - cet) * 1e6),
        ("parity lower  S e^-qT - K", lo), ("  C_A - P_A", ca - pa), ("parity upper  S - K e^-rT", hi),
        ("  European C - P", ce - pe), ("premium cap  K(1 - e^-rT)", k * (1.0 - (-r * t).exp())),
        ("2-step: u", u), ("2-step: p", p), ("2-step: one-step discount", dd), ("2-step: Acme after a fall", sd),
        ("2-step: after two falls", sdd), ("2-step: payoff after two falls", k - sdd), ("2-step: hold after a fall", hold_d),
        ("2-step: exercise after a fall", k - sd), ("2-step: rule 'never'", dd * (1.0 - p) * hold_d),
        ("2-step: rule 'sell after a fall'", dd * (1.0 - p) * (k - sd)),
        ("2-step: tree with max", tr(r, q, sig, 2, false, Rule::Best)),
    ];
    for (name, val) in &rows { println!("{:<34} {:>12.6}", name, val); }
    println!("stopping rules on the 2000-step tree: exercise first time Acme <= L");
    let mut best_rule = 0.0_f64;
    for l in [70.0, 75.0, 80.0, 82.0, 85.0, 90.0, 99.99] {
        let val = tr(r, q, sig, n, false, Rule::Level(l)); best_rule = best_rule.max(val);
        println!("  L = {:6.2}   {:10.6}", l, val);
    }
    println!("convergence: American put, European put, gap to closed form");
    let steps = [50usize, 100, 200, 500, 1000, 2000];
    let mut am = Vec::new();
    for &m in &steps {
        let a = if m == 1000 { pa1 } else if m == 2000 { pa } else { tr(r, q, sig, m, false, Rule::Best) };
        let e = tr(r, q, sig, m, false, Rule::Never); am.push(a);
        println!("  N = {:5}   {:10.6}   {:10.6}   {:+.6}", m, a, e, e - pe);
    }
    let tries: Vec<(&str, f64)> = vec![
        ("try r = 0: American", tr(0.0, q, sig, 500, false, Rule::Best)),
        ("try r = 0: European", tr(0.0, q, sig, 500, false, Rule::Never)),
        ("try r = 10%: premium", tr(0.10, q, sig, 500, false, Rule::Best) - tr(0.10, q, sig, 500, false, Rule::Never)),
        ("try q = 0: American put", tr(r, 0.0, sig, 500, false, Rule::Best)),
        ("try sigma = 40%: premium", tr(r, q, 0.4, 500, false, Rule::Best) - tr(r, q, 0.4, 500, false, Rule::Never)),
    ];
    for (name, val) in &tries { println!("{:<34} {:>12.6}", name, val); }
    assert!((pe - 6.330080627550).abs() < 1e-9, "own normal CDF reproduces the house put");
    assert!((pa - pag).abs() < 0.001 && (2.0 * pa - pa1 - pag).abs() < 2e-4, "tree and grid agree on the American put");
    assert!((pet - pe).abs() < 0.002 && (peg - pe).abs() < 0.002, "both machines price the European put");
    assert!(best_rule < pa, "no fixed level beats the best stopping rule");
    assert!(lo < ca - pa && ca - pa < hi && ca - pa < ce - pe, "American parity band, below European parity");
    assert!(am.windows(2).all(|w| w[1] > w[0]), "the tree price climbs as steps grow");
    assert!((tries[0].1 - tries[1].1).abs() < 1e-9, "no rate, no reason to sell early");
    println!("ALL CHECKS PASS");
}
