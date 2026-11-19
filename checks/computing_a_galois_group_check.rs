// Computing a Galois group: x^4 + x + 1 -- the check behind the card.  std only, no crates.
// Road 1: discriminant and resolvent cubic, exact integers.  Road 2: factor patterns mod 2 and 3,
// then the group those cycles generate inside S4.  Road 3: numeric roots, from which the
// discriminant and the resolvent's roots are rebuilt.  Road 4: patterns over many primes (evidence).
use std::collections::HashSet;
type P = Vec<i64>; // coefficients low to high

fn trim(mut a: P) -> P { while a.last() == Some(&0) { a.pop(); } a } fn md(x: i64, p: i64) -> i64 { ((x % p) + p) % p }
fn powm(mut b: i64, mut e: i64, p: i64) -> i64 {
    let mut r = 1; b = md(b, p);
    while e > 0 { if e & 1 == 1 { r = r * b % p; } b = b * b % p; e >>= 1; } r
}
fn pmod(a: &P, b: &P, p: i64) -> P {
    let mut a: P = trim(a.iter().map(|&c| md(c, p)).collect());
    let inv = powm(b[b.len() - 1], p - 2, p);
    while a.len() >= b.len() {
        let c = a[a.len() - 1] * inv % p; let s = a.len() - b.len();
        for (i, &bi) in b.iter().enumerate() { a[s + i] = md(a[s + i] - c * bi, p); }
        a = trim(a);
    }
    a
}
fn pdiv(a: &P, b: &P, p: i64) -> P {
    let mut a: P = a.iter().map(|&c| md(c, p)).collect();
    let mut q = vec![0; a.len() - b.len() + 1]; let inv = powm(b[b.len() - 1], p - 2, p);
    for s in (0..q.len()).rev() {
        let c = a[s + b.len() - 1] * inv % p; q[s] = c;
        for (i, &bi) in b.iter().enumerate() { a[s + i] = md(a[s + i] - c * bi, p); }
    }
    q
}
fn pmul(a: &P, b: &P, g: &P, p: i64) -> P {
    let mut r = vec![0i64; a.len() + b.len()];
    for (i, &x) in a.iter().enumerate() { for (j, &y) in b.iter().enumerate() { r[i + j] = (r[i + j] + x * y) % p; } }
    pmod(&r, g, p)
}
fn ppow(a: &P, mut e: i64, g: &P, p: i64) -> P {
    let (mut r, mut a) = (vec![1], a.clone());
    while e > 0 { if e & 1 == 1 { r = pmul(&r, &a, g, p); } a = pmul(&a, &a, g, p); e >>= 1; }
    r
}
fn pgcd(a: &P, b: &P, p: i64) -> P {
    let (mut a, mut b) = (trim(a.iter().map(|&c| md(c, p)).collect()), trim(b.iter().map(|&c| md(c, p)).collect()));
    while !b.is_empty() { let r = pmod(&a, &b, p); a = b; b = r; } a
}
fn pattern(f: &P, p: i64) -> Vec<usize> { // degrees of the irreducible factors of f mod p (f squarefree mod p)
    let (mut g, mut h, mut d, mut out): (P, P, usize, Vec<usize>) = (f.iter().map(|&c| md(c, p)).collect(), vec![0, 1], 0, vec![]);
    while g.len() > 1 {
        d += 1;
        if 2 * d > g.len() - 1 { out.push(g.len() - 1); break; }
        h = ppow(&h, p, &g, p); // h = x^(p^d) mod g
        let mut hx = h.clone(); while hx.len() < 2 { hx.push(0); } hx[1] -= 1;
        let c = pgcd(&g, &hx, p); // product of the factors of degree d
        for _ in 0..(c.len() - 1) / d { out.push(d); }
        if c.len() > 1 { g = pdiv(&g, &c, p); h = pmod(&h, &g, p); }
    }
    out.sort_by(|a, b| b.cmp(a)); out
}
fn resolvent(b: i64, c: i64, d: i64) -> P { vec![4 * b * d - c * c, -4 * d, -b, 1] } // of x^4 + b x^2 + c x + d
fn disc3(r: &P) -> i64 { let (c, b, a) = (r[0], r[1], r[2]); a * a * b * b - 4 * b.pow(3) - 4 * a.pow(3) * c - 27 * c * c + 18 * a * b * c }
fn int_roots(r: &P) -> Vec<i64> {
    let bd = 1 + r.iter().map(|x| x.abs()).max().unwrap();
    (-bd..=bd).filter(|&y| r.iter().enumerate().map(|(i, &c)| c * y.pow(i as u32)).sum::<i64>() == 0).collect()
}
fn isqrt(n: i64) -> i64 { let mut s = (n as f64).sqrt() as i64; while s * s > n { s -= 1; } while (s + 1) * (s + 1) <= n { s += 1; } s }
fn join(v: &[usize]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join("+") }
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn cm(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cs(a: C, b: C) -> C { C { re: a.re - b.re, im: a.im - b.im } } fn ca(a: C, b: C) -> C { C { re: a.re + b.re, im: a.im + b.im } }
fn cd(a: C, b: C) -> C { // scaled division, as in Python
    if b.re.abs() >= b.im.abs() { let r = b.im / b.re; let d = b.re + b.im * r; C { re: (a.re + a.im * r) / d, im: (a.im - a.re * r) / d } }
    else { let r = b.re / b.im; let d = b.re * r + b.im; C { re: (a.re * r + a.im) / d, im: (a.im * r - a.re) / d } }
}
fn sieve(n: usize) -> Vec<i64> {
    let mut s = vec![true; n]; s[0] = false; s[1] = false;
    let mut i = 2; while i * i < n { if s[i] { let mut j = i * i; while j < n { s[j] = false; j += i; } } i += 1; }
    (0..n).filter(|&i| s[i]).map(|i| i as i64).collect()
}
fn count(f: &P, bad: i64, n: i64, types: &[Vec<usize>], pr: &[i64]) -> Vec<usize> {
    let mut c = vec![0; types.len()];
    for &p in pr { if p < n && bad % p != 0 { let t = pattern(f, p); c[types.iter().position(|x| *x == t).unwrap()] += 1; } }
    c
}
fn ev(f: &P, x: i64, p: i64) -> i64 { f.iter().rev().fold(0, |acc, &c| md(acc * x + c, p)) }

fn main() {
    let f: P = vec![1, 1, 0, 0, 1]; // x^4 + x + 1
    let disc = -27 * 1i64.pow(4) + 256 * 1i64.pow(3); // x^4 + c x + d has discriminant -27 c^4 + 256 d^3
    let r = resolvent(0, 1, 1);
    println!("discriminant of x^4+x+1: {} | from the resolvent cubic: {} | isqrt: {}", disc, disc3(&r), isqrt(disc));
    println!("resolvent cubic y^3 - 4y - 1: integer roots {:?} | value at 1 and -1: {} {}", int_roots(&r), 1 - 4 - 1, -1 + 4 - 1);
    assert!(disc == disc3(&r) && isqrt(disc).pow(2) != disc); assert!(int_roots(&r).is_empty());
    // Road 2: irreducible mod 2 (also by trial division by every monic linear and quadratic) and 1 + 3 mod 3
    let small: Vec<P> = vec![vec![0, 1], vec![1, 1], vec![0, 0, 1], vec![0, 1, 1], vec![1, 0, 1], vec![1, 1, 1]];
    let r3: Vec<i64> = (0..3).filter(|&x| ev(&f, x, 3) == 0).collect();
    println!("x^4+x+1 mod 2: {} | mod 3: {} | roots mod 3: {:?}", join(&pattern(&f, 2)), join(&pattern(&f, 3)), r3);
    assert!(pattern(&f, 2) == vec![4] && small.iter().all(|g| !pmod(&f, g, 2).is_empty()));
    assert!(pattern(&f, 3) == vec![3, 1]);
    let closure = |gens: [[usize; 4]; 2]| { // every shuffle the generators produce, composed in any order
        let (mut grp, mut todo) = (HashSet::new(), vec![[0usize, 1, 2, 3]]);
        while let Some(s) = todo.pop() { if grp.insert(s) { for g in &gens { todo.push([s[g[0]], s[g[1]], s[g[2]], s[g[3]]]); } } }
        grp.len()
    };
    let (g24, g8) = (closure([[1, 2, 3, 0], [0, 2, 3, 1]]), closure([[1, 2, 3, 0], [2, 1, 0, 3]]));
    println!("group from (1 2 3 4) and (2 3 4): {} shuffles | from (1 2 3 4) and (1 3): {} shuffles", g24, g8);
    assert!(g24 == 24 && g8 == 8);
    // Road 3: complex roots by Durand-Kerner, then the discriminant and resolvent rebuilt from them
    let one = C { re: 1.0, im: 0.0 }; let s0 = C { re: 0.4, im: 0.9 };
    let mut z = [one, s0, cm(s0, s0), cm(cm(s0, s0), s0)];
    for _ in 0..200 {
        for i in 0..4 {
            let mut den = one;
            for j in 0..4 { if j != i { den = cm(den, cs(z[i], z[j])); } }
            let zi = z[i]; let fz = ca(ca(cm(cm(zi, zi), cm(zi, zi)), zi), one);
            z[i] = cs(zi, cd(fz, den));
        }
    }
    let mut nd = one;
    for i in 0..4 { for j in i + 1..4 { let d = cs(z[i], z[j]); nd = cm(nd, cm(d, d)); } }
    let mut th = [ca(cm(z[0], z[1]), cm(z[2], z[3])).re, ca(cm(z[0], z[2]), cm(z[1], z[3])).re, ca(cm(z[0], z[3]), cm(z[1], z[2])).re];
    th.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let mut zs = z.to_vec(); zs.sort_by(|a, b| (a.re, a.im).partial_cmp(&(b.re, b.im)).unwrap());
    println!("roots: {}", zs.iter().map(|w| format!("{:.6}{:+.6}i", w.re, w.im)).collect::<Vec<_>>().join(", "));
    println!("numeric discriminant: {:.6} | numeric resolvent roots: {:.6} {:.6} {:.6}", nd.re, th[0], th[1], th[2]);
    assert!((nd.re - disc as f64).abs() < 1e-6 && th.iter().all(|&t| r.iter().enumerate().map(|(i, &c)| c as f64 * t.powi(i as i32)).sum::<f64>().abs() < 1e-9));
    // Road 4: factor patterns over primes; a prime dividing the discriminant is set aside
    let pr = sieve(100000);
    for &p in &pr[..46] { // brute-force root count agrees with the pattern's 1s
        if p != 229 { assert!((0..p).filter(|&x| ev(&f, x, p) == 0).count() == pattern(&f, p).iter().filter(|&&d| d == 1).count()); }
    }
    let (t4, t3): (Vec<Vec<usize>>, Vec<Vec<usize>>) = (vec![vec![1, 1, 1, 1], vec![2, 1, 1], vec![2, 2], vec![3, 1], vec![4]], vec![vec![1, 1, 1], vec![2, 1], vec![3]]);
    let (s4, d4) = ([1, 6, 3, 8, 6], [1, 2, 3, 0, 2]); // elements of each cycle type, out of 24 and out of 8
    println!("pattern counts       1+1+1+1   2+1+1    2+2    3+1      4   primes");
    let mut c = vec![];
    for n in [1000, 10000, 100000] {
        c = count(&f, disc, n, &t4, &pr);
        println!("x^4+x+1, p < {:<6} {:>8} {:>7} {:>6} {:>6} {:>6} {:>8}", n, c[0], c[1], c[2], c[3], c[4], c.iter().sum::<usize>());
    }
    let c4 = count(&vec![-2, 0, 0, 0, 1], 2048, 100000, &t4, &pr); let n4 = c4.iter().sum::<usize>();
    println!("x^4-2,   p < 100000 {:>8} {:>7} {:>6} {:>6} {:>6} {:>8}", c4[0], c4[1], c4[2], c4[3], c4[4], n4);
    let tot = c.iter().sum::<usize>() as f64;
    for i in 0..5 {
        let sh = c[i] as f64 / tot;
        println!("{:<8} {:<30} {:5.2}%  S4 predicts {:5.2}%", join(&t4[i]), "#".repeat((sh * 80.0).round() as usize), 100.0 * sh, 100.0 * s4[i] as f64 / 24.0);
        assert!((sh - s4[i] as f64 / 24.0).abs() < 0.01);
    }
    assert!((0..5).all(|i| (c4[i] as f64 / n4 as f64 - d4[i] as f64 / 8.0).abs() < 0.01));
    let cr = count(&r, disc, 100000, &t3, &pr); let nr = cr.iter().sum::<usize>() as f64;
    println!("resolvent y^3-4y-1, p < 100000, patterns 1+1+1, 2+1, 3: {} {} {} | S3 predicts shares 1/6, 1/2, 1/3", cr[0], cr[1], cr[2]);
    assert!((0..3).all(|i| (cr[i] as f64 / nr - [1.0, 3.0, 2.0][i] / 6.0).abs() < 0.01));
    // What breaks
    let r229: Vec<i64> = (0..229).filter(|&x| ev(&f, x, 229) == 0).collect();
    let der: Vec<i64> = r229.iter().map(|&x| ev(&vec![1, 0, 0, 4], x, 229)).collect();
    let q229 = pdiv(&f, &vec![75 * 75 % 229, md(-150, 229), 1], 229);
    println!("mod 229: roots {:?} | derivative there: {:?} | f = (x-75)^2 times {:?} | routine says {}", r229, der, q229, join(&pattern(&f, 229)));
    assert!(r229 == vec![75] && ev(&vec![1, 0, 0, 4], 75, 229) == 0 && (0..229).all(|x| ev(&q229, x, 229) != 0));
    assert!(pmul(&q229, &vec![75 * 75, -150, 1], &vec![0, 0, 0, 0, 0, 1], 229) == vec![1, 1, 0, 0, 1]);
    let (r2, r4) = (resolvent(0, 0, -2), resolvent(0, 0, 4));
    let q4: P = vec![-2, 0, 0, 0, 1]; let r7: Vec<i64> = (0..7).filter(|&x| ev(&q4, x, 7) == 0).collect();
    println!("x^4-2: discriminant {} | resolvent {:?} integer roots {:?} | 3+1 never seen: {} | mod 7: roots {:?} pattern {}", disc3(&r2), r2, int_roots(&r2), c4[3], r7, join(&pattern(&q4, 7)));
    assert!(int_roots(&r2) == vec![0] && c4[3] == 0 && disc3(&r2) < 0 && pattern(&q4, 7) == vec![2, 1, 1]); // a single swap: not C4
    let (a, b) = ([2i64, 2, 1], [2i64, -2, 1]);
    let fac: Vec<i64> = (0..5).map(|k| (0..3).flat_map(|i| (0..3).map(move |j| (i, j))).filter(|&(i, j)| i + j == k).map(|(i, j)| a[i] * b[j]).sum()).collect();
    println!("x^4+4: discriminant {} = {} squared | resolvent integer roots {:?} | but (x^2+2x+2)(x^2-2x+2) = {:?}", disc3(&r4), isqrt(disc3(&r4)), int_roots(&r4), fac);
    assert!(isqrt(disc3(&r4)).pow(2) == disc3(&r4) && int_roots(&r4).len() == 3 && fac == vec![4, 0, 0, 0, 1]);
    let cub: P = vec![1, -3, 0, 1]; let c3 = count(&cub, 81, 10000, &t3, &pr);
    println!("x^3-3x+1: discriminant {} | p < 10000 patterns 1+1+1, 2+1, 3: {} {} {}", disc3(&cub), c3[0], c3[1], c3[2]);
    assert!(isqrt(disc3(&cub)).pow(2) == disc3(&cub) && c3[1] == 0);
    println!("ALL CHECKS PASS");
}
