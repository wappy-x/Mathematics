// Liouville to Roth -- the check behind the card.  std only, no crates.
// Road 1: exact decimal digits of Liouville's constant.
// Road 2: the geometric-series bound of Why it works.  Road 3: every q up to 10^6
// against the continued fraction of the cube root of 2, built by Lagrange's method.

fn fact(n: usize) -> usize { if n == 0 { 1 } else { n * fact(n - 1) } }

fn digits(places: &[usize], length: usize) -> Vec<i32> {
    let mut d = vec![0; length + 1];
    for &k in places { d[k] = 1; }
    d
}

fn first_nonzero(x: &[i32], y: &[i32]) -> (usize, f64) {
    let (mut diff, mut borrow) = (vec![0; x.len()], 0);
    for i in (1..x.len()).rev() {
        let v = x[i] - y[i] - borrow;
        borrow = if v < 0 { 1 } else { 0 };
        diff[i] = v + 10 * borrow;
    }
    let j = (1..x.len()).find(|&i| diff[i] != 0).unwrap();
    let mut s: String = diff[j..(j + 15).min(x.len())].iter().map(|d| d.to_string()).collect();
    while s.len() < 15 { s.push('0'); }
    (j, s.parse::<u64>().unwrap() as f64 / 1e14)
}

fn truncations(gaps: &[usize], nmax: usize, length: usize, d_show: f64) -> Vec<f64> {
    let (full, mut ex) = (digits(gaps, length), Vec::new());
    for n in 1..=nmax {
        let (j, m) = first_nonzero(&full, &digits(&gaps[..n], length));
        let logq = gaps[n - 1];
        let expo = (j as f64 - m.log10()) / logq as f64;
        let l3 = d_show * logq as f64 - j as f64 + m.log10();
        let tail: f64 = gaps[n + 1..].iter().map(|&g| 10f64.powi(gaps[n] as i32 - g as i32)).sum();
        assert!(j == gaps[n] && (m - (1.0 + tail)).abs() < 1e-12); // road 2 agrees
        assert!(1.0 <= m && m < 2.0);                                // error < 2 / q^(n+1)
        println!("{} | 10^{} | 10^-{} x {:.12} | {:.6} | {:.6}", n, logq, j, m, expo, l3);
        ex.push(expo);
    }
    ex
}

fn icbrt(n: i128) -> i128 {
    let a = n.abs();
    let mut x = (a as f64).powf(1.0 / 3.0).round() as i128;
    while x * x * x > a { x -= 1; }
    while (x + 1) * (x + 1) * (x + 1) <= a { x += 1; }
    if n >= 0 { x } else if x * x * x == a { -x } else { -(x + 1) }
}

fn err(p: i128, q: i128, a: f64) -> f64 {
    let r = p as f64 / q as f64;
    (p * p * p - 2 * q * q * q).abs() as f64 / ((q * q * q) as f64 * (a * a + a * r + r * r))
}

