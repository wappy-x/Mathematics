// Bezout's theorem -- the same check as the Python, in Rust.  No crates.  House cubic C:
// y^2 = x^2(x + 1), equation F = y^2 - x^3 - x^2; its one point at infinity is O = (0 : 1 : 0).
// Each partner G is counted in the plane by two roads: the resultant Res_x(F, G), from Sylvester
// determinants at ten values of y, and G(t^2 - 1, t^3 - t), a polynomial in t.  A third road
// counts the meetings at O: the cut-off local count.  Plane plus O must give 3 x deg G.
// Fractions are i128 pairs in lowest terms; checked arithmetic stops the run on overflow.
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }
fn cm(x: i128, y: i128) -> i128 { x.checked_mul(y).unwrap() } // panics on overflow
fn qa(a: Q, b: Q) -> Q { q(cm(a.n, b.d).checked_add(cm(b.n, a.d)).unwrap(), cm(a.d, b.d)) }
fn qm(a: Q, b: Q) -> Q { q(cm(a.n, b.n), cm(a.d, b.d)) }
fn qneg(a: Q) -> Q { Q { n: -a.n, d: a.d } }  fn qdiv(a: Q, b: Q) -> Q { qm(a, q(b.d, b.n)) }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }  fn qf(a: Q) -> f64 { a.n as f64 / a.d as f64 }
type P = Vec<Q>; // polynomial, coefficients low first
type Curve = Vec<(u32, u32, i128)>; // (i, j, c) for c x^i y^j
fn trim(mut p: P) -> P { while p.last().map_or(false, |c| c.n == 0) { p.pop(); } p }
fn add(p: &P, r: &P) -> P {
    trim((0..p.len().max(r.len())).map(|i| qa(*p.get(i).unwrap_or(&z(0)), *r.get(i).unwrap_or(&z(0)))).collect()) }
fn mul(p: &P, r: &P) -> P {
    if p.is_empty() || r.is_empty() { return vec![]; } let mut out = vec![z(0); p.len() + r.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in r.iter().enumerate() { out[i + j] = qa(out[i + j], qm(*a, *b)); } } trim(out) }
