// Slepian-Wolf and the multiple-access channel -- the same check as the Python, in Rust.
// No crates: std's f64 gives logs, exp, cos, sqrt; nothing knows a rate region.
// Part 1: two weather stations A and B log rain (1) or dry (0); half the days are wet,
// and B disagrees with A on 10% of days.  Part 2: two radios, power 1 each, share
// one receiver with noise power 1.  Random numbers: SplitMix64, seed 2026.
use std::f64::consts::PI;
const P_DIS: f64 = 0.1; const LOW: f64 = 0.40; const HIGH: f64 = 0.55;
const P1: f64 = 1.0; const P2: f64 = 1.0; const NOISE: f64 = 1.0;

fn h(p: f64) -> f64 { -p * p.log2() - (1.0 - p) * (1.0 - p).log2() }  // binary entropy, bits
fn ent(ps: &[f64]) -> f64 { -ps.iter().filter(|&&q| q > 0.0).map(|q| q * q.log2()).sum::<f64>() }
fn cap(snr: f64) -> f64 { 0.5 * (1.0 + snr).log2() }       // bits per pulse at a signal-to-noise ratio

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) }
}

fn log2_binoms(n: usize) -> Vec<f64> {                     // log2 of C(n, j) for j = 0..n, built up
    let (mut out, mut v) = (vec![0.0], 0.0);
    for j in 0..n { v += ((n - j) as f64 / (j + 1) as f64).log2(); out.push(v) }
    out
}

fn log2_add(a: f64, b: f64) -> f64 {                       // log2(2^a + 2^b)
    let (a, b) = if a < b { (b, a) } else { (a, b) };
    if b > -1e300 { a + (1.0 + 2f64.powf(b - a)).log2() } else { a }
}

fn best_success(n: usize, rate: f64) -> f64 {              // keep the 2^(nR) likeliest patterns
    let (lb, room) = (log2_binoms(n), n as f64 * rate);
    let (mut used, mut s) = (-1e308, 0.0);
    for j in 0..=n {
        let lp = j as f64 * P_DIS.log2() + (n - j) as f64 * (1.0 - P_DIS).log2();
        if log2_add(used, lb[j]) <= room + 1e-9 {
            s += 2f64.powf(lb[j] + lp); used = log2_add(used, lb[j]);
        } else if room - used < 1e-9 { return s }
        else { return s + 2f64.powf(room + (1.0 - 2f64.powf(used - room)).log2() + lp) }
    }
    s
}

fn binning_error(n: usize, rate: f64) -> f64 {             // union bound for random bins
    let (lb, mut vol, mut e) = (log2_binoms(n), -1e308, 0.0);
    for d in 0..=n {
        vol = log2_add(vol, lb[d]);
        let lp = lb[d] + d as f64 * P_DIS.log2() + (n - d) as f64 * (1.0 - P_DIS).log2();
        e += 2f64.powf(lp + (vol - n as f64 * rate).min(0.0));
    }
    e
}

fn syndrome(word: u32) -> u32 { (0..7).filter(|i| word >> i & 1 == 1).fold(0, |s, i| s ^ (i + 1)) } // Hamming (7,4): column i is i in binary
fn decode(a: u32, sb: u32) -> u32 { let s = syndrome(a) ^ sb; if s == 0 { a } else { a ^ (1 << (s - 1)) } } // town holds A's week and B's label

fn lp(x: f64, v: f64) -> f64 { -x * x / (2.0 * v * 2f64.ln()) - 0.5 * (2.0 * PI * v).log2() }

fn entropy_simpson(v: f64) -> f64 {                        // -integral of f log2 f, normal of variance v
    let m = 4000;
    let (a, b) = (-14.0 * v.sqrt(), 14.0 * v.sqrt());
    let w = (b - a) / m as f64;
    let f = |x: f64| -2f64.powf(lp(x, v)) * lp(x, v);
    w / 3.0 * (0..=m).map(|k| (if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 })
        * f(a + k as f64 * w)).sum::<f64>()
}

