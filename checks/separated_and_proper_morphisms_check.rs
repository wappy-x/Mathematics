// Separated, finite and proper -- the same check as the Python, in Rust.  No
// crates.  Field Q for limits; F_7 and F_49 for counts.  A rational function
// of t is a pair (num, den) of i128 coefficient lists, lowest power first,
// multiplied with checked_mul so overflow stops the run.  The limit of a
// punctured-disc curve as t -> 0 is found by rescaling by the least order,
// against chart by chart, against a float evaluation near t = 0.
use std::collections::BTreeSet;
type P = Vec<i128>;
type F = (P, P);

fn gcd(mut a: i128, mut b: i128) -> i128 { while b != 0 { (a, b) = (b, a % b) } a.abs() }

fn pmul(a: &P, b: &P) -> P {
    let mut out = vec![0i128; a.len() + b.len() - 1];
    for (i, c) in a.iter().enumerate() {
        for (j, d) in b.iter().enumerate() { out[i + j] += c.checked_mul(*d).expect("overflow") }
    }
    out
}

fn order(p: &P) -> Option<usize> { p.iter().position(|&c| c != 0) }   // how many times t divides p

fn val(f: &F) -> Option<i64> {                    // v(f): order of top minus order of bottom
    order(&f.0).map(|n| n as i64 - order(&f.1).unwrap() as i64)
}

fn at0(f: &F) -> (i128, i128) {                   // value at t = 0 of f with v(f) >= 0
    match val(f) {
        None => (0, 1),
        Some(v) if v > 0 => (0, 1),
        _ => {
            let (a, b) = (f.0[order(&f.0).unwrap()], f.1[order(&f.1).unwrap()]);
            let g = gcd(a, b) * if b > 0 { 1 } else { -1 };
            (a / g, b / g)
        }
    }
}

fn normal(v: &[i128]) -> Vec<i128> {             // lowest terms, last nonzero entry > 0
    let g = v.iter().fold(0, |g, &c| gcd(g, c));
    let s = if *v.iter().filter(|&&c| c != 0).last().unwrap() > 0 { 1 } else { -1 };
    v.iter().map(|&c| s * c / g).collect()
}

fn rescale(curve: &[F]) -> Vec<i128> {           // road 1: clear bottoms, divide by t^m
    let polys: Vec<P> = (0..curve.len()).map(|i| {
        let mut n = curve[i].0.clone();
        for j in 0..curve.len() { if j != i { n = pmul(&n, &curve[j].1) } }
        n
    }).collect();
    let m = polys.iter().filter_map(order).min().unwrap();
    normal(&polys.iter().map(|p| if p.len() > m { p[m] } else { 0 }).collect::<Vec<_>>())
}

fn chart_limits(curve: &[F]) -> BTreeSet<Vec<i128>> {   // road 2: chart by chart
    let mut found = BTreeSet::new();
    for (ni, di) in curve {
        if order(ni).is_none() { continue }
        let ratios: Vec<F> = curve.iter().map(|(n, d)| (pmul(n, di), pmul(d, ni))).collect();
        if ratios.iter().all(|r| val(r).map_or(true, |v| v >= 0)) {
            let vals: Vec<(i128, i128)> = ratios.iter().map(at0).collect();
            let den = vals.iter().fold(1, |den, &(_, b)| den * b / gcd(den, b));
            found.insert(normal(&vals.iter().map(|&(a, b)| a * (den / b)).collect::<Vec<_>>()));
        }
    }
    found
}

fn by_float(curve: &[F], r: &[i128], t: f64) -> bool {   // road 3: evaluate near 0, compare with r
    let ev = |p: &P| p.iter().enumerate().map(|(k, &c)| c as f64 * t.powi(k as i32)).sum::<f64>();
    let v: Vec<f64> = curve.iter().map(|(n, d)| ev(n) / ev(d)).collect();
    let big = v.iter().cloned().fold(0.0f64, |b, c| if c.abs() > b.abs() { c } else { b });
    let rbig = r.iter().cloned().fold(0i128, |b, x| if x.abs() > b.abs() { x } else { b }) as f64;
    v.iter().zip(r).all(|(a, &b)| (a / big - b as f64 / rbig).abs() < 1e-4)
}

