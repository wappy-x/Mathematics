// The large sieve -- the same check as the Python, in Rust.  No crates.  The set A: whole numbers
// 1..10,000 that are a square mod every odd prime up to Q = 100.  Road one: count A exactly by
// Euler's criterion and compare with the perfect squares.  Road two: the large sieve bound
// (N - 1 + Q^2)/L.  Road three: the exponential sums S(a/q) themselves, between both sides of the
// inequality.  Road four: the worst-case ratio for a small case, by Jacobi rotations.
use std::f64::consts::PI;
fn commas(s: String) -> String {                       // 1234567.5 -> 1,234,567.5
    let (int, frac) = match s.find('.') { Some(i) => (s[..i].to_string(), s[i..].to_string()), None => (s.clone(), String::new()) };
    let b = int.as_bytes(); let mut out = String::new();
    for (i, ch) in b.iter().enumerate() { if i > 0 && (b.len() - i) % 3 == 0 { out.push(','); } out.push(*ch as char); }
    out + &frac
}
fn ci(v: u64) -> String { commas(v.to_string()) }
fn cf(v: f64) -> String { commas(format!("{:.3}", v)) }
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn isqrt(n: u64) -> u64 { let mut r = (n as f64).sqrt() as u64; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn modpow(mut b: u64, mut e: u64, m: u64) -> u64 { let mut r = 1 % m; b %= m; while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r }
fn l_of(qm: u64, h: &dyn Fn(u64) -> f64) -> f64 {     // L = sum over squarefree q <= qm of prod over p | q of h(p)
    let mut tot = 0.0;
    for q in 1..=qm {
        let (mut prod, mut m, mut p, mut ok) = (1.0, q, 2u64, true);
        while m > 1 {
            if m % p == 0 { m /= p; if m % p == 0 { ok = false; break; } prod *= h(p); }
            p += 1;
        }
        if ok { tot += prod; }
    }
    tot
}
fn k_sq(p: u64) -> u64 { if p == 2 { 0 } else { (p - 1) / 2 } }      // k_p: classes a square never lands in, mod p
fn h_sq(p: u64) -> f64 { k_sq(p) as f64 / (p - k_sq(p)) as f64 }      // the odds k_p/(p - k_p)
fn budget(n: u64, q: u64) -> u64 { n - 1 + q * q }                     // the large sieve's constant N - 1 + Q^2, tested in road four
fn s2(a_set: &[u64], a: u64, q: u64) -> f64 {          // |S(a/q)|^2, S = sum over members n of e(n a/q)
    let (mut re, mut im) = (0.0f64, 0.0f64);
    for &n in a_set { let t = 2.0 * PI * ((n * a % q) as f64) / q as f64; re += t.cos(); im += t.sin(); }
    re * re + im * im
}
fn main() {
    let (n, q) = (10000u64, 100u64); let lim = 1000002usize;
    let mut isp = vec![true; lim + 1]; isp[0] = false; isp[1] = false;
    let mut i = 2; while i * i <= lim { if isp[i] { let mut j = i * i; while j <= lim { isp[j] = false; j += i; } } i += 1; }
    let ps: Vec<u64> = (2..=q).filter(|&p| isp[p as usize]).collect();
    // Road one: the exact count
    let a_set: Vec<u64> = (1..=n).filter(|&m| ps[1..].iter().all(|&p| { let r = modpow(m, (p - 1) / 2, p); r == 0 || r == 1 })).collect();
    let nsq = a_set.iter().filter(|&&m| isqrt(m) * isqrt(m) == m).count();
    let hit = |p: u64| { let mut s = vec![false; p as usize]; for &m in &a_set { s[(m % p) as usize] = true; } s.iter().filter(|&&b| b).count() as u64 };
    let na = a_set.len() as u64; let naf = na as f64;
    println!("A = n in 1..{} that are a square mod every odd prime p <= {}: {} members, {} of them perfect squares", ci(n), q, na, nsq);
    println!("classes hit mod 3, 5, 7, 97: {}, {}, {}, {}; missed: {}, {}, {}, {}", hit(3), hit(5), hit(7), hit(97), 3 - hit(3), 5 - hit(5), 7 - hit(7), 97 - hit(97));
    // Road two: the bound
    let l = l_of(q, &h_sq); let top = budget(n, q);
    let l_seen = l_of(q, &|p| (p - hit(p)) as f64 / hit(p) as f64);   // second road: the odds from the classes A really hits
    let (bound, gal) = (top as f64 / l, (PI * n as f64 + (q * q) as f64) / l);
    let guess = n as f64 * ps.iter().fold(1.0, |acc, &p| acc * (1.0 - k_sq(p) as f64 / p as f64));
    println!("L = {:.6}; large sieve bound (N - 1 + Q^2)/L = {}/{:.6} = {:.3}", l, ci(top), l, bound);
    println!("Gallagher's constant (pi N + Q^2)/L = {:.3}; independence guess N x prod(1 - k_p/p) = {:.6}", gal, guess);
    println!("terms of L: q = 1: 1; q = 3: {:.6}; q = 5: {:.6}; q = 7: {:.6}; q = 11: {:.6}; q = 13: {:.6}; q = 15: {:.6}; total to 15: {:.6}", h_sq(3), h_sq(5), h_sq(7), h_sq(11), h_sq(13), h_sq(3) * h_sq(5), l_of(15, &h_sq));
    // Road three: the exponential sums at the Farey fractions a/q, q <= Q, gcd(a, q) = 1
    let farey: Vec<(u64, u64)> = (1..=q).flat_map(|d| (0..d).filter(move |&a| gcd(a, d) == 1).map(move |a| (a, d))).collect();
    let mut order = farey.clone(); order.sort_by(|x, y| (x.0 as f64 / x.1 as f64).partial_cmp(&(y.0 as f64 / y.1 as f64)).unwrap());
    let mut gaps: Vec<(u64, u64)> = order.windows(2).map(|w| (w[1].0 * w[0].1 - w[0].0 * w[1].1, w[0].1 * w[1].1)).collect();
    let last = order[order.len() - 1]; gaps.push((last.1 - last.0, last.1));
    let mg = *gaps.iter().min_by(|x, y| (x.0 as f64 / x.1 as f64).partial_cmp(&(y.0 as f64 / y.1 as f64)).unwrap()).unwrap();
    println!("Farey fractions with q <= {}: {}; closest pair {}/{}, at least 1/Q^2 = 1/{}", q, ci(farey.len() as u64), mg.0, ci(mg.1), ci(q * q));
    let mut by_q = vec![0.0f64; q as usize + 1];
    for &(a, d) in &farey { by_q[d as usize] = by_q[d as usize] + s2(&a_set, a, d); }
    let t = by_q[1..].iter().fold(0.0, |s, v| s + v);
    println!("left side, sum of |S(a/q)|^2: {}", cf(t));
    println!("lower, |A|^2 L = {}; upper, (N - 1 + Q^2)|A| = {}", cf(naf * naf * l), ci(top * na));
    let zc = |m: u64| (0..m).map(|b| a_set.iter().filter(|&&x| x % m == b).count() as u64).collect::<Vec<u64>>();
    let (z3, z7) = (zc(3), zc(7));
    println!("q = 3: Z = {:?}; |S(1/3)|^2 = {:.3}; sum over a = 1, 2: {:.3}; lemma's floor |A|^2 x 1/2 = {:.3}", z3, s2(&a_set, 1, 3), by_q[3], naf * naf / 2.0);
    println!("q = 3 Parseval: 3 x sum Z^2 = {}; |S(0)|^2 + {:.3} = {}", ci(3 * z3.iter().map(|z| z * z).sum::<u64>()), by_q[3], cf((na * na) as f64 + by_q[3]));
    let par7 = (0..7).fold(0.0, |s, a| s + s2(&a_set, a, 7)); let z7sq = 7 * z7.iter().map(|z| z * z).sum::<u64>();
    println!("q = 7: Z = {:?}; sum over all a of |S(a/7)|^2 = {}; 7 x sum Z^2 = {}", z7, cf(par7), ci(z7sq));
    let (mut floors, mut worst) = (0, 9.0f64);
    for d in 2..=q {
        let f = l_of(d, &h_sq) - l_of(d - 1, &h_sq);        // the q-th term of L: 0 unless q is squarefree and odd
        if f > 0.0 {
            floors += 1; worst = worst.min(by_q[d as usize] / (naf * naf * f));
            assert!(by_q[d as usize] >= naf * naf * f * (1.0 - 1e-9));   // Montgomery's lemma, modulus by modulus
        }
    }
    println!("odd squarefree q <= {} checked (q > 1) against the lemma's floor: {}; tightest ratio {:.6}", q, floors, worst);
    let chart: Vec<String> = (1..=10).map(|k| { let x = 20 * k as u64; format!("{}", ((n - 1 + x * x) as f64 / l_of(x, &h_sq)).round()) }).collect();
    println!("chart, bound at Q = 20, 40, ..., 200: {}", chart.join(", "));
    // Road four: the worst sequence for a small case, N0 = 49 terms, Q0 = 7
    let (n0, q0) = (49usize, 7u64);
    let f0: Vec<f64> = (1..=q0).flat_map(|d| (0..d).filter(move |&a| gcd(a, d) == 1).map(move |a| a as f64 / d as f64)).collect();
    let c: Vec<f64> = (0..n0).map(|d| f0.iter().fold(0.0, |s, &x| s + (2.0 * PI * d as f64 * x).cos())).collect();
    let kv = |v: &[f64]| -> Vec<f64> { (0..n0).map(|m| (0..n0).fold(0.0, |s, k| s + c[(m as i64 - k as i64).unsigned_abs() as usize] * v[k])).collect() };
    let mut mm: Vec<Vec<f64>> = (0..n0).map(|r| (0..n0).map(|k| c[(r as i64 - k as i64).unsigned_abs() as usize]).collect()).collect();
    for _sweep in 0..12 {                                 // Jacobi rotations: zero each off-diagonal entry in turn
        for i in 0..n0 { for j in i + 1..n0 {
            if mm[i][j].abs() < 1e-300 { continue; }
            let th = (mm[j][j] - mm[i][i]) / (2.0 * mm[i][j]);
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
            let cs = 1.0 / (t * t + 1.0).sqrt(); let sn = t * cs;
            for k in 0..n0 { let (a, b) = (mm[k][i], mm[k][j]); mm[k][i] = cs * a - sn * b; mm[k][j] = sn * a + cs * b; }
            for k in 0..n0 { let (a, b) = (mm[i][k], mm[j][k]); mm[i][k] = cs * a - sn * b; mm[j][k] = sn * a + cs * b; }
        } }
    }
    let mut eig: Vec<f64> = (0..n0).map(|i| mm[i][i]).collect(); eig.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let lam = eig[n0 - 1]; let mut off = 0.0f64;
    for i in 0..n0 { for j in 0..n0 { if i != j { off = off.max(mm[i][j].abs()); } } }
    let eig_sum = eig.iter().fold(0.0, |s, v| s + v);
    let (mut st, mut worst_rand) = (20261115u64, 0.0f64);
    for _trial in 0..20 {                                 // SplitMix64 signs: random +1/-1 sequences
        let mut seq = Vec::new();
        for _ in 0..n0 {
            st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = st;
            z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
            seq.push(if (z ^ (z >> 31)) & 1 == 1 { 1.0 } else { -1.0 });
        }
        let kseq = kv(&seq);
        worst_rand = worst_rand.max(seq.iter().zip(&kseq).fold(0.0, |s, (x, y)| s + x * y) / n0 as f64);
    }
    println!("small case N0 = {}, Q0 = {}: {} fractions; worst ratio = top eigenvalue {:.6}; next {:.6}", n0, q0, f0.len(), lam, eig[n0 - 2]);
    println!("  eigenvalues add to {:.6}; trace N0 x fractions = {}", eig_sum, n0 * f0.len());
    println!("  random signs, best of 20: {:.6}; floor max(N0, fractions) = {}; bound N0 - 1 + Q0^2 = {}", worst_rand, n0.max(f0.len()), n0 as u64 - 1 + q0 * q0);
    // The house example: twin pairs below a million
    let (x, qt) = (1_000_000usize, 300u64);
    let twins = (3..=x).filter(|&m| isp[m] && isp[m + 2]).count() as u64;
    let small = (3..=qt as usize).filter(|&m| isp[m] && isp[m + 2]).count() as u64;
    let lt = l_of(qt, &|p| if p == 2 { 1.0 } else { 2.0 / (p - 2) as f64 });
    let tw: Vec<u64> = (qt as usize + 1..=x).filter(|&m| isp[m] && isp[m + 2]).map(|m| m as u64).collect();
    let th: Vec<u64> = (0..=qt).map(|p| if p >= 2 && isp[p as usize] { let mut s = vec![false; p as usize]; for &m in &tw { s[(m % p) as usize] = true; } s.iter().filter(|&&b| b).count() as u64 } else { 1 }).collect();
    let lt_seen = l_of(qt, &|p| (p - th[p as usize]) as f64 / th[p as usize] as f64);   // second road: the odds from the classes the twins really hit
    let bt = (x as u64 - qt - 1 + qt * qt) as f64 / lt;
    println!("twin pairs (n, n + 2) with n <= {}: {}; with n <= {}: {}; above: {}", ci(x as u64), ci(twins), qt, small, ci(twins - small));
    println!("twins, Q = {}: L = {:.6}; bound ({} - 1 + {})/L = {}; plus {} small pairs = {}", qt, lt, ci(x as u64 - qt), ci(qt * qt), cf(bt), small, cf(bt + small as f64));
    // What breaks
    let primes = (1..=n as usize).filter(|&m| isp[m]).count() as u64;
    println!("mistake 1, independence guess: {:.6} against {} true", guess, na);
    println!("mistake 2, the squares' bound used on the primes up to {}: {:.3} against {} primes", ci(n), bound, ci(primes));
    println!("mistake 3, drop Q^2: one term a_1 = 1 gives left side {} against N|a_1|^2 = 1 for N = 1", ci(farey.len() as u64));
    println!("mistake 4, points not spaced: {} copies of a/q = 0 give {} against {}", ci(farey.len() as u64), ci(farey.len() as u64 * na * na), ci(top * na));
    let allq = (1..=q).fold(0.0, |s, d| (0..d).fold(s, |s, a| s + s2(&a_set, a, d)));
    println!("trap, every a mod q, not just gcd 1: {} against {}", cf(allq), ci(top * na));
    let ls = l_of(q, &|p| k_sq(p) as f64 / p as f64);
    println!("trap, q = 1 left out of L: bound {:.3}; shares k_p/p for odds: L = {:.6}, bound {:.3}", top as f64 / (l - 1.0), ls, top as f64 / ls);
    assert!(na == nsq as u64 && na == isqrt(n));                                    // the sieve count equals the count of squares
    assert!(ps[1..].iter().all(|&p| hit(p) == (p + 1) / 2));                         // A misses exactly (p - 1)/2 classes mod each odd p
    assert!(naf <= bound && bound < n as f64 && gal > bound);                        // the theorem against the count
    assert!((l_seen - l).abs() < 1e-9 && (lt_seen - lt).abs() < 1e-9);              // L from k_p by formula against k_p counted
    assert!(naf * naf * l <= t && t <= (top * na) as f64);                          // both sides of the inequality
    assert!((par7 - z7sq as f64).abs() < 1e-6);                                       // Parseval: exponential sums against residue counts
    assert!(mg == (1, q * (q - 1)));                                                  // Farey spacing: closest pair 1/(Q(Q - 1))
    assert!(off < 1e-9 && (eig_sum - (n0 * f0.len()) as f64).abs() < 1e-9);          // eigenvalues against the trace
    assert!(n0.max(f0.len()) as f64 <= lam && lam <= budget(n0 as u64, q0) as f64 && worst_rand <= lam);   // the exact worst case under the budget
    assert!(twins == 8169 && bt >= (twins - small) as f64);                          // the house example
    assert!(primes as f64 > bound && allq > (top * na) as f64);                      // the broken versions really break
    println!("ALL CHECKS PASS");
}
