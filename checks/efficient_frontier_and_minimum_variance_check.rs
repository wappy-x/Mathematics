// Efficient frontier and minimum variance -- the same check as the Python, in Rust.  Std only, no crates.
// Different routes on purpose: the inverse comes from cofactors (not elimination), and the
// no-calculus road fits a parabola through three points instead of a golden-section search.
// Compile: rustc --edition 2021 -O efficient_frontier_and_minimum_variance_check.rs -o /tmp/ef_check
type M3 = [[f64; 3]; 3];
const NAMES: [&str; 3] = ["shares", "bonds", "gold"];
const MU: [f64; 3] = [0.08, 0.04, 0.05];
const SD: [f64; 3] = [0.20, 0.06, 0.15];

fn cov(sd: [f64; 3], r01: f64, r02: f64, r12: f64) -> M3 {
    let rho = [[1.0, r01, r02], [r01, 1.0, r12], [r02, r12, 1.0]];
    let mut s = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { s[i][j] = sd[i] * sd[j] * rho[i][j]; } }
    s
}
fn det(s: &M3) -> f64 {
    s[0][0] * (s[1][1] * s[2][2] - s[1][2] * s[2][1]) - s[0][1] * (s[1][0] * s[2][2] - s[1][2] * s[2][0])
        + s[0][2] * (s[1][0] * s[2][1] - s[1][1] * s[2][0])
}
fn inverse(s: &M3) -> M3 {                                     // cofactors over the determinant
    let d = det(s);
    let mut inv = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 {
        let (r1, r2, c1, c2) = ((j + 1) % 3, (j + 2) % 3, (i + 1) % 3, (i + 2) % 3);
        inv[i][j] = (s[r1][c1] * s[r2][c2] - s[r1][c2] * s[r2][c1]) / d;
    } }
    inv
}
fn dot(u: &[f64; 3], v: &[f64; 3]) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn mv(m: &M3, v: &[f64; 3]) -> [f64; 3] { [dot(&m[0], v), dot(&m[1], v), dot(&m[2], v)] }
fn var(s: &M3, w: &[f64; 3]) -> f64 { dot(w, &mv(s, w)) }

struct Front { a: f64, b: f64, c: f64, d: f64, u: [f64; 3], v: [f64; 3] }
impl Front {                                                   // road 1: A, B, C and the frontier formula
    fn new(mu: &[f64; 3], s: &M3) -> Front {
        let si = inverse(s);
        let (u, v) = (mv(&si, &[1.0; 3]), mv(&si, mu));
        let (a, b, c) = (u[0] + u[1] + u[2], v[0] + v[1] + v[2], dot(mu, &v));
        Front { a, b, c, d: a * c - b * b, u, v }
    }
    fn gmv(&self) -> [f64; 3] { [self.u[0] / self.a, self.u[1] / self.a, self.u[2] / self.a] }
    fn mults(&self, m: f64) -> (f64, f64) { ((self.c - self.b * m) / self.d, (self.a * m - self.b) / self.d) }
    fn w(&self, m: f64) -> [f64; 3] {
        let (l, e) = self.mults(m);
        [l * self.u[0] + e * self.v[0], l * self.u[1] + e * self.v[1], l * self.u[2] + e * self.v[2]]
    }
}
fn kkt(mu: &[f64; 3], s: &M3, m: f64) -> [f64; 3] {           // road 2: the five Lagrange equations
    let mut a = [[0.0; 6]; 5];
    for i in 0..3 { for j in 0..3 { a[i][j] = s[i][j]; } a[i][3] = -1.0; a[i][4] = -mu[i]; }
    for j in 0..3 { a[3][j] = 1.0; a[4][j] = mu[j]; }
    a[3][5] = 1.0; a[4][5] = m;
    for c in 0..5 {
        let p = (c..5).max_by(|&x, &y| a[x][c].abs().partial_cmp(&a[y][c].abs()).unwrap()).unwrap();
        a.swap(c, p);
        let piv = a[c][c];
        for k in 0..6 { a[c][k] /= piv; }
        for r in 0..5 { if r != c { let f = a[r][c]; for k in 0..6 { a[r][k] -= f * a[c][k]; } } }
    }
    [a[0][5], a[1][5], a[2][5]]
}
fn vertex(f: &dyn Fn(f64) -> f64, x0: f64, step: f64) -> f64 {   // lowest point of a parabola through 3 points
    let (fl, f0, fr) = (f(x0 - step), f(x0), f(x0 + step));
    x0 + step * (fl - fr) / (2.0 * (fl - 2.0 * f0 + fr))
}
fn search(mu: &[f64; 3], s: &M3, m: f64) -> [f64; 3] {       // road 3: walk the line of weights that hit m
    let h = [mu[2] - mu[1], mu[0] - mu[2], mu[1] - mu[0]];
    let ws = (m - mu[1]) / (mu[0] - mu[1]);
    let line = move |t: f64| [ws + t * h[0], 1.0 - ws + t * h[1], t * h[2]];
    line(vertex(&|t| var(s, &line(t)), 0.0, 1.0))
}
fn pct(w: &[f64; 3]) -> String { w.iter().map(|x| format!("{:8.4}", 100.0 * x)).collect::<Vec<_>>().join("  ") }
fn report(label: &str, w: &[f64; 3], s: &M3) {
    println!("{:<30}{}  mean {:.4}%  sd {:.4}%", label, pct(w), 100.0 * dot(&MU, w), 100.0 * var(s, w).sqrt());
}

