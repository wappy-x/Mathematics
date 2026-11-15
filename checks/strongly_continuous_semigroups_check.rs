// Strongly continuous semigroups -- the check behind the card.  Rust std only, no crates.
// A help desk queue moves one step at a time: an arrival adds a caller, a finished call removes one.
// Space: rows of chances p over the counts 0, 1, 2, ...; size ||p|| = sum of |p_n| (the l1 norm).
// Roads: closed forms; uniformization (a Poisson clock driving a jump table); Taylor series with
// repeated squaring; the stationary row as an invariant.  Every computation is a truncation.
const LAM: f64 = 4.0;
const MU: f64 = 5.0; // arrivals and completions per hour
type M = Vec<Vec<f64>>;

fn chain(n: usize, servers: usize) -> (Vec<f64>, Vec<f64>) {
    // up and down rates on states 0..n-1, arrivals stop at n-1
    let up = (0..n).map(|k| if k + 1 < n { LAM } else { 0.0 }).collect();
    let dn = (0..n).map(|k| MU * k.min(servers) as f64).collect();
    (up, dn)
}

fn row_at(up: &[f64], dn: &[f64], start: usize, t: f64) -> Vec<f64> {
    // row start of P(t) = sum_k Poisson(Ct; k) K^k, K = I + G/C
    let n = up.len();
    let c = (0..n).map(|m| up[m] + dn[m]).fold(0.0, f64::max);
    let mut v = vec![0.0; n];
    v[start] = 1.0;
    let mut w = (-c * t).exp();
    let mut out: Vec<f64> = v.iter().map(|x| w * x).collect();
    let (mut k, mut mass) = (0usize, w);
    while mass < 1.0 - 1e-15 || (k as f64) < c * t {
        k += 1;
        v = (0..n)
            .map(|m| {
                let mut s = v[m] * (1.0 - (up[m] + dn[m]) / c);
                if m > 0 { s += v[m - 1] * up[m - 1] / c; }
                if m + 1 < n { s += v[m + 1] * dn[m + 1] / c; }
                s
            })
            .collect();
        w *= c * t / k as f64;
        mass += w;
        for m in 0..n { out[m] += w * v[m]; }
    }
    out
}

fn matrix(up: &[f64], dn: &[f64], t: f64) -> M { (0..up.len()).map(|s| row_at(up, dn, s, t)).collect() }
fn mul(a: &M, b: &M) -> M {
    let n = b[0].len();
    a.iter().map(|r| (0..n).map(|j| r.iter().zip(b.iter()).map(|(x, br)| x * br[j]).sum()).collect()).collect()
}
fn gap(a: &M, b: &M) -> f64 {
    a.iter().zip(b).flat_map(|(r, s)| r.iter().zip(s).map(|(x, y)| (x - y).abs())).fold(0.0, f64::max)
}
fn dist_from_start(p: &M) -> f64 { (0..p.len()).map(|n| 2.0 * (1.0 - p[n][n])).fold(0.0, f64::max) }

fn taylor_exp(up: &[f64], dn: &[f64], t: f64) -> M {
    // second road: e^{tG} by Taylor series, then square s = 12 times
    let n = up.len();
    let s = 12;
    let mut g = vec![vec![0.0; n]; n];
    for k in 0..n {
        g[k][k] = -(up[k] + dn[k]);
        if k + 1 < n { g[k][k + 1] = up[k]; }
        if k > 0 { g[k][k - 1] = dn[k]; }
    }
    let a: M = g.iter().map(|r| r.iter().map(|x| x * t / 2f64.powi(s)).collect()).collect();
    let mut e: M = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let mut term = e.clone();
    for k in 1..12 {
        term = mul(&term, &a).iter().map(|r| r.iter().map(|x| x / k as f64).collect()).collect();
        for i in 0..n { for j in 0..n { e[i][j] += term[i][j]; } }
    }
    for _ in 0..s { e = mul(&e, &e); }
    e
}

fn two_state(t: f64, lam: f64) -> M {
    let e = (-(lam + MU) * t).exp();
    let s = lam + MU; vec![vec![MU / s + lam / s * e, lam / s * (1.0 - e)], vec![MU / s * (1.0 - e), lam / s + MU / s * e]]
}
fn yes(ok: bool) -> &'static str { if ok { "yes" } else { "no" } }

