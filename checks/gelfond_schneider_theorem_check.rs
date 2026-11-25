// Gelfond-Schneider -- the check behind the card.  std only, no crates.
// Road 1: a^b = exp(b ln a), from series written here.  Road 2: a^b from the binary
// digits of b, one square root per digit.  Siegel's lemma: a pigeonhole collision,
// checked against a brute-force search for the smallest whole solution.
use std::collections::HashMap;

fn sqrt(x: f64) -> f64 {            // Newton's method from above, stops when it stops falling
    let mut r = if x > 1.0 { x } else { 1.0 };
    loop { let n = 0.5 * (r + x / r); if n >= r { return r; } r = n; }
}

fn series(t: f64, sign: i32) -> f64 { // atanh (sign 1), atan (sign -1)
    let (mut s, mut p) = (0.0f64, t);
    for k in (1..120).step_by(2) {
        s += (if k % 4 == 1 || sign == 1 { p } else { -p }) / k as f64;
        p *= t * t;
    }
    s
}

fn ln(mut x: f64, ln2: f64) -> f64 { // x = m 2^e with 1 <= m < 2; ln m = 2 atanh((m-1)/(m+1))
    let mut e = 0i32;
    while x >= 2.0 { x /= 2.0; e += 1; }
    while x < 1.0 { x *= 2.0; e -= 1; }
    e as f64 * ln2 + 2.0 * series((x - 1.0) / (x + 1.0), 1)
}

fn exp(mut x: f64) -> f64 {         // halve until small, Taylor series, square back
    let mut k = 0;
    while x.abs() > 1.0 / 1024.0 { x /= 2.0; k += 1; }
    let (mut s, mut term) = (1.0f64, 1.0f64);
    for n in 1..20 { term *= x / n as f64; s += term; }
    for _ in 0..k { s *= s; }
    s
}

fn pow_bits(a: f64, b: f64) -> f64 { // road 2: a^floor(b), times a^(1/2^k) for each 1 bit of b
    let n = b as i64;
    let (mut f, mut out) = (b - n as f64, 1.0f64);
    for _ in 0..n { out *= a; }
    let mut r = a;
    for _ in 0..60 {
        r = sqrt(r); f *= 2.0;
        if f >= 1.0 { f -= 1.0; out *= r; }
    }
    out
}

