// Divisors and Riemann-Roch on the cubic y^2 = x^3 + x^2 + 1 -- the same check as the Python.
// No crates; exact fractions are written here on i128 with overflow checks.  A function is
// (A + B y)/C with A, B, C polynomials in x, lowest power first.  Orders come from Laurent series.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // numerator, denominator > 0, lowest terms
fn q(n: i128, d: i128) -> Q {
    let (mut a, mut b) = (n.abs(), d.abs());
    while b != 0 { (a, b) = (b, a % b); }
    if a == 0 { return Q(0, 1); }
    Q(n / a * d.signum(), d.abs() / a)
}
fn ml(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn ad(x: Q, y: Q) -> Q { q(ml(x.0, y.1).checked_add(ml(y.0, x.1)).expect("overflow"), ml(x.1, y.1)) }
fn ng(x: Q) -> Q { Q(-x.0, x.1) }
fn sb(x: Q, y: Q) -> Q { ad(x, ng(y)) }
fn mu(x: Q, y: Q) -> Q { q(ml(x.0, y.0), ml(x.1, y.1)) }
fn dv(x: Q, y: Q) -> Q { q(ml(x.0, y.1), ml(x.1, y.0)) }
fn n(v: i128) -> Q { Q(v, 1) }
fn txt(x: Q) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{}/{}", x.0, x.1) } }
type P = Vec<Q>;
fn f_() -> P { vec![n(1), n(0), n(1), n(1)] } // x^3 + x^2 + 1, the smooth neighbour
fn ev(p: &P, x: Q) -> Q { p.iter().rev().fold(n(0), |s, &c| ad(mu(s, x), c)) }
fn evf(p: &P, x: f64) -> f64 { p.iter().rev().fold(0.0, |s, &c| s * x + c.0 as f64 / c.1 as f64) }
fn pmul(a: &P, b: &P) -> P {
    if a.is_empty() || b.is_empty() { return vec![n(0)]; }
    let mut r = vec![n(0); a.len() + b.len() - 1];
    for (i, &u) in a.iter().enumerate() { for (j, &v) in b.iter().enumerate() { r[i + j] = ad(r[i + j], mu(u, v)); } }
    r
}
fn psub(a: &P, b: &P) -> P { (0..a.len().max(b.len())).map(|i| sb(*a.get(i).unwrap_or(&n(0)), *b.get(i).unwrap_or(&n(0)))).collect() }
fn deg(p: &P) -> i64 { p.iter().rposition(|c| c.0 != 0).map_or(-1, |i| i as i64) }
fn shift(p: &P, x0: Q) -> P { p.iter().rev().fold(vec![n(0)], |r, &c| psub(&pmul(&r, &vec![x0, n(1)]), &vec![ng(c)])) } // in powers of t = x - x0
fn lowest(s: &P) -> i64 { s.iter().position(|c| c.0 != 0).unwrap() as i64 }
fn roots(p: &P) -> Vec<(i128, i64)> { // integer roots with multiplicity
    let mut out = vec![];
    for r in -10..11 {
        let (mut qq, mut k) = (p.clone(), 0);
        while deg(&qq) > 0 && ev(&qq, n(r)).0 == 0 { k += 1; let b = shift(&qq, n(r))[1..].to_vec(); qq = shift(&b, n(-r)); }
        if k > 0 { out.push((r, k)); }
    }
    out
}
const NN: usize = 8;
type Fun = (P, P, P);
fn ord_p(f: &Fun, x0: i128, y0: i128) -> i64 { // order at an affine point with y0 != 0
    let pad = |p: &P| { let mut v = shift(p, n(x0)); v.resize(v.len() + NN, n(0)); v };
    let (a, b, c, fs) = (pad(&f.0), pad(&f.1), pad(&f.2), pad(&f_()));
    let mut y = vec![n(y0)]; // Laurent (here Taylor) series of y in t
    for k in 1..NN {
        let s = (1..k).fold(n(0), |s, i| ad(s, mu(y[i], y[k - i])));
        y.push(dv(sb(fs[k], s), n(2 * y0)));
    }
    let num: P = (0..NN).map(|k| (0..=k).fold(a[k], |s, i| ad(s, mu(b[i], y[k - i])))).collect();
    lowest(&num) - lowest(&c)
}
fn ord_o(f: &Fun) -> i64 { // x has a double pole at O, y a triple one
    let pa = if deg(&f.0) >= 0 { 2 * deg(&f.0) } else { -1 };
    let pb = if deg(&f.1) >= 0 { 2 * deg(&f.1) + 3 } else { -1 };
    2 * deg(&f.2) - pa.max(pb)
}
fn isqrt(v: i128) -> i128 { let mut s = 0; while (s + 1) * (s + 1) <= v { s += 1; } s }
fn div(f: &Fun) -> (Vec<(String, i64)>, bool, bool) { // every zero and pole, over the rationals
    let nm = psub(&pmul(&f.0, &f.0), &pmul(&pmul(&f.1, &f.1), &f_()));
    let (rn, rc) = (roots(&nm), roots(&f.2));
    let mut xs: Vec<i128> = rn.iter().chain(rc.iter()).map(|e| e.0).collect();
    xs.sort(); xs.dedup();
    let mut d = vec![];
    for x0 in xs {
        let fx = ev(&f_(), n(x0)).0; let s = isqrt(fx);
        for y0 in [s, -s] { if s * s == fx { let o = ord_p(f, x0, y0); if o != 0 { d.push((format!("({}, {})", x0, y0), o)); } } }
    }
    if ord_o(f) != 0 { d.push(("O".to_string(), ord_o(f))); }
    let sm = |r: &Vec<(i128, i64)>| r.iter().map(|e| e.1).sum::<i64>();
    (d, sm(&rn) == deg(&nm), sm(&rc) == deg(&f.2))
}
fn show(d: &Vec<(String, i64)>) -> String {
    format!("{}, degree {}", d.iter().map(|(k, v)| format!("{:+}{}", v, k)).collect::<Vec<_>>().join(" "), d.iter().map(|e| e.1).sum::<i64>()) }
fn lst(p: &P) -> String { format!("[{}]", p.iter().map(|c| txt(*c)).collect::<Vec<_>>().join(", ")) }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    let ff = f_(); // discriminant of x^3 + ax^2 + bx + c
    let disc = |a: i128, b: i128, c: i128| 18 * a * b * c - 4 * a * a * a * c + a * a * b * b - 4 * b * b * b - 27 * c * c;
    let dsc = disc(ff[2].0, ff[1].0, ff[0].0);
    println!("curve y^2 = x^3 + x^2 + 1; discriminant of the cubic {}, not 0: smooth; genus (3-1)(3-2)/2 = {}", dsc, (3 - 1) * (3 - 2) / 2);
    println!("nodal neighbour y^2 = x^3 + x^2: discriminant {}: a node at (0, 0)", disc(1, 0, 0));
    assert!(dsc == -4 - 27 && disc(1, 0, 0) == 0); // by hand: only the c terms survive
    let (p, qq) = ((0i128, 1i128), (-1i128, -1i128));
    let on = |x: Q, y: Q| mu(y, y) == ev(&ff, x);
    let m = q(qq.1 - p.1, qq.0 - p.0); let k = sb(n(p.1), mu(m, n(p.0)));
    let cub = psub(&ff, &pmul(&vec![k, m], &vec![k, m]));
    let xr = sb(sb(ng(cub[2]), n(p.0)), n(qq.0)); let r = (xr, ad(mu(m, xr), k));
    let rts: Vec<String> = roots(&cub).iter().map(|e| e.0.to_string()).collect();
    let rev = |v: &P| { let mut w = v.clone(); w.reverse(); lst(&w) };
    println!("P = ({}, {}), Q = ({}, {}) on the curve: {}; line y = {}x + {}; cubic on it {}, roots [{}]", p.0, p.1, qq.0, qq.1, tf(on(n(p.0), n(p.1)) && on(n(qq.0), n(qq.1))), txt(m), txt(k), rev(&cub), rts.join(", "));
    println!("third point R = ({}, {}): {} = {}; reflection -R = ({}, {})", txt(r.0), txt(r.1), txt(mu(r.1, r.1)), txt(ev(&ff, r.0)), txt(r.0), txt(ng(r.1)));
    assert!(on(r.0, r.1) && rts == ["-1", "0", "4"]);
    let ell: Fun = (vec![ng(k), ng(m)], vec![n(1)], vec![n(1)]);
    let vrt: Fun = (vec![ng(r.0), n(1)], vec![], vec![n(1)]);
    let g: Fun = (vec![k, m], vec![n(1)], vec![n(0), n(1), n(1)]);
    let lhs = pmul(&vec![ng(r.0), n(1)], &vec![n(0), n(1), n(1)]); let rhs = psub(&ff, &pmul(&vec![k, m], &vec![k, m]));
    println!("(x - 4) x (x + 1) = {} and y^2 - (2x + 1)^2 = {}: so (x - 4)/(y - 2x - 1) = (y + 2x + 1)/(x(x + 1))", rev(&lhs), rev(&rhs));
    assert!(lhs[..] == rhs[..lhs.len()]);
    let xf: Fun = (vec![n(0), n(1)], vec![], vec![n(1)]);
    for (name, f) in [("line y - 2x - 1", &ell), ("vertical x - 4", &vrt), ("u", &g), ("x", &xf)] {
        let (d, z, pp) = div(f);
        println!("div {}: {}; every zero and pole found: {}", name, show(&d), tf(z && pp));
        assert!(d.iter().map(|e| e.1).sum::<i64>() == 0 && z && pp);
    }
    let dg = div(&g).0;
    let want = [("(-1, -1)", -1), ("(0, 1)", -1), ("(4, -9)", 1), ("O", 1)];
    assert!(dg.len() == 4 && dg.iter().zip(want.iter()).all(|(u, v)| u.0 == v.0 && u.1 == v.1));
    let tq = ord_p(&(vec![n(3), n(1)], vec![n(2)], vec![n(1)]), qq.0, qq.1); // the tangent x + 2y + 3 at Q tests the series of y past y0
    println!("tangent x + 2y + 3 at Q: order {} there, a double zero, read off the series of y in t = x + 1", tq);
    let dy = div(&(vec![], vec![n(1)], vec![n(1)])).0; // div y: its norm -F has no rational root
    let (mut lo, mut hi) = (-2.0f64, -1.0f64);
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if evf(&ff, mid) < 0.0 { lo = mid } else { hi = mid } }
    let re = (-1.0 - lo) / 2.0; let im = (-1.0 / lo - re * re).sqrt();
    println!("div y over the complex numbers: zeros at x = {:.10} and {:.6} +/- {:.6}i, -3O, degree 0", lo, re, im);
    println!("mistake, div y over the rationals only: {} zeros, pole {}", dy.iter().filter(|e| e.1 > 0).count(), show(&dy));
    println!("mistake, div x with O left out: {}", show(&div(&xf).0.into_iter().filter(|e| e.0 != "O").collect()));
    let mut ln: Vec<Vec<(i64, i64)>> = vec![];
    for nn in 0..7i64 { // L(nO): monomials x^i y^j, j <= 1
        let mut mons: Vec<(i64, i64)> = (0..4).flat_map(|i| [(i, 0), (i, 1)]).filter(|e| 2 * e.0 + 3 * e.1 <= nn).collect();
        mons.sort_by_key(|e| 2 * e.0 + 3 * e.1);
        let basis: Vec<String> = mons.iter().map(|&(i, j)| {
            let xp = match i { 0 => String::new(), 1 => "x".into(), _ => format!("x^{}", i) };
            if j == 0 { if i == 0 { "1".into() } else { xp } } else { format!("{}y", xp) } }).collect();
        let rr = nn + 1 - 1 + if nn == 0 { 1 } else { 0 }; // l(K - D) = l(-nO) is 1 at n = 0, else 0
        println!("L({}O): pole orders 2i + 3j <= {}: {}; l = {}; Riemann-Roch {} + 1 - 1 + l(K - D) = {}", nn, nn, basis.join(", "), basis.len(), nn, rr);
        assert!(basis.len() as i64 == rr); ln.push(mons);
    }
    let gaps: Vec<usize> = (1..ln.len()).filter(|&k| ln[k].len() == ln[k - 1].len()).collect(); // pole orders no function reaches: the gaps at O
    println!("mistake, Riemann-Roch at D = 0 without l(K - D): 0 + 1 - 1 = {}, but the constants give l(0) = 1", 0 + 1 - 1);
    let top = -ord_o(&ell) as usize; let dd = ["(0, 1)", "(-1, -1)"]; // D = P + Q; f(y - 2x - 1) lies in L(3O), 3 read off div of the line
    let row: Vec<Q> = ln[top].iter().map(|&(i, j)| mu((0..i).fold(n(1), |s, _| mu(s, r.0)), (0..j).fold(n(1), |s, _| mu(s, r.1)))).collect(); // L(3O) at R
    let pv = row.iter().position(|v| v.0 != 0).unwrap(); // elimination on one nonzero row: a pivot, and each other column free
    let ker: Vec<P> = (0..row.len()).filter(|&e| e != pv).map(|e| (0..row.len()).map(|c| if c == e { n(1) } else if c == pv { ng(dv(row[e], row[pv])) } else { n(0) }).collect()).collect();
    let (dim, genus) = (ker.len() as i64, gaps.len() as i64); let (rank, rr2) = (row.len() as i64 - dim, dd.len() as i64 + 1 - genus);
    let inl = ker.iter().all(|h| { // h/(y - 2x - 1) = h(y + 2x + 1)/(y^2 - (2x + 1)^2), as (A + By)/C
        let hp = |jj: i64| -> P { (0..4).map(|i| h.iter().zip(&ln[top]).filter(|e| *e.1 == (i, jj)).fold(n(0), |s, e| ad(s, *e.0))).collect() };
        let (d, _, pp) = div(&(psub(&pmul(&hp(0), &vec![k, m]), &pmul(&vec![n(-1)], &pmul(&hp(1), &ff))), psub(&hp(0), &pmul(&vec![n(-1)], &pmul(&hp(1), &vec![k, m]))), cub.clone()));
        pp && d.iter().all(|(s, v)| *v >= -(dd.contains(&s.as_str()) as i64)) });
    println!("L(P + Q): f x (y - 2x - 1) = a + bx + cy, zero at R: a + {}b + {}c = 0, rank {}, so l(P + Q) = {} - {} = {}", txt(row[1]), txt(row[2]), rank, row.len(), rank, dim);
    println!("kernel in 1, x, y: [{}]; each over y - 2x - 1 has at most simple poles at P and Q, none elsewhere: {}", ker.iter().map(lst).collect::<Vec<_>>().join(", "), tf(inl));
    println!("Riemann-Roch: l(P + Q) = deg {} + 1 - genus {} = {}, the genus counted as the gaps {:?} in the pole orders at O", dd.len(), genus, rr2, gaps);
    let idn: P = (0..3).map(|c| sb(sb(ker[1][c], [ng(k), ng(m), n(1)][c]), mu(n(2), ker[0][c]))).collect(); // (y - 9) - (y - 2x - 1) - 2(x - 4), in 1, x, y
    println!("second solution (y - 9)/(y - 2x - 1) = 1 + 2u: (y - 9) - (y - 2x - 1) - 2(x - 4) = {}", lst(&idn));
    let dl = |s: &str| dg.iter().find(|e| e.0 == s).map(|e| e.1);
    assert!(dim == rr2 && dim == 2 && genus == (3 - 1) * (3 - 2) / 2 && inl && tq == 2 && idn.iter().all(|v| v.0 == 0) && dl("(0, 1)") == Some(-1) && dl("(-1, -1)") == Some(-1));
    println!("mistake, Riemann-Roch with genus 0 on the cubic: l(P + Q) = {}, but the count above gives {}", 2 + 1 - 0, dim);
    println!("test P + Q ~ (4, -9) + O: difference = -div u, so equivalent; the chord gives P + Q = ({}, {}) in the group law", txt(r.0), txt(ng(r.1)));
    let mm = [[n(1), n(p.0)], [n(1), n(qq.0)]]; let det = sb(mu(mm[0][0], mm[1][1]), mu(mm[0][1], mm[1][0])); // h = a + bx at P and at Q
    println!("test P + Q ~ 2O: h in L(2O) = span(1, x) with zeros P, Q needs a + 0b = 0, a - b = 0; determinant {}: only h = 0, not equivalent", txt(det));
    assert!(det.0 != 0);
    println!("test P ~ Q: l(Q) = 1 + 1 - 1 = {}, constants only, so no function has divisor P - Q: not equivalent", 1 + 1 - genus);
    let ok = (-3..4i128).all(|t| { let x = n(t * t - 1); let y = n(t * (t * t - 1)); mu(y, y) == ad(mu(x, mu(x, x)), mu(x, x)) });
    println!("nodal y^2 = x^3 + x^2: x = t^2 - 1, y = t^3 - t fits at 7 values of t, a degree-6 identity: {}", tf(ok));
    let mt = roots(&psub(&vec![n(0), n(0), n(1), n(1)], &vec![n(0), n(0), n(4)])); // where the line y = 2x meets it: x^3 + x^2 - (2x)^2 = 0
    let x2 = mt.iter().map(|e| e.0).max().unwrap();
    println!("nodal, on its smooth model (the t-line): y = 2x meets it {} times at the node (t = 1 and t = -1) and once at ({}, {}), so t = y/x is 2 only there; one simple pole at O, so l(O) = 2, not the smooth cubic's {}", mt[0].1, x2, 2 * x2, ln[1].len());
    assert!(ok && mt == [(0, 2), (3, 1)] && ord_o(&(vec![], vec![n(1)], vec![n(0), n(1)])) == -1);
    let sv = |x: f64, y: f64| format!("{:.1},{:.1}", 70.0 + 20.0 * x, 230.0 - 20.0 * y);
    let pts: Vec<String> = (0..17).map(|i| { let t = i as f64 / 16.0; let x = lo + (4.4 - lo) * (t * t); sv(x, evf(&ff, x).max(0.0).sqrt()) }).collect();
    println!("figure, 20 per unit, origin (70,230), upper curve: {}", pts.join(" "));
    println!("figure, P {} Q {} R {} -R {} line {} to {} vertical {} to {}", sv(0.0, 1.0), sv(-1.0, -1.0), sv(4.0, 9.0), sv(4.0, -9.0), sv(-1.5, -2.0), sv(4.5, 10.0), sv(4.0, 10.5), sv(4.0, -10.5));
    println!("ALL CHECKS PASS");
}