fn main() {
    // 1. The desk with no hold line (N = 2): closed form against uniformization.
    let (up2, dn2) = chain(2, 1);
    for &t in &[0.25, 0.5, 0.75] {
        let p = two_state(t, LAM);
        assert!(gap(&p, &matrix(&up2, &dn2, t)) < 1e-12);
        println!("no hold line, P({}) = [[{:.6}, {:.6}], [{:.6}, {:.6}]]", t, p[0][0], p[0][1], p[1][0], p[1][1]);
    }
    let pp = mul(&two_state(0.25, LAM), &two_state(0.5, LAM));
    println!("no hold line, P(0.25) P(0.5) row 0 = {:.6}, {:.6}; P(0.75) row 0 = {:.6}", pp[0][0], pp[0][1], two_state(0.75, LAM)[0][0]);
    let (h1, h2) = (two_state(0.25, LAM)[0][0] * two_state(0.5, LAM)[0][0], two_state(0.25, LAM)[0][1] * two_state(0.5, LAM)[1][0]);
    println!("by hand, 5/9 = {:.6}, e^-2.25 = {:.6}, e^-4.5 = {:.6}, e^-6.75 = {:.6}, products {:.6} + {:.6}", 5.0 / 9.0, (-2.25f64).exp(), (-4.5f64).exp(), (-6.75f64).exp(), h1, h2);
    assert!(gap(&pp, &two_state(0.75, LAM)) < 1e-12 && gap(&two_state(0.0, LAM), &vec![vec![1.0, 0.0], vec![0.0, 1.0]]) < 1e-15);

    // 2. One agent with a hold line (M/M/1), cut at N = 40 states: the semigroup laws.
    let (up, dn) = chain(40, 1);
    let (a, b, c) = (matrix(&up, &dn, 0.25), matrix(&up, &dn, 0.5), matrix(&up, &dn, 0.75));
    let law = gap(&mul(&a, &b), &c);
    let road = gap(&c, &taylor_exp(&up, &dn, 0.75));
    let tot: f64 = (0..40).map(|n| 0.8f64.powi(n)).sum();
    let pi: Vec<f64> = (0..40).map(|n| 0.8f64.powi(n) / tot).collect();
    let inv: f64 = (0..40).map(|n| ((0..40).map(|m| pi[m] * c[m][n]).sum::<f64>() - pi[n]).abs()).sum();
    let rows = c.iter().map(|r| (r.iter().sum::<f64>() - 1.0).abs()).fold(0.0, f64::max);
    let low = c.iter().flatten().cloned().fold(f64::INFINITY, f64::min);
    println!("M/M/1, N = 40, agree to 1e-12: P(0.25)P(0.5) with P(0.75) {}; uniformization with Taylor {}", yes(law < 1e-12), yes(road < 1e-12));
    println!("M/M/1, N = 40, P(0.75): rows sum to 1 {}; no negative entry {}; stationary row unmoved {}; P(0) = I {}",
        yes(rows < 1e-12), yes(low > -1e-15), yes(inv < 1e-12), yes(gap(&matrix(&up, &dn, 0.0), &taylor_exp(&up, &dn, 0.0)) < 1e-15));
    assert!(law < 1e-12 && road < 1e-12 && inv < 1e-12 && low > -1e-15);
    println!("norm continuity, t (h), ||P(t) - I|| on N = 10, on N = 40, bound 2(1 - e^{{-9t}})");
    let (up10, dn10) = chain(10, 1);
    for &t in &[0.1, 0.01, 0.001] {
        let (d10, d40, bd) = (dist_from_start(&matrix(&up10, &dn10, t)), dist_from_start(&matrix(&up, &dn, t)), -2.0 * (-9.0 * t).exp_m1());
        println!("norm continuity, {}, {:.4}, {:.4}, {:.4}", t, d10, d40, bd);
        assert!(d40 <= bd && (d40 - d10).abs() < 1e-3);
    }

    // 3. An agent for every caller (M/M/infinity): exact P_nn(t) from survivors (binomial) plus newcomers (Poisson).
    let mut lf = vec![0.0f64];
    for k in 1..=10000 { let l = lf[k - 1] + (k as f64).ln(); lf.push(l); }
    let stay = |n: usize, t: f64| -> f64 {
        // chance to be at n again after t hours, starting from n
        let (p, q) = ((-MU * t).exp(), -(-MU * t).exp_m1());
        let m = LAM / MU * q;
        (0..=n.min(200)).map(|k| (lf[n] - lf[k] - lf[n - k] + (n - k) as f64 * p.ln() + k as f64 * q.ln()
            - m + k as f64 * m.ln() - lf[k]).exp()).sum()
    };
    let sgn = |n: usize| if n % 2 == 0 { 1.0 } else { -1.0 };
    let parity = |n: usize, t: f64| -> f64 {
        // (P(t)f)(n) for f(n) = (-1)^n, in closed form
        sgn(n) * (2.0 * (-MU * t).exp() - 1.0).powi(n as i32) * (-2.0 * LAM / MU * -(-MU * t).exp_m1()).exp()
    };
    let (u80, d80) = chain(80, 80);
    let r = row_at(&u80, &d80, 10, 0.05);
    let pf: f64 = r.iter().enumerate().map(|(m, x)| x * sgn(m)).sum();
    println!("M/M/inf, start 10, t = 0.05: P_10,10 exact {:.6}, uniformization on 80 states {:.6}; (P f)(10) exact {:.6}, uniformization {:.6}",
        stay(10, 0.05), r[10], parity(10, 0.05), pf);
    assert!((stay(10, 0.05) - r[10]).abs() < 1e-9 && (parity(10, 0.05) - pf).abs() < 1e-9);
    let l1: f64 = r.iter().enumerate().map(|(m, x)| (x - if m == 10 { 1.0 } else { 0.0 }).abs()).sum();
    assert!((r.iter().sum::<f64>() - 1.0).abs() < 1e-12 && (l1 - 2.0 * (1.0 - r[10])).abs() < 1e-12);
    println!("strong continuity, t (h), distance 2(1 - P_nn(t)) from start n = 1, 10, 100, 1000");
    let starts = [1usize, 10, 100, 1000];
    for &t in &[0.1, 0.01, 0.001] {
        let d: Vec<f64> = starts.iter().map(|&n| 2.0 * (1.0 - stay(n, t))).collect();
        println!("strong continuity, {}, {}", t, d.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", "));
        for (x, &n) in d.iter().zip(&starts) { assert!(*x <= -2.0 * (-(LAM + MU * n as f64) * t).exp_m1()); }
    }
    assert!(2.0 * (1.0 - stay(1000, 0.001)) > 1.98 && 2.0 * (1.0 - stay(1, 0.001)) < 0.02);
    println!("chart, log10 t, {}", (2..13).map(|e| format!("{:.1}", -(e as f64) / 2.0)).collect::<Vec<_>>().join(", "));
    for &n in &[1usize, 100, 10000] {
        let pts: Vec<String> = (2..13).map(|e| format!("{:.3}", 2.0 * (1.0 - stay(n, 10f64.powf(-(e as f64) / 2.0))))).collect();
        println!("chart, start {}, {}", n, pts.join(", "));
    }
    println!("generator size ||G_N|| for M/M/inf cut at N = 10, 100, 1000: {}; M/M/1: {:.0}",
        [10usize, 100, 1000].iter().map(|&n| { let (u, d) = chain(n, n); format!("{:.0}", 2.0 * (0..n).map(|m| u[m] + d[m]).fold(0.0, f64::max)) }).collect::<Vec<_>>().join(", "), 2.0 * (LAM + MU));

    // 4. What breaks.
    let (u10, d10) = chain(10, 10);
    let q10 = (0..10).map(|m| u10[m] + d10[m]).fold(0.0, f64::max);
    let cut = -2.0 * (-q10 * 0.001).exp_m1();
    println!("breaks, trust the N = 10 cut (top leaving rate {:.0} an hour): distance at most {:.4} at t = 0.001 for every start; from 1000 callers it is {:.4}",
        q10, cut, 2.0 * (1.0 - stay(1000, 0.001)));
    assert!(cut < 0.1 && 0.1 < 2.0 * (1.0 - stay(1000, 0.001)));
    println!("breaks, sup norm on f(n) = (-1)^n at t = 0.001, gap |P(t)f(n) - f(n)| for n = 1, 10, 100, 1000: {}",
        starts.iter().map(|&n| format!("{:.4}", (parity(n, 0.001) - sgn(n)).abs())).collect::<Vec<_>>().join(", "));
    assert!((parity(1000, 0.001) - 1.0).abs() > 0.99);
    let (ra, rb) = (two_state(0.5, LAM)[0][0], two_state(0.5, 8.0)[0][0]);
    println!("breaks, rush hour (arrivals 4 then 8 an hour): idle to idle over the first half hour {:.6}, over the second {:.6}", ra, rb);
    assert!((ra - rb).abs() > 0.1);
    println!("ALL CHECKS PASS");
}
