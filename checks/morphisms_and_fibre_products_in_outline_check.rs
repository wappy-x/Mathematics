// Morphisms and fibre products -- the same check as the Python, in Rust.  No
// crates.  The family is y^2 = x^3 + t over the t-line: the ring map
// t -> y^2 - x^3 read backwards as the map (x, y) -> t.  A polynomial in x, y
// is a map {(i, j): coeff} for x^i y^j.  Roads: expand polynomials exactly;
// put points back in; count over F_7 by brute force against a character sum;
// build a fibre product from joined equations against a sum over fibres.
use std::collections::BTreeMap;
type Poly = BTreeMap<(u32, u32), i64>;

fn poly(terms: &[((u32, u32), i64)]) -> Poly { terms.iter().cloned().collect() }

fn mul(a: &Poly, b: &Poly) -> Poly {
    let mut out = Poly::new();
    for (&(i, j), &c) in a { for (&(k, l), &d) in b { *out.entry((i + k, j + l)).or_insert(0) += c * d } }
    out.retain(|_, c| *c != 0);
    out
}

fn add(a: &Poly, b: &Poly, s: i64) -> Poly {
    let mut out = a.clone();
    for (&m, &c) in b { *out.entry(m).or_insert(0) += s * c }
    out.retain(|_, c| *c != 0);
    out
}

fn ev(g: &Poly, x: i64, y: i64) -> i64 { g.iter().map(|(&(i, j), &c)| c * x.pow(i) * y.pow(j)).sum() }
fn gcd(mut a: i64, mut b: i64) -> i64 { while b != 0 { (a, b) = (b, a % b) } a.abs() }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn pi(x: i64, y: i64) -> i64 { y * y - x * x * x }          // the map to the t-line
fn md(a: i64, q: i64) -> i64 { a.rem_euclid(q) }
fn powm(a: i64, e: i64, q: i64) -> i64 { let mut r = 1; for _ in 0..e { r = r * md(a, q) % q } r }

