// Infinitely many coin tosses from one dart -- the same check in Rust, std only.
// Exact work is done in whole numbers: a dyadic chance is a count of cells over
// a power of two.  Roads: (1) one dart x = 0.7236 m, digits by exact doubling,
// split two ways; (2) Lebesgue measure of digit events on the 4,096 cells of
// level 12 against the product rule 0.5^n; (3) SplitMix64, seed 20260929,
// 200,000 darts, each x held to 128 binary digits.
use std::collections::{HashMap, HashSet};

fn digits(mut p: u128, q: u128, n: usize) -> Vec<u64> { // first n binary digits of p/q
    (0..n).map(|_| { p *= 2; let d = (p >= q) as u128; p -= q * d; d as u64 }).collect()
}
fn slot(mut n: usize) -> (usize, usize) {    // position n = 2^(k-1) * (2j - 1)  ->  (k, j)
    let mut k = 1;
    while n % 2 == 0 { n /= 2; k += 1; }
    (k, (n + 1) / 2)
}
fn split(ds: &[u64], count: usize, cap: usize) -> Vec<f64> { // U_k from slots (k, 1..cap)
    let mut u = vec![0.0; count];
    for (i, &d) in ds.iter().enumerate() {
        let (k, j) = slot(i + 1);
        if k <= count && j <= cap { u[k - 1] += d as f64 / 2f64.powi(j as i32); }
    }
    u
}
fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn uniforms(x: u128) -> [f64; 4] {           // U1..U4 from the 128 digits of x, by slot
    let mut u = [0.0; 4];
    for k in 1..=4u32 {
        let bits = 1u32 << (7 - k);
        let mut v: u64 = 0;
        for j in 1..=bits {
            let n = (1u32 << (k - 1)) * (2 * j - 1);
            v = 2 * v + ((x >> (128 - n)) & 1) as u64;
        }
        u[(k - 1) as usize] = v as f64 / 2f64.powi(bits as i32);
    }
    u
}
fn main() {
    // ---- road 1: one dart ----
    let ds = digits(1809, 2500, 320);         // x = 0.7236 = 1809/2500
    let (mut p, mut dbl) = (1809u64, Vec::new());
    for _ in 0..4 { p *= 2; dbl.push(format!("{:.4}", p as f64 / 2500.0)); if p >= 2500 { p -= 2500 } }
    println!("doubling 0.7236 four times: {}", dbl.join(", "));
    let s: Vec<String> = ds[..16].iter().map(|d| d.to_string()).collect();
    println!("dart x = 0.7236 m, binary digits 1-16: {}", s.join(" "));
    let s: Vec<String> = (1..=16).map(|n| slot(n).0.to_string()).collect();
    println!("position 1-16 goes to uniform k:      {}", s.join(" "));
    let u = split(&ds, 4, 20);
    let sl: Vec<f64> = (0..4).map(|k| ds.iter().skip((1 << k) - 1).step_by(1 << (k + 1)).take(20)
        .enumerate().map(|(j, &d)| d as f64 / 2f64.powi(j as i32 + 1)).sum()).collect();
    let f6: Vec<String> = sl.iter().map(|v| format!("{:.6}", v)).collect();
    println!("U1..U4 from 20 digits each: {}", f6.join(", "));
    println!("dart 1 = (U1, U2) = ({}, {}); dart 2 = (U3, U4) = ({}, {})", f6[0], f6[1], f6[2], f6[3]);
    let die: Vec<i64> = sl.iter().map(|v| (6.0 * v) as i64 + 1).collect();
    println!("die rolls floor(6U) + 1: {:?}", die);
    assert!(u == sl);                         // two readings of the split
    println!("figure, x scale 30 + 300x px; dart at {:.2} px; digit-1 cells row 1 [0.5,1], row 2 [0.25,0.5] [0.75,1], row 3 [0.125,0.25] [0.375,0.5] [0.625,0.75] [0.875,1]",
             30.0 + 300.0 * 1809.0 / 2500.0);

    // ---- road 2: Lebesgue measure on the 4,096 cells of level 12 ----
    let m = 12usize;
    let cells: Vec<Vec<u64>> = (0..1u128 << m).map(|i| digits(2 * i + 1, 1 << (m + 1), m)).collect();
    let mut worst = 0i64;
    for n in 1..=m {
        let mut tally: HashMap<Vec<u64>, i64> = HashMap::new();
        for c in &cells { *tally.entry(c[..n].to_vec()).or_insert(0) += 1; }
        assert!(tally.len() == 1 << n);
        for &t in tally.values() { worst = worst.max((t * (1 << n) - (1 << m)).abs()); }
    }
    println!("all 8,190 words of lengths 1 to 12: measure = 0.5^n, largest gap {}", worst);
    let pair = cells.iter().filter(|c| c[1] == 1 && c[4] == 0 && c[6] == 1).count();
    println!("P(d2 = 1, d5 = 0, d7 = 1) = {} by counting cells; 0.5^3 = {}", pair as f64 / 4096.0, 0.5f64.powi(3));
    let combos: HashSet<Vec<u64>> = cells.iter().map(|c| split(c, 4, 12).iter().map(|v| v.to_bits()).collect()).collect();
    println!("U1..U4 read from 12 digits: 64 x 8 x 4 x 2 = {} value combinations, {} distinct, each measure 1/4096", 64 * 8 * 4 * 2, combos.len());
    let rect = cells.iter().filter(|c| { let v = split(c, 2, 12); v[0] < 0.5 && v[1] < 0.25 }).count();
    println!("P(U1 < 0.5, U2 < 0.25) = {} by counting cells; 0.5 x 0.25 = {}", rect as f64 / 4096.0, 0.5 * 0.25);
    assert!(worst == 0 && pair * 8 == 4096 && combos.len() == 4096 && rect * 8 == 4096);

    // ---- what breaks ----
    let mut corr = 0.0;
    for &mm in &[4u32, 8, 12, 16] {           // U from digits 1..m, V from digits 2..m: a reused digit
        let n = 1i128 << mm;
        let (mut sa, mut sb, mut saa, mut sbb, mut sab) = (0i128, 0i128, 0i128, 0i128, 0i128);
        for i in 0..n {
            let c = digits(2 * i as u128 + 1, 1 << (mm + 1), mm as usize);
            let a = c.iter().fold(0i128, |acc, &d| 2 * acc + d as i128);          // U = a / 2^m
            let b = c[1..].iter().fold(0i128, |acc, &d| 2 * acc + d as i128);     // V = b / 2^(m-1)
            sa += a; sb += b; saa += a * a; sbb += b * b; sab += a * b;
        }
        let cov = (n * sab - sa * sb) as f64;
        let (vu, vv) = ((n * saa - sa * sa) as f64, (n * sbb - sb * sb) as f64);
        corr = cov / (vu * vv).sqrt();
        println!("shifted digits, m = {:2}: correlation of U and V = {:.6}", mm, corr);
    }
    let (var, cov_d1) = (2i64, 9 - 6);        // in 24ths: Var U = 1/12; Cov(U, d1) = 3/8 - 1/4
    let limit = (2 * var - cov_d1) as f64 / var as f64; // V = 2U - d1, worked on the card
    println!("shifted digits, by hand: Var U = {:.6}, Cov(U, d1) = {:.6}, Cov(U, V) = {:.6}, limit {}",
             var as f64 / 24.0, cov_d1 as f64 / 24.0, (2 * var - cov_d1) as f64 / 24.0, limit);
    assert!((corr - limit).abs() < 1e-3);
    let cdf16 = |a4: i64| a4 * a4;            // density 2x: P(x <= a4/4) = a4^2 / 16
    let anti = [16 - cdf16(2), cdf16(2) - cdf16(1) + 16 - cdf16(3), 16 - cdf16(3)]; // sixteenths
    let mut mid = [0i64; 3];                  // the same three chances by midpoint sums, in 2^-24
    for (i, c) in cells.iter().enumerate() {
        let w = 2 * i as i64 + 1;
        mid[0] += w * c[0] as i64; mid[1] += w * c[1] as i64; mid[2] += w * (c[0] * c[1]) as i64;
    }
    println!("density-2x dart: P(d1 = 1) = {}, P(d2 = 1) = {}, P(both) = {}, product {}",
             anti[0] as f64 / 16.0, anti[1] as f64 / 16.0, anti[2] as f64 / 16.0, (anti[0] * anti[1]) as f64 / 256.0);
    assert!((0..3).all(|t| mid[t] == anti[t] << 20) && anti[2] * 16 != anti[0] * anti[1]);

    // ---- Kolmogorov's consistency condition ----
    let sticky = |w: &[u8]| -> i64 {          // numerator over 2 * 5^(n-1): repeat weighs 4, switch 1
        w.windows(2).map(|p| if p[0] == p[1] { 4 } else { 1 }).product()
    };
    let mut ok = true;
    for n in 1..10u32 {
        for code in 0..1u32 << n {
            let w: Vec<u8> = (0..n).map(|i| ((code >> i) & 1) as u8).collect();
            let (h, t) = ([&w[..], &[1]].concat(), [&w[..], &[0]].concat());
            ok &= sticky(&h) + sticky(&t) == 5 * sticky(&w);
        }
    }
    println!("sticky coin, consistent for n = 1 to 10: {}; mu_3(HHH) = {}", if ok { "yes" } else { "no" },
             sticky(&[1, 1, 1]) as f64 / 50.0);
    let parity = |w: &[u8]| -> f64 {          // uniform on the words with an even number of heads
        if w.iter().filter(|&&d| d == 1).count() % 2 == 0 { 1.0 / 2f64.powi(w.len() as i32 - 1) } else { 0.0 }
    };
    let (p1, p2) = (parity(&[1]), parity(&[1, 1]) + parity(&[1, 0]));
    println!("parity family: mu_1(H) = {:.2}, but mu_2 gives the first toss H with {:.2}", p1, p2);
    assert!(ok && p1 != p2);

    // ---- road 3: simulation ----
    let mut state: u64 = 20260929;
    let t = 200000usize;
    let (mut s1, mut s11, mut s2, mut s22, mut s12) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let (mut three, mut six, mut hhh, mut darts) = (0usize, 0usize, 0usize, 0usize);
    for _ in 0..t {
        let hi = splitmix(&mut state) as u128;
        let x = (hi << 64) | splitmix(&mut state) as u128;
        let [u1, u2, u3, u4] = uniforms(x);
        s1 += u1; s11 += u1 * u1; s2 += u2; s22 += u2 * u2; s12 += u1 * u2;
        three += (u1 < 0.5 && u2 < 0.5 && u3 < 0.5) as usize;
        six += ((6.0 * u1) as i64 + 1 == 6) as usize;
        let t1 = u1 < 0.5;
        let t2 = if u2 < 0.8 { t1 } else { !t1 }; let t3 = if u3 < 0.8 { t2 } else { !t2 };
        hhh += (t1 && t2 && t3) as usize;
        darts += (u1 < 0.5 && u4 >= 0.5) as usize;
    }
    let tf = t as f64; let (m1, m2) = (s1 / tf, s2 / tf);
    let r = (s12 / tf - m1 * m2) / ((s11 / tf - m1 * m1) * (s22 / tf - m2 * m2)).sqrt();
    println!("simulated, {} darts: mean U1 {:.6}, correlation U1 U2 {:.6}", t, m1, r);
    let sims = [("P(U1, U2, U3 all < 0.5)", three, 0.125), ("P(die from U1 shows 6)", six, 1.0 / 6.0),
                ("P(sticky HHH)", hhh, 0.32), ("P(dart 1 left half, dart 2 top half)", darts, 0.25)];
    for (label, hits, exact) in sims {
        let (f, se) = (hits as f64 / tf, (exact * (1.0 - exact) / tf).sqrt());
        println!("simulated {} = {:.6}; exact {:.6}; standard error {:.6}", label, f, exact, se);
        assert!((f - exact).abs() < 4.0 * se);
    }
    assert!((m1 - 0.5).abs() < 4.0 * (1.0 / 12.0 / tf).sqrt() && r.abs() < 4.0 / tf.sqrt());
    println!("ALL CHECKS PASS");
}
