// Convergence to equilibrium -- the check behind the card.  Rust std only.
// Weather in states 0 sunny, 1 cloudy, 2 rainy; one step is one day.
// Road 1: exact matrix powers in whole numbers (10^n P^n).  Road 2: the eigenvalue
// formula P^n = Pi + (1/2)^n A2 + (3/10)^n A3.  Road 3: a seeded simulation of the
// coupling used in the proof, and of a month of weather.
type M = [[i128; 3]; 3]; // exact whole numbers
type F = [[f64; 3]; 3]; // floating point
const P10: M = [[8, 1, 1], [5, 4, 1], [1, 3, 6]]; // P in tenths
const PI5: [i128; 3] = [3, 1, 1]; // stationary law in fifths: 0.6, 0.2, 0.2

fn mat_mul(a: &M, b: &M) -> M { let mut c = [[0i128; 3]; 3]; for i in 0..3 { for j in 0..3 { for k in 0..3 { c[i][j] += a[i][k] * b[k][j]; } } } c }
fn fmul(a: &F, b: &F) -> F { let mut c = [[0.0f64; 3]; 3]; for i in 0..3 { for j in 0..3 { for k in 0..3 { c[i][j] += a[i][k] * b[k][j]; } } } c }
fn powers(p: &M, top: usize) -> Vec<M> { // exact whole-number powers of p, n = 0..top
    let mut out = Vec::new();
    let mut a: M = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
    for _ in 0..=top { out.push(a); a = mat_mul(&a, p); }
    out
}
fn ten(n: usize) -> i128 { 10i128.pow(n as u32) }
fn tv(u: &[f64; 3], v: &[f64; 3]) -> f64 { 0.5 * (0..3).map(|j| (u[j] - v[j]).abs()).sum::<f64>() }
fn d_exact(a: &M, n: usize, pin: [i128; 3], pid: i128) -> f64 { // worst-start distance to pi = pin / pid
    let num = (0..3).map(|i| (0..3).map(|j| (pid * a[i][j] - pin[j] * ten(n)).abs()).sum::<i128>()).max().unwrap();
    num as f64 / (2 * pid * ten(n)) as f64
}
fn sci(x: f64) -> String { // Python's {:.3e} layout: two-digit signed exponent
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    format!("{}e{}{:0>2}", m, if e.starts_with('-') { '-' } else { '+' }, e.trim_start_matches('-'))
}
fn pw(x: f64, n: usize) -> f64 { let mut out = 1.0; for _ in 0..n { out *= x; } out }
fn pn(a: &M, n: usize) -> F {
    let mut f = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { f[i][j] = a[i][j] as f64 / ten(n) as f64; } }
    f
}
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 { // SplitMix64, top 53 bits as a uniform in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn pick(w: &[i128; 3], u: f64) -> usize { // state drawn from weights w, by one uniform u
    let t = u * (w[0] + w[1] + w[2]) as f64;
    let mut acc = 0i128;
    for j in 0..3 { acc += w[j]; if t < acc as f64 { return j; } }
    2
}

