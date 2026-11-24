// The ellipsoid method -- the check behind the card.  std only, no crates.
// Question: is there a workshop plan earning at least T pounds?  Each limit is relaxed
// by EPS so a plan, if one exists, leaves room of area at least (2 EPS/39)^2.
// Roads to the answer: central-cut ellipsoid steps plus bisection on T; every corner
// of the region listed in exact fractions; the prices y = (3, 0, 7) as a dual bound.
const G: [[f64; 2]; 6] = [[4.0, 2.0], [3.0, 1.0], [1.0, 2.0], [-1.0, 0.0], [0.0, -1.0], [-19.0, -20.0]];
const H: [i64; 5] = [160, 120, 64, 0, 0];
const NAMES: [&str; 6] = ["timber", "labour", "finish", "tables>=0", "chairs>=0", "profit"];
const EPS: f64 = 0.05;
type M2 = [[f64; 2]; 2];
type Q = (i64, i64); // an exact fraction: numerator, denominator > 0

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); (n / g, d / g) }
fn qs(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn qf(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
fn f4(v: f64) -> String { format!("{:.4}", v) }
fn real(t: f64, c: [f64; 2]) -> (bool, f64) { let h = [160.0, 120.0, 64.0, 0.0, 0.0, -t]; ((0..6).all(|i| G[i][0] * c[0] + G[i][1] * c[1] <= h[i]), c[0] + 2.0 * c[1]) } // unloosened limits kept? finish used

fn step_l(c: [f64; 2], l: M2, a: [f64; 2]) -> ([f64; 2], M2) { // one central cut, P = L L^T kept as L
    let (s, beta) = ((4.0f64 / 3.0).sqrt(), 1.0 - (1.0f64 / 3.0).sqrt()); let w = [l[0][0] * a[0] + l[1][0] * a[1], l[0][1] * a[0] + l[1][1] * a[1]];
    let qq = (w[0] * w[0] + w[1] * w[1]).sqrt(); let u = [w[0] / qq, w[1] / qq];
    let b = [l[0][0] * u[0] + l[0][1] * u[1], l[1][0] * u[0] + l[1][1] * u[1]];
    let n = |i: usize, j: usize| s * (l[i][j] - beta * b[i] * u[j]);
    ([c[0] - b[0] / 3.0, c[1] - b[1] / 3.0], [[n(0, 0), n(0, 1)], [n(1, 0), n(1, 1)]])
}

fn step_p(c: [f64; 2], p: M2, a: [f64; 2], sym: bool) -> ([f64; 2], M2, f64, [f64; 2]) { // the same cut on P itself
    let pa = [p[0][0] * a[0] + p[0][1] * a[1], p[1][0] * a[0] + p[1][1] * a[1]];
    let q2 = a[0] * pa[0] + a[1] * pa[1];
    if q2 <= 0.0 { return (c, p, q2, [0.0; 2]); }
    let b = [pa[0] / q2.sqrt(), pa[1] / q2.sqrt()]; // sym: the off-diagonal is worked out once
    let n = |i: usize, j: usize| { let (i, j) = if sym { (i.min(j), i.max(j)) } else { (i, j) }; 4.0 / 3.0 * (p[i][j] - 2.0 / 3.0 * b[i] * b[j]) };
    ([c[0] - b[0] / 3.0, c[1] - b[1] / 3.0], [[n(0, 0), n(0, 1)], [n(1, 0), n(1, 1)]], q2, b)
}

fn p_of_l(l: &M2) -> M2 { let e = |i: usize, j: usize| l[i][0] * l[j][0] + l[i][1] * l[j][1]; [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]] }

fn first_cut(c: [f64; 2], h: &[f64; 6], eps: f64) -> Option<usize> { (0..6).find(|&i| G[i][0] * c[0] + G[i][1] * c[1] > h[i] + eps) }

type Hist = Vec<(usize, [f64; 2], M2, f64, Option<usize>)>;
fn decide(t: i64, eps: f64, rad: f64, vmin: Option<f64>, hist: &mut Hist, side: f64) -> (bool, usize, [f64; 2]) {
    let (h, mut c, mut l) = ([160.0, 120.0, 64.0, 0.0, 0.0, -(t as f64)], [0.0, 0.0], [[rad, 0.0], [0.0, rad]]);
    let (vmin, mut k) = (vmin.unwrap_or((2.0 * eps / 39.0).powi(2)), 0);
    loop {
        let area = std::f64::consts::PI * (l[0][0] * l[1][1] - l[0][1] * l[1][0]).abs();
        let cut = first_cut(c, &h, eps); hist.push((k, c, l, area, cut));
        let Some(i) = cut else { return (true, k, c) };
        if area < vmin { return (false, k, c); }
        (c, l) = step_l(c, l, [side * G[i][0], side * G[i][1]]); k += 1;
    }
}

fn bisect(eps: f64, vmin: Option<f64>, log: &mut Vec<(i64, bool, usize, [f64; 2])>) -> i64 {
    let (mut lo, mut hi) = (0i64, 2759i64); // the disc's best profit is 100 sqrt(761) = 2758.6
    while hi - lo > 1 {
        let m = (lo + hi) / 2; let (ok, k, c) = decide(m, eps, 100.0, vmin, &mut Vec::new(), 1.0);
        log.push((m, ok, k, c)); if ok { lo = m } else { hi = m }
    }
    lo
}

fn inside(v: [f64; 2], c: [f64; 2], p: &M2) -> f64 { // at most 1 means inside the ellipse
    let (d, x, y) = (p[0][0] * p[1][1] - p[0][1] * p[1][0], v[0] - c[0], v[1] - c[1]);
    (p[1][1] * x * x - 2.0 * p[0][1] * x * y + p[0][0] * y * y) / d
}

fn corners(h: &[Q]) -> (Vec<(Q, Q)>, f64) { // every crossing of two limit lines that keeps all limits
    let g: Vec<[i64; 2]> = G.iter().map(|r| [r[0] as i64, r[1] as i64]).collect();
    let mut out: Vec<(Q, Q)> = Vec::new();
    for p in 0..h.len() { for r in p + 1..h.len() {
        let det = g[p][0] * g[r][1] - g[p][1] * g[r][0];
        if det == 0 { continue; }
        let d = h[p].1 * h[r].1 * det; // common denominator
        let v = (q(h[p].0 * h[r].1 * g[r][1] - g[p][1] * h[r].0 * h[p].1, d), q(g[p][0] * h[r].0 * h[p].1 - h[p].0 * h[r].1 * g[r][0], d));
        let ok = (0..h.len()).all(|i| { let lhs = q(g[i][0] * v.0 .0 * v.1 .1 + g[i][1] * v.1 .0 * v.0 .1, v.0 .1 * v.1 .1); lhs.0 * h[i].1 <= h[i].0 * lhs.1 });
        if ok && !out.contains(&v) { out.push(v); }
    } }
    let m = [out.iter().map(|v| qf(v.0)).sum::<f64>() / out.len() as f64, out.iter().map(|v| qf(v.1)).sum::<f64>() / out.len() as f64];
    out.sort_by(|a, b| (qf(a.1) - m[1]).atan2(qf(a.0) - m[0]).partial_cmp(&(qf(b.1) - m[1]).atan2(qf(b.0) - m[0])).unwrap());
    let (n, mut s) = (out.len(), q(0, 1));
    for i in 0..n {
        let (a, b) = (out[i], out[(i + n - 1) % n]);
        let (t1, t2) = (q(a.0 .0 * b.1 .0, a.0 .1 * b.1 .1), q(b.0 .0 * a.1 .0, b.0 .1 * a.1 .1));
        s = q(s.0 * t1.1 * t2.1 + t1.0 * s.1 * t2.1 - t2.0 * s.1 * t1.1, s.1 * t1.1 * t2.1);
    }
    (out, (qf(s) / 2.0).abs())
}

fn main() {
    let ratio = (2.0f64 / 3.0) * (4.0f64 / 3.0).sqrt(); // area factor per central cut, n = 2
    let yn = |b: bool| if b { "yes" } else { "no" };
    println!("maximise 19 x1 + 20 x2 pounds: timber 4,2 <= 160 m; labour 3,1 <= 120 h; finish 1,2 <= 64 l; limits relaxed by 0.05");
    let (c1, p1, q2, b) = step_p([0.0, 0.0], [[1e4, 0.0], [0.0, 1e4]], G[5], false);
    println!("step 0, T = 900: a = (-19, -20), a^T P a = {}, root {}, d = ({}, {})", f4(q2), f4(q2.sqrt()), f4(b[0]), f4(b[1]));
    let r0 = (p1[0][0] * p1[1][1] - p1[0][1] * p1[1][0]).sqrt() / 1e4; // area ratio from det P, no L
    println!("centre 1 = ({}, {}); P1 rows {}, {}; {}, {}; area ratio {:.6}", f4(c1[0]), f4(c1[1]), f4(p1[0][0]), f4(p1[0][1]), f4(p1[1][0]), f4(p1[1][1]), r0);
    let mut hist: Hist = Vec::new(); let found = decide(900, EPS, 100.0, None, &mut hist, 1.0);
    println!(" k       x1       x2        area  cut by");
    for (k, c, _, area, cut) in &hist {
        println!("{:2} {:8.4} {:8.4} {:11.4}  {}", k, c[0], c[1], area, match cut { Some(i) => NAMES[*i], None => "fits: a plan" });
    }
    let c = hist[hist.len() - 1].1; let r900 = real(900.0, c);
    println!("plan found: ({}, {}) earns {}; real limits kept: {}, finish {} l", f4(c[0]), f4(c[1]), f4(19.0 * c[0] + 20.0 * c[1]), yn(r900.0), f4(r900.1));
    println!("chart log10 area: {}", hist.iter().map(|h| format!("{:.2}", h.3.log10())).collect::<Vec<_>>().join(", "));
    let ratios: Vec<f64> = (0..hist.len() - 1).map(|k| hist[k + 1].3 / hist[k].3).collect();
    let e = q(1, 20);
    let (q900, a_q) = corners(&[q(3201, 20), q(2401, 20), q(1281, 20), e, e, q(-17999, 20)]);
    let mut worst: f64 = 0.0; for h in &hist { for v in &q900 { worst = worst.max(inside([qf(v.0), qf(v.1)], h.1, &p_of_l(&h.2))); } }
    println!("area ratio each step: min {:.6}, max {:.6}; formula (2/3) sqrt(4/3) = {:.6}", ratios.iter().cloned().fold(f64::INFINITY, f64::min), ratios.iter().cloned().fold(0.0, f64::max), ratio);
    println!("relaxed region for 900: {} corners, area {}; worst corner score over all 22 ellipses {}", q900.len(), f4(a_q), f4(worst));
    let hq: Vec<Q> = H.iter().map(|&x| q(x, 1)).collect(); let (mut r0s, _) = corners(&hq);
    r0s.sort_by(|a, b| (a.0 .0 * b.0 .1).cmp(&(b.0 .0 * a.0 .1)).then((a.1 .0 * b.1 .1).cmp(&(b.1 .0 * a.1 .1))));
    let prof = |v: &(Q, Q)| q(19 * v.0 .0 * v.1 .1 + 20 * v.1 .0 * v.0 .1, v.0 .1 * v.1 .1);
    println!("corners: {}", r0s.iter().map(|v| format!("({}, {}) {}", qs(v.0), qs(v.1), qs(prof(v)))).collect::<Vec<_>>().join("; "));
    let mut h9 = hq.clone(); h9.push(q(-900, 1)); let (p900, a9) = corners(&h9);
    println!("plans earning >= 900: corners {}; area {}", p900.iter().map(|v| format!("({}, {})", qs(v.0), qs(v.1))).collect::<Vec<_>>().join(", "), f4(a9));
    let yc = [3i64, 0, 7];
    let ceil: i64 = (0..3).map(|i| H[i] * yc[i]).sum();
    let slack = ceil as f64 + EPS * (yc.iter().sum::<i64>() as f64);
    let cover: Vec<i64> = (0..2).map(|j| (0..3).map(|i| G[i][j] as i64 * yc[i]).sum()).collect();
    println!("certificate y = (3, 0, 7): tables {}, chairs {}; bound {}; relaxed: profit <= {} < 929 - 0.05", cover[0], cover[1], ceil, f4(slack));
    let mut log = Vec::new(); let best = bisect(EPS, None, &mut log);
    for i in [0usize, 6] {
        println!("tests: {}", log[i..i + 6].iter().map(|e| format!("{} {} ({})", e.0, yn(e.1), e.2)).collect::<Vec<_>>().join(", "));
    }
    let c928 = log.iter().find(|e| e.0 == 928).unwrap().3; let r928 = real(928.0, c928);
    println!("best whole target {}: loosened point ({}, {}), real limits kept: {}, finish {} l; {} tests, {} steps", best, f4(c928[0]), f4(c928[1]), yn(r928.0), f4(r928.1), log.len(), log.iter().map(|e| e.2).sum::<usize>());
    let (vmin, v0) = ((2.0 * EPS / 39.0).powi(2), std::f64::consts::PI * 1e4);
    let (kk, kb) = (((v0 / vmin).ln() / -ratio.ln()).ceil() as usize, ((v0 / vmin).ln() / (1.0 / 6.0)).ceil() as usize);
    println!("floor area {:.4} millionths; steps to reach it: exact ratio {}, bound exp(-1/6) {}", vmin * 1e6, kk, kb);
    let nr: Vec<(usize, f64, f64)> = [2usize, 3, 10, 100].iter().map(|&n| { let f = n as f64;
        (n, f / (f + 1.0) * (f * f / (f * f - 1.0)).powf((f - 1.0) / 2.0), (-1.0 / (2.0 * (f + 1.0))).exp()) }).collect();
    println!("volume ratio by n (exact, bound): {}; centre of gravity at most {:.4}", nr.iter().map(|(n, r, e)| format!("{} {:.4} {:.4}", n, r, e)).collect::<Vec<_>>().join("; "), 1.0 - (-1.0f64).exp());
    let bad = [c1[0] * -1.0, c1[1] * -1.0]; // the wrong half's centre: old centre + b/3
    let (rw, sbad) = (decide(900, EPS, 100.0, None, &mut Vec::new(), -1.0), inside([32.0, 16.0], bad, &p1));
    println!("break, wrong half kept: corner (32, 16) scores {} > 1 after one cut; target 900 says {} after {} steps", f4(sbad), yn(rw.0), rw.1);
    let (b0, b5) = (bisect(0.0, Some(vmin), &mut Vec::new()), bisect(0.5, None, &mut Vec::new()));
    println!("break, no relaxation, same budget: says {}; relaxed by 0.5: says {}", b0, b5);
    let r20 = decide(900, EPS, 20.0, None, &mut Vec::new(), 1.0);
    println!("break, start disc radius 20: target 900 says {} after {} steps", yn(r20.0), r20.1);
    let (h929, mut runs) = ([160.0, 120.0, 64.0, 0.0, 0.0, -929.0], Vec::new()); // target 929 on P itself: the off-diagonal worked out twice, then once
    for sym in [false, true] {
        let (mut k, mut c, mut p, mut q2) = (0usize, [0.0, 0.0], [[1e4, 0.0], [0.0, 1e4]], 1.0);
        while k < kk { let r = step_p(c, p, G[first_cut(c, &h929, EPS).unwrap()], sym); q2 = r.2; if q2 <= 0.0 { break; } (c, p, k) = (r.0, r.1, k + 1); }
        runs.push((k, c, p, q2));
    }
    let ((k, _, p, qlast), (ks, cs, _, _), r929) = (runs[0], runs[1], decide(929, EPS, 100.0, None, &mut Vec::new(), 1.0));
    println!("break, P updated with two off-diagonals worked out apart, target 929: at step {} a^T P a = {:.6}; off-diagonals {:.6} against {:.6}", k, qlast, p[0][1], p[1][0]);
    println!("P updated with one off-diagonal, target 929: {} steps, centre ({}, {}); factor L run: ({}, {})", ks, f4(cs[0]), f4(cs[1]), f4(r929.2[0]), f4(r929.2[1]));
    let mut fig = Vec::new();
    for j in [0usize, 1, 2, 21] {
        let pk = p_of_l(&hist[j].2); let (a, bq, s) = (pk[0][0], pk[0][1], pk[1][1]);
        let (m, th) = (((a - s) * (a - s) / 4.0 + bq * bq).sqrt(), 0.5 * (2.0 * bq).atan2(a - s));
        fig.push(format!("k{} ({:.1},{:.1}) r {:.1} {:.1} rot {:.1}", j, 170.0 + 1.1 * hist[j].1[0], 140.0 - 1.1 * hist[j].1[1],
            1.1 * ((a + s) / 2.0 + m).sqrt(), 1.1 * ((a + s) / 2.0 - m).sqrt(), 0.0 - th.to_degrees() + 0.0));
    }
    let reg = r0s.iter().map(|v| format!("({:.1},{:.1})", 170.0 + 1.1 * qf(v.0), 140.0 - 1.1 * qf(v.1))).collect::<Vec<_>>().join(" ");
    println!("figure, px = 170 + 1.1*x1, py = 140 - 1.1*x2: region {}; {}", reg, fig.join("; "));

    let top = r0s.iter().max_by(|a, b| qf(prof(a)).partial_cmp(&qf(prof(b))).unwrap()).unwrap();
    assert!(qf(top.0) == 32.0 && qf(top.1) == 16.0 && prof(top) == q(best, 1)); // ellipsoid meets enumeration
    assert!(cover[0] >= 19 && cover[1] >= 20 && ceil == best && slack < best as f64 + 1.0 - EPS); // dual bound meets it
    assert!(ratios.iter().chain([r0].iter()).all(|&r| (r - ratio).abs() < 1e-9 && r < (-1.0f64 / 6.0).exp()) && worst <= 1.0 + 1e-9); // ratio, bound, containment
    let ph = p_of_l(&hist[1].2); assert!((0..2).all(|i| (0..2).all(|j| (ph[i][j] - p1[i][j]).abs() < 1e-6)));
    assert!(found.0 && found.1 == 21 && log.iter().filter(|e| !e.1).all(|e| e.2 == kk) && r900.0 && !r928.0);
    assert!(sbad > 1.0 && !rw.0 && b0 == 927 && b5 > 928 && !r20.0 && qlast <= 0.0 && k == 71);
    assert!(ks == kk && (0..2).all(|i| (cs[i] - r929.2[i]).abs() < 1e-9)); // P form meets factor form
    println!("ALL CHECKS PASS");
}
