// Scale function, speed measure and boundaries -- the check behind the card.
// std only.  A CIR rate dr = kappa(theta - r)dt + sigma sqrt(r) dW, pull 0.5 a
// year, level 0.04, noise 0.30 or 0.10.  Three roads: scale and speed integrals,
// finite differences on the generator, and a simulation.
use std::f64::consts::PI;
const KAPPA: f64 = 0.5; const THETA: f64 = 0.04; const X0: f64 = 0.04; const TOP: f64 = 0.08;
const I0: usize = 800 * 60; // index of 4% on the grid
fn du() -> f64 { 2f64.ln() / 800.0 }
fn idx(x: f64) -> usize { (I0 as f64 + ((x / X0).ln() / du()).round()) as usize }
fn psum(v: impl Iterator<Item = f64>) -> f64 { // compensated sum, as Python's sum()
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in v { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; } s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn g4(v: f64) -> String { // Python's {:.4g}
    let e: i32 = format!("{:.3e}", v).split('e').nth(1).unwrap().parse().unwrap();
    if e < -4 || e >= 4 {
        let s = format!("{:.3e}", v); let m = s.split_once('e').unwrap().0.trim_end_matches('0').trim_end_matches('.');
        format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
    } else { let s = format!("{:.*}", (3 - e) as usize, v);
        if s.contains('.') { s.trim_end_matches('0').trim_end_matches('.').to_string() } else { s } }
}
struct Grid { xs: Vec<f64> }
impl Grid { // integral of f(x) dx from xs[i] to xs[j] (dx = x du), trapezoid
    fn trap(&self, f: &dyn Fn(usize) -> f64, i: usize, j: usize) -> f64 {
        let (xs, d) = (&self.xs, du()); psum((i + 1..=j).map(|k| 0.5 * (f(k) * xs[k] + f(k - 1) * xs[k - 1]) * d)) } }
struct Diffusion { s: Vec<f64>, m: Vec<f64>, cs: Vec<f64> }
fn diffusion(g: &Grid, sig: f64, th: f64) -> Diffusion {
    let xs = &g.xs; let n = xs.len(); let d = du();
    let (mu, sd) = (|x: f64| KAPPA * (th - x), |x: f64| sig * x.max(0.0).sqrt());
    let q: Vec<f64> = xs.iter().map(|&x| 2.0 * mu(x) / sd(x).powi(2) * x).collect();
    let (mut ls, mut cs) = (vec![0.0; n], vec![0.0; n]);
    for i in I0 + 1..n { ls[i] = ls[i - 1] - 0.5 * (q[i] + q[i - 1]) * d; }
    for i in (0..I0).rev() { ls[i] = ls[i + 1] + 0.5 * (q[i] + q[i + 1]) * d; }
    let s: Vec<f64> = ls.iter().map(|v| v.exp()).collect();
    let m: Vec<f64> = xs.iter().zip(&s).map(|(&x, &v)| 2.0 / (sd(x).powi(2) * v)).collect();
    let w: Vec<f64> = s.iter().zip(xs).map(|(&v, &x)| v * x * d).collect();
    for i in I0 + 1..n { cs[i] = cs[i - 1] + 0.5 * (w[i] + w[i - 1]); }
    for i in (0..I0).rev() { cs[i] = cs[i + 1] - 0.5 * (w[i] + w[i + 1]); }
    Diffusion { s, m, cs }
}
impl Diffusion {
    fn tests(&self, g: &Grid, k: usize) -> [f64; 4] { // Feller's two integrals at zero, cut at 4%/2^k
        let (e, s, m) = (I0 - 800 * k, &self.cs, &self.m);
        let arrive = g.trap(&|i| (s[i] - s[e]) * m[i], e, I0);   // A: can the edge be reached?
        let depart = g.trap(&|i| (s[I0] - s[i]) * m[i], e, I0);  // D: can a path start there?
        [-s[e], g.trap(&|i| m[i], e, I0), arrive, depart]
    }
    fn band(&self, g: &Grid, b: f64, x: f64, reached: bool) -> (f64, f64) {
        let (s, m, ib, ix) = (&self.cs, &self.m, idx(b), idx(x));
        if !reached { return (0.0, g.trap(&|i| (s[ib] - s[i.max(ix)]) * m[i], 0, ib)); }
        let (s0, w) = (s[0], s[ib] - s[0]); let gr = |i: usize| (s[i.min(ix)] - s0) * (s[ib] - s[i.max(ix)]) / w;
        ((s[ib] - s[ix]) / w, g.trap(&|i| gr(i) * m[i], 0, ib))
    }
    fn law(&self, g: &Grid) -> (f64, f64, f64, f64) {
        let (m, xs, last) = (&self.m, &g.xs, g.xs.len() - 1);
        let z = g.trap(&|i| m[i], 0, last); let mean = g.trap(&|i| xs[i] * m[i], 0, last) / z;
        let var = g.trap(&|i| (xs[i] - mean).powi(2) * m[i], 0, last) / z;
        (z, mean, var.sqrt(), g.trap(&|i| m[i], 0, idx(X0 / 8.0)) / z)
    }
}
fn uniform_band(mu: &dyn Fn(f64) -> f64, sd: &dyn Fn(f64) -> f64, a: f64, b: f64, x: f64, n: usize) -> (f64, f64) {
    let h = (b - a) / n as f64; let ys: Vec<f64> = (0..=n).map(|i| a + i as f64 * h).collect();
    let (mut ls, mut cs) = (vec![0.0], vec![0.0]);
    for i in 1..=n { let v = ls[i - 1] - h * (mu(ys[i]) / sd(ys[i]).powi(2) + mu(ys[i - 1]) / sd(ys[i - 1]).powi(2)); ls.push(v); }
    let s: Vec<f64> = ls.iter().map(|v| v.exp()).collect(); let m: Vec<f64> = ys.iter().zip(&s).map(|(&y, &v)| 2.0 / (sd(y).powi(2) * v)).collect();
    for i in 1..=n { let v = cs[i - 1] + 0.5 * h * (s[i] + s[i - 1]); cs.push(v); }
    let ix = ((x - a) / h).round() as usize; let gg: Vec<f64> = (0..=n).map(|i| cs[i.min(ix)] * (cs[n] - cs[i.max(ix)]) / cs[n] * m[i]).collect();
    (cs[ix] / cs[n], h * (psum(gg.iter().cloned()) - 0.5 * (gg[0] + gg[n])))
}
fn fd(mu: &dyn Fn(f64) -> f64, sd: &dyn Fn(f64) -> f64, a: f64, b: f64, x: f64, rhs: f64, fa: f64, fb: f64, n: usize, entrance: bool) -> f64 {
    let h = (b - a) / n as f64;
    let (mut lo, mut di, mut up, mut r) = (vec![0.0; n + 1], vec![1.0; n + 1], vec![0.0; n + 1], vec![0.0; n + 1]); r[0] = fa; r[n] = fb;
    if entrance { di[0] = -mu(a) / h; up[0] = mu(a) / h; r[0] = rhs; } // no noise at 0: drift only
    for i in 1..n {
        let y = a + i as f64 * h; let dd = 0.5 * sd(y).powi(2) / h.powi(2); let c = mu(y) / (2.0 * h);
        lo[i] = dd - c; di[i] = -2.0 * dd; up[i] = dd + c; r[i] = rhs;
    }
    for i in 1..=n { let w = lo[i] / di[i - 1]; di[i] -= w * up[i - 1]; r[i] -= w * r[i - 1]; }
    let mut f = vec![0.0; n + 1]; f[n] = r[n] / di[n];
    for i in (0..n).rev() { f[i] = (r[i] - up[i] * f[i + 1]) / di[i]; }
    f[((x - a) / h).round() as usize]
}
struct Rng(u64);
impl Rng {
    fn nxt(&mut self) -> f64 { // splitmix64, then a uniform on (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0; z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 2f64.powi(53)
    }
}
fn simulate(rng: &mut Rng, sig: f64, h: f64, paths: usize) -> (f64, f64, f64) { // road 3: Euler
    let (mut hits, mut total) = (0usize, 0.0f64);
    for _ in 0..paths {
        let (mut r, mut t) = (X0, 0.0); while 0.0 < r && r < TOP {
            let u1 = rng.nxt(); let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * rng.nxt()).cos();
            r += KAPPA * (THETA - r) * h + sig * (r * h).sqrt() * z; t += h; }
        if r <= 0.0 { hits += 1; } total += t;
    }
    let p = hits as f64 / paths as f64; (p, (p * (1.0 - p) / paths as f64).sqrt(), total / paths as f64)
}
fn main() {
    let g = Grid { xs: (0..=800 * 66).map(|j| X0 * ((j as f64 - I0 as f64) * du()).exp()).collect() };
    println!("CIR rate: pull 0.5 a year, level 4%, start 4%, band 0 to 8%");
    let cases = [("noise 0.30", 0.3, THETA), ("noise 0.10", 0.1, THETA), ("level 0, noise 0.30", 0.3, 0.0)];
    let dd: Vec<Diffusion> = cases.iter().map(|&(_, sg, th)| diffusion(&g, sg, th)).collect();
    for &(name, sg, th) in &cases {
        let nu = 2.0 * KAPPA * th / sg.powi(2);
        println!("{}: Feller ratio 2 x 0.5 x {:.2} / {:.2} = {:.4}; near 0, s ~ x^{:.4}, m ~ x^{:.4}", name, th, sg.powi(2), nu, 0.0 - nu, nu - 1.0); }
    println!("Feller's tests at zero, cut at 4%/2^k: k | S(4%)-S(cut) | M(cut,4%) | A | D");
    let mut t = vec![];
    for (c, d) in cases.iter().zip(&dd) {
        let row: Vec<[f64; 4]> = [10, 20, 40].iter().map(|&k| d.tests(&g, k)).collect();
        for (k, v) in [10, 20, 40].iter().zip(&row) { println!("  {:<20} {:>2} {}", c.0, k, v.iter().map(|x| format!("{:>11}", g4(*x))).collect::<Vec<_>>().join(" ")); }
        t.push(row);
    }
    let finite = |a: f64, b: f64, c: f64| (c - b).abs() < 0.5 * (b - a).abs(); let mut verdict = vec![];
    for (c, row) in cases.iter().zip(&t) { // A finite <=> zero is reached; D finite <=> the rate can start at zero
        let (fa, fdp) = (finite(row[0][2], row[1][2], row[2][2]), finite(row[0][3], row[1][3], row[2][3]));
        let v = match (fa, fdp) { (true, true) => "regular", (true, false) => "exit", (false, true) => "entrance", _ => "natural" };
        println!("  {}: zero is {}", c.0, v); verdict.push(v);
    }
    let d3 = &dd[0];
    let inf: Vec<String> = [2, 4, 6].iter().map(|&k| format!("{:.4}", g.trap(&|i| d3.cs[i] * d3.m[i], I0, I0 + 800 * k))).collect();
    println!("D at infinity, noise 0.30, cut at 16%, 64%, 256%: {} -> natural", inf.join(", "));
    let ((p3, g3), (p1, g1)) = (d3.band(&g, TOP, X0, true), dd[1].band(&g, TOP, X0, false));
    let mu = |x: f64| KAPPA * (THETA - x); let sd3 = |x: f64| 0.3 * x.max(0.0).sqrt(); let sd1 = |x: f64| 0.1 * x.max(0.0).sqrt();
    let (fp3, fg3) = (fd(&mu, &sd3, 0.0, TOP, X0, 0.0, 1.0, 0.0, 20000, false), fd(&mu, &sd3, 0.0, TOP, X0, -1.0, 0.0, 0.0, 20000, false));
    let fg1 = fd(&mu, &sd1, 0.0, TOP, X0, -1.0, 0.0, 0.0, 20000, true);
    let mut rng = Rng(0x2026); let (mp, mse, mt) = simulate(&mut rng, 0.3, 0.001, 4000);
    println!("noise 0.30, P(zero before 8%): scale {:.4}, finite differences {:.4}, simulation {:.4} +/- {:.4}", p3, fp3, mp, mse);
    println!("noise 0.30, mean exit time (years): speed {:.4}, finite differences {:.4}, simulation {:.4}", g3, fg3, mt);
    println!("noise 0.10, P(zero before 8%) {:.4}; mean time to 8% (years): speed {:.4}, finite differences {:.4}", p1, g1, fg1);
    let sdou = |_x: f64| 0.02; let (op, og) = uniform_band(&mu, &sdou, 0.04, 0.08, 0.06, 4000);
    let (fop, fog) = (fd(&mu, &sdou, 0.04, 0.08, 0.06, 0.0, 0.0, 1.0, 4000, false), fd(&mu, &sdou, 0.04, 0.08, 0.06, -1.0, 0.0, 0.0, 4000, false));
    println!("OU band 4% to 8% from 6%: P(8% first) {:.6} (fd {:.6}), mean exit {:.6} years (fd {:.6})", op, fop, og, fog);
    let laws = [dd[0].law(&g), dd[1].law(&g)];
    for (name, sg, l) in [("noise 0.30", 0.3f64, laws[0]), ("noise 0.10", 0.1, laws[1])] {
        println!("stationary, {}: mean {:.4}, sd {:.4}; moments: mean {:.4}, variance {:.4}, sd {:.4}; P(rate < 0.5%) {:.4}",
                 name, l.1, l.2, THETA, THETA * sg.powi(2) / (2.0 * KAPPA), (THETA * sg.powi(2) / (2.0 * KAPPA)).sqrt(), l.3);
    }
    let density = |x: f64, sg: f64, z: f64| { // stationary density per percentage point, s in closed form
        let (nu, beta) = (2.0 * KAPPA * THETA / sg.powi(2), 2.0 * KAPPA / sg.powi(2));
        0.01 * 2.0 / (sg.powi(2) * x * (x / X0).powf(-nu) * (beta * (x - X0)).exp()) / z
    };
    for (sg, z) in [(0.3f64, laws[0].0), (0.1, laws[1].0)] {
        let v: Vec<String> = (1..=20).map(|j| format!("{:.3}", density(0.005 * j as f64, sg, z))).collect();
        println!("chart, density per point, noise {:.2}: {}", sg, v.join(" "));
    }
    let last = g.xs.len() - 1; let zw = g.trap(&|i| 1.0 / d3.s[i], 0, last);
    let mean_w = g.trap(&|i| g.xs[i] / d3.s[i], 0, last) / zw;
    println!("breaks: ratio with sigma not squared, noise 0.10: {:.4}; straight-line chance {:.4}; density 1/s, noise 0.30: mean {:.4}",
             2.0 * KAPPA * THETA / 0.1, (TOP - X0) / TOP, mean_w);
    let d2 = diffusion(&g, 0.2, THETA); let tr: Vec<String> = [10, 20, 40].iter().map(|&k| format!("{:.4}", d2.tests(&g, k)[0])).collect();
    println!("try: noise 0.20, S(4%)-S(cut) at k = 10, 20, 40: {}", tr.join(", "));
    println!("try: level 2%, noise 0.30, P(zero first) {:.4}; band 0 to 16%, P(zero first) {:.4}",
             diffusion(&g, 0.3, 0.02).band(&g, TOP, X0, true).0, d3.band(&g, 0.16, X0, true).0);
    println!("try: simulation with 100 steps a year, P(zero first) {:.4}", simulate(&mut rng, 0.3, 0.01, 4000).0);
    let nu3 = 2.0 * KAPPA * THETA / 0.09;
    assert!((d3.s[idx(TOP)] - 2f64.powf(-nu3) * (TOP / 0.09 - X0 / 0.09).exp()).abs() < 1e-6); // s in closed form
    assert_eq!(verdict, ["regular", "entrance", "exit"]);
    assert!((p3 - fp3).abs() < 2e-3 && (g3 - fg3).abs() < 5e-3 && (g1 - fg1).abs() < 1e-3); // road 1 vs road 2
    assert!((p3 - mp).abs() < 3.0 * mse && (g3 - mt).abs() < 0.03); // road 1 vs road 3
    assert!((op - fop).abs() < 1e-5 && (og - fog).abs() < 1e-5);
    for (sg, l) in [(0.3f64, laws[0]), (0.1, laws[1])] { // speed vs moments
        assert!((l.1 - THETA).abs() < 1e-5 && (l.2 - (THETA * sg.powi(2) / (2.0 * KAPPA)).sqrt()).abs() < 1e-5);
    }
    println!("ALL CHECKS PASS");
}
