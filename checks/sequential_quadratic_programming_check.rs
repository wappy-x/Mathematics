// Sequential quadratic programming -- the same check as the Python, in Rust.  No crates.
// Three pumps.  Choose their powers p_i (kW) to MINIMISE total power f(p) = p1 + p2 + p3,
// subject to: demand, flow Q(p) = sum sqrt(p_i / a_i) = 150 L/s, and head H(p) = sum k_i sqrt(p_i / a_i) >= 35 m,
// held as an equality.  Written c(p) = (150 - Q, 35 - H): c_1 = 0, c_2 <= 0, prices mu = (nu, lam).
// Road 1: SQP, each step a quadratic model solved through its KKT linear system, guarded by an l1 merit function.
// Road 2: the same problem in flows, where it is a convex quadratic with straight rules: one linear solve.
// Road 3: a scan of every feasible plan on a 0.1 L/s grid of flows: demand met, head at least 35 m.
const A: [f64; 3] = [0.02, 0.03, 0.05]; // kW per (L/s)^2
const K: [f64; 3] = [0.1, 0.2, 0.4]; // m of head per L/s
const DEM: f64 = 150.0; const HEAD: f64 = 35.0; const RHO: f64 = 20.0;
type V = Vec<f64>;

fn gauss(m0: &[V], r: &[f64]) -> Option<V> { // solve M z = r by elimination with row swaps
    let n = r.len();
    let mut m: Vec<V> = m0.iter().zip(r).map(|(row, v)| { let mut x = row.clone(); x.push(*v); x }).collect();
    for c in 0..n {
        let mut p = c;
        for i in c..n { if m[i][c].abs() > m[p][c].abs() { p = i; } }
        if m[p][c].abs() < 1e-12 { return None; }
        m.swap(c, p);
        for i in 0..n {
            if i == c { continue; }
            let (f, rc) = (m[i][c] / m[c][c], m[c].clone());
            for (u, v) in m[i].iter_mut().zip(rc) { *u -= f * v; }
        }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}
fn flows(p: &[f64]) -> V { (0..3).map(|i| (p[i] / A[i]).sqrt()).collect() }
fn miss(p: &[f64]) -> V { let q = flows(p); vec![DEM - q.iter().sum::<f64>(), HEAD - (0..3).map(|i| K[i] * q[i]).sum::<f64>()] }
fn jac(p: &[f64]) -> Vec<V> { let q = flows(p); vec![(0..3).map(|i| -q[i] / (2.0 * p[i])).collect(), (0..3).map(|i| -K[i] * q[i] / (2.0 * p[i])).collect()] }
fn hdiag(p: &[f64], mu: &[f64]) -> V { let q = flows(p); (0..3).map(|i| (mu[0] + mu[1] * K[i]) * q[i] / (4.0 * p[i] * p[i])).collect() } // Hessian of L
fn viol(p: &[f64]) -> f64 { let c = miss(p); c[0].abs() + c[1].max(0.0) }
fn merit(p: &[f64], rho: f64) -> f64 { p.iter().sum::<f64>() + rho * viol(p) }
fn f4(v: &[f64]) -> String { v.iter().map(|u| format!("{:.4}", (u * 1e9).round() / 1e9 + 0.0)).collect::<Vec<_>>().join(", ") }
fn dist(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(x, y)| (x - y) * (x - y)).sum::<f64>().sqrt() }
fn sci(x: f64, d: usize) -> String { // Python's e-format: 6.124e+01
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn gram(j: &[V]) -> Vec<V> { (0..2).map(|i| (0..2).map(|k| (0..3).map(|t| j[i][t] * j[k][t]).sum()).collect()).collect() }

fn kkt(p: &[f64], mu: &[f64], h: Option<V>) -> Option<(V, V)> { // [B J^T; J 0] [d; mu+] = [-grad f; -c]
    let j = jac(p);
    let h = h.unwrap_or_else(|| hdiag(p, mu));
    let mut m: Vec<V> = (0..3).map(|i| { let mut r: V = (0..3).map(|c| if c == i { h[i] } else { 0.0 }).collect(); r.push(j[0][i]); r.push(j[1][i]); r }).collect();
    for row in &j { let mut r = row.clone(); r.push(0.0); r.push(0.0); m.push(r); }
    let c = miss(p); let z = gauss(&m, &[-1.0, -1.0, -1.0, -c[0], -c[1]])?;
    Some((z[..3].to_vec(), z[3..].to_vec()))
}
fn ls_prices(p: &[f64]) -> V { // least-squares prices: make grad f + J^T mu as small as possible
    let j = jac(p);
    gauss(&gram(&j), &[-j[0].iter().sum::<f64>(), -j[1].iter().sum::<f64>()]).unwrap()
}
fn sqp(p0: &[f64], mu0: &[f64], steps: usize, soc: bool, rho: f64) -> Vec<(V, V, f64, &'static str)> {
    let (mut p, mut mu) = (p0.to_vec(), mu0.to_vec());
    let mut hist = vec![(p.clone(), mu.clone(), 1.0, "start")];
    for _ in 0..steps {
        let (d, mu1) = kkt(&p, &mu, None).unwrap();
        let slope = d.iter().sum::<f64>() - rho * viol(&p);
        let (mut a, mut tag) = (1.0, "full");
        let x = loop {
            let x: V = (0..3).map(|i| p[i] + a * d[i]).collect();
            let pos = x.iter().all(|v| *v > 0.0);
            if pos && merit(&x, rho) <= merit(&p, rho) + 1e-4 * a * slope { break x; }
            if a == 1.0 && soc && pos { // second-order correction: shortest move that re-meets the rules
                let (j, cx) = (jac(&p), miss(&x));
                let w = gauss(&gram(&j), &[-cx[0], -cx[1]]).unwrap();
                let y: V = (0..3).map(|t| x[t] + j[0][t] * w[0] + j[1][t] * w[1]).collect();
                if y.iter().all(|v| *v > 0.0) && merit(&y, rho) <= merit(&p, rho) + 1e-4 * slope { tag = "corrected"; break y; }
            }
            a /= 2.0;
        };
        (p, mu) = (x, mu1);
        hist.push((p.clone(), mu.clone(), a, tag));
    }
    hist
}
fn flowform(hd: f64) -> V { // in flows: 2 a_i q_i = nu + lam k_i, sum q = 150, k.q = head
    let mut m: Vec<V> = (0..3).map(|i| { let mut r: V = (0..3).map(|c| if c == i { 2.0 * A[i] } else { 0.0 }).collect(); r.push(-1.0); r.push(-K[i]); r }).collect();
    m.extend([vec![1.0, 1.0, 1.0, 0.0, 0.0], vec![K[0], K[1], K[2], 0.0, 0.0]]);
    gauss(&m, &[0.0, 0.0, 0.0, DEM, hd]).unwrap()
}
fn pen(r: f64) -> V { // in flows: head priced at r per m, demand held
    let mut m: Vec<V> = (0..3).map(|i| { let mut row: V = (0..3).map(|c| if c == i { 2.0 * A[i] } else { 0.0 }).collect(); row.push(-1.0); row }).collect();
    m.push(vec![1.0, 1.0, 1.0, 0.0]);
    gauss(&m, &[r * K[0], r * K[1], r * K[2], DEM]).unwrap()
}
fn below(v: f64) -> &'static str { if v < 1e-6 { "below" } else { "ABOVE" } }
fn power(q: &[f64]) -> f64 { (0..3).map(|i| A[i] * q[i] * q[i]).sum() }
fn head(q: &[f64]) -> f64 { (0..3).map(|i| K[i] * q[i]).sum() }
fn steps(h: &[(V, V, f64, &str)], tag: bool) -> String { h[1..].iter().map(|g| if tag { format!("{} {}", g.2, g.3) } else { format!("{}", g.2) }).collect::<Vec<_>>().join(" ") }

fn main() {
    // ---- road 2 ----
    let z = flowform(HEAD); let ps: V = (0..3).map(|i| A[i] * z[i] * z[i]).collect();
    println!("road 2, flow form: flows {} L/s, powers {} kW, total {:.4} kW, nu {:.4}, lam {:.4}", f4(&z[..3]), f4(&ps), ps.iter().sum::<f64>(), z[3], z[4]);
    // ---- road 1: SQP from 100 kW on every pump ----
    let (p0, mu0) = (vec![100.0; 3], ls_prices(&vec![100.0; 3]));
    let (j0, h0, c0) = (jac(&p0), hdiag(&p0, &mu0), miss(&p0));
    println!("start: flows {} L/s, total {:.4} L/s, head {:.4} m, misses {}", f4(&flows(&p0)), flows(&p0).iter().sum::<f64>(), HEAD - c0[1], f4(&c0));
    println!("start: demand row {}; head row {}; prices mu0 {}; curvature {}", f4(&j0[0]), f4(&j0[1]), f4(&mu0), f4(&h0));
    let s: Vec<V> = (0..2).map(|j| (0..2).map(|l| (0..3).map(|i| j0[j][i] * j0[l][i] / h0[i]).sum()).collect()).collect();
    let r: V = (0..2).map(|j| c0[j] - (0..3).map(|i| j0[j][i] / h0[i]).sum::<f64>()).collect();
    let mh = gauss(&s, &r).unwrap(); // by hand: eliminate d, leaving 2 equations in the 2 new prices
    let dh: V = (0..3).map(|i| -(1.0 + j0[0][i] * mh[0] + j0[1][i] * mh[1]) / h0[i]).collect();
    println!("by hand: [{}; {}] mu = ({}); mu1 {}; step d {} kW", f4(&s[0]), f4(&s[1]), f4(&r), f4(&mh), f4(&dh));
    let h = sqp(&p0, &mu0, 4, true, RHO);
    let d1: V = (0..3).map(|i| h[1].0[i] - p0[i]).collect(); assert!(dist(&dh, &d1) < 1e-9 && dist(&mh, &h[1].1) < 1e-9);
    let err: V = h.iter().map(|g| dist(&g.0, &ps)).collect();
    println!("k | powers (kW) | total kW | demand miss L/s | head miss m | prices | step | merit | error kW");
    for (k, (p, mu, a, tag)) in h.iter().enumerate() {
        let (st, c) = (if k > 0 { format!("{} {}", a, tag) } else { tag.to_string() }, miss(p));
        println!("{} | {} | {:.4} | {:.6} | {:.6} | {} | {} | {:.4} | {}", k, f4(p), p.iter().sum::<f64>(), c[0], c[1], f4(mu), st, merit(p, RHO), sci(err[k], 3));
    }
    println!("error ratios e(k+1)/e(k)^2: {}", (0..4).map(|k| format!("{:.4}", err[k + 1] / (err[k] * err[k]))).collect::<Vec<_>>().join(" "));
    println!("chart, log10 error at k = 0..4: {}", err[..5].iter().map(|e| format!("{:.2}", e.log10())).collect::<Vec<_>>().join(" "));
    let first = h.iter().position(|g| miss(&g.0).iter().all(|v| v.abs() < 1e-3)).unwrap();
    let (p, mu) = (h[4].0.clone(), h[4].1.clone()); let jp = jac(&p);
    let gl = (0..3).map(|i| (1.0 + jp[0][i] * mu[0] + jp[1][i] * mu[1]).abs()).fold(0.0, f64::max);
    let u = [K[2] - K[1], K[0] - K[2], K[1] - K[0]]; // flow changes keeping both rules: (1,1,1) x k
    let z: V = (0..3).map(|i| -u[i] / jp[0][i]).collect(); // the same move in powers: J z = 0
    let hp = hdiag(&p, &mu); let curv = (0..3).map(|i| hp[i] * z[i] * z[i]).sum::<f64>() / z.iter().map(|v| v * v).sum::<f64>();
    println!("feasible to 0.001 after {} steps; step 4: KKT residual {}, head price {:.4} > 0, curvature on allowed step {:.6}", first, sci(gl, 1), mu[1], curv);
    assert!(first == 3 && gl < 1e-6 && mu[1] > 0.0 && curv > 0.0 && dist(&p, &ps) < 1e-6);
    assert!((0..3).all(|k| err[k + 1] < 0.02 * err[k] * err[k]) && (0..3).all(|k| merit(&h[k + 1].0, RHO) < merit(&h[k].0, RHO)));
    let mut nd: f64 = 0.0;
    for i in 0..3 {
        let (mut up, mut dn) = (p.clone(), p.clone()); up[i] += 1e-5; dn[i] -= 1e-5;
        for j in 0..2 { nd = nd.max(((miss(&up)[j] - miss(&dn)[j]) / 2e-5 - jp[j][i]).abs()); }
    }
    println!("rule gradients against central differences: largest gap {}", sci(nd, 1));
    assert!(nd < 1e-6);
    // ---- road 3: every plan on a 0.1 L/s grid of flows that meets demand with at least 35 m of head ----
    let (mut best, mut n) = ((1e9, 0.0, 0.0), 0);
    for n1 in 0..1501 { for n2 in 0..(1501 - n1) {
        let q = [n1 as f64 / 10.0, n2 as f64 / 10.0, DEM - n1 as f64 / 10.0 - n2 as f64 / 10.0];
        if head(&q) >= HEAD - 1e-9 { n += 1; let c = power(&q); if c < best.0 { best = (c, q[0], q[1]); } } // no binding assumed
    } }
    let tot: f64 = p.iter().sum();
    println!("road 3, scan of {} feasible plans: lowest {:.4} kW at flows {} L/s; SQP total {:.4} kW", n, best.0, f4(&[best.1, best.2, DEM - best.1 - best.2]), tot);
    assert!((best.0 - tot).abs() < 1e-6 && (tot - ps.iter().sum::<f64>()).abs() < 1e-6);
    // ---- what breaks ----
    println!("model with f's own Hessian (zero): {}", if kkt(&p0, &mu0, Some(vec![0.0; 3])).is_none() { "singular" } else { "solvable" });
    assert!(kkt(&p0, &[0.0, 0.0], None).is_none() && kkt(&p0, &mu0, Some(vec![0.0; 3])).is_none());
    let far = vec![300.0; 3];
    let (d, _) = kkt(&far, &ls_prices(&far), None).unwrap();
    assert!(miss(&far)[1] < 0.0 && (merit(&far, RHO) - far.iter().sum::<f64>() - RHO * miss(&far)[0].abs()).abs() < 1e-9); // head slack there: no fine for it
    let (land, g): (V, _) = ((0..3).map(|i| far[i] + d[i]).collect(), sqp(&far, &ls_prices(&far), 6, true, RHO));
    let eg = dist(&g[6].0, &ps);
    println!("from 300 kW each, unguarded full step lands at {} kW; guarded steps {}, error {} 1e-6", f4(&land), steps(&g, false), below(eg));
    assert!(land.iter().cloned().fold(f64::MAX, f64::min) < 0.0 && eg < 1e-6);
    let (w, w0, l) = (pen(5.0), pen(0.0), flowform(25.0));
    let pw: V = (0..3).map(|i| A[i] * w[i] * w[i]).collect();
    println!("penalty weight 5 < head price 10: merit lowest at head {:.4} m, merit {:.4} < {:.4} kW", head(&w), merit(&pw, 5.0), merit(&ps, 5.0));
    println!("head limit 25 m held as equality: head price {:.4} kW per m, total {:.4} kW; rule dropped {:.4} kW at {:.4} m", l[4], power(&l), power(&w0), head(&w0));
    assert!(merit(&pw, 5.0) < merit(&ps, 5.0) - 1.0 && viol(&pw) > 1.0 && l[4] < 0.0 && power(&l) > power(&w0));
    let pf: V = [54.0, 44.0, 52.0].iter().enumerate().map(|(i, q)| A[i] * q * q).collect(); // a feasible plan near the answer
    let (d, _) = kkt(&pf, &[1.0, 10.0], None).unwrap(); let pd: V = (0..3).map(|i| pf[i] + d[i]).collect(); // the full step
    println!("Maratos: start {} kW, misses {}; full step total {:.4} -> {:.4} kW, violation 0 -> {:.4}", f4(&pf), f4(&miss(&pf)), pf.iter().sum::<f64>(), pd.iter().sum::<f64>(), viol(&pd));
    println!("Maratos: merit {:.4} -> {:.4} kW, rejected; error {:.4} -> {:.4}", merit(&pf, RHO), merit(&pd, RHO), dist(&pf, &ps), dist(&pd, &ps));
    let (nn, cc) = (sqp(&pf, &[1.0, 10.0], 4, false, RHO), sqp(&pf, &[1.0, 10.0], 4, true, RHO));
    println!("Maratos, no correction: steps {}, error after 4 {:.4}", steps(&nn, false), dist(&nn[4].0, &ps));
    println!("Maratos, with correction: steps {}, error after 4 {} 1e-6", steps(&cc, true), below(dist(&cc[4].0, &ps)));
    assert!(merit(&pd, RHO) > merit(&pf, RHO) && dist(&pd, &ps) < 0.15 * dist(&pf, &ps) && dist(&nn[4].0, &ps) > 1.0 && dist(&cc[4].0, &ps) < 1e-6);
    println!("ALL CHECKS PASS");
}
