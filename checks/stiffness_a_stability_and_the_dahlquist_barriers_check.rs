// Stiffness and the Dahlquist barriers: the same check as the Python, in Rust.  No crates.  A reaction A -> B -> C
// (rates 1e6 and 1 per s, illustrative) stepped five ways; stability on y' = lam*y; the BDF family; both barriers.
use std::f64::consts::PI;
const K1: f64 = 1e6; const K2: f64 = 1.0;                          // fast and slow rates, per s
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }                // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }   fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }   fn scale(a: C, s: f64) -> C { c(a.re * s, a.im * s) }
fn div(p: C, q: C) -> C { let d = q.re * q.re + q.im * q.im; let n = mul(p, c(q.re, -q.im)); c(n.re / d, n.im / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }   fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
fn re(v: &[f64]) -> Vec<C> { v.iter().map(|x| c(*x, 0.0)).collect() }
fn fmax(v: impl Iterator<Item = f64>) -> f64 { v.fold(f64::MIN, f64::max) }
fn sci(v: f64, d: usize) -> String { format!("{:.*e}", d, v) }     // 1.234e-5
fn rate(a: f64, b: f64) -> (f64, f64) { (-K1 * a, K1 * a - K2 * b) }
fn solve(cc: f64, h: f64, ra: f64, rb: f64) -> (f64, f64) {     // (I - c h J) y = r; J is lower triangular
    let a = ra / (1.0 + cc * h * K1); (a, (rb + cc * h * K1 * a) / (1.0 + cc * h * K2)) }
fn run(m: &str, h: f64, n: usize) -> (f64, f64) {                 // n steps of size h from a = 1, b = 0
    let (mut a, mut b, mut prev): (f64, f64, Option<(f64, f64)>) = (1.0, 0.0, None);
    for _ in 0..n {
        let (na, nb) = match (m, prev) {
            ("FE", _) => { let (da, db) = rate(a, b); (a + h * da, b + h * db) }
            ("RK4", _) => {
                let p = rate(a, b); let q = rate(a + h / 2.0 * p.0, b + h / 2.0 * p.1);
                let r = rate(a + h / 2.0 * q.0, b + h / 2.0 * q.1); let s = rate(a + h * r.0, b + h * r.1);
                (a + h / 6.0 * (p.0 + 2.0 * q.0 + 2.0 * r.0 + s.0), b + h / 6.0 * (p.1 + 2.0 * q.1 + 2.0 * r.1 + s.1)) }
            ("TR", _) => { let (da, db) = rate(a, b); solve(0.5, h, a + h / 2.0 * da, b + h / 2.0 * db) }
            ("BDF2", Some(pr)) => solve(2.0 / 3.0, h, (4.0 * a - pr.0) / 3.0, (4.0 * b - pr.1) / 3.0),
            _ => solve(1.0, h, a, b),                               // BE, and the BE step that starts BDF2
        };
        prev = Some((a, b)); a = na; b = nb;
    }
    (a, b) }
fn pv(cs: &[C], x: C) -> C { let mut p = c(0.0, 0.0); for v in cs.iter().rev() { p = add(mul(p, x), *v); } p }   // Horner
fn roots(c0: &[C]) -> Vec<C> {                                      // Durand-Kerner: every root of sum c[j] x^j
    let (cs, n): (Vec<C>, usize) = (c0.iter().map(|x| div(*x, c0[c0.len() - 1])).collect(), c0.len() - 1);
    if n == 1 { return vec![scale(cs[0], -1.0)]; }
    let mut z = vec![c(1.0, 0.0)];
    while z.len() < n { let l = z[z.len() - 1]; z.push(mul(l, c(0.4, 0.9))); }
    for _ in 0..800 {
        let new: Vec<C> = (0..n).map(|i| { let mut q = c(1.0, 0.0);
            for j in 0..n { if j != i { q = mul(q, sub(z[i], z[j])); } }
            sub(z[i], div(pv(&cs, z[i]), q)) }).collect();
        let moved = fmax(new.iter().zip(&z).map(|(u, v)| abs(sub(*u, *v))));
        z = new; if moved < 1e-15 { break; }
    }
    z }
fn r4(z: C) -> C { pv(&re(&[1.0, 1.0, 1.0 / 2.0, 1.0 / 6.0, 1.0 / 24.0]), z) }   // RK4's factor per step on y' = lam*y
fn meth(m: &str) -> (Vec<f64>, Vec<f64>) { match m {
    "FE" => (vec![-1.0, 1.0], vec![1.0, 0.0]), "AB2" => (vec![0.0, -1.0, 1.0], vec![-0.5, 1.5, 0.0]),
    "BE" => (vec![-1.0, 1.0], vec![0.0, 1.0]), "TR" => (vec![-1.0, 1.0], vec![0.5, 0.5]),
    "AM2" => (vec![0.0, -1.0, 1.0], vec![-1.0 / 12.0, 8.0 / 12.0, 5.0 / 12.0]), "BDF2" => (vec![0.5, -2.0, 1.5], vec![0.0, 0.0, 1.0]),
    _ => (vec![-1.0 / 3.0, 1.5, -3.0, 11.0 / 6.0], vec![0.0, 0.0, 0.0, 1.0]) } }
fn amp(m: &str, z: C) -> f64 {                                      // largest root size of the characteristic polynomial
    if m == "RK4" { return abs(r4(z)); }
    let (al, be) = meth(m); fmax(roots(&al.iter().zip(&be).map(|(u, v)| sub(c(*u, 0.0), scale(z, *v))).collect::<Vec<C>>()).iter().map(|x| abs(*x)))
}
fn edge(m: &str) -> Option<f64> {                                   // left end of the stable stretch of the real axis
    if amp(m, c(-1e4, 0.0)) <= 1.0 { return None; }
    let (mut lo, mut hi) = (-50.0f64, -1e-6f64);
    while hi - lo > 1e-13 { let mid = (lo + hi) / 2.0; if amp(m, c(mid, 0.0)) > 1.0 { lo = mid } else { hi = mid } }
    Some(hi) }
fn consts(al: &[f64], be: &[f64]) -> (i32, f64) {                  // order p and error constant C_(p+1)/sigma(1)
    let mut f1 = 1.0;
    for q in 1..9u32 { f1 *= q as f64;
        let s1 = al.iter().enumerate().fold(0.0, |s, (j, a)| s + a * (j as i64).pow(q) as f64);
        let s2 = be.iter().enumerate().fold(0.0, |s, (j, b)| s + b * (j as i64).pow(q - 1) as f64);
        let cq = s1 / f1 - q as f64 * s2 / f1;
        if cq.abs() > 1e-10 { return (q as i32 - 1, cq / be.iter().fold(0.0, |s, b| s + b)); }
    }
    (0, 0.0) }
fn main() {
    let (tr, dt) = (-K1 - K2, K1 * K2);
    let (l1, l2) = ((tr - (tr * tr - 4.0 * dt).sqrt()) / 2.0, (tr + (tr * tr - 4.0 * dt).sqrt()) / 2.0);
    println!("J = [[-{:.0}, 0], [{:.0}, -{:.0}]]; eigenvalues from trace and determinant: {:.1} and {:.6} per s; stiffness ratio {:.0}", K1, K1, K2, l1, l2, l1 / l2);
    assert!((l1 + K1).abs() < 1e-6 && (l2 + K2).abs() < 1e-9);
    let bt = K1 / (K1 - K2) * ((-K2).exp() - (-K1).exp()); println!("true B at 1 s: {:.10}; target: an error under 1e-4", bt);
    let mut xr = -2.8f64;                                           // second road to RK4's edge: Newton on (R(x) - 1)/x = 0
    for _ in 0..50 { xr -= (1.0 + xr * (1.0 / 2.0 + xr * (1.0 / 6.0 + xr / 24.0))) / (1.0 / 2.0 + xr * (1.0 / 3.0 + xr / 8.0)); }
    let (efe, erk, eab) = (edge("FE").unwrap(), edge("RK4").unwrap(), edge("AB2").unwrap());
    assert!((efe + 2.0).abs() < 1e-9 && (eab + 1.0).abs() < 1e-9 && (erk - xr).abs() < 1e-9);
    println!("explicit step limits h < -edge/1e6: FE {} s, RK4 {} s (Newton edge {:.6}), AB2 {} s", sci(-efe / K1, 3), sci(-erk / K1, 3), xr, sci(-eab / K1, 3));
    println!("run to 1 s           steps    evals  A at 1 s    B error");
    for (m, n, ev) in [("FE", 525000usize, 1usize), ("RK4", 360000, 4), ("BE", 100, 1), ("TR", 100, 1), ("BDF2", 100, 1)] {
        let (a, b) = run(m, 1.0 / n as f64, n);
        println!("{:>4}, h = {:>8}  {:>6}  {:>7}  {:>10}  {:>10}", m, sci(1.0 / n as f64, 2), n, n * ev, sci(a, 3), sci(b - bt, 3));
        if m == "BDF2" { assert!((b - bt).abs() < 1e-4 && 1e-4 < (run("BE", 0.01, 100).1 - bt).abs()); }
        if m == "FE" { assert!((b - bt - K1 / (K1 - K2) * ((1.0 - K2 / n as f64).powi(n as i32) - (1.0 - K1 / n as f64).powi(n as i32) - (-K2).exp())).abs() < 1e-10); }   // FE's exact discrete B
        if m == "TR" { assert!((a - ((1.0 - K1 / (2.0 * n as f64)) / (1.0 + K1 / (2.0 * n as f64))).powi(n as i32)).abs() < 1e-12); }   // TR's factor on A, n times
    }
    let fa = run("FE", 2.1e-6, 476).0; println!("FE at h = 2.1e-6 (factor -1.1), 476 steps = 1 ms: A = {}", sci(fa, 3)); assert!(1e19 < fa.abs() && fa.abs() < 1e21);
    let eb: Vec<f64> = ["BE", "BDF2"].iter().flat_map(|m| [100usize, 200, 400].map(|n| (run(m, 1.0 / n as f64, n).1 - bt).abs())).collect();
    let (pb, pd) = ((eb[1] / eb[2]).ln() / 2f64.ln(), (eb[4] / eb[5]).ln() / 2f64.ln()); assert!((pb - 1.0).abs() < 0.02 && (pd - 2.0).abs() < 0.02);
    let j3 = |v: &[f64]| v.iter().map(|x| sci(*x, 3)).collect::<Vec<_>>().join(", ");
    println!("B errors at h = 0.01, 0.005, 0.0025: BE {} (order {:.3}); BDF2 {} (order {:.3})", j3(&eb[..3]), pb, j3(&eb[3..]), pd);
    let z = -1e4f64;                                                // h = 0.01 on the fast rate
    println!("one step at z = h*lam = {:.0}: FE {:.0}, RK4 {}, BE {}, TR {:.5}, BDF2 root size {:.7}", z, 1.0 + z, sci(r4(c(z, 0.0)).re, 3),
             sci(amp("BE", c(z, 0.0)), 3), div(c(1.0 + z / 2.0, 0.0), c(1.0 - z / 2.0, 0.0)).re, amp("BDF2", c(z, 0.0)));
    assert!((amp("BDF2", c(z, 0.0)) - (0.5 / (1.5 - z)).sqrt()).abs() < 1e-12);
    let th: Vec<f64> = (0..4000).map(|i| PI * (i as f64 + 0.5) / 4000.0).collect();
    let grid: Vec<C> = (0..21).flat_map(|s| (0..60).map(move |i| { let a = PI * (0.5 + (i as f64 + 0.5) / 60.0);
        scale(c(a.cos(), a.sin()), 10f64.powf(s as f64 / 4.0 - 2.0)) })).collect();
    println!("method  p  C/sigma(1)  real edge  locus min Re z  worst grid amp  A-stable  amp at -1e8");
    for m in ["FE", "AB2", "RK4", "AM2", "BE", "TR", "BDF2", "BDF3"] {
        let (al, be) = meth(m);
        let (p, cst) = if m != "RK4" { let (p, k) = consts(&al, &be); (p, Some(k)) } else { (4, None) };
        let wg = fmax(grid.iter().map(|g| amp(m, *g)));
        let lm = if m != "RK4" {                                    // road 1: smallest Re z on the locus z = rho/sigma
            th.iter().map(|t| div(pv(&re(&al), cis(*t)), pv(&re(&be), cis(*t))).re).fold(f64::MAX, f64::min)
        } else { th.iter().step_by(20).map(|t| roots(&[sub(c(1.0, 0.0), cis(*t)), c(1.0, 0.0), c(1.0 / 2.0, 0.0), c(1.0 / 6.0, 0.0), c(1.0 / 24.0, 0.0)])
                .iter().map(|x| x.re).fold(f64::MAX, f64::min)).fold(f64::MAX, f64::min) };
        let (ok, eg) = (wg <= 1.0 + 1e-9, edge(m));               // the locus's leftmost point: the real edge, BDF3's -1/12, or 0
        assert!(ok == (lm >= -1e-9) && (lm - eg.unwrap_or(if m == "BDF3" { -1.0 / 12.0 } else { 0.0 })).abs() < 1e-5);
        assert!(!ok || (p <= 2 && (p < 2 || cst.unwrap() <= -1.0 / 12.0 + 1e-12)));   // second barrier, on each A-stable one
        let (ed, cs) = (eg.map_or("-inf".to_string(), |x| format!("{:.4}", x)), cst.map_or("-".to_string(), |x| format!("{:.5}", x)));
        let ws = if wg < 100.0 { format!("{:.4}", wg) } else { sci(wg, 2) };
        println!("{:>6}  {}  {:>10}  {:>9}  {:>13}  {:>14}  {:>8}  {}", m, p, cs, ed, format!("{:.5}", if lm.abs() > 1e-9 { lm } else { 0.0 }), ws,
                 if ok { "yes" } else { "no" }, sci(amp(m, c(-1e8, 0.0)), 2));
    }
    let ph: Vec<f64> = ["TR", "BDF2", "AM2"].iter().map(|m| { let (al, be) = meth(m);    // the proof's phi at zeta = 1.01
        div(pv(&re(&be), c(1.01, 0.0)), pv(&re(&al), c(1.01, 0.0))).re - 2.01 / (2.0 * (1.01 - 1.0)) }).collect();
    println!("proof: Re phi(1.01) = Re[sigma/rho - (zeta+1)/(2(zeta-1))]: TR {}, BDF2 {}, AM2 {}", sci(ph[0], 3), sci(ph[1], 3), sci(ph[2], 3));
    assert!(ph[2] < 0.0 && 0.0 < ph[1] && (ph[2] + 0.01 / 12.0).abs() < 2e-4 && (ph[1] - 0.0025).abs() < 3e-4);
    println!("BDF k  max |root of rho| besides 1  alpha (deg)");
    for k in 1..8usize {
        let mut rho = vec![0.0f64; k + 1];
        for j in 1..=k {                                            // rho = sum (1/j) x^(k-j) (x-1)^j
            let mut t = vec![1.0f64]; for _ in 0..j { t.insert(0, 0.0); t = (0..t.len()).map(|i| t[i] - if i + 1 < t.len() { t[i + 1] } else { 0.0 }).collect(); }
            for (i, v) in t.iter().enumerate() { rho[i + k - j] += v / j as f64; }
        }
        let mut rs = roots(&re(&rho)); rs.sort_by(|x, y| abs(sub(*x, c(1.0, 0.0))).partial_cmp(&abs(sub(*y, c(1.0, 0.0)))).unwrap());
        let big = rs[1..].iter().map(|x| abs(*x)).fold(0.0, f64::max);
        let mut al = PI / 2.0;                                      // A(alpha): smallest angle of the locus from the negative real axis
        for i in 1..20000 { let t = PI * i as f64 / 20000.0; let w = div(pv(&re(&rho), cis(t)), cis(k as f64 * t));
            if w.re < 0.0 { al = al.min(w.im.abs().atan2(-w.re)); } }
        al *= 180.0 / PI;
        println!("    {}  {:28.4}  {:>11}", k, big, if big < 1.0 { format!("{:.2}", al) } else { "unstable".to_string() });
        assert!((big > 1.0) == (k == 7));
        assert!(k > 6 || (al - [90.0, 90.0, 86.03, 73.35, 51.84, 17.84][k - 1]).abs() < 0.006);
    }
    let (mut al, mut be) = (vec![], vec![]);
    for k in 1..4usize {                                            // first barrier: the highest-order implicit k-step formula
        let n = 2 * k + 1;                                          // unknowns a_0..a_(k-1), b_0..b_k; a_k = 1
        let mut a: Vec<Vec<f64>> = (0..n as u32).map(|q| { let mut row: Vec<f64> = (0..k as i64).map(|j| j.pow(q) as f64).collect();
            for j in 0..=k as i64 { row.push(if q > 0 { -((q as i64 * j.pow(q - 1)) as f64) } else { 0.0 }); }
            row.push(-((k as i64).pow(q) as f64)); row }).collect();
        for cc in 0..n {                                            // Gaussian elimination with partial pivoting
            let mut piv = cc; for r in cc..n { if a[r][cc].abs() > a[piv][cc].abs() { piv = r; } }
            a.swap(cc, piv);
            for r in 0..n { if r != cc { let f = a[r][cc] / a[cc][cc]; for j in 0..=n { a[r][j] -= f * a[cc][j]; } } }
        }
        let x: Vec<f64> = (0..n).map(|i| a[i][n] / a[i][i]).collect();
        al = x[..k].to_vec(); al.push(1.0); be = x[k..].to_vec();
        let (p, big) = (consts(&al, &be).0, fmax(roots(&re(&al)).iter().map(|r| abs(*r))));
        println!("first barrier, k = {}: order {}, rho = {}; largest |root| {:.4}", k, p, al.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", "), big);
        assert!(p == 2 * k as i32 && (big > 1.0 + 1e-9) == (p > if k % 2 == 0 { k as i32 + 2 } else { k as i32 + 1 }));
    }
    let h = 0.1;                                                    // run the order-6 three-step formula on y' = -y
    let mut ys: Vec<f64> = (0..3).map(|i| (-0.1 * i as f64).exp()).collect();
    for _ in 3..31 { let l = ys.len();
        let (sa, sb) = (0..3).fold((0.0, 0.0), |(sa, sb), j| (sa + al[j] * ys[l - 3 + j], sb + be[j] * ys[l - 3 + j]));
        ys.push((-sa + h * -sb) / (1.0 + h * be[3])); }
    println!("order-6 three-step formula on y' = -y, h = 0.1: error at steps 10, 20, 30: {}", [10, 20, 30].map(|i| sci(ys[i] - (-h * i as f64).exp(), 3)).join(", "));
    assert!((ys[30] - (-3f64).exp()).abs() > 1.0);
    let (b2, mut w) = (re(&meth("BDF2").0), c(0.0, f64::MIN));
    for t in &th { let v = div(pv(&b2, cis(*t)), cis(2.0 * t)); if v.im > w.im { w = v; } }
    assert!((abs(r4(c(0.0, 8f64.sqrt()))) - 1.0).abs() < 1e-12 && (w.im - (3f64.sqrt() / 2.0).sqrt() * (3.0 + 3f64.sqrt()) / 2.0).abs() < 1e-6);
    println!("figure, 34 px per unit, origin (140, 120): FE centre (106.0, 120.0) radius 34.0; RK4 edge ({:.1}, 120.0), imaginary tips +-{:.4} at y {:.1}; BDF2 locus right end {:.0} at (276.0, 120.0), top {:.4} + {:.4}i at ({:.1}, {:.1})",
             140.0 + 34.0 * erk, 8f64.sqrt(), 120.0 - 34.0 * 8f64.sqrt(), pv(&b2, c(-1.0, 0.0)).re, w.re, w.im, 140.0 + 34.0 * w.re, 120.0 - 34.0 * w.im);
    println!("ALL CHECKS PASS");
}
