// Sphere packing in dimensions 8 and 24 -- the same check as the Python, in Rust.
// No crates.  Exact counts: E8 and Leech vectors by enumeration and by modular
// forms.  Floats: densities, oranges in a crate, and the magic function.
use std::f64::consts::PI;

fn sigma(k: u32, n: i64) -> i64 { (1..=n).filter(|d| n % d == 0).map(|d| d.pow(k)).sum() }
fn ball8(rad: f64) -> f64 { PI.powi(4) / 24.0 * rad.powi(8) } // volume of an 8-dim ball
fn sci(x: f64, p: usize) -> String {                           // Python-style 1.2345e+06
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn tuples(vals: &[i64], len: usize) -> Vec<Vec<i64>> {        // every list of len entries from vals
    let mut out = vec![vec![]];
    for _ in 0..len {
        out = out.iter().flat_map(|v| vals.iter().map(move |&x| { let mut w = v.clone(); w.push(x); w })).collect();
    }
    out
}
fn theta8(t: f64) -> f64 { 1.0 + (1..40).map(|m| 240.0 * sigma(3, m) as f64 * (-PI * t * 2.0 * m as f64).exp()).sum::<f64>() }

// Viazovska's magic function g from phi0 (E2, E4, E6) and psi (theta functions)
fn qsum(s: f64, f: &dyn Fn(i64) -> f64) -> f64 { let q = (-2.0 * PI * s).exp(); (1..80).map(|n| f(n) * q.powi(n as i32)).sum() }
fn delta(s: f64) -> f64 {
    let q = (-2.0 * PI * s).exp();
    let mut d = 1.0;
    for n in 1..80 { d *= (1.0 - q.powi(n)).powi(24) }
    1728.0 * q * d
}
fn phi0(s: f64) -> f64 { 1728.0 * (720.0 * qsum(s, &|n| (n * sigma(3, n)) as f64)).powi(2) / delta(s) }
fn phi0_inv(t: f64) -> f64 {
    if t <= 1.0 { return phi0(1.0 / t) }
    let e4 = 1.0 + 240.0 * qsum(t, &|n| sigma(3, n) as f64);
    1728.0 * (720.0 * qsum(t, &|n| (n * sigma(3, n)) as f64) - 6.0 * e4 / (PI * t)).powi(2) / delta(t)
}
fn theta(s: f64) -> (f64, f64, f64) {
    let a = 1.0 + 2.0 * (1..40).map(|n| (-PI * s * (n * n) as f64).exp()).sum::<f64>();
    let b = 1.0 + 2.0 * (1..40).map(|n| if n % 2 == 1 { -1.0 } else { 1.0 } * (-PI * s * (n * n) as f64).exp()).sum::<f64>();
    let c = 2.0 * (0..40).map(|n| (-PI * s * (n as f64 + 0.5).powi(2)).exp()).sum::<f64>();
    (a, b, c)
}
fn psi_i(s: f64) -> f64 { let (a, b, c) = theta(s); 128.0 * (a.powi(4) + b.powi(4)) / c.powi(8) + 128.0 * (b.powi(4) - c.powi(4)) / a.powi(8) }
fn psi_s(s: f64) -> f64 { let (a, b, c) = theta(s); -128.0 * (a.powi(4) + c.powi(4)) / b.powi(8) - 128.0 * (c.powi(4) - b.powi(4)) / a.powi(8) }
fn expansion(t: f64, sgn: f64) -> f64 {
    (sgn - 1.0) * 36.0 / (PI * PI) * (2.0 * PI * t).exp() + 8640.0 * t / PI - (18144.0 - sgn * 5184.0) / (PI * PI)
}
fn ab(t: f64, sgn: f64) -> f64 {                               // A (sgn -1) and B (sgn +1)
    if t < 0.25 { return sgn * 368640.0 / (PI * PI) * t * t * (-PI / t).exp() }
    if t > 4.0 { return expansion(t, sgn) }
    let psi = if t >= 1.0 { psi_i(t) } else { -t * t * psi_s(1.0 / t) };
    -t * t * phi0_inv(t) + sgn * 36.0 / (PI * PI) * psi
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, m: usize) -> f64 {
    let h = (hi - lo) / m as f64;
    h / 3.0 * (0..=m).map(|k| (if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + k as f64 * h)).sum::<f64>()
}
fn gval(r: f64, sgn: f64) -> f64 {                             // g(r) (sgn -1, r > sqrt 2) or g-hat(r)
    let c = PI * r * r;
    let body = simpson(&|t| if t > 0.0 { ab(t, sgn) * (-c * t).exp() } else { 0.0 }, 0.0, 4.0, 3200);
    let tail = (sgn - 1.0) * 36.0 / (PI * PI) * (8.0 * PI - 4.0 * c).exp() / (c - 2.0 * PI)
        + 8640.0 / PI * (-4.0 * c).exp() * (4.0 / c + 1.0 / (c * c)) - (18144.0 - sgn * 5184.0) / (PI * PI) * (-4.0 * c).exp() / c;
    PI / 2160.0 * (PI * r * r / 2.0).sin().powi(2) * (body + tail)
}

fn main() {
    // 1. E8 = integer points with even sum, plus half-integer points with even sum
    let mut shells = [0i64; 7];
    for v in tuples(&[-2, -1, 0, 1, 2], 8) {
        let n: i64 = v.iter().map(|x| x * x).sum();
        if (n == 2 || n == 4 || n == 6) && v.iter().sum::<i64>().rem_euclid(2) == 0 { shells[n as usize] += 1 }
    }
    for v in tuples(&[-3, -1, 1, 3], 8) {                      // coordinates v/2, v odd
        let n4: i64 = v.iter().map(|x| x * x).sum();
        if n4 % 4 == 0 && [2, 4, 6].contains(&(n4 / 4)) && v.iter().sum::<i64>().rem_euclid(4) == 0 { shells[(n4 / 4) as usize] += 1 }
    }
    let counted = vec![shells[2], shells[4], shells[6]];
    let e4: Vec<i64> = (1..=3).map(|m| 240 * sigma(3, m)).collect();
    println!("E8 vectors of squared length 2, 4, 6, counted: {:?}", counted);
    println!("the same from E4 = 1 + 240 sum sigma3(n) q^n:   {:?}", e4);
    let hole = |d: usize| tuples(&[0, 1], d).iter().filter(|v| v.iter().sum::<i64>() % 2 == 0)
        .map(|v| v.iter().map(|&x| (x as f64 - 0.5).powi(2)).sum::<f64>()).fold(f64::INFINITY, f64::min);
    for d in [3, 8] {
        println!("dim {}: hole (1/2,...,1/2) sits {:.6} from the lattice; minimum distance {:.6}", d, hole(d).sqrt(), 2f64.sqrt());
    }
    let nn = 100;
    let pts: i64 = 1 + (1..=nn).map(|m| 240 * sigma(3, m)).sum::<i64>();
    let bv = ball8((2.0 * nn as f64).sqrt());
    println!("E8 points with squared length <= {}: {}; ball volume / covolume 1 = {:.1}; ratio {:.4}", 2 * nn, pts, bv, pts as f64 / bv);
    let r = 2f64.sqrt() / 2.0;
    println!("density Z8 {:.6}, D8 {:.6}, E8 {:.6} = pi^4/384 {:.6}", ball8(0.5), ball8(r) / 2.0, ball8(r), PI.powi(4) / 384.0);
    let gauss = theta8(1.0);
    println!("Poisson, covolume 1, self-dual: sum at t = 0.8 {:.9}; t^-4 x sum at 1/t {:.9}", theta8(0.8), theta8(1.25) / 0.8f64.powi(4));
    println!("Gaussian test exp(-pi x^2) summed over E8: {:.6}, above its value 1 at 0", gauss);

    // 2. Leech lattice: theta = E12 - (65520/691) Delta, against the Golay code count
    let mut tau = [0i64; 6];
    tau[1] = 1;
    for n in 1..6 { for _ in 0..24 { for k in (n..=5).rev() { tau[k] -= tau[k - n] } } }
    let leech: Vec<i64> = (1..=3).map(|m| { let x = 65520 * (sigma(11, m) - tau[m as usize]); assert!(x % 691 == 0); x / 691 }).collect();
    println!("Leech vectors of squared length 2, 4, 6 from modular forms: {:?}", leech);
    let g = [1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1];               // x^11+x^10+x^6+x^5+x^4+x^2+1
    let mut words: Vec<Vec<i64>> = Vec::new();
    for c in tuples(&[0, 1], 12) {                             // cyclic code of length 23
        let mut w = vec![0i64; 23];
        for i in 0..12 { if c[i] == 1 { for j in 0..12 { w[i + j] ^= g[j] } } }
        let par = w.iter().sum::<i64>() % 2;
        w.push(par);                                           // extend by a parity bit
        words.push(w);
    }
    let wt: Vec<i64> = words.iter().map(|w| w.iter().sum()).collect();
    let octads = wt.iter().filter(|&&x| x == 8).count() as i64;
    let minw = *wt.iter().filter(|&&x| x > 0).min().unwrap();
    let mut distinct = words.clone();
    distinct.sort();
    distinct.dedup();
    println!("Golay code: {} words, minimum weight {}, {} octads", words.len(), minw, octads);
    let kiss = octads * 128 + 24 * 4096 + 276 * 4;
    println!("Leech shortest vectors from the code: {}*2^7 + 24*2^12 + 276*4 = {}", octads, kiss);
    let fact12: f64 = (1..=12).map(|k| k as f64).product();
    println!("density Leech pi^12/12! {:.10}", PI.powi(12) / fact12);

    // 3. Oranges, 8 cm across, in a cube crate; densities in dimensions 2 and 3
    for side in [40i64, 80] {
        let m = side / 8;
        let layers = ((side - 8) as f64 / (8.0 / 2f64.sqrt())) as i64 + 1; // square layers, 5.657 cm apart
        let pyr: i64 = (0..layers).map(|k| if k % 2 == 0 { m * m } else { (m - 1) * (m - 1) }).sum();
        println!("crate {} cm: cubic stacking {} oranges, grocer's pyramid {} ({} layers)", side, m * m * m, pyr, layers);
    }
    println!("density cubic {:.6}, pyramid pi/sqrt18 {:.6}, plane hexagonal {:.6}", PI / 6.0, PI / 18f64.sqrt(), PI / 12f64.sqrt());
    println!("figure, unit 40 px, square hole radius {:.6}, hex row gap {:.6}, square density {:.6}", (2f64.sqrt() - 1.0) / 2.0, 3f64.sqrt() / 2.0, PI / 4.0);

    // 4. The magic function
    let t0 = 1.5;
    println!("phi0(i/t) at t = 1.5: direct {:.4}, via z -> -1/z {:.4}", phi0(1.0 / t0), phi0_inv(t0));
    println!("psiI(i t) at t = 1.5: {:.4}; -t^2 psiS(i/t): {:.4}", psi_i(t0), -t0 * t0 * psi_s(1.0 / t0));
    let grid = [0.25, 0.5, 1.0, 2.0, 4.0];
    println!("t      :       0.25         0.5           1           2           4");
    println!("A(t)   : {}", grid.iter().map(|&t| format!("{:>11}", sci(ab(t, -1.0), 4))).collect::<Vec<_>>().join("  "));
    println!("B(t)   : {}", grid.iter().map(|&t| format!("{:>11}", sci(ab(t, 1.0), 4))).collect::<Vec<_>>().join("  "));
    let fine: Vec<f64> = (0..376).map(|k| 0.25 + k as f64 / 100.0).collect();
    println!("checked on t = 0.25 to 4 in steps of 0.01: A < 0: {}  B > 0: {}",
             tf(fine.iter().all(|&t| ab(t, -1.0) < 0.0)), tf(fine.iter().all(|&t| ab(t, 1.0) > 0.0)));
    println!("t = 4, A direct {}, expansion {}; B direct {:.3}, expansion {:.3}",
             sci(ab(4.0, -1.0), 6), sci(expansion(4.0, -1.0), 6), ab(4.0, 1.0), expansion(4.0, 1.0));
    let s3 = 3f64.sqrt();
    println!("g-hat(0.02) {:.6}; g-hat(0.05) {:.6}; g-hat(1) {:.6}; g-hat(sqrt3) {:.6}", gval(0.02, 1.0), gval(0.05, 1.0), gval(1.0, 1.0), gval(s3, 1.0));
    println!("g(sqrt3) {:.6}; g(sqrt5) {:.7}", gval(s3, -1.0), gval(5f64.sqrt(), -1.0));

    assert!(counted == e4 && e4 == vec![240, 2160, 6720]);
    assert!((pts as f64 / bv - 1.0).abs() < 0.05 && hole(8) == 2.0 && hole(3) < 2.0);
    assert!((theta8(0.8) - theta8(1.25) / 0.8f64.powi(4)).abs() < 1e-9 && gauss > 1.0);
    assert!(leech == vec![0, 196560, 16773120] && leech[1] == kiss);
    assert!(octads == 759 && minw == 8 && distinct.len() == 4096);
    assert!((phi0(1.0 / t0) / phi0_inv(t0) - 1.0).abs() < 1e-9);
    assert!((ab(4.0, 1.0) / expansion(4.0, 1.0) - 1.0).abs() < 1e-4 && (ab(4.0, -1.0) / expansion(4.0, -1.0) - 1.0).abs() < 1e-9);
    assert!((psi_i(t0) / (-t0 * t0 * psi_s(1.0 / t0)) - 1.0).abs() < 1e-9);
    assert!(fine.iter().all(|&t| ab(t, -1.0) < 0.0 && 0.0 < ab(t, 1.0)) && (gval(0.02, 1.0) - 1.0).abs() < 0.002);
    assert!(gval(s3, -1.0) < 0.0 && 0.0 < gval(s3, 1.0) && gval(5f64.sqrt(), -1.0) < 0.0);
    println!("ALL CHECKS PASS");
}
