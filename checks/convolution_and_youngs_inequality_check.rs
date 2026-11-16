// Convolution and Young's inequality -- the check behind the card.  Rust std only.
// Time t in seconds.  The lamp f is 1 on [0, 1) s.  The meter's window g is 1 per second
// on [0, 1) s.  Their convolution, the meter reading, is the triangle on [0, 2] s.
use std::f64::consts::PI;
const INF: f64 = f64::INFINITY;

fn tri(t: f64) -> f64 { // road 1: the overlap of [0, 1) and (t - 1, t]
    (t.min(1.0) - (t - 1.0).max(0.0)).max(0.0)
}
fn conv_mid(t: f64, n: usize) -> f64 { // road 2: the defining integral, n midpoint cells
    let h = 1.0 / n as f64;
    h * (0..n).filter(|&k| { let u = t - (k as f64 + 0.5) * h; 0.0 <= u && u < 1.0 }).count() as f64
}
fn dconv(a: &[i64], b: &[i64]) -> Vec<i64> { // road 3: the finite twin, exact whole numbers
    let mut c = vec![0i64; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { c[i + j] += x * y; } }
    c
}
fn tri_norm(r: f64, w: f64) -> f64 { // closed form r-size of the triangle from width-w gates
    if r == INF { w } else { (2.0 / (r + 1.0)).powf(1.0 / r) * w.powf(1.0 + 1.0 / r) }
}
fn twin_norm(r: f64, n: usize, w: f64) -> f64 { // r-size of the sampled gates' discrete convolution
    let h = w / n as f64;
    let c: Vec<f64> = (0..2 * n - 1).map(|m| h * ((m + 1).min(2 * n - 1 - m)) as f64).collect();
    if r == INF { c.iter().cloned().fold(0.0, f64::max) }
    else { (h * c.iter().map(|x| x.powf(r)).sum::<f64>()).powf(1.0 / r) }
}
fn gate_norm(p: f64, w: f64) -> f64 { if p == INF { 1.0 } else { w.powf(1.0 / p) } }
fn a_fac(m: f64) -> f64 { // Beckner's factor; A(1) = A(inf) = 1
    if m == 1.0 || m == INF { return 1.0; }
    let mp = m / (m - 1.0);
    (m.powf(1.0 / m) / mp.powf(1.0 / mp)).sqrt()
}
fn conj(m: f64) -> f64 { if m == 1.0 { INF } else if m == INF { 1.0 } else { m / (m - 1.0) } }
fn gsum(v: &[f64], p: f64, d: f64) -> f64 {
    if p == INF { v.iter().cloned().fold(0.0, f64::max) }
    else { (d * v.iter().map(|x| x.powf(p)).sum::<f64>()).powf(1.0 / p) }
}
fn big_g(s: f64) -> f64 { if s >= 0.0 { (1.0 + s).ln() } else { -(1.0 - s).ln() } }
fn hx(x: f64) -> f64 { (1.0 + x) * (1.0 + x).ln() - x }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(",") }

