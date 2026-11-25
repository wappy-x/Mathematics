// Darboux's theorem and Moser's trick -- the check behind the card.  std only.
// Part 1, the plane: rain lies 1 + x^2 mm deep at x km from a river, the form w1 = (1 + x^2) dx^dy.
// Darboux coordinates u = x + x^3/3, v = y.  Roads: du/dx by finite differences against 1 + x^2;
// rain in a strip by the midpoint rule against the strip's u-width; Moser's flow, stepped by RK4,
// against Cardano's formula and Newton's method for x + x^3/3 = u.  Part 2: a constant form on R^4
// brought to dq^dp by symplectic Gram-Schmidt, against the shift P1 = p1 + b q2 found by hand.
// Part 3: Lagrangian tests, by w on tangent pairs and by the loop integral of p dq.  Part 4: breaks.
type M4 = [[f64; 4]; 4];
fn f6(x: f64) -> String { format!("{:.6}", x + 0.0) }
fn sci(x: f64) -> String { // Python's .1e: two-digit exponent with its sign
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn u_of(x: f64, k: i32) -> f64 { x + x.powf((k + 1) as f64) / (k + 1) as f64 }
fn cardano(u: f64) -> f64 { // the real root of x^3 + 3x - 3u = 0
    let r = (9.0 * u * u / 4.0 + 1.0).sqrt();
    (1.5 * u + r).cbrt() - (r - 1.5 * u).cbrt()
}
fn newton(u: f64) -> f64 { (0..60).fold(u, |x, _| x - (u_of(x, 2) - u) / (1.0 + x * x)) }
fn xf(t: f64, x: f64, k: i32, s: f64) -> f64 { // Moser's field: iota_X w_t = -s alpha, alpha = x^(k+1)/(k+1) dy
    -s * x.powf((k + 1) as f64) / ((k + 1) as f64 * (1.0 + t * x.powf(k as f64)))
}
fn moser(a: f64, n: usize, tt: f64, k: i32, s: f64) -> f64 { // RK4 on dx/dt = X(t, x) from x = a, t = 0 to T
    let (mut x, h) = (a, tt / n as f64);
    for j in 0..n {
        let t = j as f64 * h;
        let k1 = xf(t, x, k, s); let k2 = xf(t + h / 2.0, x + h / 2.0 * k1, k, s);
        let k3 = xf(t + h / 2.0, x + h / 2.0 * k2, k, s); let k4 = xf(t + h, x + h * k3, k, s);
        x += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    }
    x
}
fn w_a(a: &M4, u: &[f64], v: &[f64]) -> f64 { (0..16).fold(0.0, |s, m| s + u[m / 4] * a[m / 4][m % 4] * v[m % 4]) }
fn form(entries: &[((usize, usize), f64)]) -> M4 { // antisymmetric 4x4 matrix in the order (q1, q2, p1, p2)
    let mut a = [[0.0; 4]; 4];
    for &((i, j), c) in entries { a[i][j] = c; a[j][i] = -c; }
    a
}
fn pf(a: &M4) -> f64 { a[0][1] * a[2][3] - a[0][2] * a[1][3] + a[0][3] * a[1][2] }
fn axis(i: usize) -> Vec<f64> { (0..4).map(|m| if m == i { 1.0 } else { 0.0 }).collect() }
fn gram_schmidt(a: &M4) -> Vec<Vec<f64>> { // symplectic Gram-Schmidt: returns e1, e2, f1, f2
    let (mut rest, mut es, mut fs): (Vec<Vec<f64>>, Vec<Vec<f64>>, Vec<Vec<f64>>) = ((0..4).map(axis).collect(), vec![], vec![]);
    while !rest.is_empty() { // pair the first arrow with the last one it sees
        let e = rest.remove(0);
        let k = (0..rest.len()).filter(|&i| w_a(a, &e, &rest[i]).abs() > 1e-12).max().unwrap();
        let f0 = rest.remove(k);
        let f: Vec<f64> = f0.iter().map(|c| c / w_a(a, &e, &f0)).collect();
        rest = rest.iter().map(|r| { let (x, y) = (w_a(a, r, &f), w_a(a, r, &e)); (0..4).map(|i| r[i] - x * e[i] + y * f[i]).collect() }).collect();
        es.push(e); fs.push(f);
    }
    es.extend(fs);
    es
}
fn dev(a: &M4, p: &[Vec<f64>]) -> f64 { // largest gap between P^T A P and the standard matrix J
    let j = form(&[((0, 2), 1.0), ((1, 3), 1.0)]);
    (0..16).fold(0.0, |m: f64, k| m.max((w_a(a, &p[k / 4], &p[k % 4]) - j[k / 4][k % 4]).abs()))
}
fn vec_s(v: &[f64]) -> String { format!("({})", v.iter().map(|c| format!("{}", c + 0.0)).collect::<Vec<_>>().join(", ")) }
fn on(w: &M4, g: &dyn Fn(f64, f64) -> [f64; 4], pts: &[(f64, f64)]) -> Vec<f64> { // w on the tangent pair, by central differences
    pts.iter().map(|&(q1, q2)| {
        let (a, b, c, d) = (g(q1 + 1e-5, q2), g(q1 - 1e-5, q2), g(q1, q2 + 1e-5), g(q1, q2 - 1e-5));
        let t1: Vec<f64> = (0..4).map(|i| (a[i] - b[i]) / 2e-5).collect();
        let t2: Vec<f64> = (0..4).map(|i| (c[i] - d[i]) / 2e-5).collect();
        w_a(w, &t1, &t2)
    }).collect()
}
fn worst(w: &M4, g: &dyn Fn(f64, f64) -> [f64; 4], pts: &[(f64, f64)]) -> f64 { on(w, g, pts).iter().fold(0.0, |m, x| m.max(x.abs())) }
fn lp(g: &dyn Fn(f64, f64) -> [f64; 4]) -> f64 { // p dq round the surface g's square 1 <= s, t <= 2, anticlockwise
    let (n, nf) = (400, 400.0);
    let mut c: Vec<(f64, f64)> = (0..n).map(|i| (1.0 + i as f64 / nf, 1.0)).collect();
    c.extend((0..n).map(|i| (2.0, 1.0 + i as f64 / nf)));
    c.extend((0..n).map(|i| (2.0 - i as f64 / nf, 2.0)));
    c.extend((0..n).map(|i| (1.0, 2.0 - i as f64 / nf)));
    (0..c.len()).fold(0.0, |tot, i| {
        let ((a1, a2), (b1, b2)) = (c[i], c[(i + 1) % c.len()]);
        let (m, ga, gb) = (g((a1 + b1) / 2.0, (a2 + b2) / 2.0), g(a1, a2), g(b1, b2));
        tot + m[2] * (gb[0] - ga[0]) + m[3] * (gb[1] - ga[1])
    })
}
fn flux(af: &dyn Fn(&[f64]) -> M4) -> f64 { // w over the boundary of the unit cube in (q1, q2, p1)
    let (n, mut tot) = (10, 0.0);
    for k in 0..3 {
        let (a, b) = ((k + 1) % 3, (k + 2) % 3);
        for &(c, sgn) in &[(1.0, 1.0), (0.0, -1.0)] {
            for m in 0..n * n {
                let mut z = [0.0; 4];
                z[k] = c; z[a] = ((m / n) as f64 + 0.5) / n as f64; z[b] = ((m % n) as f64 + 0.5) / n as f64;
                tot += sgn * w_a(&af(&z), &axis(a), &axis(b)) / n as f64 / n as f64;
            }
        }
    }
    tot
}
fn main() {
    let ch: Vec<String> = (0..7).map(|i| format!("{:.4}", u_of(i as f64 / 2.0, 2))).collect();
    println!("chart, u = x + x^3/3 at x = 0, 0.5, ..., 3 [{}]", ch.join(", "));
    for &x in &[0.0f64, 1.0, 2.0, 3.0] {
        let d = (u_of(x + 1e-5, 2) - u_of(x - 1e-5, 2)) / 2e-5;
        println!("x = {:.0} km: rain 1 + x^2 = {} mm, du/dx by differences {}", x, f6(1.0 + x * x), f6(d));
        assert!((d - (1.0 + x * x)).abs() < 1e-8);
    }
    for &(a, b) in &[(0, 1), (1, 2), (2, 3)] {
        let (af, bf) = (a as f64, b as f64);
        let mids: Vec<f64> = [10usize, 100].iter().map(|&n| ((0..n).map(|i| 1.0 + (af + (i as f64 + 0.5) / n as f64).powf(2.0)).sum::<f64>() / n as f64 - (u_of(bf, 2) - u_of(af, 2))).abs()).collect();
        println!("strip {}-{} km out, 1 km along: rain {} mm km^2 = u-width; midpoint error {} (10 cells), {} (100)", a, b, f6(u_of(bf, 2) - u_of(af, 2)), sci(mids[0]), sci(mids[1]));
        assert!(mids[1] < mids[0] / 50.0 && mids[1] < 1e-4);
    }
    println!("one unit square in (u, v) reaches out to x = {} km; check u(x) = {}", f6(cardano(1.0)), f6(u_of(cardano(1.0), 2)));
    for &x in &[1.0f64, 2.0] {
        let a = u_of(x, 2);
        let (e1, e2) = ((moser(a, 40, 1.0, 2, 1.0) - x).abs(), (moser(a, 80, 1.0, 2, 1.0) - x).abs());
        println!("Moser flow from a = {}: lands at {}; Cardano {}, Newton {}; RK4 error {} (40 steps), {} (80)", f6(a), f6(moser(a, 80, 1.0, 2, 1.0)), f6(cardano(a)), f6(newton(a)), sci(e1), sci(e2));
        assert!((cardano(a) - x).abs() < 1e-12 && (newton(a) - x).abs() < 1e-12 && e2 < e1 / 8.0 && e2 < 1e-4);
    }
    let xm = moser(4.0 / 3.0, 200, 0.5, 2, 1.0);
    println!("halfway, t = 0.5: x = {} and x + t x^3/3 = {} (kept)", f6(xm), f6(xm + 0.5 * xm.powf(3.0) / 3.0));
    assert!((xm + 0.5 * xm.powf(3.0) / 3.0 - 4.0 / 3.0).abs() < 1e-10);
    let dxda = (moser(4.0 / 3.0 + 1e-5, 200, 1.0, 2, 1.0) - moser(4.0 / 3.0 - 1e-5, 200, 1.0, 2, 1.0)) / 2e-5;
    let pb = (1.0 + moser(4.0 / 3.0, 200, 1.0, 2, 1.0).powf(2.0)) * dxda;
    println!("pullback at a = 4/3: (1 + x^2) dx/da = {} x {} = {} (w0 = 1 da^dy)", f6(2.0), f6(dxda), f6(pb));
    assert!((pb - 1.0).abs() < 1e-7);
    let bm = 2.0;
    let a = form(&[((0, 2), 1.0), ((1, 3), 1.0), ((0, 1), bm)]); // dq1^dp1 + dq2^dp2 + b dq1^dq2
    let p = gram_schmidt(&a);
    println!("magnetic form, b = 2: Pfaffian {} | Gram-Schmidt e1, e2, f1, f2 = {}", f6(pf(&a)), p.iter().map(|v| vec_s(v)).collect::<Vec<_>>().join(", "));
    let hand = vec![vec![1.0, 0.0, 0.0, 0.0], vec![0.0, 1.0, -bm, 0.0], vec![0.0, 0.0, 1.0, 0.0], vec![0.0, 0.0, 0.0, 1.0]];
    let ident: Vec<Vec<f64>> = (0..4).map(axis).collect();
    println!("largest gap from dq^dp: Gram-Schmidt {} | shift P1 = p1 + 2 q2 {} | no change {}", f6(dev(&a, &p)), f6(dev(&a, &hand)), f6(dev(&a, &ident)));
    assert!(dev(&a, &p) < 1e-12 && dev(&a, &hand) < 1e-12 && (dev(&a, &ident) - bm).abs() < 1e-12 && p[1] == vec![0.0, 1.0, -bm, 0.0]);
    let w = form(&[((0, 2), 1.0), ((1, 3), 1.0)]);
    let (w12, w13) = (w_a(&w, &ident[0], &ident[1]), w_a(&w, &ident[0], &ident[2]));
    println!("plane of q1, q2: w = {} | plane of q1, p1: w = {}", f6(w12), f6(w13));
    let pts = [(1.0, 2.0), (0.5, -1.0), (2.0, 3.0)];
    let gs = |a: f64, b: f64| [a, b, 2.0 * a * b, a * a];
    let gb = |a: f64, b: f64| [a, b, 0.0, a];
    let s12 = gs(1.0, 2.0);
    println!("graph p = grad S, S = q1^2 q2: at q = (1, 2), p = {} | largest |w| {} | loop of p dq {}", vec_s(&s12[2..]), sci(worst(&w, &gs, &pts)), f6(lp(&gs).abs()));
    let ob = on(&w, &gb, &pts);
    println!("graph p = (0, q1), from beta = q1 dq2: w = {} | loop of p dq {}", ob.iter().map(|v| f6(*v)).collect::<Vec<_>>().join(", "), f6(lp(&gb)));
    let sq = lp(&|s: f64, t: f64| [s, 0.0, t, 0.0]); // the (q1, p1) plane: the unit square 1 <= q1, p1 <= 2
    println!("plane of q1, p1, unit square anticlockwise: loop of p dq {} = minus w on it", f6(sq));
    assert!(worst(&w, &gs, &pts) < 1e-8 && lp(&gs).abs() < 1e-9 && (lp(&gb) - 1.0).abs() < 1e-9 && ob.iter().all(|v| (v + 1.0).abs() < 1e-8));
    assert!((sq + w13).abs() < 1e-12);
    assert!(w12 == 0.0);
    println!("break, w = x dx^dy: u = x^2/2 gives {} at x = -0.5 and {} at x = 0.5", f6(0.5f64.powf(2.0) / 2.0), f6((-0.5f64).powf(2.0) / 2.0));
    let bad = |z: &[f64]| form(&[((0, 2), 1.0), ((1, 3), 1.0), ((1, 2), z[0])]); // adds q1 dq2^dp1
    let std_w = |_z: &[f64]| form(&[((0, 2), 1.0), ((1, 3), 1.0)]);
    println!("break, w + q1 dq2^dp1: Pfaffian {} ; w through the cube's boundary {} against {} for dq^dp", f6(pf(&bad(&[0.5; 4]))), f6(flux(&bad)), f6(flux(&std_w)));
    assert!((flux(&bad) - 1.0).abs() < 1e-12 && flux(&std_w).abs() < 1e-12);
    let (mut lo, mut hi) = (0.0f64, 1.0f64); // straight path from dq^dp to dq1^dp1 - dq2^dp2: Pfaffian = 0 where?
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if pf(&form(&[((0, 2), 1.0), ((1, 3), 1.0 - 2.0 * lo)])) * pf(&form(&[((0, 2), 1.0), ((1, 3), 1.0 - 2.0 * mid)])) <= 0.0 { hi = mid; } else { lo = mid; }
    }
    println!("break, path without the linear step: w_t degenerate at t = {}", f6(lo));
    assert!((lo - 0.5).abs() < 1e-9);
    let xw = moser(4.0 / 3.0, 200, 1.0, 2, -1.0);
    println!("break, sign of alpha flipped: flow lands at {} where u = {} not 4/3", f6(xw), f6(u_of(xw, 2)));
    println!("try: rain 1 + x^4, flow from 1.2 lands at {} | RK4 5 steps error {}", f6(moser(1.2, 200, 1.0, 4, 1.0)), sci((moser(4.0 / 3.0, 5, 1.0, 2, 1.0) - 1.0).abs()));
    let a5 = form(&[((0, 2), 1.0), ((1, 3), 1.0), ((0, 1), 5.0)]);
    let g5 = |a: f64, b: f64| [a, b, 3.0 * a * a, 2.0 * b];
    println!("try: b = 5, e2 = {} gap {} | S = q1^3 + q2^2, largest |w| {}", vec_s(&gram_schmidt(&a5)[1]), f6(dev(&a5, &gram_schmidt(&a5))), sci(worst(&w, &g5, &pts)));
    assert!((moser(1.2, 200, 1.0, 4, 1.0) - 1.0).abs() < 1e-9 && (u_of(xw, 2) - 4.0 / 3.0).abs() > 0.5);
    println!("ALL CHECKS PASS");
}