fn show(pt: &[i128]) -> String { format!("({})", pt.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" : ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (t, one): (P, P) = (vec![0, 1], vec![1]);
    let glue = |chart: char, a: (i128, i128)| if a.0 == 0 { (chart, a) } else { ('*', a) };   // doubled line: (A, a) = (B, a) unless a = 0
    let curves: Vec<(&str, F)> = vec![("x = 1/t", (one.clone(), t.clone())), ("x = t", (t.clone(), one.clone())),
                                      ("x = 1 + 2t", (vec![1, 2], one.clone()))];
    println!("punctured-disc curves t -> x(t), t != 0; limit points as t -> 0 (field Q)");
    let mut counts = Vec::new();
    for (name, x) in &curves {
        let curve = vec![x.clone(), (one.clone(), one.clone())];
        let (p1, r) = (chart_limits(&curve), rescale(&curve));
        let a1: Vec<(i128, i128)> = if val(x).map_or(true, |v| v >= 0) { vec![at0(x)] } else { vec![] };   // A^1: x must lie in R
        let dbl: BTreeSet<(char, (i128, i128))> = ['A', 'B'].iter().flat_map(|&c| a1.iter().map(move |&a| glue(c, a))).collect();
        counts.push((a1.len(), p1.len(), dbl.len()));
        assert!(p1.len() == 1 && p1.contains(&r) && by_float(&curve, &r, 1e-6));   // three roads to the P^1 limit
        println!("  {:11}: limits in A^1 {}; in P^1 {}, {}; in the doubled line {}", name, a1.len(), p1.len(), show(&r), dbl.len());
    }
    assert!(counts == vec![(0, 1, 0), (1, 1, 2), (1, 1, 1)]);
    let vs: Vec<i64> = [(vec![0, 0, 1], one.clone()), (vec![3, 1], one.clone()), (one.clone(), t.clone()), (one.clone(), vec![0, 0, 1])]
        .iter().map(|f| val(f).unwrap()).collect();
    println!("valuations: v(t^2) = {}, v(3 + t) = {}, v(1/t) = {}, v(1/t^2) = {}; (1/t : 1) has m = {}", vs[0], vs[1], vs[2], vs[3], vs[2].min(0));
    assert!(vs == vec![2, 0, -1, -2]);
    println!("x = 1/t near 0: t = 1/10, 1/100, 1/1000 gives x = 10, 100, 1000; in P^1, (x : 1) = (1 : t) = {}",
             (1..4).map(|k| format!("(1 : 1/{})", 10i64.pow(k))).collect::<Vec<_>>().join(", "));

    let plane: Vec<(&str, Vec<F>)> = vec![
        ("line y = 2x + 1, x = 1/t", vec![(one.clone(), t.clone()), (vec![2, 1], t.clone()), (one.clone(), one.clone())]),
        ("line y = 2x + 5, x = 1/t", vec![(one.clone(), t.clone()), (vec![2, 5], t.clone()), (one.clone(), one.clone())]),
        ("parabola y = x^2, x = 1/t", vec![(one.clone(), t.clone()), (one.clone(), vec![0, 0, 1]), (one.clone(), one.clone())]),
        ("x = 3 + t, y = t/(1 - t)", vec![(vec![3, 1], one.clone()), (t.clone(), vec![1, -1]), (one.clone(), one.clone())])];
    for (name, curve) in &plane {
        let (r, c) = (rescale(curve), chart_limits(curve));
        let close = by_float(curve, &r, 1e-6);
        println!("P^2, {}: rescaled {}; charts {} point(s), {}; float near 0 agrees: {}",
                 name, show(&r), c.len(), show(c.iter().next().unwrap()), yn(close));
        assert!(c.len() == 1 && c.contains(&r) && close);   // three roads to one limit
    }
    assert!(rescale(&plane[0].1) == rescale(&plane[1].1));   // parallel lines meet

    let p: i64 = 7;                                  // the diagonal in chart (A, B): x in A and y in B name one point
    let diag_aa = (0..p).flat_map(|x| (0..p).map(move |y| (x, y))).filter(|&(x, y)| glue('A', (x as i128, 1)) == glue('A', (y as i128, 1))).count();
    let diag_ab = (0..p).flat_map(|x| (0..p).map(move |y| (x, y))).filter(|&(x, y)| glue('A', (x as i128, 1)) == glue('B', (y as i128, 1))).count();
    println!("doubled line, diagonal over F_{}: chart (A, A) {} of the {} points on x = y; chart (A, B) {} of {}, missing (0_A, 0_B)",
             p, diag_aa, p, diag_ab, p);
    let hyper: BTreeSet<i64> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
        .filter(|&(x, y)| (x * y - 1).rem_euclid(p) == 0).map(|(x, _)| x).collect();
    let mut p1: Vec<(i64, i64)> = vec![(1, 0)];
    p1.extend((0..p).map(|a| (a, 1)));
    let closure: Vec<(i64, (i64, i64))> = (0..p).flat_map(|x| p1.iter().map(move |&q| (x, q)))
        .filter(|&(x, q)| (x * q.0 - q.1).rem_euclid(p) == 0).collect();   // xy = 1 as x y0 = y1
    let over0: Vec<(i64, i64)> = closure.iter().filter(|&&(x, _)| x == 0).map(|&(_, q)| q).collect();
    let shadow: BTreeSet<i64> = closure.iter().map(|&(x, _)| x).collect();
    println!("hyperbola xy = 1 over F_{}: shadow on the x-line {} of {} points, x = 0 missing", p, hyper.len(), p);
    println!("its closure in A^1 x P^1: {} points, shadow {} of {}; over x = 0 the point y = {}", closure.len(), shadow.len(), p,
             show(&[over0[0].0 as i128, over0[0].1 as i128]));
    assert!(hyper.len() as i64 == p - 1 && !hyper.contains(&0) && shadow.len() as i64 == p && over0 == vec![(1, 0)]);
    println!("mistake 1: A^1 -> a point is closed (shadow 1 of 1), yet its base change has shadow {} of {}", hyper.len(), p);
    println!("mistake 2: P^1 tested in the chart x only: x = 1/t finds {} limits, not {}", counts[0].0, counts[0].1);
    let fib: Vec<usize> = (0..p).map(|a| (1..p).filter(|&x| x == a).count()).collect();
    println!("mistake 3: punctured line -> line, fibres over F_{} {:?}: all at most 1, image {} of {}, origin missing",
             p, fib, fib.iter().sum::<usize>(), p);
    assert!((diag_aa as i64, diag_ab as i64) == (p, p - 1) && fib == [vec![0], vec![1; p as usize - 1]].concat());
    println!("mistake 4: doubled line, x = t has {} limits; separated needs at most 1", counts[1].2);

    let f: Vec<i64> = vec![2, -1, 3, 0, 0, 1];   // x^5 + 3x^2 - x + 2, lowest power first
    let g: Vec<i64> = f.iter().step_by(2).cloned().collect();
    let h: Vec<i64> = f.iter().skip(1).step_by(2).cloned().collect();
    let ev = |q: &[i64], x: i64, s: u32| q.iter().enumerate().map(|(k, &c)| c * x.pow(s * k as u32)).sum::<i64>();
    let same = (-4..5).all(|x| ev(&f, x, 1) == ev(&g, x, 2) + x * ev(&h, x, 2));
    println!("x -> u = x^2: f = x^5 + 3x^2 - x + 2 = g(x^2) + x h(x^2), g(u) = 3u + 2, h(u) = u^2 - 1; agrees at x = -4..4: {}", yn(same));
    assert!(g == vec![2, 3, 0] && h == vec![-1, 0, 1] && same);
    let sq7: Vec<usize> = (0..p).map(|a| (0..p).filter(|&x| (x * x - a).rem_euclid(p) == 0).count()).collect();
    let pw = |a: i64| (0..(p - 1) / 2).fold(1, |r, _| r * a % p);
    let euler: Vec<usize> = (0..p).map(|a| if a == 0 { 1 } else if pw(a) == 1 { 2 } else { 0 }).collect();
    let sq49: Vec<usize> = (0..p).map(|c| (0..p).flat_map(|a| (0..p).map(move |b| (a, b)))
        .filter(|&(a, b)| (a * a - b * b - c).rem_euclid(p) == 0 && (2 * a * b).rem_euclid(p) == 0).count()).collect();
    println!("fibres of x -> x^2 over u = 0..{}: points over F_{} {:?}, Euler's test {:?}; over F_{} {:?}", p - 1, p, sq7, euler, p * p, sq49);
    println!("fibre ring k[x]/<x^2 - u> has basis 1, x: dimension 2 for every u; at u = 0 the one point counts twice");
    let mut want = vec![2usize; p as usize];
    want[0] = 1;
    assert!(sq7 == euler && sq49 == want);       // brute force against Euler, and F_49 roots
    println!("ALL CHECKS PASS");
}
