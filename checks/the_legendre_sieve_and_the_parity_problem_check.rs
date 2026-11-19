// Legendre's sieve and the parity problem -- the same check as the Python, in Rust.
// No crates.  Road one crosses out multiples and counts what is left.
// Road two is Legendre's signed sum of floor(x/d) over squarefree d.  Road three
// is the main term x * prod(1 - 1/p), set against the 2^k ceiling on the error.
const X: usize = 1_000_000;

fn com(v: f64, d: usize, plus: bool) -> String {      // thousands commas, d decimals
    let s = format!("{:.*}", d, v.abs());
    let (int, frac) = match s.find('.') { Some(i) => (&s[..i], &s[i..]), None => (&s[..], "") };
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    let sign = if v < 0.0 { "-" } else if plus { "+" } else { "" };
    format!("{}{}{}", sign, out, frac)
}
fn ci(v: usize) -> String { com(v as f64, 0, false) }
fn big(k: usize) -> String {                          // 2^k, written for the reader
    if k <= 30 { return ci(1usize << k) }
    let e = (k as f64 * 2f64.log10()) as i32;
    format!("{:.2} x 10^{}", 2f64.powi(k as i32) / 10f64.powi(e), e)
}
struct Leg { layers: Vec<i64>, terms: usize, near: f64, frac: f64 }
fn go(x: usize, ps: &[usize], i: usize, d: usize, k: usize, o: &mut Leg) {
    let s = if k % 2 == 0 { 1.0 } else { -1.0 };
    o.layers[k] += (x / d) as i64; o.terms += 1;
    o.near += s * (x as f64 / d as f64); o.frac += (x % d) as f64 / d as f64;
    for j in i..ps.len() {
        if d * ps[j] > x { break }
        go(x, ps, j + 1, d * ps[j], k + 1, o);
    }
}
fn legendre(x: usize, ps: &[usize]) -> (Leg, i64) {   // walk squarefree d <= x built from ps
    let mut o = Leg { layers: vec![0; ps.len() + 1], terms: 0, near: 0.0, frac: 0.0 };
    go(x, ps, 0, 1, 0, &mut o);
    let sum = o.layers.iter().enumerate().map(|(k, v)| if k % 2 == 0 { *v } else { -*v }).sum();
    (o, sum)
}
fn count(x: usize, ps: &[usize]) -> usize { (1..=x).filter(|n| ps.iter().all(|p| n % p != 0)).count() }
fn mainterm(x: f64, ps: &[usize]) -> f64 {
    let mut m = 1.0;
    for &p in ps { m *= 1.0 - 1.0 / p as f64 }
    x * m
}