fn evq(p: &P, v: Q) -> Q { p.iter().rev().fold(z(0), |s, c| qa(qm(s, v), *c)) } // Horner's rule
fn evf(p: &[f64], v: f64) -> f64 { let mut s = 0.0; for c in p.iter().rev() { s = s * v + c; } s }
fn show(p: &P, v: &str) -> String {
    let mut out = String::new();
    for k in (0..p.len()).rev().filter(|&k| p[k].n != 0) {
        let a = Q { n: p[k].n.abs(), d: p[k].d }; out += if p[k].n < 0 { " - " } else { " + " };
        if a != z(1) || k == 0 { out += &qs(a); } if k > 0 { out += v; } if k > 1 { out += &format!("^{}", k); }
    }
    if out.is_empty() { "0".into() } else if &out[1..2] == "+" { out[3..].into() } else { format!("-{}", &out[3..]) }
}
fn deg(g: &Curve) -> usize { g.iter().map(|&(i, j, _)| (i + j) as usize).max().unwrap() }
fn elim(mut m: Vec<Vec<Q>>) -> (usize, Q) { // exact Gaussian elimination: rank and determinant
    let (w, mut d, mut r) = (m[0].len(), z(1), 0);
    for c in 0..w {
        let p = match (r..m.len()).find(|&i| m[i][c].n != 0) { Some(p) => p, None => { d = z(0); continue } };
        if p != r { m.swap(r, p); d = qneg(d); }
        d = qm(d, m[r][c]);
        for i in (r + 1..m.len()).filter(|&i| m[i][c].n != 0).collect::<Vec<_>>() {
            let f = qdiv(m[i][c], m[r][c]); for k in c..w { m[i][k] = qa(m[i][k], qneg(qm(f, m[r][k]))); } }
        r += 1;
    }
    (r, d)
}
fn xrow(g: &Curve, y: Q) -> Vec<Q> { // G's coefficients in x at this y, top first, full degree
    let (n, mut out) = (deg(g), vec![z(0); deg(g) + 1]);
    for &(i, j, c) in g { out[n - i as usize] = qa(out[n - i as usize], qm(z(c), (0..j).fold(z(1), |s, _| qm(s, y)))); }
    out
}
fn sylvester(g: &Curve, h: &Curve, y: Q) -> Q { // n shifted rows of G's coefficients, m of H's
    let (a, b) = (xrow(g, y), xrow(h, y)); let (m, n) = (a.len() - 1, b.len() - 1);
    let row = |src: &Vec<Q>, lead: usize, len: usize| [vec![z(0); lead], src.clone(), vec![z(0); len - 1 - lead]].concat();
    elim((0..n).map(|k| row(&a, k, n)).chain((0..m).map(|k| row(&b, k, m))).collect()).1
}
fn resultant(g: &Curve, h: &Curve) -> P { // degree at most 9: ten samples fix it
    let ys: Vec<Q> = (-4..6).map(z).collect();
    let mut c: Vec<Q> = ys.iter().map(|&y| sylvester(g, h, y)).collect();
    for k in 1..10 { for i in (k..10).rev() { c[i] = qdiv(qa(c[i], qneg(c[i - 1])), qa(ys[i], qneg(ys[i - k]))); } }
    (0..10).rev().fold(vec![], |p: P, i| add(&mul(&p, &vec![qneg(ys[i]), z(1)]), &vec![c[i]]))
}
fn on_c(g: &Curve) -> P { // G(t^2 - 1, t^3 - t)
    let (x, y) = (vec![z(-1), z(0), z(1)], vec![z(0), z(-1), z(0), z(1)]);
    g.iter().fold(vec![], |p, &(i, j, c)| add(&p, &(0..i).map(|_| &x).chain((0..j).map(|_| &y)).fold(vec![z(c)], |t, f| mul(&t, f))))
}
fn at_o(g: &Curve, h: &Curve, n: usize) -> usize { // road three: dim k[x, z] / (G, H, all terms of degree N), chart y = 1
    let mons: Vec<(usize, usize)> = (0..n).flat_map(|d| (0..=d).map(move |i| (i, d - i))).collect();
    let mut rows = vec![];
    for k in [g, h] { for &(a, b) in &mons {
        let mut row = vec![z(0); mons.len()];
        for &(i, j, c) in k { let (i, zj) = (i as usize, deg(k) - (i + j) as usize);
            if i + zj + a + b < n { let ix = mons.iter().position(|&m| m == (i + a, zj + b)).unwrap(); row[ix] = qa(row[ix], z(c)); } }
        rows.push(row); } }
    mons.len() - elim(rows).0
}
fn mult_o(g: &Curve, h: &Curve) -> Vec<usize> { // raise N until two counts agree: then the count is final
    let mut s = vec![at_o(g, h, 1)];
    while s.len() < 2 || s[s.len() - 1] != s[s.len() - 2] { s.push(at_o(g, h, s.len() + 1)); }
    s
}
fn roots(p: &P, lo: f64, hi: f64, n: usize) -> Vec<f64> { // sign changes on a grid, then halving
    let (pf, mut out): (Vec<f64>, Vec<f64>) = (p.iter().map(|&c| qf(c)).collect(), vec![]);
    for k in 0..n {
        let (mut a, mut b) = (lo + (hi - lo) * k as f64 / n as f64, lo + (hi - lo) * (k + 1) as f64 / n as f64);
        if (evf(&pf, a) > 0.0) == (evf(&pf, b) > 0.0) { continue; }
        for _ in 0..60 { let m = (a + b) / 2.0; if (evf(&pf, a) > 0.0) != (evf(&pf, m) > 0.0) { b = m } else { a = m } }
        out.push((a + b) / 2.0);
    }
    out
}
fn distinct(p: &P) -> usize { // roots in C counted once: deg p - deg gcd(p, p')
    let (mut a, mut b) = (p.clone(), trim((1..p.len()).map(|i| qm(z(i as i128), p[i])).collect()));
    while !b.is_empty() { // Euclid: (a, b) becomes (b, a mod b)
        while a.len() >= b.len() {
            let (f, s) = (qdiv(*a.last().unwrap(), *b.last().unwrap()), a.len() - b.len());
            a = trim(a.iter().enumerate().map(|(i, &c)| if i >= s { qa(c, qneg(qm(f, b[i - s]))) } else { c }).collect());
        }
        std::mem::swap(&mut a, &mut b);
    }
    p.len() - a.len()
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn main() {
    let f: Curve = vec![(0, 2, 1), (3, 0, -1), (2, 0, -1)];
    let l: Curve = vec![(0, 3, 54), (0, 2, 9), (0, 1, -6), (0, 0, -1)]; // (3y - 1)(3y + 1)(6y + 1)
    let g: Curve = vec![(1, 0, 1), (0, 3, -216), (0, 2, -36), (0, 1, 24), (0, 0, 4)]; // x = 4(9y^2 - 1)(6y + 1)
    let e: Curve = vec![(0, 2, 10), (3, 0, -10), (2, 0, -10), (0, 0, 1)]; // y^2 = x^2(x + 1) - 1/10
    let (t, w): (Curve, Curve) = (vec![(1, 0, 4), (0, 1, 16), (0, 0, 9)], vec![(1, 0, 1), (0, 0, 2)]);
    let partners: Vec<(&str, Curve, (usize, usize))> = vec![
        ("tangent line 4x + 16y + 9 = 0", t.clone(), (3, 0)),
        ("line x = 5/4", vec![(1, 0, 4), (0, 0, -5)], (2, 1)), ("line x = -2", w.clone(), (2, 1)),
        ("three lines y = 1/3, -1/3, -1/6", l.clone(), (9, 0)),
        ("cubic G: x = 4(9y^2 - 1)(6y + 1)", g.clone(), (9, 0)),
        ("cubic E: y^2 = x^2(x + 1) - 1/10", e.clone(), (0, 9))];
    println!("C: y^2 = x^2(x + 1); (t^2 - 1, t^3 - t) lies on C: {}", yn(on_c(&f).is_empty()));
    let mut plane = vec![];
    for (name, h, want) in &partners {
        let (r, p, d, cut) = (resultant(&f, h), on_c(h), deg(h), mult_o(&f, h)); let o = *cut.last().unwrap();
        plane.push(r.len() - 1);
        println!("{}: degree {}, Bezout 3 x {} = {}", name, d, d, 3 * d);
        println!("    in the plane: resultant road {}, parametrisation road {}", r.len() - 1, p.len() - 1);
        println!("    at O, cut-off counts {:?}: {}; total {} + {} = {}", cut, o, r.len() - 1, o, r.len() - 1 + o);
        assert!(r.len() == p.len() && (r.len() - 1, o) == *want && r.len() - 1 + o == 3 * d);
        if d == 1 { println!("    Res_x = {}; on C: {}", show(&r, "y"), show(&p, "t")); }
    }
    let (p0, r0) = ((q(-3, 4), q(-3, 8)), (q(9, 16), q(-45, 64)));
    assert!([p0, r0].iter().all(|&(x, y)| qm(y, y) == qm(qm(x, x), qa(x, z(1))) && qa(qa(qm(z(4), x), qm(z(16), y)), z(9)) == z(0)));
    let (half, res_t) = (vec![q(-1, 2), z(1)], mul(&mul(&vec![z(3), z(8)], &vec![z(3), z(8)]), &vec![z(-45), z(-64)])); // -(8y + 3)^2(64y + 45)
    let ok = on_c(&t) == mul(&mul(&half, &half), &vec![z(20), z(16)]) && resultant(&f, &t) == res_t;
    println!("tangent: P = ({}, {}) at t = 1/2, R = ({}, {}) at t = -5/4; on C 16(t - 1/2)^2(t + 5/4), Res_x -(8y + 3)^2(64y + 45): {}",
             qs(p0.0), qs(p0.1), qs(r0.0), qs(r0.1), yn(ok));
    println!("line x = 5/4 meets C at (5/4, 15/8), (5/4, -15/8) and O = (0 : 1 : 0): {}", yn(qm(q(15, 8), q(15, 8)) == qm(q(25, 16), q(9, 4))));
    println!("line x = -2: y^2 = (-2)^2(-2 + 1) = {}, so y = 2i or -2i, and O", (-2i64).pow(2) * (-2 + 1));
    let (tg, yg, tl) = (roots(&on_c(&g), -3.0, 3.0, 2400), roots(&resultant(&f, &g), -1.0, 1.0, 2400), roots(&on_c(&l), -3.0, 3.0, 2400));
    let mut pts: Vec<(f64, f64)> = tg.iter().map(|&t| (t * t - 1.0, t * t * t - t)).collect();
    pts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    assert!(pts.iter().all(|&(x, y)| (y * y - x * x * (x + 1.0)).abs() < 1e-9 && (evf(&[-4.0, -24.0, 36.0, 216.0], y) - x).abs() < 1e-9)); // each point on both curves
    println!("C and G: {} real points, (x, y) =", pts.len());
    for k in (0..9).step_by(3) { println!("    {}", pts[k..k + 3].iter().map(|(x, y)| format!("({:.4}, {:.4})", x, y)).collect::<Vec<_>>().join("; ")); }
    let mut ys: Vec<f64> = pts.iter().map(|p| p.1).collect(); ys.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let same = yg.len() == 9 && ys.iter().zip(&yg).all(|(a, b)| (a - b).abs() < 1e-9);
    println!("    the same nine y-values from the resultant's roots: {}", yn(same));
    println!("C and the three lines: {} real points, 3 on each line", tl.len());
    assert!(same && pts.len() == 9 && tl.len() == 9);
    println!("C and E: Res_x(F, E) = {}, a nonzero constant; E on C's parametrisation: {}",
             show(&resultant(&f, &e), "y"), show(&on_c(&e), "t"));
    let b1: Curve = vec![(2, 0, 1), (0, 2, 1), (0, 0, -25)]; // beacon A: 5 m around (0, 0)
    let b2: Curve = vec![(2, 0, 1), (0, 2, 1), (1, 0, -8), (0, 1, -8), (0, 0, -17)]; // beacon B: 7 m around (4, 4)
    let rb = resultant(&b1, &b2);
    let fix = [(4i128, -3i128), (-3, 4)].iter().all(|&(x, y)| x * x + y * y == 25 && (x - 4).pow(2) + (y - 4).pow(2) == 49);
    let sq = |(a, b): (i128, i128)| (a * a - b * b, 2 * a * b); // (a + bi)^2
    let top: Vec<(i128, i128)> = [1, -1].iter().map(|&s| (sq((1, 0)).0 + sq((0, s)).0, sq((1, 0)).1 + sq((0, s)).1)).collect(); // degree-2 part
    println!("beacon circles: Res_x = {}: {} in the plane + {} at infinity", show(&rb, "y"), rb.len() - 1, 5 - rb.len());
    println!("    real fixes (4, -3), (-3, 4) on both: {}; (1 : i : 0), (1 : -i : 0) on both: {}", yn(fix), yn(top == vec![(0, 0), (0, 0)]));
    assert!(fix && top == vec![(0, 0), (0, 0)] && rb.len() == 3 && evq(&rb, z(-3)) == z(0) && evq(&rb, z(4)) == z(0));
    let zres = resultant(&f, &f.iter().map(|&(i, j, c)| (i, j, 2 * c)).collect());
    println!("C against 2F, a shared curve: Res_x = {}, so no finite count", show(&zres, "y"));
    assert!(zres.is_empty() && distinct(&on_c(&t)) == 2 && ok && on_c(&f).is_empty() && qm(q(15, 8), q(15, 8)) == qm(q(25, 16), q(9, 4)));
    println!("mistakes: C and E in the plane only: {}; tangent line as distinct points: {}", plane[5], distinct(&on_c(&t)));
    println!("    C and x = -2 in the real plane: {}; beacon circles in the real plane: {}", roots(&on_c(&w), -3.0, 3.0, 2400).len(), roots(&rb, -10.0, 10.0, 2401).len());
    let mut ef = e.clone(); ef[3].2 = -1;                       // E flipped: y^2 = x^2(x + 1) + 1/10
    let tries: Vec<(&str, Curve)> = vec![("cubic S", vec![(0, 1, 1), (3, 0, -1), (2, 0, 4), (0, 0, -3)]), ("line y = 2x", vec![(0, 1, 1), (1, 0, -2)]),
        ("line x = 0", vec![(1, 0, 1)]), ("E flipped", ef)];  // the "try changing" answers
    println!("try: {}", tries.iter().map(|(n, h)| format!("{} {} + {}, on C {}", n, resultant(&f, h).len() - 1, mult_o(&f, h).last().unwrap(),
             show(&on_c(h), "t"))).collect::<Vec<_>>().join("; "));
    println!("figure, window x -1.2 to 0.6, y -0.8 to 0.45; P ({}, {}), R ({}, {}); node (0, 0)", qf(p0.0), qf(p0.1), qf(r0.0), qf(r0.1));
    println!("ALL CHECKS PASS");
}