fn main() {
    // ---- road 1: exact powers ----
    let a = powers(&P10, 31);
    for j in 0..3 { assert_eq!((0..3).map(|i| PI5[i] * P10[i][j]).sum::<i128>(), 10 * PI5[j]); } // pi P = pi
    let d: Vec<f64> = (0..32).map(|n| d_exact(&a[n], n, PI5, 5)).collect();

    // ---- road 2: eigenvalues from trace and determinant, then Sylvester's formula ----
    let mut p = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { p[i][j] = P10[i][j] as f64 / 10.0; } }
    let tr = p[0][0] + p[1][1] + p[2][2];
    let det = p[0][0] * (p[1][1] * p[2][2] - p[1][2] * p[2][1]) - p[0][1] * (p[1][0] * p[2][2] - p[1][2] * p[2][0])
        + p[0][2] * (p[1][0] * p[2][1] - p[1][1] * p[2][0]);
    let (s, pr) = (tr - 1.0, det); // the other two eigenvalues: sum s, product pr
    let l2 = (s + (s * s - 4.0 * pr).sqrt()) / 2.0;
    let l3 = (s - (s * s - 4.0 * pr).sqrt()) / 2.0;
    let shift = |lb: f64| { let mut m = p; for i in 0..3 { m[i][i] -= lb; } m };
    let proj = |la: f64, lb: f64, lc: f64| { // (P - lb I)(P - lc I) / ((la - lb)(la - lc))
        let mut m = fmul(&shift(lb), &shift(lc));
        for i in 0..3 { for j in 0..3 { m[i][j] /= (la - lb) * (la - lc); } }
        m
    };
    let (pi, a2, a3) = (proj(1.0, l2, l3), proj(l2, 1.0, l3), proj(l3, 1.0, l2));
    let mut worst: f64 = 0.0;
    for n in 0..31 {
        let q = pn(&a[n], n);
        for i in 0..3 { for j in 0..3 {
            let sp = pi[i][j] + pw(l2, n) * a2[i][j] + pw(l3, n) * a3[i][j];
            worst = worst.max((sp - q[i][j]).abs());
        } }
    }
    assert!(worst < 1e-12); // the two roads agree on every entry, 31 days
    let eps = (0..3).map(|j| (0..3).map(|i| P10[i][j]).min().unwrap()).sum::<i128>() as f64 / 10.0; // Doeblin's common part
    println!("eigenvalues from trace {:.1} and determinant {:.2}: other two sum {:.1}, product {:.2}, root {:.1}: 1, {:.6}, {:.6}", tr, det, s, pr, (s * s - 4.0 * pr).sqrt(), l2, l3);
    println!("stationary law: sunny {:.6} cloudy {:.6} rainy {:.6}", pi[0][0], pi[0][1], pi[0][2]);
    let rows: Vec<String> = P10.iter().map(|r| r.iter().map(|&x| format!("{:.1}", x as f64 / 10.0)).collect::<Vec<_>>().join(" ")).collect();
    println!("weather P, rows sunny cloudy rainy: {}", rows.join(" | "));
    println!("common part of the rows eps = {:.1}; guaranteed factor 1 - eps = {:.1}", eps, 1.0 - eps);
    println!("roads 1 and 2 agree on all 9 entries, days 0..30, to 1e-12: {}; d(31)/d(30) = {:.6}; d(30)/0.5^30 = {:.4}", if worst < 1e-12 { "yes" } else { "no" }, d[31] / d[30], d[30] / pw(0.5, 30));

    // ---- the forecasts: chance of sun on day n from each start ----
    println!("day  sun|sunny  sun|cloudy  sun|rainy   d(n) exact  bound 0.7^n  0.5^n");
    for n in (0..11).chain([14, 30]) {
        let q = pn(&a[n], n);
        println!("{:3}  {:9.6}  {:10.6}  {:9.6}   {}  {}  {}", n, q[0][0], q[1][0], q[2][0], sci(d[n]), sci(pw(0.7, n)), sci(pw(0.5, n)));
    }
    for n in 0..32 { assert!(d[n] <= pw(0.7, n) + 1e-15); } // the guarantee holds every day
    assert!((d[31] / d[30] - l2).abs() < 1e-6); // the true rate is lambda2
    println!("by hand, rainy start: sun on day n = 0.6 + a 0.5^n + b 0.3^n, a = {:.4}, b = {:.4}", a2[2][0], a3[2][0]);
    assert!((a2[2][0] + 1.6).abs() < 1e-9 && (a3[2][0] - 1.0).abs() < 1e-9); // the by-hand weights a, b
    for n in [1, 2, 3, 7] {
        let (t2, t3) = (a2[2][0] * pw(l2, n), a3[2][0] * pw(l3, n));
        println!("  day {}: a 0.5^n = {:.7}  b 0.3^n = {:.7}  sun = {:.7}", n, t2, t3, pi[2][0] + t2 + t3);
    }
    for lim in [0.25, 0.01] {
        let ex = (0..200).find(|&n| d[n.min(31)] <= lim).unwrap();
        let bd = (0..200).find(|&n| pw(1.0 - eps, n) <= lim).unwrap();
        println!("first day d(n) <= {}: exact {}, from bound {}", lim, ex, bd);
        assert!(bd as f64 == (lim.ln() / (1.0 - eps).ln()).ceil()); // the bound's day, two ways
        if lim == 0.01 { assert!(ex == 8); } // the exact day, from P^n
    }
    let row = |f: &dyn Fn(usize) -> f64| (0..11).map(|n| format!("{:.2}", f(n))).collect::<Vec<_>>().join(" ");
    println!("chart, sun|sunny {}", row(&|n| pn(&a[n], n)[0][0]));
    println!("chart, sun|cloudy {}", row(&|n| pn(&a[n], n)[1][0]));
    println!("chart, sun|rainy {}", row(&|n| pn(&a[n], n)[2][0]));

    // ---- road 3: simulation, SplitMix64 seed 20260929 ----
    let mut rng = Rng(20260929);
    let mut res = P10;
    for i in 0..3 { for j in 0..3 { res[i][j] -= 1; } } // what is left after the common part
    let (nn, days) = (20000usize, 8usize);
    let mut alive = vec![0usize; days + 1]; // pairs not yet met after n days
    for _ in 0..nn {
        let (mut x, mut y) = (0usize, 2usize); // one copy starts sunny, the other rainy
        for n in 1..=days {
            if x == y {
                x = pick(&P10[x], rng.next()); y = x;
            } else if rng.next() < eps {
                x = pick(&[1, 1, 1], rng.next()); y = x; // the shared draw: both land together
            } else {
                x = pick(&res[x], rng.next()); y = pick(&res[y], rng.next());
            }
            if x != y { alive[n] += 1; }
        }
    }
    println!("coupling, {} pairs from sunny and rainy: n, P(not met) +- se, bound 0.7^n, exact P(not met), exact TV", nn);
    let mut unmet = [[0.0f64; 3]; 3]; unmet[0][2] = 1.0; // exact chance on each unmet pair (x, y); day 0 sunny, rainy
    for n in 1..7 {
        let pr = alive[n] as f64 / nn as f64;
        let se = (pr * (1.0 - pr) / nn as f64).sqrt();
        let q = pn(&a[n], n);
        let gap = tv(&q[0], &q[2]);
        let mut nx = [[0.0f64; 3]; 3];
        for u in 0..3 { for w in 0..3 { if u != w { for x in 0..3 { for y in 0..3 { nx[u][w] += unmet[x][y] * (1.0 - eps) * res[x][u] as f64 * res[y][w] as f64 / (res[x].iter().sum::<i128>() * res[y].iter().sum::<i128>()) as f64; } } } } }
        unmet = nx;
        let exm = unmet.iter().map(|r| r.iter().sum::<f64>()).sum::<f64>();
        println!("  {}  {:.4} +- {:.4}  {:.4}  {:.4}  {:.4}", n, pr, se, pw(0.7, n), exm, gap);
        assert!(gap <= pr + 3.0 * se && pr <= pw(0.7, n) + 3.0 * se); // coupling inequality, Doeblin bound
        assert!((exm - gap).abs() < 1e-12); // for this pair the coupling is exact
    }
    let mut sunny = 0usize;
    for _ in 0..nn {
        let mut x = 2usize;
        for _ in 0..30 { x = pick(&P10[x], rng.next()); }
        if x == 0 { sunny += 1; }
    }
    let (pr, se) = (sunny as f64 / nn as f64, ((sunny as f64 / nn as f64) * (1.0 - sunny as f64 / nn as f64) / nn as f64).sqrt());
    println!("month from rainy, {} runs: sunny on day 30 {:.4} +- {:.4}, exact {:.6}", nn, pr, se, pn(&a[30], 30)[2][0]);
    assert!((pr - 0.6).abs() < 4.0 * se);

    // ---- what breaks ----
    let c = powers(&[[0, 10, 0], [0, 0, 10], [10, 0, 0]], 30); // sunny -> cloudy -> rainy -> sunny, period 3
    println!("breaks, cycle: d(29) {:.6}  d(30) {:.6}", d_exact(&c[29], 29, [1, 1, 1], 3), d_exact(&c[30], 30, [1, 1, 1], 3));
    for n in 0..31 { assert!((d_exact(&c[n], n, [1, 1, 1], 3) - 2.0 / 3.0).abs() < 1e-12); } // never settles
    let r = powers(&[[8, 2, 0], [5, 5, 0], [0, 0, 10]], 30); // rainy never leaves, the others never reach it
    println!("breaks, two climates: TV(start sunny, start rainy) day 30 {:.6}", tv(&pn(&r[30], 30)[0], &pn(&r[30], 30)[2]));
    for n in 0..31 { assert!((tv(&pn(&r[n], n)[0], &pn(&r[n], n)[2]) - 1.0).abs() < 1e-12); } // the starts never meet
}
