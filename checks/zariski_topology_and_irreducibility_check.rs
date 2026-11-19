// The Zariski topology and irreducible pieces -- the same check as the Python,
// in Rust.  No crates; every number is an exact integer.  The field for the
// theorems is the complex numbers.  The finite fields F_13 and F_7 are used
// only to count points by listing them all, as an independent road.
use std::collections::BTreeSet;

fn trim(mut a: Vec<i64>) -> Vec<i64> {                 // drop zero coefficients at the top
    while a.len() > 1 && *a.last().unwrap() == 0 { a.pop(); }
    a
}

fn mul(a: &[i64], b: &[i64]) -> Vec<i64> {             // one-variable product; a[i] is the x^i coefficient
    let mut out = vec![0; a.len() + b.len() - 1];
    for (i, s) in a.iter().enumerate() { for (j, t) in b.iter().enumerate() { out[i + j] += s * t; } }
    trim(out)
}

fn from_roots(rs: &[i64]) -> Vec<i64> {                // (x - r1)(x - r2)...: a finite set as a zero set
    let mut p = vec![1];
    for &r in rs { p = mul(&p, &[-r, 1]); }
    p
}

fn igcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { (a, b) = (b, a % b); }
    a.abs()
}

fn primitive(a: &[i64]) -> Vec<i64> {                  // divide out the common factor, top coefficient positive
    let g = a.iter().fold(0, |g, &c| igcd(g, c));
    let s = if *a.last().unwrap() < 0 { -1 } else { 1 };
    a.iter().map(|&c| s * c / g).collect()
}

fn poly_gcd(mut a: Vec<i64>, mut b: Vec<i64>) -> Vec<i64> {   // Euclid with pseudo-remainders: integers only
    while b != vec![0] {
        let mut r = a.clone();
        while r.len() >= b.len() && r != vec![0] {
            let (shift, lead, top) = (r.len() - b.len(), *r.last().unwrap(), *b.last().unwrap());
            r = r.iter().map(|&c| top * c).collect();
            for (i, &c) in b.iter().enumerate() { r[i + shift] -= lead * c; }
            r = trim(r);
        }
        let next = if r != vec![0] { primitive(&r) } else { vec![0] };
        a = b;
        b = next;
    }
    primitive(&a)
}

fn roots(p: &[i64]) -> Vec<i64> {                      // road two: try every whole number from -10 to 10
    (-10i64..=10).filter(|&x| p.iter().enumerate().map(|(i, &c)| c * x.pow(i as u32)).sum::<i64>() == 0).collect()
}

fn show(p: &[i64]) -> String {                         // leading term first, e.g. x^3 - x
    let mut out = String::new();
    for i in (0..p.len()).rev() {
        let c = p[i];
        if c == 0 { continue; }
        let num = if c.abs() == 1 && i > 0 { String::new() } else { c.abs().to_string() };
        let var = if i == 0 { String::new() } else if i == 1 { "x".to_string() } else { format!("x^{}", i) };
        let sign = if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " };
        out += &format!("{}{}{}", sign, num, var);
    }
    out
}

fn rank(m: &[[i64; 3]; 3]) -> usize {                  // elimination without division; counts pivots
    let (mut a, mut r) = (*m, 0);
    for col in 0..3 {
        let piv = match (r..3).find(|&i| a[i][col] != 0) { Some(i) => i, None => continue };
        a.swap(r, piv);
        for i in r + 1..3 {
            let (top, here) = (a[r][col], a[i][col]);
            for j in 0..3 { a[i][j] = top * a[i][j] - here * a[r][j]; }
        }
        r += 1;
    }
    r
}

fn det3(m: &[[i64; 3]; 3]) -> i64 {                    // road two: the cofactor formula
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}

fn count3(p: i64, t: impl Fn(i64, i64, i64) -> i64) -> usize {   // list every point of F_p^3, count zeros
    (0..p * p * p).filter(|v| t(v / (p * p), v / p % p, v % p) % p == 0).count()
}

fn count2(p: i64, t: impl Fn(i64, i64) -> i64) -> usize { (0..p * p).filter(|v| t(v / p, v % p) % p == 0).count() }

fn cone(x: i64, y: i64, z: i64) -> i64 { x * x + y * y - z * z }   // the house cone; each slice's polynomial is read off it

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn set(v: &[i64]) -> BTreeSet<i64> { v.iter().copied().collect() }

