// Large prime gaps and the Cramer model -- the same check as the Python, in Rust.
// No crates.  Road one sieves every prime up to 10^8 and finds the record gaps.
// Road two tests the endpoints with Miller-Rabin and re-sieves the 1,132-gap by
// every prime up to its square root.  Road three is the coin-flip model, by formula
// and by simulation.  Gaps above 10^8 are quoted from the table of Oliveira e Silva,
// Herzog and Pardi (2014), labelled so.
fn com(v: f64, d: usize) -> String {                  // thousands commas, d decimals
    let s = format!("{:.*}", d, v.abs());
    let (int, frac) = match s.find('.') { Some(i) => (&s[..i], &s[i..]), None => (&s[..], "") };
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    format!("{}{}{}", if v < 0.0 { "-" } else { "" }, out, frac)
}
fn ci(v: u64) -> String { com(v as f64, 0) }
fn sci(v: f64) -> String {                            // 4.829 x 10^13
    let s = format!("{:.3e}", v);
    let (m, e) = s.split_at(s.find('e').unwrap());
    format!("{} x 10^{}", m, &e[1..])
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn mulmod(a: u64, b: u64, n: u64) -> u64 { ((a as u128 * b as u128) % n as u128) as u64 }
fn powmod(mut b: u64, mut e: u64, n: u64) -> u64 {
    let mut r = 1u64; b %= n;
    while e > 0 { if e & 1 == 1 { r = mulmod(r, b, n) } b = mulmod(b, b, n); e >>= 1 }
    r
}
fn is_prime(n: u64) -> bool {                         // Miller-Rabin, exact below 3.3 x 10^24
    if n < 2 { return false }
    let bs = [2u64, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
    for &b in &bs { if n % b == 0 { return n == b } }
    let (mut d, mut r) = (n - 1, 0);
    while d % 2 == 0 { d /= 2; r += 1 }
    'outer: for &b in &bs {
        let mut x = powmod(b, d, n);
        if x == 1 || x == n - 1 { continue }
        for _ in 0..r - 1 { x = mulmod(x, x, n); if x == n - 1 { continue 'outer } }
        return false;
    }
    true
}
fn splitmix(state: u64) -> (u64, u64) {
    let st = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (st, z ^ (z >> 31))
}

fn main() {
    const N: usize = 100_000_000;
    let mut s = vec![true; N + 1]; s[0] = false; s[1] = false;
    let mut i = 2;
    while i * i <= N { if s[i] { let mut j = i * i; while j <= N { s[j] = false; j += i } } i += 1 }
    let primes: Vec<u64> = (0..=N).filter(|&k| s[k]).map(|k| k as u64).collect();
    let (p, g) = (1693182318746371u64, 1132u64);
    let mr: Vec<u64> = (p..=p + g).filter(|&n| is_prime(n)).collect();
    let mut seg = vec![true; g as usize + 1];         // road two: sieve [P, P + g]
    let root = ((p + g) as f64).sqrt() as u64;
    let root = (root.saturating_sub(2)..root + 3).filter(|r| r * r <= p + g).max().unwrap();
    for &q in &primes {
        if q > root { break }
        let mut j = ((q - p % q) % q) as usize;
        while j <= g as usize { seg[j] = false; j += q as usize }
    }
    let sv: Vec<u64> = (0..=g).filter(|&k| seg[k as usize]).map(|k| p + k).collect();
    let l = (p as f64).ln();
    let shown: Vec<String> = mr.iter().map(|&v| ci(v)).collect();
    println!("p = {}: primes in [p, p + {}] by Miller-Rabin: {}; by sieve to {}: {} found; composites between {}", ci(p), ci(g), shown.join(", "), ci(root), sv.len(), ci(g - 1));
    let gf = g as f64;
    println!("log p = {:.4}; (log p)^2 = {:.2}; merit g / log p = {:.2}; g / (log p)^2 = {:.4}", l, l * l, gf / l, gf / (l * l));
    let gstar = l * (l - l.ln());
    println!("model: chance a gap is >= {} = e^-{:.2} = {}; primes below p about {}; expected such gaps {:.2}; predicted largest gap log p (log p - log log p) = {:.1}",
             ci(g), gf / l, sci((-gf / l).exp()), sci(p as f64 / l), p as f64 / l * (-gf / l).exp(), gstar);
    let eg = 2.0 * (-0.5772156649015329f64).exp();
    println!("Granville 2e^-gamma = {:.4}; 2e^-gamma (log p)^2 = {:.1}", eg, eg * l * l);
    let l10 = (p as f64).log10();
    println!("base-10 slip: (log10 p)^2 = {:.1}; g / (log10 p)^2 = {:.2}", l10 * l10, gf / (l10 * l10));
    println!("quoted from the table: every maximal gap below 4 x 10^18 checked (2014); the gap of 1,132 first found in 1999");
    let (mut rec, mut best): (Vec<(u64, u64)>, u64) = (Vec::new(), 0); // road one: record gaps to 10^8
    for w in primes.windows(2) { if w[1] - w[0] > best { best = w[1] - w[0]; rec.push((best, w[0])) } }
    println!("record gaps below 10^8 ({}), gap@prime:", rec.len());
    for c in rec.chunks(7) {
        let row: Vec<String> = c.iter().map(|&(d, a)| format!("{}@{}", d, ci(a))).collect();
        println!("  {}", row.join(", "));
    }
    let known = [1u64, 2, 4, 6, 8, 14, 18, 20, 22, 34, 36, 44, 52, 72, 86, 96, 112, 114, 118, 132, 148, 154, 180, 210, 220];
    let rec_d: Vec<u64> = rec.iter().map(|r| r.0).collect();
    let mr_ok = rec.iter().all(|&(d, a)| is_prime(a) && is_prime(a + d) && !(a + 1..a + d).any(is_prime));
    println!("records match the quoted table: {}; every endpoint and gap confirmed by Miller-Rabin: {}", yn(rec_d == known), yn(mr_ok));
    let quoted = [282u64, 354, 464, 540, 674, 804, 906, 1132];
    let mut gx = vec![0u64; 17];
    println!("x | G(x) | (log x)^2 | G / (log x)^2 | model log x (log x - log log x)");
    for e in 2..17u32 {
        let x = 10u64.pow(e);
        let gg = if e > 8 { quoted[e as usize - 9] } else { rec.iter().filter(|&&(d, a)| a + d <= x).map(|r| r.0).max().unwrap() };
        gx[e as usize] = gg;
        let lx = (x as f64).ln();
        println!("10^{} | {}{} | {:.1} | {:.3} | {:.1}", e, ci(gg), if e > 8 { " (quoted)" } else { "" }, lx * lx, gg as f64 / (lx * lx), lx * (lx - lx.ln()));
    }
    let n8 = primes.len();
    let avg = (primes[n8 - 1] - 2) as f64 / (n8 - 1) as f64;
    println!("pi(10^8) = {}; average gap (p_last - 2) / (count - 1) = {:.3}; log 10^8 = {:.3}; largest gap {}", ci(n8 as u64), avg, (N as f64).ln(), rec[rec.len() - 1].0);
    let mut tail = [0u64; 6];                         // share of gaps above t log p
    for w in primes[1..].windows(2) {
        let r = (w[1] - w[0]) as f64 / (w[0] as f64).ln();
        for t in 1..6 { if r > t as f64 { tail[t] += 1 } }
    }
    let m = (n8 - 2) as f64;
    println!("t | share of gaps after p above t log p, p < 10^8 | model e^-t");
    for t in 1..6 { println!("{} | {:.5} | {:.5}", t, tail[t] as f64 / m, (-(t as f64)).exp()) }
    const X: usize = 1_000_000;
    let mut inv = vec![0.0f64; X + 1];
    for n in 3..=X { inv[n] = 1.0 / (n as f64).ln() }
    let mut runs: Vec<(usize, u64)> = Vec::new();
    for seed in 1..=20u64 {                           // road three: the coin-flip model
        let (mut st, mut last, mut mx, mut cnt) = (seed, 2usize, 0usize, 1u64);
        for n in 3..=X {
            let (s2, z) = splitmix(st); st = s2;
            if (z >> 11) as f64 / 9007199254740992.0 < inv[n] { mx = mx.max(n - last); last = n; cnt += 1 }
        }
        runs.push((mx, cnt));
    }
    let mxs: Vec<String> = runs.iter().map(|r| r.0.to_string()).collect();
    let mean_cnt = runs.iter().map(|r| r.1).sum::<u64>() as f64 / 20.0;
    let mut expect = 0.0; for v in &inv { expect += v } expect += 1.0;
    let mean_mx = runs.iter().map(|r| r.0).sum::<usize>() as f64 / 20.0;
    let pi6 = primes.partition_point(|&q| q <= X as u64);
    println!("model to 10^6, 20 runs (SplitMix64, seeds 1-20): largest gaps {}", mxs.join(", "));
    println!("  mean largest gap {:.1}; runs above the true 114: {}; mean count {}; expected 1 + sum 1/log n = {}; true pi(10^6) = {}",
             mean_mx, runs.iter().filter(|r| r.0 > 114).count(), com(mean_cnt, 1), com(expect, 1), ci(pi6 as u64));
    let twins = primes.windows(2).filter(|w| w[1] - w[0] == 2 && w[1] <= X as u64).count();
    let mut cram = 0.0; for n in 3..X - 1 { cram += 1.0 / ((n as f64).ln() * ((n + 2) as f64).ln()) }
    let (u0, u1) = (2f64.ln(), (X as f64).ln());     // Simpson in u = log t: dt / log^2 t = e^u du / u^2
    let h = (u1 - u0) / X as f64; let mut simp = u0.exp() / u0.powi(2) + u1.exp() / u1.powi(2);
    for i in 1..X { let u = u0 + i as f64 * h; simp += (if i % 2 == 1 { 4.0 } else { 2.0 }) * u.exp() / u.powi(2) }
    simp *= h / 3.0;
    let mut c2 = 1.0; for &q in &primes[1..pi6] { c2 *= 1.0 - 1.0 / ((q - 1) as f64).powi(2) }
    println!("twin pairs below 10^6: true {}; Cramer model: integral of 1/log^2 t = {}, sum 1/(log n log(n+2)) = {}", ci(twins as u64), com(simp, 1), com(cram, 1));
    println!("twin constant C2 = {:.6}; Hardy-Littlewood 2 C2 x integral = {}", c2, com(2.0 * c2 * simp, 1));
    let (l2, l3) = (l.ln(), l.ln().ln()); let l4 = l3.ln();
    let mut lf = 0.0; for k in 2..g + 1 { lf += (k as f64).log10() }
    let mut lp = 0.0; for &q in primes.iter().filter(|&&q| q <= 1129) { lp += (q as f64).log10() }
    println!("at p: log log p = {:.3}; 2018 lower-bound shape (log p)(log2 p)(log4 p) / (log3 p) = {:.1}; x^0.525 = {}; sqrt(p) log p = {}",
             l2, l * l2 * l4 / l3, sci((0.525 * l).exp()), sci((p as f64).sqrt() * l));
    println!("factorial road: gap of {} needs {}! = 10^{:.1}; primorial road: 1129# = 10^{:.1}", ci(g), ci(g), lf, lp);
    let kb = 1024.0 * 2f64.ln();
    println!("1024-bit primes: log 2^1024 = {:.2}; odd numbers tested on average about {:.1}; (log 2^1024)^2 = {}", kb, kb / 2.0, com(kb * kb, 0));
    let lxs: Vec<f64> = (2..17).map(|e| (10f64.powi(e)).ln()).collect();
    println!("chart G(x): {}", gx[2..].iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart (log x)^2: {}", lxs.iter().map(|lx| format!("{:.0}", lx * lx)).collect::<Vec<_>>().join(", "));
    println!("chart model: {}", lxs.iter().map(|lx| format!("{:.0}", lx * (lx - lx.ln()))).collect::<Vec<_>>().join(", "));
    assert!(mr == sv && mr == vec![p, p + g]);        // two roads agree on the example
    assert!(rec_d == known && mr_ok && rec[rec.len() - 1] == (220, 47326693));
    assert!(n8 == 5761455 && twins == 8169 && simp.round() == 6247.0 && (2.0 * c2 * simp).round() == 8248.0); // known tables
    assert!((2..9).all(|e| (gx[e] as f64) < lxs[e - 2] * lxs[e - 2]) && (cram - simp).abs() < 0.001 * simp);
    assert!((mean_cnt - expect).abs() < 3.0 * expect.sqrt() / 20f64.sqrt());
    assert!((1..4).all(|t| (tail[t] as f64 / m - (-(t as f64)).exp()).abs() < 0.6 * (-(t as f64)).exp()));
    assert!(0.8 < avg / (N as f64).ln() && avg / (N as f64).ln() < 1.0 && (gstar - gf).abs() < 0.05 * gf);
    println!("ALL CHECKS PASS");
}