fn main() {
    let s = cov(SD, 0.2, 0.1, 0.0);
    let f = Front::new(&MU, &s);
    let (wg, mg, vg) = (f.gmv(), f.b / f.a, 1.0 / f.a);
    let wg_kkt = kkt(&MU, &s, mg);
    let mg_search = vertex(&|m| var(&s, &search(&MU, &s, m)), 0.05, 0.05);
    let wg_search = search(&MU, &s, mg_search);
    let (w6, (lam6, eta6)) = (f.w(0.06), f.mults(0.06));
    let (w6_kkt, w6_search) = (kkt(&MU, &s, 0.06), search(&MU, &s, 0.06));
    let w7 = f.w(0.07);
    let shift = [w7[0] - w6[0], w7[1] - w6[1], w7[2] - w6[2]];
    let v6 = (f.a * 0.06 * 0.06 - 2.0 * f.b * 0.06 + f.c) / f.d;
    let two_asset = |m: f64| { let ws = (m - 0.04) / 0.04; var(&s, &[ws, 1.0 - ws, 0.0]).sqrt() };
    let (d, si) = (det(&s), inverse(&s));
    let (u, v) = (mv(&si, &[1.0; 3]), mv(&si, &MU));

    println!("inputs: mean% {:.2} {:.2} {:.2}  sd% {:.2} {:.2} {:.2}  rho {:.2} {:.2} {:.2}",
        100.0 * MU[0], 100.0 * MU[1], 100.0 * MU[2], 100.0 * SD[0], 100.0 * SD[1], 100.0 * SD[2], 0.2, 0.1, 0.0);
    println!("covariance matrix, units of percent squared");
    for i in 0..3 { println!("  {:<7}{:10.4}{:10.4}{:10.4}", NAMES[i], 1e4 * s[i][0], 1e4 * s[i][1], 1e4 * s[i][2]); }
    for i in 0..3 { println!("  adjugate {:<7}{:12.4}{:12.4}{:12.4}", NAMES[i], d * 1e8 * si[i][0], d * 1e8 * si[i][1], d * 1e8 * si[i][2]); }
    println!("det {:.4}  det*inv(S)1 {:.4}  {:.4}  {:.4}  det*inv(S)mu {:.4}  {:.4}  {:.4}   (percent units)",
        d * 1e12, d * 1e8 * u[0], d * 1e8 * u[1], d * 1e8 * u[2], d * 1e10 * v[0], d * 1e10 * v[1], d * 1e10 * v[2]);
    println!("det*A {:.4}  det*B {:.4}  det*C {:.4}", d * 1e8 * f.a, d * 1e10 * f.b, d * 1e12 * f.c);
    println!("A {:.8}  B {:.8}  C {:.8}  Delta {:.8}   (percent units)", f.a * 1e-4, f.b * 1e-2, f.c, f.d * 1e-4);
    println!("{:<30}{}", "GMV road 1 closed form", pct(&wg));
    println!("{:<30}{}", "GMV road 2 Lagrange solve", pct(&wg_kkt));
    println!("{:<30}{}", "GMV road 3 search", pct(&wg_search));
    println!("GMV mean {:.4}%  variance {:.4} pp^2  sd {:.4}%  search mean {:.4}%", 100.0 * mg, 1e4 * vg, 100.0 * vg.sqrt(), 100.0 * mg_search);
    println!("GMV on $10,000 {}", (0..3).map(|i| format!("{} {:.2}", NAMES[i], 1e4 * wg[i])).collect::<Vec<_>>().join("  "));
    println!("{:<30}{}", "6% road 1 closed form", pct(&w6));
    println!("{:<30}{}", "6% road 2 Lagrange solve", pct(&w6_kkt));
    println!("{:<30}{}", "6% road 3 search", pct(&w6_search));
    println!("6% lambda {:.4}  eta {:.4}  variance {:.4} pp^2  sd direct {:.4}%  sd formula {:.4}%", 1e4 * lam6, 100.0 * eta6, 1e4 * v6, 100.0 * var(&s, &w6).sqrt(), 100.0 * v6.sqrt());
    println!("{:<30}{}", "shift per +1 point of target", pct(&shift));
    println!("frontier: target%  shares%   bonds%    gold%     sd%   shares+bonds sd%");
    for k in 0..13 {
        let m = 0.03 + 0.005 * k as f64;
        let w = f.w(m);
        println!("  {:6.2}  {:9.2}{:9.2}{:9.2}  {:7.2}  {:7.2}", 100.0 * m, 100.0 * w[0], 100.0 * w[1], 100.0 * w[2],
            100.0 * var(&s, &w).sqrt(), 100.0 * two_asset(m));
    }
    let mut sd_only = [[0.0; 3]; 3];
    for i in 0..3 { sd_only[i][i] = s[i][i]; }
    report("wrong: ignore correlations", &Front::new(&MU, &sd_only).gmv(), &s);
    let vs = v[0] + v[1] + v[2];
    report("wrong: normalise inv(S) mu", &[v[0] / vs, v[1] / vs, v[2] / vs], &s);
    let w8 = f.w(0.08);
    let cl = [w8[0].max(0.0), w8[1].max(0.0), w8[2].max(0.0)];
    let cs = cl[0] + cl[1] + cl[2];
    let wc = [cl[0] / cs, cl[1] / cs, cl[2] / cs];
    report("8% target, true frontier", &w8, &s);
    report("wrong: clamp shorts at 8%", &wc, &s);
    report("  frontier at clamped mean", &f.w(dot(&MU, &wc)), &s);
    report("wrong: lower branch 3.5%", &f.w(0.035), &s);
    report("wrong: leave gold out, 6%", &[0.5, 0.5, 0.0], &s);
    let (s_neg, s_g30) = (cov(SD, -0.2, 0.1, 0.0), cov([0.20, 0.06, 0.30], 0.2, 0.1, 0.0));
    report("try: shares-bonds rho -0.2", &Front::new(&MU, &s_neg).gmv(), &s_neg);
    report("try: gold sd 30%", &Front::new(&MU, &s_g30).gmv(), &s_g30);
    report("try: target 10%", &f.w(0.10), &s);

    let gap = |a: &[f64; 3], b: &[f64; 3]| (0..3).map(|i| (a[i] - b[i]).abs()).fold(0.0, f64::max);
    assert!(gap(&w6, &w6_kkt) < 1e-12, "closed form vs direct Lagrange solve");
    assert!(gap(&w6, &w6_search) < 1e-8, "closed form vs parabola search with no calculus");
    assert!(gap(&wg, &wg_search) < 1e-6, "GMV closed form vs two-level parabola search");
    assert!((mg_search - mg).abs() < 1e-7, "searched GMV mean vs B/A");
    assert!((var(&s, &w6_kkt) - v6).abs() < 1e-14, "direct variance vs (Am^2-2Bm+C)/Delta");
    assert!(vg.sqrt() < SD[1], "the mix beats the least risky asset");
    assert!((1e4 * vg - 3078000.0 / 99504.0).abs() < 1e-9, "GMV variance vs the hand table, det / (det*A)");
    println!("ALL CHECKS PASS");
}