fn main() {
    println!("Liouville's constant L = 0.1100010000...: a 1 at places 1!, 2!, 3!, ...");
    let lg: Vec<usize> = (1..6).map(fact).collect();
    let l = digits(&lg, 130);
    let s: String = l[1..31].iter().map(|d| d.to_string()).collect();
    println!("L to 30 places: 0.{}", s);
    println!("n | q = 10^(n!) | L - p/q = 10^-j x m | exponent | log10(q^3 x error)");
    let ex_l = truncations(&lg, 4, 130, 3.0);
    println!("doubling gaps S = 0.0101000100...: a 1 at places 2, 4, 8, 16, ...");
    let mg: Vec<usize> = (1..8).map(|k| 1usize << k).collect();
    let ex_s = truncations(&mg, 5, 130, 3.0);

    let mut a = 1.0f64;
    for _ in 0..8 { a = a - (a * a * a - 2.0) / (3.0 * a * a); }
    println!("cube root of 2 = {:.12}", a);
    let (mut best, mut records) = (9.0f64, Vec::new());
    let (mut low3, mut low25, mut lowb) = ((9.0f64, 0i128), (9.0f64, 0i128), (9.0f64, 0i128));
    for q in 1..=1_000_000i128 {
        let p0 = icbrt(2 * q * q * q);
        for p in [p0, p0 + 1] {
            let e = err(p, q, a);
            if q as f64 * e < best { best = q as f64 * e; records.push((p, q)); }
            let v3 = (q * q * q) as f64 * e;
            if v3 < low3.0 || (v3 == low3.0 && q < low3.1) { low3 = (v3, q); }
            let v25 = (q as f64).powf(2.5) * e;
            if v25 < low25.0 || (v25 == low25.0 && q < low25.1) { low25 = (v25, q); }
            let vb = (q as f64).powf(2.955) * e;
            if vb < lowb.0 || (vb == lowb.0 && q < lowb.1) { lowb = (vb, q); }
        }
    }

    let (mut cf, mut poly): (Vec<i128>, [i128; 4]) = (Vec::new(), [1, 0, 0, -2]);
    for _ in 0..records.len() {
        let [c3, c2, c1, c0] = poly;
        let pv = |x: i128| ((c3 * x + c2) * x + c1) * x + c0;
        let mut k = 1;
        while c3 * pv(k + 1) < 0 { k += 1; }
        cf.push(k);
        poly = [pv(k), 3 * k * k * c3 + 2 * k * c2 + c1, 3 * k * c3 + c2, c3];
    }
    let (mut conv, mut p1, mut q1, mut p2, mut q2) = (Vec::new(), 1i128, 0i128, 0i128, 1i128);
    for &x in &cf {
        let (np, nq) = (x * p1 + p2, x * q1 + q2);
        p2 = p1; q2 = q1; p1 = np; q1 = nq;
        conv.push((p1, q1));
    }
    assert!(conv == records);
    let cfs: Vec<String> = cf.iter().map(|x| x.to_string()).collect();
    println!("convergents with q <= 10^6: {}, partial quotients [{}]", conv.len(), cfs.join(", "));
    println!("k | p/q | |p^3 - 2q^3| | q^2 x error | exponent");
    for (i, &(p, q)) in conv.iter().enumerate() {
        let e = err(p, q, a);
        let ex = if q == 1 { "-".to_string() } else { format!("{:.6}", -e.ln() / (q as f64).ln()) };
        println!("{} | {}/{} | {} | {:.6} | {}", i, p, q, (p * p * p - 2 * q * q * q).abs(),
                 (q * q) as f64 * e, ex);
        assert!(((q * q) as f64) * e < 1.0);
    }
    let c_proof = 1.0 / (3.0 * a * a + 3.0 * a + 1.0);
    let brk = (0..=2000).map(|i| { let r = a - 1.0 + i as f64 / 1000.0; a * a + a * r + r * r })
        .fold(0.0f64, f64::max);
    assert!((c_proof * brk - 1.0).abs() < 1e-9);    // c = 1 / largest bracket, by sampling
    let c_tan = 1.0 / (3.0 * (a + 1.0) * (a + 1.0));  // Step 2's general proof: M = largest slope 3x^2
    let mslope = (0..=2000).map(|i| { let x = a - 1.0 + i as f64 / 1000.0; 3.0 * x * x })
        .fold(0.0f64, f64::max);
    assert!((c_tan * mslope - 1.0).abs() < 1e-9);
    println!("Liouville's c, general proof: M = {:.6}, c = {:.6}; exact identity: largest chord slope {:.6}, c = {:.6}",
             1.0 / c_tan, c_tan, 1.0 / c_proof, c_proof);
    println!("least q^3 x error to 10^6: {:.6} at q = {}", low3.0, low3.1);
    println!("least q^2.5 x error to 10^6: {:.6} at q = {} (Bennett: > 0.25)", low25.0, low25.1);
    println!("least q^2.955 x error to 10^6: {:.6} at q = {} (Baker: > 10^-6)", lowb.0, lowb.1);
    assert!(low3.0 >= c_proof && low25.0 > 0.25 && lowb.0 > 1e-6);
    println!("exponent allowed at degree 3: Liouville 3, Thue {:?}, Dyson {:.6}, Roth 2 + any eps",
             1.5 + 1.0, 6f64.sqrt());
    let e54 = err(5, 4, a);
    println!("5/4 alone: error {:.6}, exponent {:.6}, q^3 x error {:.6}", e54, -e54.ln() / 4f64.ln(),
             64.0 * e54);

    let m: i128 = 1;                 // x^3 - 2y^3 = m, bounded by Bennett's inequality
    let t = 16.0 * m.abs() as f64 / (3.0 * a * a);
    let ybound = (t * t) as i128;
    let thue = |lo: i128, hi: i128| -> Vec<(i128, i128)> {
        (lo..=hi).filter(|&y| { let n = 2 * y * y * y + m; let x = icbrt(n); x * x * x == n })
            .map(|y| (icbrt(2 * y * y * y + m), y)).collect()
    };
    let (sols, wide) = (thue(-ybound, ybound), thue(-100_000, 100_000));
    let y_last = (1..1_000_000i128).find(|&y| { let yf = y as f64;
        1.0 / (4.0 * yf.powf(2.5)) > 4.0 * m.abs() as f64 / (3.0 * a * a * yf.powi(3)) }).unwrap() - 1;
    assert!(sols == wide && ybound == y_last);      // the box, against Bennett's bound tried y by y
    let ss: Vec<String> = sols.iter().map(|(x, y)| format!("({}, {})", x, y)).collect();
    println!("x^3 - 2y^3 = {}: Bennett forces |y| <= {}; solutions [{}]; search to |y| = 100,000 finds {}",
             m, ybound, ss.join(", "), wide.len());
    let isqrt = |n: i128| -> i128 { let mut x = n; while x * x > n { x = (x + n / x) / 2; } x };
    let pts: Vec<(i128, i128)> = (-10_000..=10_000i128)
        .filter(|&x| { let n = x * x * x - x; n >= 0 && isqrt(n) * isqrt(n) == n })
        .map(|x| (x, isqrt(x * x * x - x))).collect();
    let ps: Vec<String> = pts.iter().map(|(x, y)| format!("({}, {})", x, y)).collect();
    println!("whole-number points on y^2 = x^3 - x with |x| <= 10,000: [{}]", ps.join(", "));
    assert!(pts == vec![(-1, 0), (0, 0), (1, 0)]);
    println!("Pythagorean comma 3^12 / 2^19 = {:.6}", 531441.0f64 / 524288.0);
    assert!(ex_l.iter().enumerate().all(|(i, e)| (e - (i as f64 + 2.0)).abs() < 1e-4)); // exponent n + 1
    assert!(ex_s.iter().all(|e| (e - 2.0).abs() < 1e-4));          // doubling gaps stay at exponent 2
    println!("ALL CHECKS PASS");
}