fn main() {
    let out: std::cell::RefCell<Vec<String>> = std::cell::RefCell::new(Vec::new());
    let show = |label: &str, x: f64| -> f64 { out.borrow_mut().push(format!("{:<46}{:>12.6}", label, x)); x };
    // ---- Part 1: Slepian-Wolf ----
    let ha = show("H(A) = H(B), one station alone", ent(&[0.5, 0.5]));
    let hab_f = show("H(A,B) by 1 + h(0.1)", 1.0 + h(P_DIS));
    let c4 = [(1.0 - P_DIS) / 2.0, P_DIS / 2.0, P_DIS / 2.0, (1.0 - P_DIS) / 2.0]; // (A, B) = dry-dry, dry-wet, wet-dry, wet-wet
    let hab_t = show(&format!("H(A,B) from the four cells {}", c4.iter().map(|q| format!("{:.2}", q)).collect::<Vec<_>>().join(" ")), ent(&c4));
    let hbga = show("H(B|A) = H(A,B) - H(A)", hab_t - ha);
    show("separate coding, no correlation used", 2.0 * ha); show("saving per day, 2 - H(A,B)", 2.0 * ha - hab_t);
    show("B, long-run bits per 365 days, at H(B|A)", 365.0 * hbga);
    show("both, long-run bits per 365 days, at H(A,B)", 365.0 * hab_t);
    show("one 365-day block with 171 bits: best success", best_success(365, 171.0 / 365.0));
    show("  fewest bits for success 0.9 or more", (0..366).find(|&k| best_success(365, k as f64 / 365.0) >= 0.9).unwrap() as f64);
    let mut ok = 0.0;
    for a in 0..128u32 {
        for b in 0..128u32 {
            let d = (a ^ b).count_ones() as i32;
            let pr = 2f64.powi(-7) * P_DIS.powi(d) * (1.0 - P_DIS).powi(7 - d);
            if decode(a, syndrome(b)) == b { ok += pr }
        }
    }
    let (mut rng, weeks, mut hits) = (SplitMix64 { s: 2026 }, 100000, 0);
    for _ in 0..weeks {
        let a = (rng.next() & 127) as u32;
        let mut e = 0u32;
        for i in 0..7 { if rng.unif() < P_DIS { e |= 1 << i } }
        if decode(a, syndrome(a ^ e)) == a ^ e { hits += 1 }
    }
    let (wa, wb) = (0b1001101u32, 0b1011101u32);             // days 1..7 are bits 0..6
    out.borrow_mut().push(format!("example week: A rains days 1,3,4,7, B days 1,3,4,5,7: B's label {}, A's label {}, town flips day {}, right: {}",
        syndrome(wb), syndrome(wa), syndrome(wa) ^ syndrome(wb), if decode(wa, syndrome(wb)) == wb { "yes" } else { "no" }));
    show("Hamming label: B's rate 3/7 bits per day", 3.0 / 7.0);
    let p_ham = show("  weeks decoded right, all 2^14 week pairs", ok);
    let p_sim = show("  weeks decoded right, 100,000 simulated", hits as f64 / weeks as f64);
    let p_best7 = show("  best any 3-bit label can do, n = 7", best_success(7, 3.0 / 7.0));
    let mut w12: Vec<f64> = (0..4096u32).map(|e| { let d = e.count_ones() as i32;
        P_DIS.powi(d) * (1.0 - P_DIS).powi(12 - d) }).collect();
    w12.sort_by(|x, y| y.partial_cmp(x).unwrap());
    let p_b12 = show("n = 12, rate 1/2: top 64 of 4,096 patterns", w12[..64].iter().sum());
    let bs: Vec<f64> = [100, 1000, 2000].iter()
        .map(|&n| show(&format!("best success at rate {:.2}, n = {}", LOW, n), best_success(n, LOW))).collect();
    let be: Vec<f64> = [100, 1000, 2000].iter()
        .map(|&n| show(&format!("binning error bound at rate {:.2}, n = {}", HIGH, n), binning_error(n, HIGH))).collect();
    let (mut c, mut cum, mut e100) = (1u128, 0u128, 0.0f64); // n = 100 again, a second road: whole-number counts, no logs
    for d in 0..=100u32 { cum += c; e100 += c as f64 * P_DIS.powi(d as i32) * (1.0 - P_DIS).powi(100 - d as i32) * (cum as f64 / 2f64.powf(100.0 * HIGH)).min(1.0); c = c * (100 - d) as u128 / (d + 1) as u128; }
    show(&format!("B alone at rate {:.2}, n = 1000: log2 success", HIGH), 1000.0 * HIGH - 1000.0);
    // ---- Part 2: the Gaussian multiple-access channel ----
    let (c1, c2) = (show("R1 at most C(P1/N)", cap(P1 / NOISE)), show("R2 at most C(P2/N)", cap(P2 / NOISE)));
    let csum = show("R1 + R2 at most C((P1+P2)/N)", cap((P1 + P2) / NOISE));
    let r2c = show("corner: R2 = C(P2/(P1+N)), radio 1 as noise", cap(P2 / (P1 + NOISE)));
    show("corner: R1 = C(P1/N), radio 2 subtracted", c1);
    let s_sum = show("sum by Simpson: h(Y) - h(Z)", entropy_simpson(3.0) - entropy_simpson(1.0));
    let s_r2 = show("R2 by Simpson: h(Y) - h(Y|X2)", entropy_simpson(3.0) - entropy_simpson(2.0));
    let (mut rng, n_mc) = (SplitMix64 { s: 2026 }, 200000);
    let mut acc = [[0.0f64; 2]; 2];
    for _ in 0..n_mc {
        let mut g = Vec::new();
        for _ in 0..2 {
            let (u1, u2) = (rng.unif(), rng.unif());
            let r = (-2.0 * u1.ln()).sqrt();
            g.push(r * (2.0 * PI * u2).cos()); g.push(r * (2.0 * PI * u2 - PI / 2.0).cos());
        }
        let (x2, z) = (g[1], g[2]);
        let y = g[0] + x2 + z;
        for (k, s) in [lp(z, 1.0) - lp(y, 3.0), lp(y - x2, 2.0) - lp(y, 3.0)].iter().enumerate() {
            acc[k][0] += s; acc[k][1] += s * s;
        }
    }
    let nf = n_mc as f64;
    let mc: Vec<(f64, f64)> = acc.iter().map(|a| (a[0] / nf, ((a[1] / nf - (a[0] / nf).powi(2)) / nf).sqrt())).collect();
    show("sum by simulation, 200,000 pulses", mc[0].0); show("  its standard error", mc[0].1);
    show("R2 corner by simulation", mc[1].0); show("  its standard error", mc[1].1);
    show("both treat the other as noise: sum", 2.0 * cap(P1 / (P2 + NOISE)));
    show("take turns, power 1 each: sum", 0.5 * cap(P1 / NOISE) + 0.5 * cap(P2 / NOISE));
    show("take turns, power 2 in each turn: sum", 0.5 * cap(2.0 * P1 / NOISE) + 0.5 * cap(2.0 * P2 / NOISE));
    show("wrong: both at single-user rate 0.5: sum", c1 + c2);
    show("one sender, same pulse on both radios: C(4)", cap((P1.sqrt() + P2.sqrt()).powi(2) / NOISE));
    show("sum rate x 1,000 pulses a second", 1000.0 * csum);
    for n in [100, 1000, 2000] { show(&format!("try: HIGH = 0.50, binning bound, n = {}", n), binning_error(n, 0.50)); }
    for n in [1000, 2000] { show(&format!("try: LOW = 0.45, best success, n = {}", n), best_success(n, 0.45)); }
    show("try: P_DIS = 0.2, H(A,B) = 1 + h(0.2)", 1.0 + h(0.2)); show("  week-long label decodes", 0.8f64.powi(7) + 7.0 * 0.2 * 0.8f64.powi(6));
    for line in out.borrow().iter() { println!("{}", line) }
    let (x0, y0, s1, x0m, s2) = (42.0, 230.0, 150.0, 300.0, 320.0);  // figure: pixels per bit
    println!("figure, SW corners ({:.1},{:.1}) ({:.1},{:.1}); MAC corners ({:.1},{:.1}) ({:.1},{:.1})",
        x0 + s1 * 1.0, y0 - s1 * hbga, x0 + s1 * hbga, y0 - s1 * 1.0,
        x0m + s2 * c1, y0 - s2 * r2c, x0m + s2 * r2c, y0 - s2 * c2);
    assert!((hab_f - hab_t).abs() < 1e-12 && (hab_t - 1.468996).abs() < 1e-6);       // two roads to H(A,B)
    assert!((p_ham - (0.9f64.powi(7) + 7.0 * 0.1 * 0.9f64.powi(6))).abs() < 1e-12 && (p_ham - p_best7).abs() < 1e-12);
    assert!((p_sim - p_ham).abs() < 4.0 * (p_ham * (1.0 - p_ham) / weeks as f64).sqrt());  // within 4 SE
    assert!((s_sum - 0.5 * 3f64.log2()).abs() < 1e-9 && (s_r2 - (csum - c1)).abs() < 1e-9);
    assert!((mc[0].0 - csum).abs() < 4.0 * mc[0].1 && (mc[1].0 - r2c).abs() < 4.0 * mc[1].1);
    assert!((p_b12 - best_success(12, 0.5)).abs() < 1e-12 && bs[2] < bs[1] && bs[1] < bs[0] && be[2] < be[1] && be[1] < be[0]);
    assert!((be[0] - e100).abs() < 1e-9);                                            // binning bound: logs against whole numbers
    println!("ALL CHECKS PASS");
}
