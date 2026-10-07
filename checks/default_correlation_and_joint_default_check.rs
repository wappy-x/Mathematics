// Default correlation -- the check behind the card.  Rust std only, no crates.
// Two bakeries, each 5% likely to fail within five years; then a pool of 100
// such loans.  Normal curve, inverse, integrator and random numbers are written
// out here; nothing imported already knows the answer.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn big_n(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 400) }
fn n_inv(prob: f64) -> f64 {
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if big_n(mid) < prob { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn joint(p1: f64, p2: f64, rho: f64) -> f64 { p1 * p2 + rho * (p1 * (1.0 - p1) * p2 * (1.0 - p2)).sqrt() }
fn rho_of(p1: f64, p2: f64, j: f64) -> f64 { (j - p1 * p2) / (p1 * (1.0 - p1) * p2 * (1.0 - p2)).sqrt() }
fn pmf_formula(n: usize, q: f64) -> Vec<f64> {
    // binomial coefficients by the ratio C(n,k) = C(n,k-1) (n-k+1)/k
    let mut out = Vec::with_capacity(n + 1);
    let mut coef = 1.0;
    for k in 0..=n {
        if k > 0 { coef *= (n - k + 1) as f64 / k as f64; }
        out.push(coef * q.powi(k as i32) * (1.0 - q).powi((n - k) as i32));
    }
    out
}
fn pmf_by_adding(n: usize, q: f64) -> Vec<f64> {
    let mut d = vec![1.0];
    for _ in 0..n {
        let mut e = vec![0.0; d.len() + 1];
        for k in 0..d.len() { e[k] += d[k] * (1.0 - q); e[k + 1] += d[k] * q; }
        d = e;
    }
    d
}
fn mix(parts: &[(f64, Vec<f64>)]) -> Vec<f64> {
    (0..parts[0].1.len()).map(|k| parts.iter().map(|(w, d)| w * d[k]).sum()).collect()
}
fn tail(d: &[f64], m: usize) -> f64 { d[m..].iter().sum() }
fn mean_var(d: &[f64]) -> (f64, f64) {
    let m: f64 = d.iter().enumerate().map(|(k, x)| k as f64 * x).sum();
    let s2: f64 = d.iter().enumerate().map(|(k, x)| (k * k) as f64 * x).sum();
    (m, s2 - m * m)
}
struct SplitMix(u64);
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let (p, n, loan, recovery) = (0.05_f64, 100usize, 100_000.0_f64, 0.40_f64);
    let loss_each = loan * (1.0 - recovery);
    let nf = n as f64;

    // the pair: from default correlation to joint default and back
    let rho_d = 11.0 / 190.0;
    let j_ind = joint(p, p, 0.0);
    let j = joint(p, p, rho_d);
    let j_058 = joint(p, p, 0.058);
    let cells = [j, p - j, p - j, 1.0 - 2.0 * p + j];
    let rho_lo = rho_of(p, p, (2.0 * p - 1.0).max(0.0));
    let rho_hi = rho_of(p, p, p.min(p));

    // the town model: a bad spell (prob 11/51, 15% each) or not (2.25% each)
    let (w, p_bad, p_good) = (11.0 / 51.0, 0.15, 0.0225);
    let p_town = w * p_bad + (1.0 - w) * p_good;
    let j_town = w * p_bad * p_bad + (1.0 - w) * p_good * p_good;
    assert!((j_town - j).abs() < 1e-15, "town model misses the pair formula");
    let indep = pmf_formula(n, p);
    let town = mix(&[(w, pmf_formula(n, p_bad)), (1.0 - w, pmf_formula(n, p_good))]);
    let town2 = mix(&[(w, pmf_by_adding(n, p_bad)), (1.0 - w, pmf_by_adding(n, p_good))]);
    assert!(town.iter().zip(&town2).all(|(a, b)| (a - b).abs() < 1e-14));
    assert!((tail(&indep, 10) - tail(&pmf_by_adding(n, p), 10)).abs() < 1e-14);
    let (m_i, v_i) = mean_var(&indep);
    let (m_t, v_t) = mean_var(&town);
    let v_formula = nf * p * (1.0 - p) * (1.0 + (nf - 1.0) * rho_of(p, p, j_town));
    assert!((v_t - v_formula).abs() < 1e-9, "full law disagrees with pair formula");

    // copy model: same p, same pair, different tail
    let copy_tail = rho_d * p + (1.0 - rho_d) * tail(&indep, 10);

    // asset correlation 20% through the one-factor Gaussian model
    let rho_a = 0.20;
    let c = n_inv(p);
    let cond = |z: f64, ra: f64| big_n((c - ra.sqrt() * z) / (1.0 - ra).sqrt());
    let j_factor = |ra: f64| simpson(|z| cond(z, ra).powi(2) * phi(z), -8.0, 8.0, 400);
    let j_plackett = |ra: f64| p * p + simpson(|r| (-c * c / (1.0 + r)).exp() / (2.0 * PI * (1.0 - r * r).sqrt()), 0.0, ra, 200);
    let (j_g, j_g2) = (j_factor(rho_a), j_plackett(rho_a));
    assert!((j_g - j_g2).abs() < 1e-12, "the two Gaussian roads disagree");
    let mut gauss = vec![0.0; n + 1];
    let (a, b, steps) = (-8.0_f64, 8.0_f64, 400usize);
    let h = (b - a) / steps as f64;
    for i in 0..=steps {
        let z = a + i as f64 * h;
        let wt = if i == 0 || i == steps { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let d = pmf_formula(n, cond(z, rho_a));
        for k in 0..=n { gauss[k] += wt * d[k] * phi(z) * h / 3.0; }
    }
    assert!((mean_var(&gauss).1 - nf * p * (1.0 - p) * (1.0 + (nf - 1.0) * rho_of(p, p, j_g))).abs() < 1e-6);

    // road 3: simulate 20,000 pools of the town model
    let mut rng = SplitMix(20260928);
    let (pools, mut hits, mut pairs) = (20_000usize, 0usize, 0usize);
    for _ in 0..pools {
        let q = if rng.uniform() < w { p_bad } else { p_good };
        let s = (0..n).filter(|_| rng.uniform() < q).count();
        if s >= 10 { hits += 1; }
        pairs += s * s.saturating_sub(1);
    }
    let mc_tail = hits as f64 / pools as f64;
    let mc_joint = pairs as f64 / (pools as f64 * nf * (nf - 1.0));
    let t_town = tail(&town, 10);
    let se = (t_town * (1.0 - t_town) / pools as f64).sqrt();
    assert!((mc_tail - t_town).abs() < 4.0 * se, "simulation misses the exact tail");
    assert!((mc_joint - j).abs() < 0.0004, "simulation misses the pair");

    let t_ind = tail(&indep, 10);
    let t_gauss = tail(&gauss, 10);
    let rows: Vec<(&str, f64)> = vec![
        ("pair: both fail, independent", j_ind), ("pair: scale, sqrt of p(1-p)p(1-p)", joint(p, p, 1.0) - j_ind),
        ("pair: extra from rho_D", j - j_ind), ("pair: both fail, rho_D = 11/190", j),
        ("pair: both fail, rho_D = 0.058", j_058), ("pair: rho_D back from 0.525%", rho_of(p, p, 0.00525)),
        ("cells: one fails, other survives", cells[1]), ("cells: neither fails", cells[3]),
        ("bounds: lowest rho_D", rho_lo), ("bounds: highest rho_D", rho_hi),
        ("town: bad-spell chance", w), ("town: default chance", p_town), ("town: both fail", j_town),
        ("pool: mean defaults, independent", m_i), ("pool: mean defaults, town", m_t),
        ("pool: variance, independent", v_i), ("pool: bracket 1 + 99 rho_D", 1.0 + (nf - 1.0) * rho_d),
        ("pool: variance, pair formula", v_formula), ("pool: variance, town model", v_t),
        ("pool: sd defaults, independent", v_i.sqrt()), ("pool: sd defaults, town", v_t.sqrt()),
        ("pool: sd ratio, town / indep", (v_t / v_i).sqrt()),
        ("pool: expected loss $", m_i * loss_each), ("pool: sd loss $, independent", v_i.sqrt() * loss_each),
        ("pool: sd loss $, town", v_t.sqrt() * loss_each),
        ("tail: 10+ fail, independent", t_ind), ("tail: 10+ fail, town", t_town),
        ("tail: 10+ fail, copy model", copy_tail), ("tail: 10+ fail, asset corr 20%", t_gauss),
        ("tail: town / independent", t_town / t_ind), ("tail: asset 20% / independent", t_gauss / t_ind),
        ("tail: town / copy", t_town / copy_tail),
        ("tail: one spell in, independent", 1.0 / t_ind), ("tail: one spell in, town", 1.0 / t_town),
        ("sim: 10+ fail, 20,000 pools", mc_tail), ("sim: both fail, all pairs", mc_joint),
        ("asset: threshold c = N_inv(0.05)", c), ("asset: both fail, factor road", j_g),
        ("asset: both fail, Plackett road", j_g2), ("asset: rho_D implied by 20%", rho_of(p, p, j_g)),
        ("wrong: asset 0.20 used as rho_D", joint(p, p, rho_a)), ("wrong: rho_D times p1*p2", j_ind * (1.0 + rho_d)),
        ("try: rho_D implied by asset 40%", rho_of(p, p, j_factor(0.40))),
        ("try: sd ratio, 1,000 loans", (1.0 + 999.0 * rho_d).sqrt()),
    ];
    for (name, v) in &rows { println!("{:<34} {:>16.6}", name, v); }
    println!("dist: k, P(S=k) in %: independent, town, asset 20%; twice per line");
    for a in 0..8 {
        let b = a + 8;
        println!("dist {:>2} {:>6.2} {:>6.2} {:>6.2}  | {:>2} {:>6.2} {:>6.2} {:>6.2}",
                 a, 100.0 * indep[a], 100.0 * town[a], 100.0 * gauss[a], b, 100.0 * indep[b], 100.0 * town[b], 100.0 * gauss[b]);
    }
}
