// Sums of discrete variables -- the check behind the card.  Rust std only.
// Two help desks merged: billing gets 5 emails an hour on average, technical 7.
// Roads to the merged law: convolution, the closed form, moment generating
// functions, and a seeded simulation (SplitMix64, written out below).
fn pois(lam: f64, k_max: usize) -> Vec<f64> { // masses 0..K by the ratio p(k) = p(k-1) * lam / k
    let mut p = vec![(-lam).exp()];
    for k in 1..=k_max {
        let last = p[k - 1];
        p.push(last * lam / k as f64);
    }
    p
}
fn pois_direct(lam: f64, s: usize) -> f64 { // closed form through logs: e^-lam lam^s / s!
    let lf: f64 = (2..=s).map(|i| (i as f64).ln()).sum();
    (-lam + s as f64 * lam.ln() - lf).exp()
}
fn conv(a: &[f64], b: &[f64]) -> Vec<f64> { // P(X+Y=s) = sum over k of P(X=k) P(Y=s-k)
    let mut out = vec![0.0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() {
        for (j, y) in b.iter().enumerate() {
            out[i + j] += x * y;
        }
    }
    out
}
fn binom(n: usize, p: f64) -> Vec<f64> { // C(n,k) by Pascal's rule, then the masses
    let mut row: Vec<u64> = vec![1];
    for _ in 0..n {
        let mut next = vec![1u64];
        for i in 0..row.len() - 1 {
            next.push(row[i] + row[i + 1]);
        }
        next.push(1);
        row = next;
    }
    (0..=n).map(|k| row[k] as f64 * p.powf(k as f64) * (1.0 - p).powf((n - k) as f64)).collect()
}
fn trials(n: usize, p: f64) -> Vec<f64> { // n one-email laws convolved one at a time
    let mut law = vec![1.0];
    for _ in 0..n {
        law = conv(&law, &[1.0 - p, p]);
    }
    law
}
fn mean_var(law: &[f64]) -> (f64, f64) {
    let m: f64 = law.iter().enumerate().map(|(k, q)| k as f64 * q).sum();
    (m, law.iter().enumerate().map(|(k, q)| (k as f64 - m).powi(2) * q).sum())
}
fn mgf(law: &[f64], t: f64) -> f64 {
    law.iter().enumerate().map(|(k, q)| q * (t * k as f64).exp()).sum()
}
fn gap(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
struct SplitMix(u64);
impl SplitMix {
    fn u01(&mut self) -> f64 { // SplitMix64, top 53 bits as a number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn draw(&mut self, lam: f64) -> u64 { // Knuth: multiply uniforms until below e^-lam
        let (l, mut k, mut p) = ((-lam).exp(), 0u64, self.u01());
        while p > l {
            k += 1;
            p *= self.u01();
        }
        k
    }
}
fn shock(a: f64, b: f64, c: f64, k: usize) -> (Vec<f64>, Vec<f64>) { // X = A + C, Y = B + C: C emails copied to both desks
    let pc = pois(c, k);
    let mut twice = vec![0.0; 2 * k + 1];
    for (i, q) in pc.iter().enumerate() {
        twice[2 * i] = *q;
    }
    let s = conv(&conv(&pois(a, k), &pois(b, k)), &twice)[..=k].to_vec();
    (s, conv(&pois(a, k), &pc)[..=k].to_vec())
}
fn main() {
    let k = 60;
    let (bill, tech) = (pois(5.0, k), pois(7.0, k));
    let merged = conv(&bill, &tech)[..=k].to_vec();
    println!("road 1, convolution: merged total s = 12, billing's share k");
    for i in 0..13 {
        println!("  k={:2}  {:.6} x {:.6} = {:.6}", i, bill[i], tech[12 - i], bill[i] * tech[12 - i]);
    }
    let closed: Vec<f64> = (0..=k).map(|s| pois_direct(12.0, s)).collect();
    let tail_c = 1.0 - merged[..16].iter().sum::<f64>();
    let tail_f = 1.0 - closed[..16].iter().sum::<f64>();
    println!("convolution  P(S=12)        {:.6}   P(S>=16) {:.6}", merged[12], tail_c);
    println!("road 2, closed form Poisson(12) {:.6}   P(S>=16) {:.6}", closed[12], tail_f);
    println!("every s = 0..60 agrees to 1e-12: {}", yn(gap(&merged, &closed) < 1e-12));
    let (m_prod, m_conv) = (mgf(&bill, 0.5) * mgf(&tech, 0.5), mgf(&merged, 0.5));
    let m_form = (12.0 * (0.5f64.exp() - 1.0)).exp();
    println!("road 3, MGF at t=0.5: product {:.6}  of merged {:.6}  formula {:.6}", m_prod, m_conv, m_form);
    assert!((merged[12] - closed[12]).abs() < 1e-12);
    assert!((tail_c - tail_f).abs() < 1e-12);
    assert!(gap(&merged, &closed) < 1e-12);
    assert!((m_prod - m_form).abs() < 1e-9);
    assert!((m_conv - m_form).abs() < 1e-9);

    let mut rng = SplitMix(20260928);
    let h = 200000u64;
    let (mut hit, mut over, mut tot, mut sq) = (0u64, 0u64, 0u64, 0u64);
    for _ in 0..h {
        let s = rng.draw(5.0) + rng.draw(7.0);
        hit += (s == 12) as u64;
        over += (s >= 16) as u64;
        tot += s;
        sq += s * s;
    }
    let hf = h as f64;
    let (e12, eov) = (hit as f64 / hf, over as f64 / hf);
    let (se12, seov) = ((e12 * (1.0 - e12) / hf).sqrt(), (eov * (1.0 - eov) / hf).sqrt());
    let sm = tot as f64 / hf;
    println!("road 4, simulation, seed 20260928, {} hours", h);
    println!("  P(S=12) {:.6} +- {:.6}   P(S>=16) {:.6} +- {:.6}", e12, se12, eov, seov);
    println!("  mean {:.4}   variance {:.4}", sm, sq as f64 / hf - sm * sm);
    assert!((e12 - closed[12]).abs() < 4.0 * se12);
    assert!((eov - tail_f).abs() < 4.0 * seov);

    println!("what breaks");
    println!("  only the 6 + 6 split           {:.6}", bill[6] * tech[6]);
    println!("  averaging the two laws at 12   {:.6}", (bill[12] + tech[12]) / 2.0);
    let (sh, marg) = shock(3.0, 5.0, 2.0, k);
    let (shm, shv) = mean_var(&sh);
    println!("  copied emails: billing still Poisson(5): {}", yn(gap(&marg, &bill) < 1e-12));
    println!("  copied emails  P(S=12) {:.6}   mean {:.4}   variance {:.4}", sh[12], shm, shv);
    assert!(gap(&marg, &bill) < 1e-12);
    assert!((shv - (3.0 + 5.0 + 4.0 * 2.0)).abs() < 1e-9);
    assert!((sh[12] - closed[12]).abs() > 0.005);

    let (mon, tue, both) = (binom(20, 0.7), binom(30, 0.7), binom(50, 0.7));
    println!("binomial: 20 then 30 replies, each resolves with chance 0.7");
    println!("  convolution P(T=35) {:.6}   Binomial(50, 0.7) {:.6}", conv(&mon, &tue)[35], both[35]);
    println!("  50 one-email laws convolved {:.6}", trials(50, 0.7)[35]);
    assert!(gap(&conv(&mon, &tue), &both) < 1e-12);
    assert!(gap(&trials(50, 0.7), &both) < 1e-12);
    let (mixed, pooled) = (conv(&mon, &binom(30, 0.5)), binom(50, 0.58));
    let (mv, pv) = (mean_var(&mixed).1, mean_var(&pooled).1);
    println!("  chances 0.7 and 0.5: P(T=29) {:.6}   variance {:.4}", mixed[29], mv);
    println!("  pooled Binomial(50, 0.58): P(T=29) {:.6}   variance {:.4}", pooled[29], pv);
    assert!((mv - (20.0 * 0.7 * 0.3 + 30.0 * 0.25)).abs() < 1e-9);
    assert!((pv - mv).abs() > 0.3);

    println!("try changing");
    println!("  desks at 2 and 10: P(S=12) {:.6}", conv(&pois(2.0, k), &pois(10.0, k))[12]);
    let sh2 = shock(1.0, 3.0, 4.0, k).0;
    println!("  copies Poisson(4), A 1, B 3: P(S=12) {:.6}   variance {:.4}", sh2[12], mean_var(&sh2).1);
    let row = |v: &[f64]| (0..25).map(|s| format!("{:.3}", v[s])).collect::<Vec<_>>().join(" ");
    println!("chart, s = 0..24, merged:  {}", row(&merged));
    println!("chart, s = 0..24, copied:  {}", row(&sh));
}