fn main() {
    let mut spf: Vec<usize> = (0..=X).collect();      // smallest prime factor of each n
    for i in 2..=1000 {
        if spf[i] == i { let mut j = i * i; while j <= X { if spf[j] == j { spf[j] = i } j += i } }
    }
    let primes: Vec<usize> = (2..=X).filter(|&p| spf[p] == p).collect();
    let mut lam = vec![0i64; X + 1]; lam[1] = 1;      // Liouville's lambda from spf
    for n in 2..=X { lam[n] = -lam[n / spf[n]] }
    let mut lsum = vec![0i64; X + 1];                 // running total L(n) of lambda
    for n in 1..=X { lsum[n] = lsum[n - 1] + lam[n] }
    let pi = |y: usize| primes.iter().filter(|&&p| p <= y).count();
    let small = [2usize, 3, 5, 7];
    let (r, s100) = legendre(100, &small);
    println!("x = 100, primes 2, 3, 5, 7: layers [{}, {}, {}, {}] -> Legendre {}; counted {}; pi(100) - pi(10) + 1 = {} - {} + 1",
             r.layers[0], r.layers[1], r.layers[2], r.layers[3], s100, count(100, &small), pi(100), pi(10));
    let m100 = mainterm(100.0, &small);
    println!("x = 100: {} terms, {} with d <= 100; main term {:.3}; error {:+.3}", 1 << 4, r.terms, m100, s100 as f64 - m100);
    let mut divs: Vec<(u32, usize)> = (0..16usize)
        .map(|m| (m.count_ones(), (0..4).filter(|b| m >> b & 1 == 1).map(|b| small[b]).product())).collect();
    divs.sort();
    let shown: Vec<String> = divs.iter().map(|(_, d)| format!("{}:{}", d, 100 / d)).collect();
    println!("x = 100, each d: floor(100/d): {}", shown.join(" "));
    let idsum: i64 = divs.iter().map(|&(k, d)| if k % 2 == 0 { (210 / d) as i64 } else { -((210 / d) as i64) }).sum();
    println!("sum of mu(d) * 210/d over d | 210 = {}; prod (p - 1) = {}", idsum, small.iter().map(|p| p - 1).product::<usize>());
    println!("x = 100, primes 2, 3, 5 only: counted {}; main term {:.3}", count(100, &small[..3]), mainterm(100.0, &small[..3]));
    println!("x = 10^6: z | k | 2^k | terms d <= x | Legendre | counted | main term | error | error/main");
    let mut alive = vec![true; X + 1]; alive[0] = false;
    let mut rows: Vec<(usize, Leg, i64, f64, usize)> = Vec::new();
    for z in [7usize, 30, 100, 1000] {                // road one, prime by prime
        let ps: Vec<usize> = primes.iter().cloned().filter(|&p| p <= z).collect();
        for &p in &ps { let mut j = p; while j <= X { alive[j] = false; j += p } }
        let (r, sum) = legendre(X, &ps);
        let (m, c) = (mainterm(X as f64, &ps), alive.iter().filter(|&&b| b).count());
        println!("{:>4} | {:>3} | {} | {} | {} | {} | {} | {} | {:+.4}%", z, ps.len(), big(ps.len()), ci(r.terms),
                 com(sum as f64, 0, false), ci(c), com(m, 1, false), com(c as f64 - m, 1, true), 100.0 * (c as f64 - m) / m);
        rows.push((ps.len(), r, sum, m, c));
    }
    let (_, r, sum, m, c) = &rows[3];
    let (m, c) = (*m, *c);
    println!("z = 1000 split: near part (d <= x) {}; tail (d > x) {}; rounding {}; rounding terms in size {}",
             com(r.near, 1, false), com(m - r.near, 1, true), com(*sum as f64 - r.near, 1, true), com(r.frac, 1, false));
    let pix = primes.len();
    println!("pi(10^6) = {}; survivors at z = 1000 are 1 and the primes above 1000: {}; main / counted = {:.4}; 2e^-gamma = {:.4}",
             ci(pix), ci(1 + pix - 168), m / c as f64, 2.0 * (-0.5772156649015329f64).exp());
    let cross = *primes.iter().find(|&&p| 2f64.powi(pi(p) as i32) > mainterm(X as f64, &primes[..pi(p)])).unwrap();
    println!("x = 10^6: 2^k first passes the main term at z = {} (k = {})", cross, pi(cross));
    println!("Legendre's best bound on pi(x): x | best z | bound | x / log x | ratio");
    let mut best = Vec::new();
    for e in [6i32, 9, 12, 15] {
        let x = 10f64.powi(e);
        let mut b = (f64::MAX, 0usize);
        for &z in &primes[..60] {
            let k = pi(z);
            let v = (k as f64 - 1.0 + mainterm(x, &primes[..k])) + 2f64.powi(k as i32);
            if v < b.0 { b = (v, z) }
        }
        best.push((x, b.0));
        println!("10^{} | {} | {} | {} | {:.3}", e, b.1, com(b.0, 0, false), com(x / x.ln(), 0, false), b.0 * x.ln() / x);
    }
    let chart = [10usize, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    let c1: Vec<String> = chart.iter().map(|&z| format!("{:.2}", mainterm(X as f64, &primes[..pi(z)]).log10())).collect();
    let c2: Vec<String> = chart.iter().map(|&z| format!("{:.2}", pi(z) as f64 * 2f64.log10())).collect();
    println!("chart, log10 main term: {}", c1.join(", "));
    println!("chart, log10 2^k: {}", c2.join(", "));
    let plus = (1..=X).filter(|&n| lam[n] == 1).count();
    println!("lambda = +1 below 10^6: {}; lambda = -1: {}; L(10^6) = {}", ci(plus), ci(X - plus), lsum[X]);
    let mut om = vec![0u8; X + 1];                    // Omega(n) a second way: +1 per prime power dividing n
    for &p in &primes { let mut q = p; while q <= X { let mut j = q; while j <= X { om[j] += 1; j += q } q *= p } }
    let l2: i64 = (1..=X).map(|n| 1 - 2 * (om[n] & 1) as i64).sum();
    println!("d | A+_d counted | A+_d by formula | A-_d | x/(2d)");
    for d in [2usize, 3, 6, 210] {
        let direct = (d..=X).step_by(d).filter(|&n| lam[n] == 1).count();
        let formula = ((X / d) as i64 + lam[d] * lsum[X / d]) / 2;
        println!("{} | {} | {} | {} | {}", d, ci(direct), com(formula as f64, 0, false), ci(X / d - direct), com(X as f64 / (2 * d) as f64, 1, false));
        assert!(direct as i64 == formula);             // parity counts, two roads
    }
    let mut worst = (0.0f64, 0usize);
    for d in 1..=1000usize {
        if primes[..11].iter().any(|p| d % (p * p) == 0) { continue }
        let v = (((X / d) as i64 + lam[d] * lsum[X / d]) as f64 / 2.0 - X as f64 / (2 * d) as f64).abs();
        if v > worst.0 || (v == worst.0 && d > worst.1) { worst = (v, d) }
    }
    println!("largest |A+_d - x/(2d)| over squarefree d <= 1000: {:.1}, at d = {}", worst.0, worst.1);
    let sp = (1..=X).filter(|&n| alive[n] && lam[n] == 1).count();
    let sm = (1..=X).filter(|&n| alive[n] && lam[n] == -1).count();
    println!("survivors at z = 1000: lambda = +1 {}; lambda = -1 {}; main term for each {}", ci(sp), ci(sm), com(m / 2.0, 1, false));
    let is_p = |n: usize| n <= X && spf[n] == n && n > 1;
    let twins = primes.iter().filter(|&&p| is_p(p + 2)).count();
    let tw = (1..X - 1).filter(|&n| alive[n] && alive[n + 2]).count();
    let mut tp = 1.0;
    for &p in &primes[1..168] { tp *= 1.0 - 2.0 / p as f64 }
    let tmain = X as f64 * 0.5 * tp;
    println!("twin pairs below 10^6: {}; pairs above 1000 by the sieve {}; main term {}; ratio {:.4}", ci(twins), ci(tw), com(tmain, 1, false), tmain / tw as f64);
    for (k, _, sum, m, c) in &rows {
        assert!(*sum == *c as i64 && (*c as f64 - m).abs() <= 2f64.powi(*k as i32)); // Legendre = count; error under 2^k
    }
    assert!(count(100, &small) == 22 && s100 == 22 && pi(100) - pi(10) + 1 == 22 && idsum == 48);
    assert!(pix == 78498 && c == 1 + pix - 168);       // pi(10^6), known table
    assert!(sp == 1 && sm == pix - 168 && l2 == lsum[X]);  // L(10^6) two ways
    let low_twins = primes.iter().filter(|&&p| p + 2 <= 1000 && is_p(p + 2)).count();
    assert!(twins == 8169 && tw == twins - low_twins);
    assert!(best[0].1 >= pix as f64 && best.iter().all(|(x, b)| b * x.ln() / x > 1.5));
    println!("ALL CHECKS PASS");
}
