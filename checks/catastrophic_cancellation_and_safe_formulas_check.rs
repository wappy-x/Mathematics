// Cancellation and safe formulas -- the check behind the card.  std only, no crates.
// Three jobs: the roots of x^2 - 100000000x + 1, the spread of four weighings,
// and a total of one million 0.1s.  Each unsafe formula is run beside a safe one,
// and both are measured against a road that does not share their arithmetic.

fn sci(x: f64, p: usize) -> String { format!("{:.*e}", p, x) } // 7.450580596923828e-9

fn naive_roots(a: f64, b: f64, c: f64) -> (f64, f64) { // the school formula
    let r = (b * b - 4.0 * a * c).sqrt();
    ((-b + r) / (2.0 * a), (-b - r) / (2.0 * a))
}

fn safe_roots(a: f64, b: f64, c: f64) -> (f64, f64) { // like signs only, then c/a
    let r = (b * b - 4.0 * a * c).sqrt();
    let q = if b < 0.0 { -(b - r) / 2.0 } else { -(b + r) / 2.0 };
    (q / a, c / q)
}

fn bisect_small(b: f64) -> f64 { // road 2: halve [0, 2/b] on f(x) = x(x - b) + 1
    let (mut lo, mut hi) = (0.0f64, 2.0 / b);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if mid * (mid - b) + 1.0 > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn digits(x: f64, rf: f64) -> f64 { // correct significant digits, capped at 16
    let e = (x - rf).abs() / rf;
    if e < 1e-16 { 16.0 } else if e >= 1.0 { 0.0 } else { (-e.log10()).min(16.0) }
}

fn exact_small(k: u32) -> f64 { // road 4: 2/(B + sqrt(B^2 - 4)), B = 10^k, in whole numbers
    let (bb, s) = (10u128.pow(k), 10u128.pow(19 - k));
    let (p, q) = (2 * s, bb * s + ((bb * bb - 4) * s * s).isqrt());
    let mut e = 0; // scale p/q until the quotient has 53 bits, then round once, ties to even
    while (p << e) / q < (1u128 << 52) { e += 1; }
    let (mut m, r) = ((p << e) / q, (p << e) % q);
    if 2 * r > q || (2 * r == q && m & 1 == 1) { m += 1; }
    m as f64 / 2f64.powi(e)
}

fn add(xs: &[f64]) -> f64 { // plain left-to-right float sum
    let mut t = 0.0;
    for x in xs { t += x; }
    t
}

fn shortcut(xs: &[f64]) -> f64 { // mean of squares minus squared mean
    let n = xs.len() as f64;
    let m = add(xs) / n;
    let sq: Vec<f64> = xs.iter().map(|x| x * x).collect();
    add(&sq) / n - m * m
}

fn two_pass(xs: &[f64]) -> f64 { // find the mean first, then square distances
    let n = xs.len() as f64;
    let m = add(xs) / n;
    let sq: Vec<f64> = xs.iter().map(|x| (x - m) * (x - m)).collect();
    add(&sq) / n
}

fn welford(xs: &[f64]) -> f64 { // one pass, running mean and running sum of squares
    let (mut n, mut m, mut s) = (0.0f64, 0.0f64, 0.0f64);
    for &x in xs {
        n += 1.0;
        let d = x - m;
        m += d / n;
        s += d * (x - m);
    }
    s / n
}

fn main() {
    let (a, b, c) = (1.0f64, -1e8f64, 1.0f64);
    let d = b * b - 4.0 * a * c;
    let r = d.sqrt();
    let (nbig, nsmall) = naive_roots(a, b, c);
    let (sbig, ssmall) = safe_roots(a, b, c);
    let bis = bisect_small(-b);
    let series = (1.0 / -b) * (1.0 + 1.0 / (b * b)); // road 3: (1/B)(1 + 1/B^2 + ...), B = -b
    let true_gap = 2.0 * bis; // what -b - sqrt(D) should have been
    let rel = (nsmall - bis).abs() / bis;
    let kappa = (b.abs() + r) / true_gap; // condition number, true difference
    let eps = 2.0f64.powi(-52);
    let wrong_big = c / (-(b + r) / 2.0); // safe recipe with the sign flipped
    println!("quadratic,x^2 - 100000000x + 1");
    println!("discriminant,{:.1}", d);
    println!("sqrt stored,{:.10}", r);
    println!("gap -b - sqrt stored,{}", sci(-b - r, 15));
    println!("gap true,{}", sci(true_gap, 15));
    println!("naive roots,{:.1},{}", nbig, sci(nsmall, 15));
    println!("safe roots,{:.1},{}", sbig, sci(ssmall, 15));
    println!("bisection small root,{}", sci(bis, 15));
    println!("series small root,{}", sci(series, 15));
    println!("naive small root error,{:.2}%", rel * 100.0);
    println!("kappa,{}", sci(kappa, 3));
    println!("bound kappa*eps/2,{:.2}", kappa * eps / 2.0);
    println!("wrong sign big root,{:.1}", wrong_big);
    assert!((ssmall - bis).abs() / bis < 4e-16); // safe formula meets bisection
    assert!((series - bis).abs() / bis < 4e-16); // and the series
    assert!(0.25 < rel && rel < 0.26); // a quarter of the small root is lost
    assert!(rel <= kappa * eps / 2.0); // and the loss sits inside the kappa bound
    assert!((sbig * bis - c / a).abs() < 4e-16 && wrong_big == 2f64.powi(27)); // big root x bisection
    for k in 1..10 {
        let bb = 10f64.powi(k);
        let rf = exact_small(k as u32);
        println!("digits,B=1e{},{:.1},{:.1}", k,
            digits(naive_roots(1.0, -bb, 1.0).1, rf), digits(safe_roots(1.0, -bb, 1.0).1, rf));
    }
    assert!(digits(safe_roots(1.0, -1e9, 1.0).1, exact_small(9)) > 15.0);

    let mg: [i128; 4] = [1_000_000_004, 1_000_000_007, 1_000_000_013, 1_000_000_016];
    let n = mg.len() as i128;
    let s1: i128 = mg.iter().sum();
    let s2: i128 = mg.iter().map(|x| x * x).sum();
    let num = n * s2 - s1 * s1; // exact, whole numbers only
    let exact = num as f64 / (n * n) as f64;
    let xs: Vec<f64> = mg.iter().map(|&x| x as f64).collect();
    let nf = xs.len() as f64;
    let m = add(&xs) / nf;
    let sq: Vec<f64> = xs.iter().map(|x| x * x).collect();
    let ms = add(&sq) / nf;
    println!("weighings mean,{:.1}", m);
    println!("variance exact,{:.4}", exact);
    println!("variance shortcut,{:.4}", shortcut(&xs));
    println!("variance two-pass,{:.4}", two_pass(&xs));
    println!("variance welford,{:.4}", welford(&xs));
    println!("std dev,{:.3}", exact.sqrt());
    println!("distances from mean,{}", xs.iter().map(|x| format!("{:.0}", (x - m).abs())).collect::<Vec<_>>().join(","));
    let ulp = f64::from_bits(ms.to_bits() + 1) - ms; // the gap to the next stored number
    println!("spacing near the squares,{:.0},largest rounding,{:.0}", ulp, ulp / 2.0);
    let kv = (ms + m * m) / exact;
    println!("kappa,{},bound kappa*eps/2,{:.2},kappa*4*eps/2,{:.2}", sci(kv, 3), kv * eps / 2.0, kv * 4.0 * eps / 2.0);
    for off in [1e7f64, 1e8, 1e9] {
        let ys: Vec<f64> = [4.0, 7.0, 13.0, 16.0].iter().map(|d| off + d).collect();
        println!("shortcut at offset {},{:.4},two-pass,{:.4}", sci(off, 0), shortcut(&ys), two_pass(&ys));
    }
    assert!(exact == 22.5 && two_pass(&xs) == exact);
    assert!(welford(&xs) == exact);
    assert!((shortcut(&xs) - exact).abs() > 10.0);
    assert!((shortcut(&xs) - exact).abs() / exact <= kv * 4.0 * eps / 2.0); // 7 roundings: 4 eps/2

    let nn: i128 = 1_000_000;
    let (mut plain, mut kahan, mut comp) = (0.0f64, 0.0f64, 0.0f64);
    for _ in 0..nn {
        plain += 0.1;
        let y = 0.1 - comp;
        let t = kahan + y;
        comp = (t - kahan) - y;
        kahan = t;
    }
    let ten: i128 = 3602879701896397; // the stored 0.1 is exactly ten / 2^55
    let true_num = ten * nn; // the exact total of the stored 0.1s, over 2^55
    let s = 2f64.powi(55);
    let err_plain = ((plain * s) as i128 - true_num) as f64 / s;
    let err_kahan = ((kahan * s) as i128 - true_num) as f64 / s;
    let total = nn as f64 * 0.1;
    println!("sum of {} x 0.1,plain,{:.11},kahan,{:.11}", nn, plain, kahan);
    println!("exact total,{} + {},stored 0.1,{} / 2^55", true_num >> 55, sci((true_num % (1i128 << 55)) as f64 / s, 3), ten);
    println!("error plain,{},bound,{}", sci(err_plain, 3), sci(nn as f64 * eps / 2.0 * total, 3));
    println!("error kahan,{},bound,{}", sci(err_kahan, 3), sci(2.0 * eps / 2.0 * total, 3));
    assert!(1e-6 < err_plain.abs() && err_plain.abs() <= nn as f64 * eps / 2.0 * total);
    assert!(err_kahan.abs() <= 2f64.powi(-37) && err_kahan.abs() < err_plain.abs() / 1e4);
    let x = 1e-8f64;
    println!("1 - cos(1e-8),{},2sin^2(x/2),{}", sci(1.0 - x.cos(), 3), sci(2.0 * (x / 2.0).sin().powi(2), 3));
    assert!(1.0 - x.cos() == 0.0 && (2.0 * (x / 2.0).sin().powi(2) - x * x / 2.0).abs() < 1e-30);
    println!("ALL CHECKS PASS");
}
