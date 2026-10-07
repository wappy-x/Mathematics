// Riemann meets Lebesgue -- the check behind the card.  Rust std only.
// River depth d(x) = 4x(1 - x) metres at x km along a 1 km stretch.  Road 1:
// Riemann strips as exact integers over n^3.  Road 2: Lebesgue value slices,
// each level set an interval whose length comes from the quadratic formula.
// Road 3: the antiderivative.  Then the depth-1-at-rationals function, Thomae's
// function, sin(x)/x on (0, infinity) and 1/sqrt(x) on (0, 1].
use std::f64::consts::PI;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }
fn d(x: f64) -> f64 { 4.0 * x * (1.0 - x) }
// numerators over n^3 of the lower, upper and midpoint sums on n equal strips, n even
fn riemann(n: i128) -> (i128, i128, i128) {
    let (mut lo, mut up, mut mid) = (0, 0, 0);
    for k in 0..n {                        // n^2 d(k/n) = 4k(n - k); extremes at the strip ends
        let (a, b) = (4 * k * (n - k), 4 * (k + 1) * (n - k - 1));
        lo += a.min(b);
        up += a.max(b);
        mid += (2 * k + 1) * (2 * n - 2 * k - 1);
    }
    (lo, up, mid)
}
fn staircase(levels: u32) -> f64 {        // integral of floor(levels * d) / levels
    let mut total = 0.0;
    for k in 1..levels {
        let s = (1.0 - k as f64 / levels as f64).sqrt();
        total += (1.0 + s) / 2.0 - (1.0 - s) / 2.0;
    }
    total / levels as f64
}
fn thomae_upper(n: i64) -> f64 {          // top value in a strip is 1/q, q least denominator
    let mut total = 0.0;
    for k in 0..n {                        // least q with a multiple of 1/q in [k/n, (k+1)/n]
        let mut q = 1;
        while (k * q + n - 1) / n > (k + 1) * q / n { q += 1; }
        total += 1.0 / q as f64;
    }
    total / n as f64
}
fn thomae_by_fractions(n: i64) -> f64 {   // second road: place every p/q, q <= n, in its strips
    let mut best = vec![n + 1; n as usize];
    for q in 1..=n {
        for p in 0..=q {
            if gcd(p as i128, q as i128) != 1 { continue; }
            let j = p * n / q;
            let ks = if p * n % q == 0 { vec![j - 1, j] } else { vec![j] };
            for k in ks { if 0 <= k && k < n { best[k as usize] = best[k as usize].min(q); } }
        }
    }
    best.iter().fold(0.0, |acc, &q| acc + 1.0 / q as f64) / n as f64
}
fn hump(k: usize, panels: usize) -> f64 { // integral of sin(x)/x over [k pi, (k+1) pi], Simpson
    let h = PI / panels as f64;
    let f = |x: f64| if x == 0.0 { 1.0 } else { x.sin() / x };
    let mut s = f(k as f64 * PI) + f((k + 1) as f64 * PI);
    for i in 1..panels {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(k as f64 * PI + i as f64 * h);
    }
    s * h / 3.0
}
fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, panels: usize) -> f64 {
    let h = (b - a) / panels as f64;
    let inner = (1..panels).fold(0.0, |acc, i| acc + if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h));
    h / 3.0 * (f(a) + f(b) + inner)
}
fn main() {
    println!("Riemann meets Lebesgue: river depth d(x) = 4x(1 - x) m over 1 km");
    let n: i128 = 1000;
    let n3 = n * n * n;
    let (lo, up, mid) = riemann(n);
    assert!(3 * lo < 2 * n3 && 2 * n3 < 3 * up && (up - lo) * n == 2 * n3); // gap 2/n around 2/3
    assert!(3 * mid - 2 * n3 == n);       // midpoint minus 2/3 is 1/(3 n^2)
    let (en, ed) = (3 * mid - 2 * n3, 3 * n3);
    let g = gcd(en, ed);
    println!("road 1, 1000 strips: lower {:.7}, upper {:.7}, gap {:.3}, midpoint {:.10}",
        lo as f64 / n3 as f64, up as f64 / n3 as f64, (up - lo) as f64 / n3 as f64, mid as f64 / n3 as f64);
    println!("road 3, antiderivative: 2/3 = {:.10}; midpoint minus exact = {}/{}", 2.0 / 3.0, en / g, ed / g);
    let mut prev = 0.0;
    for m in [2u32, 4, 8, 12, 16] {
        let st = staircase(1 << m);
        assert!(prev < st && st < 2.0 / 3.0); // simple functions below d, rising
        prev = st;
        println!("road 2, staircase with {} value levels: {:.7}", 1u32 << m, st);
    }
    assert!((prev - 2.0 / 3.0).abs() < 1.0 / 65536.0);
    println!("all three roads, 4 places: {:.4} {:.4} {:.4}", mid as f64 / n3 as f64, prev, 2.0 / 3.0);
    let lo8 = riemann(8).0;
    println!("figure, 8-strip lower sum {:.5}, 4-level staircase {:.4}", lo8 as f64 / 512.0, staircase(4));
    let hs: Vec<String> = (0..8).map(|k| format!("{:.3}", 150.0 * (4 * k * (8 - k)).min(4 * (k + 1) * (7 - k)) as f64 / 64.0)).collect();
    println!("figure, strip heights px: {}", hs.join(" "));
    let lw: Vec<String> = (0..8).map(|k| format!("{:.4}", (4 * k * (8 - k)).min(4 * (k + 1) * (7 - k)) as f64 / 64.0)).collect();
    println!("worked, lowest depth in each of 8 strips (m): {}", lw.join(" "));
    let ls: Vec<String> = [1.0, 2.0, 3.0].iter().map(|j: &f64| format!("{:.4}", (1.0 - j / 4.0).sqrt())).collect();
    println!("worked, length where depth >= 0.25 0.5 0.75 (km): {}", ls.join(" "));
    let bands: Vec<String> = [1.0, 2.0, 3.0].iter().map(|j: &f64| {
        let s = (1.0 - j / 4.0).sqrt();
        format!("{:.2}-{:.2}", 190.0 + 150.0 * (1.0 - s) / 2.0, 190.0 + 150.0 * (1.0 + s) / 2.0)
    }).collect();
    println!("figure, band x px at t = 0.25 0.5 0.75: {}", bands.join(" "));
    let cv: Vec<String> = (0..17).map(|j| format!("{:.2},{:.2}", 20.0 + 150.0 * j as f64 / 16.0, 200.0 - 150.0 * d(j as f64 / 16.0))).collect();
    println!("figure, curve px: {}", cv.join(" "));

    for n in [10i64, 100, 1000] {           // depth 1 at rational x, 0 elsewhere
        let (mut up_q, mut lo_q) = (0i64, 0i64); // in units of 1/n
        for k in 0..n {                     // witnesses r = (2k+1)/(2n) and k/n + c sqrt(2), irrational because sqrt(2) is
            let ((rn, rd), (cn, cd)) = ((2 * k + 1, 2 * n), (1i64, 2 * n));
            assert!(k * rd < rn * n && rn * n < (k + 1) * rd && 0 < cn && 2 * cn * cn * n * n < cd * cd); // both strictly inside
            let dep: Vec<i64> = [0, cn].iter().map(|&c| if c == 0 { 1 } else { 0 }).collect(); // 1 exactly when the sqrt(2) part is 0
            up_q += dep.iter().max().unwrap(); // depth is only 0 or 1: the strip's top and bottom
            lo_q += dep.iter().min().unwrap();
        }
        assert!(up_q == n && lo_q == 0);   // gap 1: the jumps fill the whole stretch
        println!("rational depth, {} strips: upper sum {}, lower sum {}", n, up_q / n, lo_q);
    }
    println!("rational depth, Lebesgue: 1 x length(rationals) + 0 x length(rest) = 1 x 0 + 0 x 1 = {}", 1 * 0 + 0 * 1);

    let fs: Vec<i64> = (1..=200i128).map(|qq| (1..=qq).map(|q| (0..=q).filter(|&p| gcd(p, q) == 1).count() as i64).sum()).collect();
    for n in [10i64, 100, 1000, 10000] {
        let u = thomae_upper(n);
        let bound = (1..=200usize).map(|q| 2.0 * fs[q - 1] as f64 / n as f64 + 1.0 / q as f64).fold(f64::INFINITY, f64::min);
        assert!(0.0 < u && u <= bound);     // counting fractions with small denominators
        assert!(n > 1000 || u == thomae_by_fractions(n));
        println!("thomae, {} strips: upper sum {:.6}, counting bound {:.6}, lower sum 0", n, u, bound);
    }

    let a: Vec<f64> = (0..1001).map(|k| hump(k, 32)).collect();
    let (mut s, mut b) = (vec![0.0f64], vec![0.0f64]);
    for k in 0..1001 {
        s.push(s[k] + a[k]);
        b.push(b[k] + a[k].abs());
        assert!(a[k].abs() >= 2.0 / ((k + 1) as f64 * PI) && (a[k] > 0.0) == (k % 2 == 0));
    }
    let half_pi = 2.0 * simpson(|t| 1.0 / (1.0 + t * t), 0.0, 1.0, 1000);
    let avg = (s[1000] + s[1001]) / 2.0;
    assert!((avg - half_pi).abs() < 1e-6);  // humps against the Laplace road
    println!("sin x/x, first humps: {:.6} {:.6} {:.6} {:.6}", a[0], a[1], a[2], a[3]);
    println!("sin x/x, improper integral: humps {:.6}, Laplace road {:.6}, pi/2 {:.6}", avg, half_pi, PI / 2.0);
    let h: f64 = (1..1001).fold(0.0, |acc, k| acc + 1.0 / k as f64);
    assert!(b[1000] >= 2.0 / PI * h);       // each hump at least 2 / ((k+1) pi)
    let pos: f64 = (0..1000).step_by(2).fold(0.0, |acc, k| acc + a[k]);
    println!("|sin x/x| over 1000 humps: {:.4}, floor (2/pi) x H_1000 = {:.4}; ln 1000 = {:.4}", b[1000], 2.0 / PI * h, 1000f64.ln());
    println!("positive part over 1000 humps {:.4}, negative part {:.4}: both grow without limit", pos, pos - s[1000]);
    let ns = [1usize, 2, 3, 4, 5, 10, 20, 50, 100, 200, 500, 1000];
    let cs: Vec<String> = ns.iter().map(|&k| format!("{:.2}", s[k])).collect();
    let ca: Vec<String> = ns.iter().map(|&k| format!("{:.2}", b[k])).collect();
    println!("chart, signed to N humps: {}", cs.join(" "));
    println!("chart, absolute to N humps: {}", ca.join(" "));
    let j = 50000;                          // exhaust (0, infinity) as 2 positive humps, then 1 negative
    let tp = (0..2 * j).fold(0.0, |acc, i| acc + hump(2 * i, 32));
    let tn = (0..j).fold(0.0, |acc, i| acc + hump(2 * i + 1, 32));
    let tot = tp + tn;
    let target = PI / 2.0 + 2f64.ln() / PI;
    assert!((tot - target).abs() < 1e-4);
    println!("sin x/x, two positive humps per negative, {} humps: {:.5}; pi/2 + ln 2 / pi = {:.5}", 3 * j, tot, target);

    for n in [10i64, 100, 1000] {           // 1/sqrt(x): continuous on (0, 1], unbounded at 0
        let low = (1..=n).fold(0.0, |acc, k| acc + 1.0 / ((n * k) as f64).sqrt());
        assert!(low < 2.0 - 1.0 / (n as f64).sqrt() + 1e-12);
        println!("1/sqrt(x), {} strips: lower sum {:.4}, upper sum infinite (first strip)", n, low);
    }
    let tr: Vec<String> = [10.0, 100.0, 1000.0].iter().map(|m: &f64| format!("{:.3}", 2.0 - 1.0 / m)).collect();
    println!("1/sqrt(x), Lebesgue by truncation min(f, m), m = 10 100 1000: {}", tr.join(" "));
    println!("All checks passed.");
}
