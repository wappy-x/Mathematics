// Brun's sieve and Selberg's -- the same check as the Python, in Rust.  No crates.
// Twin primes p, p + 2 with p up to a million are counted twice, then bounded
// three ways: Legendre (keep every layer), Brun (stop after an even number of
// layers) and Selberg (squared, optimised weights).
const X: usize = 1_000_000;
const M: usize = 200_001;

fn c(n: u128) -> String {                    // thousands commas
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    out
}
fn gcd(mut a: usize, mut b: usize) -> usize { while b != 0 { (a, b) = (b, a % b) } a }
fn rho(p: usize, r2: usize) -> usize { if p == 2 { r2 } else { 2 } }  // classes n mod p with p | n(n + 2)
fn esym(vals: &[f64], m: usize) -> Vec<f64> {   // layer totals e_0 .. e_m
    let mut e = vec![0.0; m + 1];
    e[0] = 1.0;
    for &v in vals { for j in (1..=m).rev() { e[j] += e[j - 1] * v } }
    e
}
struct Sieve { spf: Vec<usize>, primes: Vec<usize> }
impl Sieve {
    // stop after m layers: main part and error allowance after each layer, and the prime count
    fn brun(&self, x: f64, z: usize, m: usize, r2: usize) -> (Vec<f64>, Vec<f64>, usize) {
        let ps: Vec<usize> = self.primes.iter().copied().filter(|&p| p < z).collect();
        let g = esym(&ps.iter().map(|&p| rho(p, r2) as f64 / p as f64).collect::<Vec<_>>(), m);
        let r = esym(&ps.iter().map(|&p| rho(p, r2) as f64).collect::<Vec<_>>(), m);
        let mains = (0..=m).map(|k| x * (0..=k).fold(0.0, |s, j| s + if j % 2 == 0 { g[j] } else { -g[j] })).collect();
        let rems = (0..=m).map(|k| r[..=k].iter().fold(0.0, |s, v| s + v)).collect();
        (mains, rems, ps.len())
    }
    // h, rho, g, mu for squarefree d < z; then Selberg's lambda_d
    fn weights(&self, z: usize) -> (f64, Vec<f64>, Vec<usize>, Vec<f64>, Vec<i64>) {
        let (mut h, mut r, mut g, mut mu) = (vec![0.0; z], vec![0usize; z], vec![0.0; z], vec![0i64; z]);
        for d in 1..z {
            let (mut n, mut ps, mut sq) = (d, vec![], true);
            while n > 1 { let p = self.spf[n]; n /= p; if n % p == 0 { sq = false; break } ps.push(p) }
            if !sq { continue }
            h[d] = 1.0; r[d] = 1; g[d] = 1.0; mu[d] = if ps.len() % 2 == 0 { 1 } else { -1 };
            for &p in &ps {
                h[d] = h[d] * rho(p, 1) as f64 / (p - rho(p, 1)) as f64;
                r[d] *= rho(p, 1);
                g[d] = g[d] * rho(p, 1) as f64 / p as f64;
            }
        }
        let big_g = h.iter().fold(0.0, |s, v| s + v);
        let lam = (0..z).map(|d| if mu[d] == 0 { 0.0 } else {
            let s = (1..=(z - 1) / d).filter(|&e| mu[e] != 0 && gcd(e, d) == 1).fold(0.0, |s, e| s + h[e]);
            mu[d] as f64 * s / g[d] * h[d] / big_g }).collect();
        (big_g, lam, r, g, mu)
    }
}
fn quad(lam: &[f64], g: &[f64]) -> f64 {     // x-free main part: sum of lam_a lam_b g([a, b])
    let ds: Vec<usize> = (1..lam.len()).filter(|&d| lam[d] != 0.0).collect();
    let mut s = 0.0;
    for &a in &ds { for &b in &ds { s += lam[a] * lam[b] * g[a] * g[b] / g[gcd(a, b)] } }
    s
}
fn main() {
    let mut spf: Vec<usize> = (0..M).collect();      // smallest prime factor of each n < M
    for i in 2..448 { if spf[i] == i { let mut j = i * i; while j < M { if spf[j] == j { spf[j] = i } j += i } } }
    let primes: Vec<usize> = (2..M).filter(|&p| spf[p] == p).collect();
    let mut isp = vec![0u8; X + 3];                  // odd n marked prime
    isp[2] = 1;
    for n in (3..X + 3).step_by(2) { isp[n] = 1 }
    for &p in &primes[1..168] { let mut j = p * p; while j < X + 3 { isp[j] = 0; j += 2 * p } }
    let twins: Vec<usize> = (2..=X).filter(|&p| isp[p] == 1 && isp[p + 2] == 1).collect();
    let sifted = |z: usize| -> usize {               // S(10^6, z): strike n = 0 and n = -2 mod p
        let mut alive = vec![1u8; X + 1];
        alive[0] = 0;
        for &p in primes.iter().filter(|&&q| q < z) {
            for s in if p == 2 { vec![2] } else { vec![p - 2, p] } { let mut j = s; while j <= X { alive[j] = 0; j += p } }
        }
        alive.iter().map(|&v| v as usize).sum()
    };
    let sv = Sieve { spf: spf.clone(), primes: primes.clone() };
    let zs = [100, 150, 200, 300, 500, 1000, 2000, 3000, 5000, 10000, 20000, 50000, 100000, 200000];
    let cache: Vec<_> = zs.iter().map(|&z| sv.weights(z)).collect();
    let selberg = |x: f64, k: usize| -> f64 {
        let (big_g, lam, r, _, _) = &cache[k];
        let s = (0..zs[k]).fold(0.0, |s, d| s + lam[d].abs() * r[d] as f64);
        x / big_g + s * s + primes.iter().filter(|&&p| p < zs[k]).count() as f64
    };
    let road2 = sifted(1001) + twins.iter().filter(|&&p| p < 1001).count();
    println!("twin pairs with p up to {}: {}; by sifting n(n + 2) with primes below 1001: {}", c(X as u128), c(twins.len() as u128), c(road2 as u128));
    println!("largest pair {}, {}; primes up to 10^6: {}", c(twins[twins.len() - 1] as u128), c(twins[twins.len() - 1] as u128 + 2), c(isp[2..=X].iter().map(|&v| v as u128).sum()));
    let mut c2 = 1.0;
    for &p in &primes[1..] { if p < X { c2 *= 1.0 - 1.0 / ((p - 1) * (p - 1)) as f64 } }
    for p in (primes[primes.len() - 1] + 2..X).step_by(2) { if isp[p] == 1 { c2 *= 1.0 - 1.0 / ((p - 1) * (p - 1)) as f64 } }
    let mut b = 0.0;
    for e in 1..7u32 {
        let top = 10usize.pow(e);
        b = twins.iter().filter(|&&p| p + 2 <= top).fold(0.0, |s, &p| s + (1.0 / p as f64 + 1.0 / (p + 2) as f64));
        let s = (2..=top).filter(|&p| isp[p] == 1).fold(0.0, |s, p| s + 1.0 / p as f64);
        println!("chart, x = 10^{}: twin reciprocals {:.4}, all prime reciprocals {:.4}", e, b, s);
    }
    let lx = (X as f64).ln();
    println!("C2 = {:.6}; tail estimate 4 C2 / log x = {:.4}; sum plus tail {:.5}, Brent 1.90216", c2, 4.0 * c2 / lx, b + 4.0 * c2 / lx);
    let (n, a) = (20000usize, 2f64.ln());            // Simpson's rule for the integral of dt / (log t)^2, t = e^u
    let hs = (lx - a) / n as f64;
    let li2 = (0..=n).fold(0.0, |s, i| {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let u = a + i as f64 * hs;
        s + w * u.exp() / (u * u) }) * hs / 3.0;
    println!("Hardy-Littlewood prediction 2 C2 Li2(10^6) = {:.0} (a conjecture)", 2.0 * c2 * li2);
    let (mains, rems, r) = sv.brun(X as f64, 23, 8, 1);
    let gl = esym(&primes[..8].iter().map(|&p| rho(p, 1) as f64 / p as f64).collect::<Vec<_>>(), 8);
    let true23 = sifted(23);
    println!("S(10^6, 23) counted directly: {}; sifting primes below 23: {}", c(true23 as u128), r);
    let n3 = (1..=X).filter(|&n| n * (n + 2) % 3 == 0).count();
    println!("n up to 10^6 with 3 | n(n + 2): {}; x g(3) = {:.1}", c(n3 as u128), X as f64 * 2.0 / 3.0);
    for j in 0..9 { println!("layer {}: e_j(g) = {:.6}, kept to here {:.1} + {:.0}", j, gl[j], mains[j], rems[j]) }
    for m in [2, 4, 6, 8] { println!("Brun, z = 23, {} layers: bound {}", m, c((mains[m] + rems[m] + r as f64).ceil() as u128)) }
    let mut res = vec![];
    for x in [1e6, 1e9, 1e12] {
        let mut bb = (u128::MAX, 0, 0);
        for &z in &primes[..168] {
            let (mm, rr, k) = sv.brun(x, z, 20, 1);
            for m in (0..=20).step_by(2) { bb = bb.min(((mm[m] + rr[m] + k as f64).ceil() as u128, z, m)) }
        }
        let mut lb = (u128::MAX, 0);
        for (i, &z) in primes[..60].iter().enumerate() {
            let (mm, rr, _) = sv.brun(x, z, 99, 1);
            lb = lb.min(((mm[99] + rr[99] + i as f64).ceil() as u128, z));
        }
        let sb = (0..zs.len()).map(|k| (selberg(x, k).ceil() as u128, zs[k])).min().unwrap();
        let u = x / (x.ln() * x.ln());
        res.push((lb.0, bb.0, sb.0));
        println!("x = 10^{}: Legendre {} (z = {}), Brun {} (z = {}, {} layers), Selberg {} (z = {})", x.log10().round(), c(lb.0), lb.1, c(bb.0), bb.1, bb.2, c(sb.0), sb.1);
        println!("  bound / (x / (log x)^2): {:.2}, {:.2}, {:.2}", lb.0 as f64 / u, bb.0 as f64 / u, sb.0 as f64 / u);
    }
    println!("the same ratio for the true count at 10^6: {:.2}; Hardy-Littlewood 2 C2 = {:.2}; Selberg's limit 16 C2 = {:.2}", 8169.0 * lx * lx / X as f64, 2.0 * c2, 16.0 * c2);
    let (big_g, lam, rr, g, mu) = &cache[2];
    let q = quad(lam, g);
    println!("Selberg, z = 200: G = {:.6}; 1/G = {:.9}; double sum of lam lam g = {:.9}", big_g, 1.0 / big_g, q);
    let sr = (0..200).fold(0.0, |s, d| s + lam[d].abs() * rr[d] as f64);
    println!("Selberg at 10^6, z = 200: x/G = {:.1}, remainder {:.1}, plus 46 primes, total {:.2}", X as f64 / big_g, sr * sr, X as f64 / big_g + sr * sr + 46.0);
    println!("lambda_1 = {:.4}, lambda_2 = {:.4}, lambda_3 = {:.4}, lambda_6 = {:.4}, largest |lambda| = {:.4}", lam[1], lam[2], lam[3], lam[6], lam.iter().fold(0.0f64, |m, v| m.max(v.abs())));
    let mu200: Vec<f64> = mu.iter().map(|&v| v as f64).collect();
    let w0 = sv.brun(X as f64, 23, 99, 2);
    let w1 = sv.brun(X as f64, 101, 99, 1);
    let w2 = sv.brun(X as f64, 23, 1, 1);
    println!("mistake 1, rho(2) = 2: bound {:.0}, below the true {}", w0.0[99] + w0.1[99] + 8.0, c(twins.len() as u128));
    println!("mistake 2, every layer at z = 101: bound {}", c((w1.0[99] + w1.1[99] + w1.2 as f64).ceil() as u128));
    println!("mistake 3, one layer read as a ceiling: {:.0}", w2.0[1] - w2.1[1]);
    let rsum = rr.iter().fold(0.0, |s, &v| s + v as f64);
    println!("mistake 4, plain Mobius weights at z = 200: bound {}", c((X as f64 * quad(&mu200, g) + rsum * rsum + 46.0).ceil() as u128));
    assert!(twins.len() == road2 && road2 == 8169);                                    // two counts agree
    assert!([2, 4, 6, 8].iter().all(|&m| true23 as f64 <= (mains[m] + rems[m]).ceil()) && twins.len() <= true23 + r);
    let prod = primes[..8].iter().fold(1.0, |s, &p| s * (1.0 - rho(p, 1) as f64 / p as f64));
    assert!((sv.brun(X as f64, 23, 99, 1).0[99] - X as f64 * prod).abs() < 1e-6);     // expansion = product
    assert!((n3 as f64 - X as f64 * rho(3, 1) as f64 / 3.0).abs() <= rho(3, 1) as f64);   // one prime's count against x g(3)
    assert!((true23 as f64 - X as f64 * prod).abs() <= (2 * 3usize.pow(7)) as f64);    // Legendre, both sides
    assert!((q - 1.0 / big_g).abs() < 1e-12 && (lam[1] - 1.0).abs() < 1e-12);          // quadratic form at its minimum
    assert!((b + 4.0 * c2 / lx - 1.9021604).abs() < 0.001);                           // against Brent's estimate
    assert!(res[0].2 > res[0].1 && res[2].2 < res[2].1);
    println!("ALL CHECKS PASS");
}