fn tup(v: &[i64]) -> String { format!("({})", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn commas(n: i64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    out
}

fn solve_last_two(cols: [[i64; 2]; 2], rhs: [i64; 2]) -> Option<(i64, i64)> { // Cramer's rule
    let ([a, b], [c, e]) = (cols[0], cols[1]);
    let det = a * e - b * c;
    let (n1, n2) = (rhs[0] * e - b * rhs[1], a * rhs[1] - c * rhs[0]);
    if n1 % det != 0 || n2 % det != 0 { None } else { Some((n1 / det, n2 / det)) }
}

fn main() {
    let ln2 = 2.0 * series(1.0 / 3.0, 1);
    let pi = 16.0 * series(1.0 / 5.0, -1) - 4.0 * series(1.0 / 239.0, -1); // Machin's formula
    let (mut e, mut term) = (1.0f64, 1.0f64);
    for n in 1..25 { term /= n as f64; e += term; }
    let r2 = sqrt(2.0);
    println!("sqrt 2 = {:.11}, ln 2 = {:.11}, pi = {:.11}, e = {:.11}", r2, ln2, pi, e);
    println!("a^b | road 1: exp(b ln a) | road 2: binary digits of b");
    let mut vals = Vec::new();
    for (name, a, b) in [("2^sqrt2", 2.0, r2), ("sqrt2^sqrt2", r2, r2), ("e^pi", e, pi)] {
        let (v1, v2) = (exp(b * ln(a, ln2)), pow_bits(a, b));
        assert!((v1 - v2).abs() < 1e-11 * v1);    // two roads agree
        vals.push(v1);
        println!("{} | {:.9} | {:.9}", name, v1, v2);
    }
    // (-1)^(-i) and i^(-2i): b times the principal log, as complex pairs (re, im)
    let cmul = |u: (f64, f64), v: (f64, f64)| (u.0 * v.0 - u.1 * v.1, u.0 * v.1 + u.1 * v.0);
    let (w1, w2) = (cmul((0.0, -1.0), (0.0, pi)), cmul((0.0, -2.0), (0.0, pi / 2.0)));
    assert!(w1 == (pi, 0.0) && w2 == (pi, 0.0));
    println!("(-1)^(-i) = exp(-i * i pi) = exp({:.9}) = {:.9}; i^(-2i) = {:.9}", w1.0, exp(w1.0), exp(w2.0));
    let back = pow_bits(vals[1], r2);
    assert!((back - 2.0).abs() < 1e-11);       // (sqrt2^sqrt2)^sqrt2 = sqrt2^2 = 2
    println!("(sqrt2^sqrt2)^sqrt2 = {:.9}", back);
    let l23 = ln(3.0, ln2) / ln2;
    println!("b = log2 3 = {:.9} (b not algebraic): 2^b = {:.9}", l23, pow_bits(2.0, l23));
    let h = pow_bits(2.0, 0.5);
    println!("b = 1/2 (rational b): 2^b = {:.9}, squared {:.9}", h, h * h);
    println!("a = 1: 1^sqrt2 = {:.9}", pow_bits(1.0, r2));
    assert!((pow_bits(2.0, l23) - 3.0).abs() < 1e-11 && (exp(pi) - vals[2]).abs() < 1e-11 * 24.0);

    // Siegel's lemma: M equations, N unknowns, coefficients at most A in size
    let a: [[i64; 4]; 2] = [[10, 7, 1, 7], [7, 6, 8, -10]];
    let (m, n, amax) = (2u32, 4u32, 10i64);
    let mut hb = 0i64;
    while (hb + 1).pow(n - m) <= (n as i64 * amax).pow(m) { hb += 1; } // largest H with H^(N-M) <= (NA)^M
    assert!(hb == ((n as f64 * amax as f64).powf(m as f64 / (n - m) as f64) + 1e-9) as i64); // second way
    println!("Siegel bound (N A)^(M/(N-M)) = ({} x {})^({}/{}) = {}", n, amax, m, n - m, hb);
    let image = |x: [i64; 4]| -> (i64, i64) {
        let f = |r: &[i64; 4]| r.iter().zip(x.iter()).map(|(p, q)| p * q).sum::<i64>();
        (f(&a[0]), f(&a[1]))
    };
    let (boxes, images) = ((hb + 1).pow(n), (n as i64 * amax * hb + 1).pow(m));
    println!("vectors with entries 0..{}: {}; possible images at most {}", hb, commas(boxes), commas(images));
    assert!(boxes > images);
    let (mut seen, mut hit): (HashMap<(i64, i64), [i64; 4]>, Option<([i64; 4], [i64; 4])>) = (HashMap::new(), None);
    let s = hb + 1;
    for i in 0..boxes {
        let x = [i / (s * s * s), i / (s * s) % s, i / s % s, i % s];
        let y = image(x);
        if let Some(&p) = seen.get(&y) { hit = Some((p, x)); break; }
        seen.insert(y, x);
    }
    let (p0, p1) = hit.unwrap();
    let d = [p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2], p1[3] - p0[3]];
    let height = |v: &[i64]| v.iter().map(|x| x.abs()).max().unwrap();
    assert!(image(d) == (0, 0) && d.iter().any(|&x| x != 0) && height(&d) <= hb);
    let im = image(p0);
    println!("first collision: {} and {}, image ({}, {}), after {} vectors", tup(&p0), tup(&p1), im.0, im.1,
             commas(seen.len() as i64));
    println!("difference {}: solves both equations, height {}", tup(&d), height(&d));
    let mut sols: Vec<[i64; 4]> = Vec::new();
    for x1 in -hb..=hb {                 // road 2: every (x1, x2), then x3, x4 forced
        for x2 in -hb..=hb {
            if x1 == 0 && x2 == 0 { continue; }
            if let Some((x3, x4)) = solve_last_two([[a[0][2], a[0][3]], [a[1][2], a[1][3]]],
                    [-(a[0][0] * x1 + a[0][1] * x2), -(a[1][0] * x1 + a[1][1] * x2)]) {
                if x3.abs().max(x4.abs()) <= hb { sols.push([x1, x2, x3, x4]); }
            }
        }
    }
    let small = *sols.iter().min_by_key(|s| (height(&s[..]), **s)).unwrap();
    assert!(sols.iter().all(|s| image(*s) == (0, 0)) && sols.contains(&d));
    println!("brute force: {} nonzero solutions of height <= {}; smallest {}, height {}", sols.len(), hb,
             tup(&small), height(&small));
    let sq = (-hb..=hb).flat_map(|x1| (-hb..=hb).map(move |x2| (x1, x2))).filter(|&(x1, x2)|
        (x1 != 0 || x2 != 0) && a[0][0] * x1 + a[0][1] * x2 == 0 && a[1][0] * x1 + a[1][1] * x2 == 0).count();
    println!("square system (first 2 unknowns): det {}, nonzero solutions {}", a[0][0] * a[1][1] - a[0][1] * a[1][0], sq);
    assert!(sq == 0);
    let h3 = (3 * amax).pow(2);         // N = 3, M = 2: exponent 2/(3-2) = 2
    let (x3, (x1, x2)) = (1..=h3).find_map(|x3| solve_last_two([[a[0][0], a[0][1]], [a[1][0], a[1][1]]],
        [-a[0][2] * x3, -a[1][2] * x3]).map(|r| (x3, r))).unwrap();
    let v3 = [x1, x2, x3];
    let cross = [7 * 8 - 1 * 6, 1 * 7 - 10 * 8, 10 * 6 - 7 * 7];
    assert!(v3 == cross || v3 == [-cross[0], -cross[1], -cross[2]]);
    println!("three unknowns: bound 30^2 = {}; smallest solution {}, height {}", h3, tup(&v3), height(&v3));

    // The squeeze in miniature: x - y sqrt2 is small (pigeonhole) but not too small (norm >= 1)
    let hq = 1000i64;
    let mut best = (9.0f64, 0i64, 0i64);
    for y in 1..=hq {
        let x = (y as f64 * r2 + 0.5) as i64;
        let v = (x * x - 2 * y * y).abs() as f64 / (x as f64 + y as f64 * r2); // |x - y sqrt2| via the norm
        assert!(v >= 1.0 / (2.0 * r2 * y as f64 + 0.5));                   // lower bound from |norm| >= 1
        if v < best.0 { best = (v, y, x); }
    }
    println!("y <= {}: smallest |x - y sqrt2| = {:.9} at x = {}, y = {}", hq, best.0, best.2, best.1);
    let lo = 1.0 / (2.0 * r2 * hq as f64 + 0.5);
    println!("lower bound 1/(2 sqrt2 H + 1/2) = {:.9}; upper bound 1/H = {:.9}", lo, 1.0 / hq as f64);
    assert!(lo <= best.0 && best.0 < 1.0 / hq as f64);
    println!("ALL CHECKS PASS");
}