fn main() {
    let p: i64 = 7;
    let phi_t = poly(&[((0, 2), 1), ((3, 0), -1)]);          // phi*(t) = y^2 - x^3
    println!("ring map phi*: Q[t] -> Q[x, y], t -> y^2 - x^3; field Q, counts over F_7");
    println!("(3, 5) lies over t = 25 - 27 = {}; (2, 3) lies over t = 9 - 8 = {}", pi(3, 5), pi(2, 3));
    let pull = add(&mul(&phi_t, &phi_t), &poly(&[((0, 0), 4)]), -1);
    let expect = poly(&[((0, 4), 1), ((3, 2), -2), ((6, 0), 1), ((0, 0), -4)]);
    let grid: Vec<(i64, i64)> = (-5..6).flat_map(|x| (-5..6).map(move |y| (x, y))).collect();
    let rule = grid.iter().all(|&(x, y)| ev(&pull, x, y) == pi(x, y).pow(2) - 4);
    println!("phi*(t^2 - 4) = y^4 - 2x^3y^2 + x^6 - 4: {}", yn(pull == expect));
    println!("(phi* f)(P) = f(pi(P)) at all {} points of the grid -5..5: {}; at (3, 5): {}", grid.len(), yn(rule), ev(&pull, 3, 5));
    let lhs = add(&mul(&poly(&[((0, 1), 1), ((0, 0), 5)]), &poly(&[((0, 1), 1), ((0, 0), -5)])),
                  &mul(&poly(&[((2, 0), 1), ((1, 0), 3), ((0, 0), 9)]), &poly(&[((1, 0), 1), ((0, 0), -3)])), -1);
    let target = poly(&[((0, 2), 1), ((3, 0), -1), ((0, 0), 2)]);   // y^2 - x^3 + 2, typed in
    println!("(y + 5)(y - 5) - (x^2 + 3x + 9)(x - 3) = y^2 - x^3 + 2: {}", yn(lhs == target));
    println!("so phi*(t + 2) lies in <x - 3, y - 5>, and the point contracts to <t + 2>");
    println!("on the line x = 3, phi*(t + 2) = y^2 - 25, not 0: the line contracts to <0>");
    let (mut num, mut den): (i64, i64) = (1 * 2, 2 * 1);   // (1/2) x 2 as a fraction, then in lowest terms
    let g = gcd(num, den); num /= g; den /= g;
    println!("forward along Z -> Q: 2 is in 2Z, (1/2) x 2 = {} is not: {}, no ideal", num, yn(2 % 2 == 0 && den == 1 && num % 2 != 0));

    let brute: Vec<i64> = (0..p).map(|t| (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
        .filter(|&(x, y)| md(y * y - x * x * x - t, p) == 0).count() as i64).collect();
    let chi = |a: i64| { let r = powm(a, (p - 1) / 2, p); if r == p - 1 { -1 } else { r } };
    let charsum: Vec<i64> = (0..p).map(|t| (0..p).map(|x| 1 + chi(x * x * x + t)).sum()).collect();
    println!("fibre sizes over F_{}, t = 0..{}, brute force: {:?}", p, p - 1, brute);
    println!("the same by the character sum over x: {:?}; total {} = {}^2", charsum, brute.iter().sum::<i64>(), p);
    let proj: Vec<i64> = brute.iter().map(|n| n + 1).collect();
    println!("with the point at infinity: {:?}; Hasse window for t != 0: {} +- {:.2}", proj, p + 1, 2.0 * (p as f64).sqrt());
    let in_window = proj[1..].iter().all(|n| (n - p - 1).pow(2) <= 4 * p);
    let mut distinct = proj[1..].to_vec();
    distinct.sort();
    distinct.dedup();
    println!("every smooth fibre inside the window: {}; six different counts: {}", yn(in_window), yn(distinct.len() == 6));

    for q in [7i64, 3, 2] {                                   // points where F and both slopes vanish
        let sing: Vec<i64> = (0..q).map(|t| (0..q).flat_map(|x| (0..q).map(move |y| (x, y)))
            .filter(|&(x, y)| md(y * y - x * x * x - t, q) == 0 && md(-3 * x * x, q) == 0 && md(2 * y, q) == 0)
            .count() as i64).collect();
        let disc: Vec<i64> = (0..q).map(|t| md(-432 * t * t, q)).collect();
        println!("over F_{}: singular points per fibre {:?}; Delta = -432t^2 mod {}: {:?}", q, sing, q, disc);
        assert!(sing.iter().map(|&s| s > 0).eq(disc.iter().map(|&d| d == 0)));   // brute force against Delta
    }
    let mut total = 0;                                       // slopes -3x^2, 2y and -1 for the t-slot
    for x in 0..7 { for y in 0..7 { for t in 0..7 {
        if md(y * y - x * x * x - t, 7) == 0 && md(-3 * x * x, 7) == 0 && md(2 * y, 7) == 0 && md(-1, 7) == 0 { total += 1 }
    } } }
    println!("total space y^2 - x^3 - t over F_7: {} singular points; fibre over 0: 1", total);

    let roots: Vec<i64> = (0..p).map(|t| (0..p).filter(|&u| powm(u, 6, p) == t).count() as i64).collect();
    let mut joined = 0;
    let mut no_t = 0;
    let mut plain = 0;
    for x in 0..p { for y in 0..p { for u in 0..p {
        for t in 0..p { if md(y * y - x * x * x - t, p) == 0 { plain += 1; if md(t - u.pow(6), p) == 0 { joined += 1 } } }
        if md(y * y - x * x * x - u.pow(6), p) == 0 { no_t += 1 }
    } } }
    let by_fibre: i64 = (0..p as usize).map(|t| brute[t] * roots[t]).sum();
    println!("base change t = u^6: solutions u per t {:?}", roots);
    println!("X x_S Y over F_{}: joined equations {}; sum over fibres {}; t eliminated {}", p, joined, by_fibre, no_t);
    println!("u != 0 fibres all copy t = 1: 7 + 6 x {} = {}", brute[1], 7 + 6 * brute[1]);
    println!("mistake 1, plain product X x Y: {} x {} = {}, not {}", brute.iter().sum::<i64>(), p, plain, joined);
    println!("mistake 2, fibre over 0 without t = 0: {} points of X, not {}", p * p, brute[0]);
    println!("mistake 3, smoothness of the total space: {} singular points, fibre over 0 has 1", total);

    println!("degeneration over R: t, leftmost real point x = -t^(1/3), Delta = -432t^2");
    for k in 0..4u32 {
        let (num, den) = (-432i64, 10i64.pow(2 * k));
        let g = gcd(num, den);
        let d = if den == g { format!("{}", num / g) } else { format!("{}/{}", num / g, den / g) };
        let tt = if k == 0 { "1".to_string() } else { format!("1/{}", 10i64.pow(k)) };
        println!("  t = {}: x = {:.4}, Delta = {}", tt, -(10f64.powi(-(k as i32))).powf(1.0 / 3.0), d);
    }
    println!("figure, t=1 from (-1, 0) through (2, 3); t=0 cusp (0, 0) through (1, 1); t=-2 from ({:.4}, 0) through (3, 5); box x -1.2..3.2, y -5.6..5.6",
             2f64.powf(1.0 / 3.0));
    assert!(pull == expect && rule);                          // expansion vs evaluation
    assert!(lhs == target && pi(3, 5) == -2);                 // cofactors certify the contraction
    assert!(brute == charsum && brute.iter().sum::<i64>() == p * p && in_window);
    assert!(joined == by_fibre && by_fibre == no_t && no_t == 7 + 6 * brute[1]);   // three roads
    assert!(total == 0 && brute[0] == p);                     // smooth total space, cusp fibre
    println!("ALL CHECKS PASS");
}