fn main() {
    println!("gates: lamp f on [0, 1) s, window g 1 per second on [0, 1) s");
    for &t in &[0.25, 0.5, 1.0, 1.5, 1.75] {
        let (a, b1, b2) = (tri(t), conv_mid(t, 1000), conv_mid(t, 2000));
        assert!((a - b1).abs() < 1e-9 && (a - b2).abs() < 1e-9);
        println!("reading at t = {:.2} s: overlap {:.6}, integral n=1000 {:.6}, n=2000 {:.6}", t, a, b1, b2);
    }
    let ts: Vec<f64> = (0..11).map(|k| k as f64 / 4.0).collect();
    println!("chart,t,{}", join(&ts));
    println!("chart,lamp,{}", join(&(0..11).map(|k| if k < 4 { 1.0 } else { 0.0 }).collect::<Vec<_>>()));
    println!("chart,reading,{}", join(&ts.iter().map(|&t| tri(t)).collect::<Vec<_>>()));

    let (gate, ramp, u) = ([1i64, 1, 1, 1], [1i64, 2, 3, 4], [1i64, 0, 2]); // four samples a second
    assert_eq!(dconv(&gate, &gate), vec![1, 2, 3, 4, 3, 2, 1]);
    assert_eq!(dconv(&gate, &ramp), dconv(&ramp, &gate));
    assert_eq!(dconv(&dconv(&gate, &ramp), &u), dconv(&gate, &dconv(&ramp, &u))); // u is not the gate
    println!("twin gate*gate {:?}", dconv(&gate, &gate));
    println!("twin gate*ramp {:?} ramp*gate {:?}", dconv(&gate, &ramp), dconv(&ramp, &gate));
    println!("twin (gate*ramp)*u {:?} with u {:?}", dconv(&dconv(&gate, &ramp), &u), u);
    println!("twin gate*(ramp*u) {:?}", dconv(&gate, &dconv(&ramp, &u)));

    let (n, d) = (1200usize, 0.01); // Gaussians e^(-pi t^2) on a grid, cut off at 6 s
    let fk: Vec<f64> = (0..=4 * n).map(|k| (-PI * ((k as f64 - 2.0 * n as f64) * d).powi(2)).exp()).collect();
    let f: Vec<f64> = (0..=n).map(|i| fk[2 * n + i - n / 2]).collect();
    let hh: Vec<f64> = (0..=n).map(|i| d * (0..=n).map(|j| f[j] * fk[2 * n + i - j]).sum::<f64>()).collect();
    println!("gaussian h(0): grid {:.6}, closed form 1/sqrt(2) {:.6}", hh[n / 2], 1.0 / 2f64.sqrt());
    println!("cut-off 6 s; beyond it h stays below {:.1e}", (-PI * 18.0).exp());
    assert!((hh[n / 2] - 1.0 / 2f64.sqrt()).abs() < 1e-9);

    let triples = [("1,1,1", 1.0, 1.0, 1.0), ("1,2,2", 1.0, 2.0, 2.0), ("4/3,4/3,2", 4.0 / 3.0, 4.0 / 3.0, 2.0),
                   ("3/2,3/2,3", 1.5, 1.5, 3.0), ("2,2,inf", 2.0, 2.0, INF)];
    println!("young: p,q,r | gates | gates twin | gaussians | gaussians grid | best constant");
    for &(lab, p, q, r) in &triples {
        let rinv = if r == INF { 0.0 } else { 1.0 / r };
        assert!((1.0 / p + 1.0 / q - 1.0 - rinv).abs() < 1e-12);
        let g1 = tri_norm(r, 1.0) / (gate_norm(p, 1.0) * gate_norm(q, 1.0));
        let g2 = twin_norm(r, 2000, 1.0);
        let gn = |m: f64| if m == INF { 1.0 } else { m.powf(-1.0 / (2.0 * m)) };
        let hn = 1.0 / 2f64.sqrt() * if r == INF { 1.0 } else { (r / 2.0).powf(-1.0 / (2.0 * r)) };
        let c1 = hn / (gn(p) * gn(q));
        let c2 = gsum(&hh, r, d) / (gsum(&f, p, d) * gsum(&f, q, d));
        let best = a_fac(p) * a_fac(q) * a_fac(conj(r));
        assert!((g1 - g2).abs() < 1e-6 && (c1 - c2).abs() < 1e-9);
        assert!(g1 <= best + 1e-12 && c1 <= best + 1e-12 && best <= 1.0 + 1e-12);
        if lab == "4/3,4/3,2" || lab == "3/2,3/2,3" {
            assert!((c1 - best).abs() < 1e-12); // Gaussians reach Beckner's constant
        }
        println!("young,{} | {:.6} | {:.6} | {:.6} | {:.6} | {:.6}", lab, g1, g2, c1, c2, best);
    }
    println!("worked: triangle squared, integrated {:.6}; (4/3)^(3/4) {:.6}; 4^(1/4) {:.6}",
             tri_norm(2.0, 1.0).powi(2), (4.0f64 / 3.0).powf(0.75), 4f64.powf(0.25));
    let a3 = [a_fac(3.0), a_fac(1.2), a_fac(conj(6.0))]; // a rule-abiding triple, 1/3 + 5/6 = 1 + 1/6
    assert!(a3[0] > 1.0 && (a_fac(3.0) * a_fac(1.5) - 1.0).abs() < 1e-12); // one factor above 1; A(m) A(m') = 1
    assert!(a3[0] * a3[1] * a3[2] <= 1.0);
    println!("beckner: p,q,r = 3,1.2,6 | A(3) {:.6} | A(1.2) {:.6} | A(6') {:.6} | product {:.6}",
             a3[0], a3[1], a3[2], a3[0] * a3[1] * a3[2]);
    let wa = (0..2000).map(|k| tri((k as f64 + 0.5) / 1000.0) * if k >= 1000 { 2.0 } else { 1.0 }).sum::<f64>() / 1000.0;
    assert!((wa - 1.5).abs() < 1e-9); // sliding changes size: seconds after 1 s count double
    println!("weighted: after 1 s each second counts double; gates' areas 1 and 1, triangle's area {:.6} = 0.5 + 2 x 0.5", wa);

    println!("scaling: gates of width w | ratio at p=q=4/3, r=2 | ratio at p=q=r=2 (off the rule) | twin n=1000");
    for &w in &[0.01, 1.0, 100.0] {
        let good = tri_norm(2.0, w) / gate_norm(4.0 / 3.0, w).powi(2);
        let bad = tri_norm(2.0, w) / gate_norm(2.0, w).powi(2); // closed form sqrt(2/3) sqrt(w)
        let twin = twin_norm(2.0, 1000, w) / gate_norm(2.0, w).powi(2);
        assert!((good - twin_norm(2.0, 1000, w) / gate_norm(4.0 / 3.0, w).powi(2)).abs() < 1e-6);
        assert!((bad - twin).abs() < 1e-6 * bad);
        println!("scaling,w = {} s | {:.6} | {:.6} | {:.6}", w, good, bad, twin);
    }
    let fall = [4i64, 3, 2, 1];
    println!("try: w = 10000 s off the rule {:.6}; 10 cells at 0.25 s {:.1}",
             tri_norm(2.0, 1e4) / gate_norm(2.0, 1e4).powi(2), conv_mid(0.25, 10));
    println!("try: falling ramp, gate*fall {:?} (gate*fall)*u {:?}", dconv(&gate, &fall), dconv(&dconv(&gate, &fall), &u));

    println!("break: kernel 1/(1 + |t|), not in L1; area of lamp * kernel on [-L, L]");
    let cell = |l: f64, n: usize, k: usize| -l + (k as f64 + 0.5) * 2.0 * l / n as f64;
    for &l in &[10usize, 100, 1000] {
        let (lf, n) = (l as f64, 200 * l);
        let num = (0..n).map(|k| { let t = cell(lf, n, k); big_g(t) - big_g(t - 1.0) }).sum::<f64>() * 2.0 * lf / n as f64;
        let exact = hx(lf + 1.0) - hx(lf - 1.0);
        assert!((num - exact).abs() < 1e-4);
        println!("break,L = {} s: area {:.6}, closed form {:.6}, 2 log L {:.6}", l, num, exact, 2.0 * lf.ln());
    }
    let (l, n) = (1000.0f64, 200000usize);
    let sq = (0..n).map(|k| { let t = cell(l, n, k); (big_g(t) - big_g(t - 1.0)).powi(2) }).sum::<f64>() * 2.0 * l / n as f64;
    assert!((sq + 2.0 / l).sqrt() <= 2f64.sqrt()); // 2-size with the tail bound stays under Young's bound
    println!("break: 2-size on [-1000, 1000] {:.6}, with tail at most {:.6}, Young bound sqrt(2) {:.6}",
             sq.sqrt(), (sq + 2.0 / l).sqrt(), 2f64.sqrt());
    println!("ALL CHECKS PASS");
}
