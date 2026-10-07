// Hull-White trinomial tree -- the same check as hull_white_trinomial_tree_check.py, in Rust, std only.
// Three roads: the fitted tree; Jamshidian's closed form on the Vasicek curve; an implicit grid in r.
use std::f64::consts::PI;
const A: f64 = 0.3; const SIG: f64 = 0.01; const THETA: f64 = 0.05; const R0: f64 = 0.04; const K: f64 = 0.047; const FACE: f64 = 1e6;

fn n_cdf(x: f64) -> f64 {                                   // bell-curve area left of x, power series
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut s, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 { k += 1.0; term *= x * x / (2.0 * k + 1.0); s += term; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn vbond(tau: f64, r: f64) -> f64 {                         // Vasicek zero-coupon bond
    let b = (1.0 - (-A * tau).exp()) / A;
    ((THETA - SIG * SIG / (2.0 * A * A)) * (b - tau) - SIG * SIG * b * b / (4.0 * A) - b * r).exp()
}
fn d(t: f64) -> f64 { vbond(t, R0) }

struct Tree { n: usize, dt: f64, m: f64, dx: f64, jmax: i64, alpha: Vec<f64>, w: Vec<i64>, q1: Vec<f64>, pmin: f64 }
impl Tree {
    fn br(&self, j: i64) -> [(i64, f64); 3] {               // (child, weight) for the three branches
        let m = j as f64 * self.m; let mm = m * m;
        if j >= self.jmax { [(j, 7.0/6.0 + (mm + 3.0*m)/2.0), (j-1, -1.0/3.0 - mm - 2.0*m), (j-2, 1.0/6.0 + (mm + m)/2.0)] }
        else if j <= -self.jmax { [(j+2, 1.0/6.0 + (mm - m)/2.0), (j+1, -1.0/3.0 - mm + 2.0*m), (j, 7.0/6.0 + (mm - 3.0*m)/2.0)] }
        else { [(j+1, 1.0/6.0 + (mm + m)/2.0), (j, 2.0/3.0 - mm), (j-1, 1.0/6.0 + (mm - m)/2.0)] }
    }
    fn back(&self, i: usize, v: &[f64]) -> Vec<f64> {        // one step of backward induction
        (-self.w[i]..=self.w[i]).map(|j| (-(self.alpha[i] + j as f64 * self.dx) * self.dt).exp()
            * self.br(j).iter().map(|&(k, p)| p * v[(k + self.w[i + 1]) as usize]).sum::<f64>()).collect()
    }
}
fn tree(n: usize, sig: f64, edges: bool, fit: bool) -> Tree {
    let dt = 6.0 / n as f64; let m = (-A * dt).exp() - 1.0;
    let dx = (3.0 * sig * sig * (1.0 - (-2.0 * A * dt).exp()) / (2.0 * A)).sqrt();
    let jmax = if edges { (0.184 / -m).ceil() as i64 } else { n as i64 };
    let w: Vec<i64> = (0..=n).map(|i| (i as i64).min(jmax)).collect();
    let mut t = Tree { n, dt, m, dx, jmax, alpha: vec![], w, q1: vec![], pmin: 1.0 };
    let mut q = vec![1.0];
    for i in 0..n {                                         // forward: fit alpha_i, push state prices on
        let wi = t.w[i];
        let a = if fit { ((-wi..=wi).map(|j| q[(j + wi) as usize] * (-(j as f64) * dx * dt).exp()).sum::<f64>()
            / d((i + 1) as f64 * dt)).ln() / dt } else { R0 };
        t.alpha.push(a);
        let mut nq = vec![0.0; (2 * t.w[i + 1] + 1) as usize];
        for j in -wi..=wi {
            for (k, p) in t.br(j) {
                t.pmin = t.pmin.min(p);
                nq[(k + t.w[i + 1]) as usize] += q[(j + wi) as usize] * p * (-(a + j as f64 * dx) * dt).exp();
            }
        }
        q = nq; if i == 0 { t.q1 = q.clone(); }
    }
    t
}
fn on_tree(t: &Tree, dates: &[usize], greedy: bool, show: bool, k: f64) -> f64 {
    let (n, s) = (t.n, t.n / 6);
    let mut p = std::collections::HashMap::new();           // zero bond prices at exercise layers
    for y in 2..7 {
        let mut v = vec![1.0; (2 * t.w[y * s] + 1) as usize];
        for i in (s..y * s).rev() { v = t.back(i, &v); if i % s == 0 { p.insert((i / s, y), v.clone()); } }
    }
    let mut v = vec![0.0; (2 * t.w[n] + 1) as usize];
    for i in (0..n).rev() {
        v = t.back(i, &v);
        let e = i / s;
        if i % s == 0 && dates.contains(&e) {
            let g: Vec<f64> = (0..v.len()).map(|x| (1.0 - p[&(e, 6)][x] - k * (e + 1..7).map(|y| p[&(e, y)][x]).sum::<f64>()).max(0.0)).collect();
            if show && (e == 1 || e == 5) {
                let rungs: Vec<i64> = if e == 1 { vec![0, 1, 2, 3] } else { vec![-1, 0, 1] };
                for j in rungs {
                    let x = (j + t.w[i]) as usize;
                    println!("year {} rung {:+}: rate {:.4}%  exercise {:10.2}  wait {:10.2}", e, j, 100.0 * (t.alpha[i] + j as f64 * t.dx), g[x] * FACE, v[x] * FACE);
                }
            }
            v = (0..v.len()).map(|x| if g[x] > 0.0 && (greedy || g[x] > v[x]) { g[x] } else { v[x] }).collect();
        }
    }
    v[0]
}
fn jamshidian(e: usize) -> f64 {                            // European payer as a put on a coupon bond
    let c = |y: usize| K + if y == 6 { 1.0 } else { 0.0 };
    let (mut lo, mut hi) = (-1.0, 1.0);
    for _ in 0..200 {                                       // bisection for the par rate r*
        let mid = 0.5 * (lo + hi);
        if (e + 1..7).map(|y| c(y) * vbond((y - e) as f64, mid)).sum::<f64>() > 1.0 { lo = mid } else { hi = mid }
    }
    let mut tot = 0.0;
    for y in e + 1..7 {
        let (ef, yf) = (e as f64, y as f64);
        let x = vbond(yf - ef, 0.5 * (lo + hi));
        let sp = SIG * ((1.0 - (-2.0 * A * ef).exp()) / (2.0 * A)).sqrt() * (1.0 - (-A * (yf - ef)).exp()) / A;
        let h = (d(yf) / (d(ef) * x)).ln() / sp + sp / 2.0;
        tot += c(y) * (x * d(ef) * n_cdf(-h + sp) - d(yf) * n_cdf(-h));
    }
    tot
}
fn pde(dates: &[usize]) -> f64 {                            // implicit grid for the term-structure equation
    let (nr, lo, hi, per_year) = (401usize, -0.11, 0.19, 500usize);
    let (dr, dt) = ((hi - lo) / (nr - 1) as f64, 1.0 / per_year as f64);
    let r: Vec<f64> = (0..nr).map(|i| lo + i as f64 * dr).collect();
    let mut v = vec![0.0f64; nr];
    for step in (0..=5 * per_year).rev() {
        let e = step / per_year;
        if step % per_year == 0 && dates.contains(&e) {
            for i in 0..nr { v[i] = v[i].max(1.0 - vbond((6 - e) as f64, r[i]) - K * (e + 1..7).map(|y| vbond((y - e) as f64, r[i])).sum::<f64>()); }
        }
        if step == 0 { break; }
        let (mut a, mut b, mut c) = (vec![0.0; nr], vec![0.0; nr], vec![0.0; nr]);
        let mut dd: Vec<f64> = v.iter().map(|x| x / dt).collect();
        for i in 0..nr {
            let (mu, df) = (A * (THETA - r[i]), 0.5 * SIG * SIG / (dr * dr));
            if i == 0 { b[i] = 1.0 / dt + r[i] + mu / dr; c[i] = -mu / dr; }
            else if i == nr - 1 { a[i] = mu / dr; b[i] = 1.0 / dt + r[i] - mu / dr; }
            else { a[i] = -(df - mu / (2.0 * dr)); b[i] = 1.0 / dt + r[i] + 2.0 * df; c[i] = -(df + mu / (2.0 * dr)); }
        }
        for i in 1..nr { let m = a[i] / b[i - 1]; b[i] -= m * c[i - 1]; dd[i] -= m * dd[i - 1]; }
        v[nr - 1] = dd[nr - 1] / b[nr - 1];
        for i in (0..nr - 1).rev() { v[i] = (dd[i] - c[i] * v[i + 1]) / b[i]; }
    }
    v[((R0 - lo) / dr).round() as usize]
}
fn main() {
    let all = [1usize, 2, 3, 4, 5];
    let (t, t30, t120) = (tree(60, SIG, true, true), tree(30, SIG, true, true), tree(120, SIG, true, true));
    println!("curve D(0.1), D(1), D(6)        {:.6} {:.6} {:.6}", d(0.1), d(1.0), d(6.0));
    println!("forward swap rate 1-into-5       {:.4}%", 100.0 * (d(1.0) - d(6.0)) / (2..7).map(|y| d(y as f64)).sum::<f64>());
    println!("tree 60: dt, M, dx               {:.6} {:.6} {:.6}", t.dt, t.m, t.dx); println!("tree 60: jmax                    {}", t.jmax);
    for j in [0i64, 7] {
        println!("tree 60: weights at rung {}       {}", j, t.br(j).iter().map(|&(_, p)| format!("{:.6}", p)).collect::<Vec<_>>().join(" "));
    }
    println!("tree 60: smallest weight         {:.6}", t.pmin);
    println!("edge: 0.184/-M, sqrt(2/3), 7M, 3*7M {:.2} {:.6} {:.6} {:.6}", 0.184 / -t.m, (2.0f64 / 3.0).sqrt(), 7.0 * t.m, 21.0 * t.m);
    let q1: Vec<String> = t.q1.iter().map(|q| format!("{:.6}", q)).collect();
    println!("step 1: alpha_0, Q(1,-1..+1)     {:.4}% {}", 100.0 * t.alpha[0], q1.join(" "));
    println!("step 2: alpha_1                  {:.4}%", 100.0 * t.alpha[1]);
    println!("chart, year                      0      1      2      3      4      5");
    for (lab, jj) in [("top", 1.0), ("centre", 0.0), ("bottom", -1.0)] {
        let row: Vec<String> = (0..60).step_by(10).map(|i| format!("{:6.2}", 100.0 * (t.alpha[i] + jj * t.w[i] as f64 * t.dx))).collect();
        println!("chart, {:<7} rate %          {}", lab, row.join(" "));
    }
    let eu: Vec<f64> = (1..6).map(jamshidian).collect();
    for e in 1..6 { println!("closed form European {}-into-{}    {:10.2}", e, 6 - e, eu[e - 1] * FACE); }
    let (e30, e60, e120) = (on_tree(&t30, &[1], false, false, K), on_tree(&t, &[1], false, false, K), on_tree(&t120, &[1], false, false, K));
    let (b30, b60, b120) = (on_tree(&t30, &all, false, false, K), on_tree(&t, &all, false, false, K), on_tree(&t120, &all, false, false, K));
    let (pe, pb) = (pde(&[1]), pde(&all));
    let rows = [("tree 30  European 1-into-5", e30), ("tree 60  European 1-into-5", e60), ("tree 120 European 1-into-5", e120),
        ("tree 2x120-60 European", 2.0 * e120 - e60), ("grid (PDE) European", pe),
        ("tree 30  Bermudan", b30), ("tree 60  Bermudan", b60), ("tree 120 Bermudan", b120),
        ("tree 2x120-60 Bermudan", 2.0 * b120 - b60), ("grid (PDE) Bermudan", pb), ("grid: Bermudan minus European", pb - pe),
        ("diff: grid - closed, European", pe - eu[0]), ("diff: tree 60 - closed, European", e60 - eu[0]),
        ("diff: tree 120 - closed, European", e120 - eu[0]), ("diff: tree 2x120-60 - closed", 2.0 * e120 - e60 - eu[0]),
        ("diff: tree 2x120-60 - grid, Bermudan", 2.0 * b120 - b60 - pb), ("diff: tree 60 Bermudan - European", b60 - e60),
        ("diff: tree 60 Bermudan - best European", b60 - eu.iter().cloned().fold(0.0, f64::max)),
        ("wrong: exercise when in the money", on_tree(&t, &all, true, false, K)),
        ("wrong: no curve fit, centre at 4%", on_tree(&tree(60, SIG, true, false), &all, false, false, K)),
        ("try: fixed rate 5%, tree 60 Bermudan", on_tree(&t, &all, false, false, 0.05)),
        ("try: sigma 2%, tree 60 Bermudan", on_tree(&tree(60, 0.02, true, true), &all, false, false, K))];
    for (lab, v) in rows { println!("{:<38} {:10.2}", lab, v * FACE); }
    let noedge = tree(60, SIG, false, true).pmin; println!("wrong: no edge turn, smallest weight   {:.6} ; middle weight < 0 from rung {}", noedge, ((2.0f64 / 3.0).sqrt() / -t.m).ceil());
    on_tree(&t, &all, false, true, K);
    let mut z6 = vec![1.0; 15]; for i in (0..60).rev() { z6 = t.back(i, &z6); }
    println!("6-year zero: tree rollback, curve    {:.9} {:.9}", z6[0], d(6.0));
    assert!((z6[0] - d(6.0)).abs() < 1e-12, "tree rollback reprices the 6-year zero on the curve");
    assert!((pe - eu[0]).abs() * FACE < 5.0, "grid European vs closed form");
    assert!((2.0 * e120 - e60 - eu[0]).abs() * FACE < 10.0, "extrapolated tree European vs closed form");
    assert!((2.0 * b120 - b60 - pb).abs() * FACE < 15.0, "extrapolated tree Bermudan vs grid Bermudan");
    let best = eu.iter().cloned().fold(0.0, f64::max); assert!(pb > best && b60 > best, "Bermudan worth more than its best European");
    assert!(t.pmin > 0.0 && 0.0 > noedge && (-7i64..=7).all(|j| (0..3).all(|e| (t.br(j).iter().map(|&(k, p)| p * ((k - j) as f64).powi(e)).sum::<f64>()
        - [1.0, j as f64 * t.m, 1.0 / 3.0 + (j as f64 * t.m).powi(2)][e as usize]).abs() < 1e-12)), "weights positive; every rung's branches match the step's mean and variance");
    println!("ALL CHECKS PASS");
}
