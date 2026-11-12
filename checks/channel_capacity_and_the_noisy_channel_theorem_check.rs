// Channel capacity -- the check behind the card.  Rust std only, no crates.
// A radio link sends 1000 bits a second and flips 1 bit in every 100. Same output as the Python.
use std::f64::consts::PI;

const P: f64 = 0.01; const BITS_PER_S: f64 = 1000.0; // flip chance; link speed
const LOG_BITS: f64 = 86400.0 * 16.0; // a day's log: one 16-bit reading a second
const B: f64 = 500.0; // channel width in hertz: 2B = 1000 pulses a second

fn splitmix64(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn uniform(s: u64) -> (u64, f64) { let (s, z) = splitmix64(s); (s, ((z >> 11) + 1) as f64 / 2f64.powi(53)) }
fn h(p: f64) -> f64 { if p <= 0.0 || p >= 1.0 { 0.0 } else { -p * p.log2() - (1.0 - p) * (1.0 - p).log2() } }
fn mutual_info(q: f64, p: f64) -> f64 {
    let px = [1.0 - q, q];
    let mut joint = [[0.0; 2]; 2];
    for x in 0..2 { for y in 0..2 { joint[x][y] = px[x] * if x == y { 1.0 - p } else { p }; } }
    let py = [joint[0][0] + joint[1][0], joint[0][1] + joint[1][1]];
    let mut s = 0.0;
    for x in 0..2 { for y in 0..2 {
        if joint[x][y] > 0.0 { s += joint[x][y] * (joint[x][y] / (px[x] * py[y])).log2(); }
    } }
    s
}
fn comb(n: u64, k: u64) -> f64 { (0..k).fold(1.0, |c, i| c * (n - i) as f64 / (i + 1) as f64) }
fn rep_error(r: u64, p: f64) -> f64 { // majority vote over r copies: more than half flipped
    ((r / 2 + 1)..=r).fold(0.0, |s, k| s + comb(r, k) * p.powf(k as f64) * (1.0 - p).powf((r - k) as f64))
}
fn best_decoder_error(cols: &[u64], n: u32, m: u32, p: f64) -> f64 {
    let mut seen = vec![false; 1 << m];
    let (mut left, mut ok, mut w) = (1u64 << m, 0.0, 0u32);
    while left > 0 {
        let mut x: u64 = (1u64 << w) - 1; // every n-bit flip pattern with w flips, in turn
        while x < (1u64 << n) {
            let (mut syn, mut y, mut i) = (0u64, x, 0usize);
            while y > 0 {
                if y & 1 == 1 { syn ^= cols[i]; }
                y >>= 1; i += 1;
            }
            if !seen[syn as usize] {
                seen[syn as usize] = true; left -= 1;
                ok += p.powf(w as f64) * (1.0 - p).powf((n - w) as f64);
            }
            if x == 0 { break; }
            let c = x & x.wrapping_neg(); let r = x + c;
            x = (((r ^ x) >> 2) / c) | r;
        }
        w += 1;
    }
    1.0 - ok
}
fn phi(t: f64) -> f64 { (-t * t / 2.0).exp() / (2.0 * PI).sqrt() }
fn big_phi(x: f64) -> f64 {
    let k = 2000; let hh = x / k as f64;
    let mut inner = 0.0;
    for j in 1..k { inner += (if j % 2 == 1 { 4.0 } else { 2.0 }) * phi(j as f64 * hh); }
    0.5 + (phi(0.0) + phi(x) + inner) * hh / 3.0
}
fn phi_series(x: f64) -> f64 { // second road, no integral: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    0.5 + phi(x) * (0..60).map(|j| x.powi(2 * j + 1) / (1..=2 * j + 1).step_by(2).map(|k| k as f64).product::<f64>()).sum::<f64>()
}
fn diff_entropy(var: f64) -> f64 {
    let k = 4000; let sd = var.sqrt(); let l = 12.0 * sd; let hh = 2.0 * l / k as f64;
    let f = |y: f64| (-y * y / (2.0 * var)).exp() / (2.0 * PI * var).sqrt();
    let g = |y: f64| -f(y) * f(y).log2();
    let mut inner = 0.0;
    for j in 1..k { inner += (if j % 2 == 1 { 4.0 } else { 2.0 }) * g(-l + j as f64 * hh); }
    (g(-l) + g(l) + inner) * hh / 3.0
}

fn main() {
    let c_cap = 1.0 - h(P);
    let (mut best_i, mut best_q) = (-1.0, -1.0);
    for i in 0..=1000 {
        let v = mutual_info(i as f64 / 1000.0, P);
        if v > best_i { best_i = v; best_q = i as f64 / 1000.0; }
    }
    let n_sim = 200000;
    let (mut s, mut count) = (2026u64, [[0u64; 2]; 2]);
    for _ in 0..n_sim {
        let (s1, z) = splitmix64(s); let x = (z >> 63) as usize; // a fair random bit
        let (s2, u) = uniform(s1); s = s2;
        count[x][x ^ if u <= P { 1 } else { 0 }] += 1;
    }
    let nf = n_sim as f64;
    let flips_sim = (count[0][1] + count[1][0]) as f64 / nf;
    let mut i_sim = 0.0;
    for x in 0..2 { for y in 0..2 {
        let pxy = count[x][y] as f64 / nf;
        let pxs = (count[x][0] + count[x][1]) as f64 / nf;
        let pys = (count[0][y] + count[1][y]) as f64 / nf;
        i_sim += if pxy > 0.0 { pxy * (pxy / (pxs * pys)).log2() } else { 0.0 };
    } }
    let rep3_brute = best_decoder_error(&[3, 1, 2], 3, 2, P);
    let rep5_brute = best_decoder_error(&[15, 1, 2, 4, 8], 5, 4, P);
    let (mut rand_err, mut sc) = ([0.0; 3], 2026u64);
    for (idx, n) in [8u32, 16, 24].iter().enumerate() {
        let m = n / 2;
        let mut cols: Vec<u64> = Vec::new();
        for _ in 0..(n / 2) {
            let (s1, z) = splitmix64(sc); sc = s1;
            cols.push(z & ((1u64 << m) - 1));
        }
        for j in 0..m { cols.push(1u64 << j); }
        rand_err[idx] = best_decoder_error(&cols, *n, m, P);
    }
    let (mut lo, mut hi) = (0.0, 10.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if big_phi(-mid) > P { lo = mid; } else { hi = mid; }
    }
    let a = (lo + hi) / 2.0; let snr = a * a;
    let per_pulse = 0.5 * (1.0 + snr).log2();
    let per_pulse_num = diff_entropy(1.0 + snr) - diff_entropy(1.0);
    let (mut neg, mut sg) = (0u64, 7u64);
    for _ in 0..n_sim {
        let (s1, u1) = uniform(sg); let (s2, u2) = uniform(s1); sg = s2;
        if a + (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() < 0.0 { neg += 1; }
    }
    let se = (P * (1.0 - P) / nf).sqrt();
    let fano = |r: f64, n: f64| 1.0 - c_cap / r - if n > 0.0 { 1.0 / (n * r) } else { 0.0 };
    let log2_c: f64 = (0..10).map(|i| ((1000 - i) as f64 / (i + 1) as f64).log2()).fold(0.0, |acc, v| acc + v);
    let rep3 = rep_error(3, P);
    let rows: Vec<(&str, f64)> = vec![
        ("flip chance p", P), ("  0.01 x log2(100)", P * (1.0 / P).log2()), ("  0.99 x log2(1/0.99)", (1.0 - P) * (1.0 / (1.0 - P)).log2()),
        ("h(p), bits of noise per bit", h(P)), ("1 formula C = 1 - h(p)", c_cap), ("2 best I(X;Y) over 1001 input mixes", best_i), ("  at input chance q", best_q),
        ("3 simulated flip rate, 200000 bits", flips_sim), ("  simulated I(X;Y)", i_sim),
        ("capacity, bits a second", c_cap * BITS_PER_S), ("day's log, bits", LOG_BITS),
        ("plain: minutes", LOG_BITS / BITS_PER_S / 60.0), ("plain: wrong bits expected", LOG_BITS * P),
        ("triple: minutes", 3.0 * LOG_BITS / BITS_PER_S / 60.0), ("triple: wrong bits expected", LOG_BITS * rep3),
        ("five-fold: minutes", 5.0 * LOG_BITS / BITS_PER_S / 60.0), ("five-fold: wrong bits expected", LOG_BITS * rep_error(5, P)),
        ("capacity: fewest minutes", LOG_BITS / (c_cap * BITS_PER_S) / 60.0),
        ("triple vote error, formula", rep3), ("  by best decoder", rep3_brute),
        ("five-fold vote error, formula", rep_error(5, P)), ("  by best decoder", rep5_brute),
        ("12 bits sent plain, block error", 1.0 - (1.0 - P).powf(12.0)),
        ("12 bits tripled (36 sent), block error", 1.0 - (1.0 - rep3).powf(12.0)),
        ("random code n=8, 4 bits, block error", rand_err[0]), ("random code n=16, 8 bits", rand_err[1]),
        ("random code n=24, 12 bits", rand_err[2]),
        ("n=1000: n h(p), log2 likely patterns", 1000.0 * h(P)), ("  log2 C(1000,10)", log2_c),
        ("  n C, log2 codewords", 1000.0 * c_cap), ("Fano floor, R=0.95, long blocks", fano(0.95, 0.0)),
        ("  R=0.95, n=1000", fano(0.95, 1000.0)), ("Gauss: a, height in noise spreads", a),
        ("  Phi(-a), by Simpson", big_phi(-a)), ("  Phi(-a), by series", phi_series(-a)), ("  simulated flip rate", neg as f64 / nf), ("  S/N", snr),
        ("  S/N in dB", 10.0 * snr.log10()),
        ("  per pulse, 1/2 log2(1+S/N)", per_pulse), ("  per pulse, by entropies", per_pulse_num),
        ("  Shannon-Hartley, B=500 Hz", B * (1.0 + snr).log2()), ("  sign only: 1000 x C", 1000.0 * c_cap),
        ("wrong: C = 1 - p", 1.0 - P), ("wrong: natural log", 1.0 - (-P * P.ln() - (1.0 - P) * (1.0 - P).ln())),
        ("wrong: S/N in dB in the formula", B * (1.0 + 10.0 * snr.log10()).log2()),
        ("try: p = 0.1", 1.0 - h(0.1)), ("try: p = 0.5", 1.0 - h(0.5)), ("try: p = 0.99", 1.0 - h(0.99)),
        ("try: S/N doubled", B * (1.0 + 2.0 * snr).log2()), ("try: B doubled, same power", 2.0 * B * (1.0 + snr / 2.0).log2()),
    ];
    for (name, v) in &rows { println!("{:<40} {:>17.9}", name, v); }
    let pts: Vec<String> = (0..11).map(|j| format!("{:.3}", 1.0 - h(j as f64 / 20.0))).collect();
    println!("chart, C at p = 0, 0.05, ..., 0.5: {}", pts.join(" "));

    assert!((best_i - c_cap).abs() < 1e-9 && best_q == 0.5); // search lands on the formula
    assert!((flips_sim - P).abs() < 4.0 * se && (i_sim - c_cap).abs() < 0.01);
    assert!((rep3_brute - rep3).abs() < 1e-12 && (rep5_brute - rep_error(5, P)).abs() < 1e-12);
    assert!(rand_err[0] > rand_err[1] && rand_err[1] > rand_err[2]); // longer blocks, fewer errors
    assert!(rand_err[2] < 1.0 - (1.0 - rep3).powf(12.0)); // beats tripling, at a higher rate
    assert!((big_phi(-a) - phi_series(-a)).abs() < 1e-9 && (neg as f64 / nf - P).abs() < 4.0 * se); // two roads
    assert!((per_pulse_num - per_pulse).abs() < 1e-6);
    assert!(c_cap < per_pulse && fano(0.95, 0.0) > 0.0); // reading the sign loses information
    println!("ALL CHECKS PASS");
}
