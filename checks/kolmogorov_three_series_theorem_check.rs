// Kolmogorov's three-series theorem -- the check behind the card.  Rust std only.
// Fair signs e_n = +1 or -1.  Series A: sum e_n/n, variances 1/n^2.  Series B: sum e_n/sqrt(n),
// variances 1/n.  Roads: all 2^16 sign patterns counted exactly, against Kolmogorov's maximal
// inequality; partial sums bracketed by the integral test, against pi^2/6; 1000 simulated
// runs (SplitMix64, seed 20261123) against the spreads and both inequalities; the three
// series for four examples, with a telescoping product against a direct product.
struct SplitMix(u64);
impl SplitMix {
    fn draw(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    println!("sum of 1/n^2 to N, integral-test bracket for pi^2/6; sum of 1/n to N, bracket [ln(N+1), 1 + ln N]");
    let (mut v2, mut h1, mut n) = (0.0f64, 0.0f64, 0u64);
    let mut brk: Vec<(f64, f64, f64, f64, f64)> = Vec::new();
    for &big in [16u64, 100, 1000, 10000, 1000000].iter() {
        while n < big {
            n += 1;
            v2 += 1.0 / (n * n) as f64;
            h1 += 1.0 / n as f64;
        }
        let nf = big as f64;
        brk.push((v2 + 1.0 / (nf + 1.0), v2 + 1.0 / nf, (nf + 1.0).ln(), h1, 1.0 + nf.ln()));
        println!("N={:7}: sum 1/n^2 {:.6}, pi^2/6 in [{:.6}, {:.6}]; sum 1/n {:.4}",
            big, v2, v2 + 1.0 / (nf + 1.0), v2 + 1.0 / nf, h1);
    }
    let z2 = std::f64::consts::PI * std::f64::consts::PI / 6.0;
    println!("pi^2/6 = {:.6}; sd of the limit of series A = sqrt(pi^2/6) = {:.4}", z2, z2.sqrt());

    const K: usize = 16;
    const L: i64 = 720720; // lcm(1..16): sums become integers
    let step: Vec<i64> = (1..=K as i64).map(|k| L / k).collect();
    let lam: [(i64, i64); 4] = [(3, 2), (2, 1), (5, 2), (3, 1)]; // lambda = p/q
    let (mut hit_max, mut hit_end) = ([0i64; 4], [0i64; 4]);
    let (mut s2sum, mut s2hit) = (0i128, 0i128);
    for mask in 0u32..(1 << K) {
        let (mut s, mut mx) = (0i64, 0i64);
        for k in 0..K {
            s += if mask >> k & 1 == 1 { step[k] } else { -step[k] };
            mx = mx.max(s.abs());
        }
        s2sum += (s as i128) * (s as i128);
        for (i, &(p, q)) in lam.iter().enumerate() {
            if mx * q >= p * L { hit_max[i] += 1; }
            if s.abs() * q >= p * L { hit_end[i] += 1; }
        }
        if mx >= 2 * L { s2hit += (s as i128) * (s as i128); }
    }
    let vnum: i128 = step.iter().map(|&t| (t as i128) * (t as i128)).sum(); // V16 = vnum / L^2
    let l2 = (L as i128) * (L as i128);
    println!("series A, n = 16, all 65536 sign patterns: Var(S_16) = {:.6}, counted {:.6}",
        vnum as f64 / l2 as f64, s2sum as f64 / (l2 << K) as f64);
    println!("lambda, P(|S_16| >= lambda), P(max_k<=16 |S_k| >= lambda), bound Var(S_16)/lambda^2");
    let mut ineq_ok = true;
    for (i, &(p, q)) in lam.iter().enumerate() {
        let (bn, bd) = (vnum * (q * q) as i128, l2 * (p * p) as i128); // bound = bn / bd
        ineq_ok &= hit_end[i] <= hit_max[i] && (hit_max[i] as i128) * bd <= bn * 65536;
        println!("{:.1}: {:.6} {:.6} {:.6}", p as f64 / q as f64, hit_end[i] as f64 / 65536.0,
            hit_max[i] as f64 / 65536.0, bn as f64 / bd as f64);
    }
    println!("lambda = 2: E[S_16^2 on the crossing set] = {:.6} >= 4 P(crossing) = {:.6}",
        s2hit as f64 / L as f64 / L as f64 / 65536.0, 4.0 * hit_max[1] as f64 / 65536.0);

    const RUNS: usize = 1000;
    const N: usize = 10000;
    let chart = [10usize, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000];
    let spread_at = [100usize, 1000, 10000];
    let a: Vec<f64> = (0..=N).map(|k| if k == 0 { 0.0 } else { 1.0 / k as f64 }).collect();
    let b: Vec<f64> = (0..=N).map(|k| if k == 0 { 0.0 } else { 1.0 / (k as f64).sqrt() }).collect();
    let mut sq = [[0.0f64; 2]; 3];
    let (mut osc_hits, mut stay_hits, mut d_sum, mut d_sq) = (0usize, 0usize, 0.0f64, 0.0f64);
    let mut rng = SplitMix(20261123);
    for r in 0..RUNS {
        let (mut sa, mut sb, mut sd) = (0.0f64, 0.0f64, 0.0f64);
        let (mut sa1000, mut osc, mut bmax) = (0.0f64, 0.0f64, 0.0f64);
        let (mut pa, mut pb) = (Vec::new(), Vec::new());
        for k in 1..=N {
            let z = rng.draw();
            let e = if z >> 63 == 1 { 1.0 } else { -1.0 }; // fair sign from the top bit
            sa += e * a[k];
            sb += e * b[k];
            sd += (if z >> 62 == 0 { -1.0 } else { 1.0 }) * a[k]; // + with chance 3/4: series D
            bmax = bmax.max(sb.abs());
            if k == 1000 { sa1000 = sa; } else if k > 1000 { osc = osc.max((sa - sa1000).abs()); }
            if let Some(i) = spread_at.iter().position(|&m| m == k) {
                sq[i][0] += sa * sa;
                sq[i][1] += sb * sb;
            }
            if r == 0 && chart.contains(&k) { pa.push(sa); pb.push(sb); }
        }
        if osc >= 0.05 { osc_hits += 1; }
        if bmax <= 1.5 { stay_hits += 1; }
        d_sum += sd;
        d_sq += sd * sd;
        if r == 0 {
            println!("run 1, same signs: n, series A, series B");
            for i in 0..chart.len() { println!("{:5}: {:8.4} {:8.4}", chart[i], pa[i], pb[i]); }
            let fa: Vec<String> = pa.iter().map(|x| format!("{:.2}", x)).collect();
            let fb: Vec<String> = pb.iter().map(|y| format!("{:.2}", y)).collect();
            println!("figure A: {}", fa.join(", "));
            println!("figure B: {}", fb.join(", "));
        }
    }
    println!("{} runs: n, spread of S_n for A (simulated, sqrt sum 1/k^2), for B (simulated, sqrt sum 1/k)", RUNS);
    let (mut va, mut vb, mut va1000) = (0.0f64, 0.0f64, 0.0f64);
    let mut spread_ok = true;
    for k in 1..=N {
        va += 1.0 / (k * k) as f64;
        vb += 1.0 / k as f64;
        if k == 1000 { va1000 = va; }
        if let Some(i) = spread_at.iter().position(|&m| m == k) {
            let (ra, rb) = ((sq[i][0] / RUNS as f64).sqrt(), (sq[i][1] / RUNS as f64).sqrt());
            spread_ok &= (ra / va.sqrt() - 1.0).abs() < 0.1 && (rb / vb.sqrt() - 1.0).abs() < 0.1;
            println!("{:5}: A {:.4} {:.4}   B {:.4} {:.4}", k, ra, va.sqrt(), rb, vb.sqrt());
        }
    }
    let tail = va - va1000;
    println!("A: share of runs with max over 1000<k<=10000 of |S_k - S_1000| >= 0.05: {:.3}; bound {:.7}/0.05^2 = {:.4}",
        osc_hits as f64 / RUNS as f64, tail, tail / 0.0025);
    println!("B: share of runs with max over k<=10000 of |S_k| <= 1.5: {:.3}; converse bound (1.5+1)^2/{:.4} = {:.4}",
        stay_hits as f64 / RUNS as f64, vb, 6.25 / vb);
    println!("B: the same converse bound at n = 1000000: 6.25/{:.4} = {:.4}", h1, 6.25 / h1);

    println!("three series, truncation level 1: sum P(|X_n|>1), sum E[Y_n], sum Var(Y_n) -> verdict");
    println!("A  +-1/n          : 0, 0, {:.4} -> converges", z2);
    println!("B  +-1/sqrt(n)    : 0, 0, infinite ({:.4} by n = 1000000) -> diverges", h1);
    println!("C  n^2 w.p. 1/n^2 : {:.4}, 1, 0 -> converges (sum Var(X_n) = sum (n^2 - 1) is infinite)", z2 - 1.0);
    println!("D  +1/n w.p. 3/4  : 0, infinite ({:.4} by n = 1000000), {:.4} -> diverges", h1 / 2.0, 0.75 * z2);
    let mut prod = 1.0f64;
    for k in 2..=N { prod *= 1.0 - 1.0 / (k * k) as f64; }
    let tele = (N + 1) as f64 / (2 * N) as f64;
    println!("C: P(no jump for 2<=n<={}) = product {:.6}, telescoped (N+1)/(2N) = {:.6}", N, prod, tele);
    let dm = d_sum / RUNS as f64;
    let dsd = (d_sq / RUNS as f64 - dm * dm).sqrt();
    println!("D: {} runs, mean of S_10000 {:.4} (sum of means {:.4}), sd {:.4} (sqrt of sum 3/(4k^2) {:.4})",
        RUNS, dm, vb / 2.0, dsd, (0.75 * va).sqrt());
    println!("Kolmogorov's strong law, fair die: sum Var((X_n - 3.5)/n) = (35/12)(pi^2/6) = {:.6}", 35.0 / 12.0 * z2);

    assert!(brk.iter().all(|&(lo, hi, l1, h, u1)| lo <= z2 && z2 <= hi && l1 <= h && h <= u1)); // series vs closed forms
    assert!(s2sum == vnum << K); // Var(S_16): count vs formula
    assert!(ineq_ok); // end <= max <= Kolmogorov's bound, counted exactly
    assert!(s2hit >= 4 * l2 * hit_max[1] as i128); // the proof's key step, counted
    assert!(spread_ok); // simulated spreads vs square roots of variance sums
    assert!(osc_hits as f64 / RUNS as f64 <= tail / 0.0025 && stay_hits as f64 / RUNS as f64 <= 6.25 / vb);
    assert!((prod - tele).abs() < 1e-9); // product vs telescoping
    assert!((dm - vb / 2.0).abs() < 4.0 * (0.75 * va / RUNS as f64).sqrt()); // simulation vs sum of means
    println!("ALL CHECKS PASS");
}
