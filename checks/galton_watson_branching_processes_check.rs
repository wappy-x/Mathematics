// Galton-Watson branching -- the check behind the card.  Rust std only.
// Each person has 0, 1 or 2 children with chances 1/4, 1/4, 1/2; Z_n people in
// generation n, Z_0 = 1.  f(s) = 1/4 + s/4 + s^2/2.  Roads: the factorised fixed-
// point equation, the iteration q_n = f(q_{n-1}), the exact law of Z_n by
// convolution, and a seeded SplitMix64 simulation of 10,000 families.
use std::collections::BTreeMap;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // an exact fraction, kept reduced
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(a: i128, b: i128) -> Q { let g = gcd(a, b).max(1); Q(a / g, b / g) }
fn add(x: Q, y: Q) -> Q { let l = x.1 / gcd(x.1, y.1) * y.1; q(x.0 * (l / x.1) + y.0 * (l / y.1), l) }
fn sub(x: Q, y: Q) -> Q { add(x, Q(-y.0, y.1)) }
fn mul(x: Q, y: Q) -> Q {
    let (g1, g2) = (gcd(x.0, y.1).max(1), gcd(y.0, x.1).max(1));
    q((x.0 / g1) * (y.0 / g2), (x.1 / g2) * (y.1 / g1))
}
fn div(x: Q, y: Q) -> Q { if y.0 < 0 { mul(x, Q(-y.1, -y.0)) } else { mul(x, Q(y.1, y.0)) } }
fn pw(x: Q, n: i32) -> Q { (0..n).fold(Q(1, 1), |a, _| mul(a, x)) }
fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn st(x: Q) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{}/{}", x.0, x.1) } }
fn fq(p: &[Q; 3], s: Q) -> Q { add(add(p[0], mul(p[1], s)), mul(mul(p[2], s), s)) }
fn ff(p: &[f64; 3], s: f64) -> f64 { p[0] + p[1] * s + p[2] * s * s }
fn q_iter_q(p: &[Q; 3], n: usize) -> Q { (0..n).fold(Q(0, 1), |s, _| fq(p, s)) } // road 2, exact
fn q_iter(p: &[f64; 3], n: usize) -> f64 { (0..n).fold(0.0, |s, _| ff(p, s)) }
fn q_closed(p: &[Q; 3]) -> Q { // road 1: p2 s^2 + (p1-1) s + p0 = (s-1)(p2 s - p0)
    if p[2].0 == 0 { return Q(1, 1); }
    let r = div(p[0], p[2]);
    if r.0 >= r.1 { Q(1, 1) } else { r }
}
fn mean_q(p: &[Q; 3]) -> Q { add(p[1], mul(Q(2, 1), p[2])) }
fn fx(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 { // SplitMix64, a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (2.0f64).powi(-53)
    }
}
fn main() {
    let law = [Q(1, 4), Q(1, 4), Q(1, 2)];
    let m = mean_q(&law);
    let var = sub(add(law[1], mul(Q(4, 1), law[2])), mul(m, m));
    let qq = q_closed(&law);
    assert!(add(sub(mul(Q(2, 1), mul(qq, qq)), mul(Q(3, 1), qq)), Q(1, 1)) == Q(0, 1) && fq(&law, qq) == qq && fq(&law, Q(1, 1)) == Q(1, 1));
    println!("offspring law P(0), P(1), P(2) = 1/4 1/4 1/2; mean m = {} = {}; variance sigma^2 = {} = {}", st(m), fl(m), st(var), fl(var));
    println!("fixed points of f(s) = s: 2s^2 - 3s + 1 = (2s - 1)(s - 1) = 0, roots 1/2 and 1; smallest q = p0/p2 = {}", st(qq));
    let h: Vec<Q> = (0..4).map(|n| q_iter_q(&law, n)).collect();
    println!("by hand: P(Z_1=0) = {}, P(Z_2=0) = f(1/4) = {} = {:.5}, P(Z_3=0) = f(11/32) = {} = {:.5}", st(h[1]), st(h[2]), fl(h[2]), st(h[3]), fl(h[3]));
    let mut dist: BTreeMap<i32, Q> = BTreeMap::new(); // road 3: the whole law of Z_n
    dist.insert(1, Q(1, 1));
    for n in 1..6i32 {
        let mut new: BTreeMap<i32, Q> = BTreeMap::new();
        for (&k, &pk) in &dist {
            let mut kids: BTreeMap<i32, Q> = BTreeMap::new();
            kids.insert(0, Q(1, 1));
            for _ in 0..k {
                let mut nk: BTreeMap<i32, Q> = BTreeMap::new();
                for (&a, &pa) in &kids { for c in 0..3 { let e = nk.entry(a + c as i32).or_insert(Q(0, 1)); *e = add(*e, mul(pa, law[c])); } }
                kids = nk;
            }
            for (&j, &pj) in &kids { let e = new.entry(j).or_insert(Q(0, 1)); *e = add(*e, mul(pk, pj)); }
        }
        dist = new;
        let (mut ez, mut ez2, mut eh) = (Q(0, 1), Q(0, 1), Q(0, 1));
        for (&k, &p) in &dist {
            ez = add(ez, mul(Q(k as i128, 1), p));
            ez2 = add(ez2, mul(Q((k * k) as i128, 1), p));
            eh = add(eh, mul(p, pw(Q(1, 2), k)));
        }
        let vz = sub(ez2, mul(ez, ez));
        assert!(dist[&0] == q_iter_q(&law, n as usize) && ez == pw(m, n) && eh == qq);
        assert!(vz == div(mul(mul(var, pw(m, n - 1)), sub(pw(m, n), Q(1, 1))), sub(m, Q(1, 1))));
        println!("exact law, n={}: P(Z=0) {:.6} = iteration; E[Z] {:.6} = m^n; Var(Z) {:.6} = formula; E[W] = {}; E[(1/2)^Z] = {}", n, fl(dist[&0]), fl(ez), fl(vz), st(div(ez, pw(m, n))), st(eh));
    }
    let sup = [0.25, 0.25, 0.5];
    let qs: Vec<f64> = (0..201).map(|n| q_iter(&sup, n)).collect();
    println!("q_n = P(dead by generation n), n = 0..10: {}", fx(&qs[..11], 4));
    let ratio = (qs[41] - 0.5) / (qs[40] - 0.5);
    assert!((qs[200] - 0.5).abs() < 1e-12 && (ratio - 0.75).abs() < 1e-6);
    println!("q_200 = {:.12}; gap ratio (q_41 - q)/(q_40 - q) = {:.4} = f'(1/2) = 1/4 + 1/2 = 0.75", qs[200], ratio);
    println!("three founders: all three lines die with chance q^3 = {}", st(pw(qq, 3)));
    for tl in [[Q(1, 8), Q(3, 8), Q(1, 2)], [Q(1, 2), Q(1, 4), Q(1, 4)]] { // edit the first law to try another
        let (tq, ti) = (q_closed(&tl), q_iter(&[fl(tl[0]), fl(tl[1]), fl(tl[2])], 400));
        assert!((ti - fl(tq)).abs() < 1e-12, "shortcut vs iteration (a law with mean exactly 1 converges too slowly)");
        println!("try: law {} {} {} (mean {}): q = min(1, p0/p2) = {}, iteration {:.4}", st(tl[0]), st(tl[1]), st(tl[2]), fl(mean_q(&tl)), st(tq), ti);
    }
    for p in [[Q(1, 4), Q(1, 4), Q(1, 2)], [Q(3, 8), Q(0, 1), Q(5, 8)], [Q(0, 1), Q(3, 4), Q(1, 4)]] {
        let (mp, qc) = (mean_q(&p), q_closed(&p));
        let qi = (0..400).fold(0.0, |s, _| ff(&[fl(p[0]), fl(p[1]), fl(p[2])], s));
        assert!(mp == m && (qi - fl(qc)).abs() < 1e-12);
        println!("same mean {}: law {} {} {}: q = p0/p2 = {:.4}, iteration {:.4}", fl(mp), st(p[0]), st(p[1]), st(p[2]), fl(qc), qi);
    }
    let laws = [("subcritical 1/2 1/4 1/4 (m 0.75)", [0.5, 0.25, 0.25]), ("critical 1/4 1/2 1/4 (m 1)", [0.25, 0.5, 0.25]),
        ("supercritical 1/4 1/4 1/2 (m 1.25)", [0.25, 0.25, 0.5])];
    for (name, p) in laws.iter() {
        let row: Vec<f64> = (0..21).map(|n| q_iter(p, n)).collect();
        println!("chart, P(dead by n), n = 0..20, {}: {}", name, fx(&row, 3));
    }
    let cl = [0.25, 0.5, 0.25]; // the critical law: mean mc = 1, variance vc
    let mc: f64 = cl.iter().enumerate().map(|(k, p)| k as f64 * p).sum();
    let vc: f64 = cl.iter().enumerate().map(|(k, p)| (k * k) as f64 * p).sum::<f64>() - mc * mc;
    let crit: Vec<(usize, f64)> = [10, 100, 1000].iter().map(|&n| (n, 1.0 - q_iter(&cl, n))).collect();
    assert!((crit[2].0 as f64 * crit[2].1 - 2.0 / vc).abs() < 0.05 && crit[0].1 > crit[1].1 && crit[1].1 > crit[2].1);
    println!("critical, P(alive at n) and n x P (Kolmogorov: tends to 2/variance = 2/{} = {:.0}): {}", vc, 2.0 / vc, crit.iter().map(|&(n, a)| format!("n={} {:.4} {:.3}", n, a, n as f64 * a)).collect::<Vec<_>>().join("  "));
    let sub_: Vec<String> = [10, 20].iter().map(|&n| { let a = 1.0 - q_iter(&[0.5, 0.25, 0.25], n); format!("n={} {:.6} {:.4}", n, a, a / 0.75f64.powi(n as i32)) }).collect();
    println!("subcritical, P(alive at n) and P / 0.75^n: {}", sub_.join("  "));
    let vw = div(var, mul(m, sub(m, Q(1, 1))));
    println!("Var(W) = sigma^2/(m(m-1)) = {}; E[W_n^2] rises to 1 + {} = {}; P(W = 0) = q = {}, so E[W | W > 0] = {}", fl(vw), fl(vw), fl(add(Q(1, 1), vw)), st(qq), st(div(Q(1, 1), sub(Q(1, 1), qq))));
    let mut rng = Rng(20261123);
    let (n_fam, g_max, mf) = (10000usize, 20usize, 1.25f64);
    let (mut dead, mut sw, mut sw2, mut sd, mut salive) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
    let (mut paths, mut kept): (Vec<(usize, Vec<f64>)>, [usize; 2]) = (Vec::new(), [0, 0]);
    for fam in 0..n_fam { // road 4: simulate generation by generation
        let (mut z, mut w) = (1u64, vec![1.0f64]);
        for g in 0..g_max {
            let mut nz = 0u64;
            for _ in 0..z { let r = rng.u(); nz += if r < 0.25 { 0 } else if r < 0.5 { 1 } else { 2 }; }
            z = nz;
            w.push(z as f64 / mf.powi(g as i32 + 1));
        }
        let wg = w[g_max];
        if z == 0 { dead += 1.0; }
        sw += wg; sw2 += wg * wg; sd += (wg - w[10]) * (wg - w[10]); salive += if z > 0 { wg } else { 0.0 };
        let i = if z > 0 { 0 } else { 1 };
        if kept[i] < (if z > 0 { 2 } else { 1 }) { kept[i] += 1; paths.push((fam + 1, w)); }
    }
    let nf = n_fam as f64;
    let show = |label: &str, mean: f64, msq: f64, exact: f64| { // msq: the mean of the squares
        let se = ((msq - mean * mean) / nf).sqrt();
        assert!((mean - exact).abs() < 4.0 * se, "{}", label);
        println!("simulated {}: {:.4} +- {:.4} (exact {:.4})", label, mean, se, exact);
    };
    let q20 = qs[g_max];
    show("share dead by generation 20", dead / nf, dead / nf, q20);
    show("mean W_20", sw / nf, sw2 / nf, 1.0);
    let (vw20, vw10) = (fl(vw) * (1.0 - 1.0 / mf.powi(20)), fl(vw) * (1.0 - 1.0 / mf.powi(10)));
    println!("simulated mean W_20^2: {:.4} (exact 1 + Var(W_20) = {:.4}); mean (W_20 - W_10)^2: {:.4} (exact {:.4})", sw2 / nf, 1.0 + vw20, sd / nf, vw20 - vw10);
    println!("simulated mean W_20 among the {} families alive: {:.4} (exact 1/(1 - q_20) = {:.4})", n_fam - dead as usize, salive / (nf - dead), 1.0 / (1.0 - q20));
    assert!((sd / nf - (vw20 - vw10)).abs() < 0.15 && (salive / (nf - dead) - 1.0 / (1.0 - q20)).abs() < 0.1);
    paths.sort_by_key(|p| p.0);
    for (fam, w) in &paths { println!("path, family {}, W_n for n = 0..20: {}", fam, fx(w, 2)); }
    println!("wrong: E[Z_20] = m^20 = {:.4}, yet P(dead by 20) = {:.4}; wrong: larger root 1 says sure death, true {:.4}", mf.powi(20), q20, fl(qq));
    println!("wrong: critical E[Z_100] = mc^100 = {:.4}, yet P(alive at 100) = {:.4}", mc.powi(100), crit[1].1);
    println!("ALL CHECKS PASS");
}