fn main() {
    let (a, b) = ([-1, 0, 1], [1, 2]);
    let (f, g) = (from_roots(&a), from_roots(&b));
    let (fg, h) = (mul(&f, &g), poly_gcd(f.clone(), g.clone()));
    let uni: Vec<i64> = set(&a).union(&set(&b)).copied().collect();
    let cap: Vec<i64> = set(&a).intersection(&set(&b)).copied().collect();
    println!("line: V({}) = {:?}; V({}) = {:?}", show(&f), roots(&f), show(&g), roots(&g));
    println!("union: V({}) = {:?}, the union of the two sets: {}", show(&fg), roots(&fg), yn(roots(&fg) == uni));
    println!("overlap: gcd = {}, V = {:?}, the shared points: {}", show(&h), roots(&h), yn(roots(&h) == cap));
    assert!(roots(&fg) == uni && roots(&fg).len() <= fg.len() - 1);   // the sets, built separately
    assert!(roots(&h) == cap);

    let p = 13;
    let both = count3(p, |x, y, _| x * y);
    let (px, py, axis) = (count3(p, |x, _, _| x), count3(p, |_, y, _| y), count3(p, |x, y, _| (x != 0) as i64 + (y != 0) as i64));
    println!("pair of planes over F_{}: V(xy) has {} points; V(x) {}, V(y) {}, corner line V(x, y) {}", p, both, px, py, axis);
    println!("inclusion-exclusion: {} + {} - {} = {}; adding the corner as a third piece gives {}", px, py, axis, px + py - axis, px + py + axis);
    let mut on_v = Vec::new();
    for x in 0..p { for y in 0..p { for z in 0..p { if x * y % p == 0 { on_v.push((x, y, z)); } } } }
    let wx = on_v.iter().filter(|q| q.0 % p != 0).count();
    let wy = on_v.iter().filter(|q| q.1 % p != 0).count();
    let wxy = on_v.iter().filter(|q| q.0 * q.1 % p != 0).count();
    println!("points of V(xy) where x is not 0: {}; where y is not 0: {}; where xy is not 0: {}", wx, wy, wxy);
    let ((x1, y1, _), (x2, y2, _)) = ((2i64, 0i64, -1i64), (0i64, 3i64, -2i64));
    println!("witnesses: x at (2, 0, -1) = {}, y at (0, 3, -2) = {}, xy at them = {} and {}", x1, y2, x1 * y1, x2 * y2);
    let pu = p as usize;
    assert!(both == px + py - axis && both == 2 * pu * pu - pu && wx == pu * pu - pu && wy == wx && wxy == 0);

    type Fac = Option<([i64; 3], [i64; 3])>;
    type Form = fn(i64, [i64; 3]) -> i64;               // the polynomial Q, given the slice's c
    let mut quads: Vec<(String, [[i64; 3]; 3], Fac, i64, Form, i64)> = vec![
        ("pair of planes xy, in (x, y, z)".to_string(), [[0, 1, 0], [1, 0, 0], [0, 0, 0]], Some(([1, 0, 0], [0, 1, 0])), 0, |_, v| v[0] * v[1], 0),
        ("cone x^2 + y^2 - z^2, in (x, y, z)".to_string(), [[2, 0, 0], [0, 2, 0], [0, 0, -2]], None, 0, |_, v| cone(v[0], v[1], v[2]), 0)];
    for c in 0..4i64 {
        quads.push((format!("slice x = {}: y^2 - z^2 + {}, in (y, z, w)", c, c * c), [[2, 0, 0], [0, -2, 0], [0, 0, 2 * c * c]],
                    if c == 0 { Some(([1, -1, 0], [1, 1, 0])) } else { None }, 0, |c, v| cone(c * v[2], v[0], v[1]), c));
    }
    quads.push(("slice z = 0: x^2 + y^2, in (x, y, w)".to_string(), [[2, 0, 0], [0, 2, 0], [0, 0, 0]], Some(([1, 5, 0], [1, -5, 0])), 13,
                |_, v| cone(v[0], v[1], 0), 0));
    let grid: Vec<[i64; 3]> = (0..125).map(|k| [k / 25 - 2, k / 5 % 5 - 2, k % 5 - 2]).collect();
    for (name, m, fac, md, form, c) in &quads {
        let (r, d) = (rank(m), det3(m));
        assert!(grid.iter().all(|v| (0..3).map(|i| (0..3).map(|j| v[i] * m[i][j] * v[j]).sum::<i64>()).sum::<i64>() == 2 * form(*c, *v))); // M is 2Q's matrix
        let pieces = if r == 3 { "one piece" } else if r == 2 { "two flat pieces" } else { "one doubled piece" };
        let mut line = format!("{}: rank {}, det {}, {}", name, r, d, pieces);
        if let Some((l, k)) = fac {
            let mut same = true;
            for i in 0..3 { for j in 0..3 {
                let diff = l[i] * k[j] + k[i] * l[j] - m[i][j];
                same &= if *md != 0 { diff % md == 0 } else { diff == 0 };
            } }
            line += &format!("; factors {:?} times {:?} expand back{}: {}", l, k, if *md != 0 { " mod 13" } else { "" }, yn(same));
            assert!(same && r == 2);
        }
        println!("{}", line);
        assert!((r == 3) == (d != 0));
    }
    assert!(quads[2..6].iter().all(|q| det3(&q.1) == -8 * q.5 * q.5));   // the slices' determinants are -8c^2
    let slices: Vec<usize> = (0..4i64).map(|c| count2(p, |y, z| y * y - z * z + c * c)).collect();
    println!("slices x = 0, 1, 2, 3 over F_{}, points: {:?}; two crossing lines give 2p - 1 = {}, one curve p - 1 = {}", p, slices, 2 * p - 1, p - 1);
    assert!(slices == vec![2 * pu - 1, pu - 1, pu - 1, pu - 1]);
    let (v13, v7) = (count2(13, |x, y| x * x + y * y), count2(7, |x, y| x * x + y * y));
    println!("x^2 + y^2 = 0: {} points over F_13, where 5^2 = {} mod 13; {} point over F_7, where -1 is no square", v13, 25 % 13 - 13, v7);
    let (sq, lin) = (count3(p, |x, _, _| x * x), count3(p, |x, _, _| x));
    println!("V(x^2) has {} points and V(x) has {}: one set, two ideals", sq, lin);
    assert!(v13 == 2 * 13 - 1 && v7 == 1 && sq == lin);
    let tops: Vec<String> = [1i64, 2].iter().map(|&c| format!("hyperbola c = {} vertices {}", c, // where the slice x = c meets y = 0
        (-4..=4i64).rev().filter(|&z| cone(c, 0, z) == 0).map(|z| format!("(0, {})", z)).collect::<Vec<_>>().join(" and "))).collect();
    println!("figure, lines z = y and z = -y cross at (0, 0); {}; window -4 to 4 in y and z", tops.join("; "));
    println!("ALL CHECKS PASS");
}
