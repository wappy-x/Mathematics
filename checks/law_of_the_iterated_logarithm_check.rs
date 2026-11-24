// Law of the iterated logarithm -- the check behind the card.  std only, no crates.
// A fair +-1 walk S_n.  Roads: every path of 14 steps listed, and a table over
// (position, maximum) for 60 steps, against the reflection formula; exact binomial
// tails against the two exponential bounds and a normal tail by Simpson's rule;
// a simulation of 500 walks of 10^6 steps (SplitMix64, seed 20261123).
fn h(n: f64) -> f64 { (2.0 * n * n.ln().ln()).sqrt() } // the envelope sqrt(2 n ln ln n)
fn counts(n: usize) -> Vec<u64> { // paths of n steps ending at each position + n
    let mut c = vec![0u64; 2 * n + 1]; c[n] = 1;
    for _ in 0..n {
        let mut d = vec![0u64; 2 * n + 1];
        for i in 0..2 * n + 1 { if c[i] > 0 { d[i - 1] += c[i]; d[i + 1] += c[i]; } }
        c = d;
    }
    c
}
fn reflect(c: &[u64], n: usize, a: i64) -> u64 { // count for M_n >= a: ending >= a, plus > a
    let mut t = 0;
    for i in 0..c.len() {
        let s = i as i64 - n as i64;
        if s >= a { t += c[i]; } if s > a { t += c[i]; }
    }
    t
}
fn tail(n: u64, a: i64) -> f64 { // P(S_n >= a), a with the parity of n, ratios from the centre
    let nf = n as f64;
    let mut lp = -nf * 2f64.ln();
    for i in 1..=n / 2 { lp += ((nf / 2.0 + i as f64) / i as f64).ln(); }
    let (mut k, mut p, mut tot) = (n / 2, lp.exp(), 0.0);
    while p > 1e-300 && k <= n {
        if 2 * k as i64 - n as i64 >= a { tot += p; }
        p *= (n - k) as f64 / (k + 1) as f64; k += 1;
    }
    tot
}
fn normal_upper(z: f64) -> f64 {
    let m = 2000;
    let f = |x: f64| (-x * x / 2.0).exp() / (2.0 * 3.141592653589793f64).sqrt();
    let w = z / m as f64;
    let mut s = f(0.0) + f(z);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * w); } 0.5 - w / 3.0 * s
}
fn binom_lower_ok(n: u64) -> bool {
    let mut p = 1.0 / 2f64.powi(n as i32);
    for k in 1..n {
        p *= (n - k + 1) as f64 / k as f64;
        let y = (2.0 * k as f64 - n as f64) / n as f64;
        let i = (1.0 + y) / 2.0 * (1.0 + y).ln() + (1.0 - y) / 2.0 * (1.0 - y).ln();
        if p < (-(n as f64) * i).exp() / (2.0 * n as f64).sqrt() * (1.0 - 1e-12) { return false; }
    }
    true
}
fn rand64(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31)
}
fn main() {
    let (n0, nf) = (1_000_000u64, 1e6f64);
    println!("n = {}: sqrt(n) = {:.1}, ln n = {:.4}, ln ln n = {:.4}", n0, nf.sqrt(), nf.ln(), nf.ln().ln());
    println!("envelope h(n) = sqrt(2 n ln ln n) = {:.1} = {:.4} sqrt(n)", h(nf), h(nf) / nf.sqrt());
    println!("die, sigma^2 = 35/12: envelope sigma h(n) = {:.1}", (35.0f64 / 12.0).sqrt() * h(nf));
    let g: Vec<String> = [3, 6, 9, 100].iter().map(|&e| format!("{:.4}", (2.0 * 10f64.powi(e).ln().ln()).sqrt())).collect();
    println!("sqrt(2 ln ln n) at n = 10^3, 10^6, 10^9, 10^100: {}", g.join(" "));
    assert!((h(nf) - 2291.6).abs() < 0.05);
    // 1. reflection
    let (c14, mut listed) = (counts(14), vec![0u64; 16]);
    for p in 0u32..(1 << 14) {
        let (mut s, mut m) = (0i64, 0i64);
        for i in 0..14 { s += if p >> i & 1 == 1 { 1 } else { -1 }; m = m.max(s); }
        for a in 1..=m { listed[a as usize] += 1; }
    }
    for a in 1..15 { assert_eq!(listed[a], reflect(&c14, 14, a as i64)); }
    // tab[s + 60][m]: paths with position s and maximum so far m (from 0)
    let mut tab = vec![vec![0u64; 61]; 121]; tab[60][0] = 1;
    for _ in 0..60 {
        let mut d = vec![vec![0u64; 61]; 121];
        for i in 0..121 { for m in 0..61 {
            let k = tab[i][m];
            if k == 0 { continue; }
            for t in [i - 1, i + 1] { d[t][m.max(if t >= 60 { t - 60 } else { 0 })] += k; }
        } }
        tab = d;
    }
    let (c60, two60) = (counts(60), 2f64.powi(60));
    for a in 1..61usize {
        let mut cnt = 0u64;
        for i in 0..121 { for m in a..61 { cnt += tab[i][m]; } }
        assert_eq!(cnt, reflect(&c60, 60, a as i64));
        assert!(reflect(&c60, 60, a as i64) as f64 / two60 <= 2.0 * (-((a * a) as f64) / 120.0).exp());
    }
    println!("reflection: 14 steps, all 16384 paths listed; 60 steps, table over (S, M): equal");
    for a in [10i64, 20, 30] {
        println!("n=60 a={}: P(M >= a) = {:.6} <= 2 e^(-a^2/2n) = {:.6}", a,
            reflect(&c60, 60, a) as f64 / two60, 2.0 * (-((a * a) as f64) / 120.0).exp());
    }
    // 2. exact binomial tails
    for n in 2..61 { assert!(binom_lower_ok(n)); }
    println!("binomial lower bound C(n,k)/2^n >= e^(-n I)/sqrt(2n): holds for n = 2..60, every k");
    println!("one time n, a = the even number nearest h(n): exact, normal, upper e^(-a^2/2n), lower bound");
    for (e, n) in [(4, 10_000u64), (5, 100_000), (6, 1_000_000)] {
        let x0 = n as f64;
        let a = 2 * (h(x0) / 2.0).round() as i64; let af = a as f64;
        let x = (af + 2.0 * x0.sqrt()) / x0;
        let (ex, nm) = (tail(n, a), normal_upper((af - 1.0) / x0.sqrt()));
        let (lo, up) = (0.5 * (-(af + 2.0 * x0.sqrt()).powi(2) / (2.0 * x0 * (1.0 - x * x))).exp(), (-af * af / (2.0 * x0)).exp());
        assert!(lo <= ex && ex <= up);
        assert!((ex - nm).abs() < 0.02 * ex);
        println!("n=10^{} a={}: {:.6} {:.6} {:.6} {:.7}", e, a, ex, nm, up, lo);
    }
    let (p_s, p_m) = (tail(n0, 2292), tail(n0, 2292) + tail(n0, 2294));
    println!("n=10^6: P(S_n >= 2292) = {:.6}; P(max to n >= 2292) = {:.6} <= 2/ln n = {:.6}", p_s, p_m, 2.0 / nf.ln());
    let p1000 = tail(n0, 1000) + tail(n0, 1002); println!("n=10^6: P(max to n >= 1000) = {:.6}; normal tail beyond 1.96 = {:.4}", p1000, normal_upper(1.96));
    // 3. Borel-Cantelli along n_k = 2^k with c = 1.5
    for k in [10i32, 20, 40] {
        let t = 2.0 * (-2.25 * h(2f64.powi(k)).powi(2) / (2.0 * 2f64.powi(k + 1))).exp();
        assert!((t - 2.0 * (k as f64 * 2f64.ln()).powf(-1.125)).abs() < 1e-12);
        println!("k={}: bound term {:.6} = 2 (k ln 2)^(-1.125)", k, t);
    }
    // 4. the mistakes
    let sb: f64 = (3..=n0).map(|n| (n as f64).ln().powf(-2.25)).sum();
    let sb_lo = (nf - 2.0) * nf.ln().powf(-2.25);
    assert!(sb >= sb_lo); // each term is at least the last
    println!("sqrt n: P(S_n >= 1000) at 10^6 = {:.6}; sqrt(2 n ln n) = {:.1}", tail(n0, 1000), (2.0 * nf * nf.ln()).sqrt());
    println!("Kolmogorov's maximal bound n/a^2 at a = h(10^6): {:.6}; along 2^k, k=20: {:.6}", nf / h(nf).powi(2), 2f64.powi(20) / h(2f64.powi(20)).powi(2));
    println!("every n, c = 1.5: sum of bounds (ln n)^(-2.25), n = 3..10^6: {:.1} >= {:.1}", sb, sb_lo);
    // 5. simulation: R(n) = max of S_m / h(m) over 1000 < m <= n, 8 steps per byte
    let (mut net, mut pre) = ([0i64; 256], [0i64; 256]);
    for b in 0..256usize {
        let (mut s, mut best) = (0i64, -9i64);
        for i in 0..8 { s += if b >> i & 1 == 1 { 1 } else { -1 }; best = best.max(s); }
        net[b] = s; pre[b] = best; }
    let nb = (n0 / 8) as usize;
    let hb: Vec<f64> = (0..nb).map(|j| if j >= 125 { h((8 * j + 1) as f64) } else { 0.0 }).collect();
    let ck: [usize; 9] = [2000, 5000, 10_000, 20_000, 50_000, 100_000, 200_000, 500_000, 1_000_000];
    let (pp, mut state, mut sum_r, mut hit_r, mut hit9) = (500, 20261123u64, [0.0f64; 9], [0u32; 9], [0u32; 9]);
    let (mut end_sq, mut end_above, mut max1000, mut n196) = (0.0f64, 0u32, 0u32, 0u32);
    for _ in 0..pp {
        let (mut s, mut mx, mut r, mut ci, mut w, mut cross) = (0i64, 0i64, -1e9f64, 0usize, 0u64, false);
        for j in 0..nb {
            if j % 8 == 0 { w = rand64(&mut state); }
            let b = ((w >> (8 * (j % 8))) & 255) as usize;
            if j >= 125 && (r < 0.0 || (s + pre[b]) as f64 > r * hb[j] || (!cross && (s + pre[b]) as f64 > 1.96 * ((8 * j + 1) as f64).sqrt())) {
                let mut t = s;
                for i in 0..8 {
                    t += if b >> i & 1 == 1 { 1 } else { -1 };
                    r = r.max(t as f64 / h((8 * j + i + 1) as f64)); cross = cross || t as f64 > 1.96 * ((8 * j + i + 1) as f64).sqrt();
                }
            }
            mx = mx.max(s + pre[b]); s += net[b];
            if 8 * j + 8 == ck[ci] {
                sum_r[ci] += r; hit_r[ci] += (r >= 1.0) as u32; hit9[ci] += (r > 0.9) as u32; if ci < 8 { ci += 1; }
            }
        }
        end_sq += (s * s) as f64 / nf; end_above += (s as f64 >= h(nf)) as u32; max1000 += (mx >= 1000) as u32; n196 += cross as u32;
    }
    let p = pp as f64;
    println!("simulation, {} walks of 10^6 steps, SplitMix64 seed 20261123:", pp);
    println!("n:            {}", ck.iter().map(|n| format!("{:>7}", n)).collect::<Vec<_>>().join(" "));
    println!("mean R(n):    {}", sum_r.iter().map(|v| format!("{:7.4}", v / p)).collect::<Vec<_>>().join(" "));
    println!("share R >= 1: {}", hit_r.iter().map(|&v| format!("{:7.3}", v as f64 / p)).collect::<Vec<_>>().join(" "));
    println!("share R > 0.9:{}", hit9.iter().map(|&v| format!("{:7.3}", v as f64 / p)).collect::<Vec<_>>().join(" "));
    println!("mean S_n^2/n at 10^6 {:.4} (exact 1); share S_n >= h(n) at 10^6 {:.3}", end_sq / p, end_above as f64 / p);
    println!("share with max to 10^6 >= 1000: {:.3} (exact {:.4})", max1000 as f64 / p, p1000);
    println!("share passing 1.96 sqrt(i) at some 1000 < i <= 10^6: {:.3}", n196 as f64 / p);
    assert!((end_sq / p - 1.0).abs() < 4.0 * (2.0 / p).sqrt());
    assert!((max1000 as f64 / p - p1000).abs() < 4.0 * (p1000 * (1.0 - p1000) / p).sqrt());
    assert!((end_above as f64 / p - p_s).abs() < 4.0 * (p_s * (1.0 - p_s) / p).sqrt());
    assert!(n196 >= hit_r[8]); // past i = 1000, h(i) > 1.966 sqrt(i) > 1.96 sqrt(i)
    println!("ALL CHECKS PASS");
}
