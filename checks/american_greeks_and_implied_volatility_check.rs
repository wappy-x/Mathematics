// American Greeks and implied volatility -- the same check as the Python, in Rust.
// Standard library only, no crates.  The bell-curve area is Simpson's rule,
// the tree, the grid and both root finders are loops written out here.
use std::f64::consts::PI;

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }

fn n_cdf(x: f64) -> f64 {                 // bell-curve area left of x, by Simpson
    let n = 2000;
    let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}

fn bs_put(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    (k * (-r * t).exp() * n_cdf(-(d1 - sig * t.sqrt())) - s * (-q * t).exp() * n_cdf(-d1), d1)
}

#[derive(Clone, Copy)]
struct M { s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64 }

fn bend(s: &[f64], v: &[f64], i: usize) -> f64 {   // three unevenly spaced prices -> gamma
    let (hp, hm) = (s[i + 1] - s[i], s[i] - s[i - 1]);
    2.0 / (hp + hm) * ((v[i + 1] - v[i]) / hp - (v[i] - v[i - 1]) / hm)
}

fn slope(s: &[f64], v: &[f64], i: usize) -> f64 {  // slope of the same parabola at the middle
    let (hp, hm) = (s[i + 1] - s[i], s[i] - s[i - 1]);
    ((v[i + 1] - v[i]) / hp * hm + (v[i] - v[i - 1]) / hm * hp) / (hp + hm)
}

// Road 1: Cox-Ross-Rubinstein tree.  Returns price, delta, gamma, theta off the nodes.
fn tree(m: M, n: usize, american: bool) -> (f64, f64, f64, f64) {
    let dt = m.t / n as f64;
    let u = (m.sig * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((m.r - m.q) * dt).exp() - d) / (u - d);
    let disc = (-m.r * dt).exp();
    let mut s: Vec<f64> = (0..=n).map(|j| m.s * d.powi(n as i32) * u.powi(2 * j as i32)).collect();
    let mut v: Vec<f64> = s.iter().map(|x| (m.k - x).max(0.0)).collect();
    let (mut s1, mut v1, mut s2, mut v2) = (vec![], vec![], vec![], vec![]);
    for i in (0..n).rev() {
        s = s[..i + 1].iter().map(|x| x * u).collect();      // prices one step earlier
        v = (0..=i).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
        if american { v = (0..=i).map(|j| v[j].max(m.k - s[j])).collect(); }
        if i == 1 { s1 = s.clone(); v1 = v.clone(); }
        if i == 2 { s2 = s.clone(); v2 = v.clone(); }
    }
    let delta = (v1[1] - v1[0]) / (s1[1] - s1[0]);
    (v[0], delta, bend(&s2, &v2, 1), (v2[1] - v[0]) / (2.0 * dt))
}
fn tp(m: M) -> f64 { tree(m, 2000, true).0 }

// Road 2: explicit finite differences in x = ln(S/100), early exercise enforced
// after every time step.  Returns node prices, prices now and one step later.
fn grid(m: M) -> (Vec<f64>, Vec<f64>, Vec<f64>, f64, Vec<f64>, usize) {
    let (dx, steps, n) = (0.005, 2500, (1.5_f64 / 0.005).round() as usize);
    let ss: Vec<f64> = (0..=2 * n).map(|i| m.s * ((i as f64 - n as f64) * dx).exp()).collect();
    let g: Vec<f64> = ss.iter().map(|x| (m.k - x).max(0.0)).collect();
    let (dt, nu) = (m.t / steps as f64, m.r - m.q - 0.5 * m.sig * m.sig);
    let a = dt * (0.5 * m.sig * m.sig / (dx * dx) - nu / (2.0 * dx));
    let c = dt * (0.5 * m.sig * m.sig / (dx * dx) + nu / (2.0 * dx));
    let b = 1.0 - dt * (m.sig * m.sig / (dx * dx) + m.r);
    let (mut v, mut prev) = (g.clone(), g.clone());
    for _ in 0..steps {
        prev = v;
        v = vec![g[0]];
        for i in 1..2 * n { v.push(g[i].max(a * prev[i - 1] + b * prev[i] + c * prev[i + 1])); }
        v.push(0.0);
    }
    (ss, v, prev, dt, g, n)
}
fn gp(m: M) -> f64 { let (_, v, _, _, _, n) = grid(m); v[n] }

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    while hi - lo > 1e-9 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn secant<F: Fn(f64) -> f64>(f: F, mut x0: f64, mut x1: f64) -> f64 {
    let (mut f0, mut f1) = (f(x0), f(x1));
    while (x1 - x0).abs() > 1e-10 {
        let x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1; x1 = x2; f0 = f1; f1 = f(x1);
    }
    x1
}

fn main() {
    let h = M { s: 100.0, k: 100.0, r: 0.05, q: 0.02, sig: 0.20, t: 1.0 };
    let quote = 6.660226;
    let (p, dl, gm, th) = tree(h, 2000, true);
    let (pe_tree, _, _, _) = tree(h, 2000, false);
    let (pe, d1) = bs_put(h.s, h.k, h.r, h.q, h.sig, h.t);
    let de = -(-h.q * h.t).exp() * n_cdf(-d1);
    let (ss, v, prev, dt, g, n) = grid(h);
    let (v21, v19) = (tp(M { sig: h.sig + 0.01, ..h }), tp(M { sig: h.sig - 0.01, ..h }));
    let vega_t = (v21 - v19) / 0.02;
    let vega_g = (gp(M { sig: h.sig + 0.01, ..h }) - gp(M { sig: h.sig - 0.01, ..h })) / 0.02;
    let rho_t = (tp(M { r: h.r + 0.01, ..h }) - tp(M { r: h.r - 0.01, ..h })) / 0.02;
    let rho_g = (gp(M { r: h.r + 0.01, ..h }) - gp(M { r: h.r - 0.01, ..h })) / 0.02;
    let b = (1..2 * n).filter(|&i| v[i] == g[i]).max().unwrap();   // last node exercised today
    let jump = 2.0 * (h.r * h.k - h.q * ss[b]) / (h.sig * h.sig * ss[b] * ss[b]);
    let (_, d70, g70, _) = tree(M { s: 70.0, ..h }, 2000, true);
    let iv_tree = bisect(|x| tp(M { sig: x, ..h }) - quote, 0.01, 2.0);
    let iv_grid = secant(|x| gp(M { sig: x, ..h }) - quote, 0.18, 0.22);
    let iv_euro = bisect(|x| bs_put(h.s, h.k, h.r, h.q, x, h.t).0 - quote, 0.01, 2.0);
    let bump_gamma = (tp(M { s: h.s + 0.01, ..h }) - 2.0 * p + tp(M { s: h.s - 0.01, ..h })) / (0.01 * 0.01);
    let p_rich = 2.0 * p - tree(h, 1000, true).0;                  // Richardson: tree error ~ 1/steps
    let theta_g = (prev[n] - v[n]) / dt;
    let rows: Vec<(&str, f64)> = vec![
        ("price, tree 2000 steps", p), ("price, grid", v[n]), ("price, Richardson 1000/2000", p_rich),
        ("price, tree + control variate", p + pe - pe_tree),
        ("European put, formula", pe), ("European put, tree 2000 steps", pe_tree),
        ("delta, tree nodes", dl), ("delta, grid", slope(&ss, &v, n)),
        ("gamma, tree nodes", gm), ("gamma, grid", bend(&ss, &v, n)),
        ("theta per year, tree nodes", th), ("theta per year, grid", theta_g),
        ("theta per day, tree nodes", th / 365.0), ("early-exercise premium, tree", p - pe),
        ("tree price at sigma 0.21", v21), ("tree price at sigma 0.19", v19),
        ("vega per 1.00, tree, bump 0.01", vega_t), ("vega per 1.00, grid, bump 0.01", vega_g),
        ("rho per 1.00, tree, bump 0.01", rho_t), ("rho per 1.00, grid, bump 0.01", rho_g), ("vega per vol point, tree", vega_t / 100.0),
        ("last exercised node today, grid", ss[b]), ("first held node today, grid", ss[b + 1]),
        ("carry rK - qS* there", h.r * h.k - h.q * ss[b]),
        ("sigma^2 S*^2 there", h.sig * h.sig * ss[b] * ss[b]), ("gamma one node above, grid", bend(&ss, &v, b + 1)), ("gamma jump 2(rK-qS*)/(s^2 S*^2)", jump),
        ("S = 70: delta, tree nodes", d70), ("S = 70: gamma, tree nodes", (g70 * 1e9).round() / 1e9 + 0.0),
        ("implied vol, bisection on tree", iv_tree), ("implied vol, secant on grid", iv_grid),
        ("wrong: European formula inverted", iv_euro), ("wrong: European delta", de),
        ("wrong: gamma by 1-cent spot bump", bump_gamma),
        ("range: price at sigma 0.01", tp(M { sig: 0.01, ..h })), ("range: price at sigma 2.00", tp(M { sig: 2.0, ..h })),
    ];
    for (name, x) in &rows { println!("{:<36} {:>12.6}", name, x); }
    let flat: Vec<String> = [0.1, 0.2, 0.3, 0.4].iter().map(|&x| format!(" {:.6}", tp(M { s: 70.0, sig: x, ..h }))).collect();
    println!("S = 70, sigma 0.10 0.20 0.30 0.40:{}", flat.concat());
    let sigs: Vec<f64> = (1..=8).map(|k| 0.05 * k as f64).collect();
    let am: Vec<f64> = sigs.iter().map(|&x| tp(M { sig: x, ..h })).collect();
    let line = |label: &str, xs: Vec<String>| println!("{}{}", label, xs.join(" "));
    line("chart, sigma        ", sigs.iter().map(|x| format!("{:6.2}", x)).collect());
    line("chart, American put ", am.iter().map(|x| format!("{:6.2}", x)).collect());
    line("chart, European put ", sigs.iter().map(|&x| format!("{:6.2}", bs_put(h.s, h.k, h.r, h.q, x, h.t).0)).collect());
    let idx: Vec<usize> = [-60i64, -51, -49, -40, -30, -20, -10, 0, 10, 20].iter().map(|k| (n as i64 + k) as usize).collect();
    let eu: Vec<f64> = idx.iter().map(|&i| bs_put(ss[i], h.k, h.r, h.q, h.sig, h.t).1).collect();
    line("chart, spot         ", idx.iter().map(|&i| format!("{:7.2}", ss[i])).collect());
    line("chart, Am. delta    ", idx.iter().map(|&i| format!("{:7.2}", slope(&ss, &v, i))).collect());
    line("chart, Eu. delta    ", eu.iter().map(|&x| format!("{:7.2}", -(-h.q * h.t).exp() * n_cdf(-x))).collect());
    line("chart, Am. gamma x100", idx.iter().map(|&i| format!("{:7.2}", 100.0 * bend(&ss, &v, i))).collect());
    line("chart, Eu. gamma x100", eu.iter().zip(&idx).map(|(&x, &i)| format!("{:7.2}", 100.0 * (-h.q * h.t).exp() * phi(x) / (ss[i] * h.sig))).collect());

    assert!((p - quote).abs() < 1e-6, "tree reproduces the house quote");
    assert!((pe - 6.330080627550).abs() < 1e-9, "own bell curve reproduces the house European put");
    assert!((p_rich - v[n]).abs() < 1e-4, "tree (extrapolated) and grid agree on the price");
    assert!((dl - slope(&ss, &v, n)).abs() < 1e-5, "delta: tree nodes vs grid");
    assert!((gm - bend(&ss, &v, n)).abs() < 1e-4, "gamma: tree nodes vs grid");
    assert!((th - theta_g).abs() < 0.01, "theta: tree nodes vs grid");
    assert!((vega_t - vega_g).abs() < 0.05, "vega: tree bump vs grid bump");
    assert!((rho_t - rho_g).abs() < 0.05, "rho: tree bump vs grid bump");
    assert!((d70 + 1.0).abs() < 1e-12, "delta is -1 inside the exercise region");
    assert!(g70.abs() < 1e-12, "gamma is 0 inside the exercise region");
    assert!((bend(&ss, &v, b + 1) - jump).abs() < 0.01 * jump, "gamma jump: grid vs 2(rK - qS*)/(sigma^2 S*^2)");
    assert!((iv_tree - h.sig).abs() < 1e-6, "bisection on the tree recovers 20 percent");
    assert!((iv_grid - iv_tree).abs() < 1e-4, "secant on the grid lands beside it");
    assert!(iv_euro > iv_tree + 0.005, "European inversion books the premium as volatility");
    assert!([0.1, 0.2].iter().all(|&x| (tp(M { s: 70.0, sig: x, ..h }) - 30.0).abs() < 1e-9), "flat at $70: a plateau");
    assert!(am.windows(2).all(|w| w[0] < w[1]), "American price strictly rises in volatility");
    println!("ALL CHECKS PASS");
}
