// Intersection numbers on the plane blown up at one point -- the same check as the Python, in Rust.  std only.
// Road 1: count meeting points of real curves on the blow-up X, inside P^2 x P^1 over F_7 and F_11.
// Road 2: the winding of the gluing rule of O(E) along E, the degree of E's normal line bundle.
// Road 3: Riemann-Roch against a count of plane forms that vanish to a given order at p.
type Pt = ([i64; 3], [i64; 2]);

fn p2(q: i64) -> Vec<[i64; 3]> {
    let mut v = vec![];
    for y in 0..q { for z in 0..q { v.push([1, y, z]); } }
    for z in 0..q { v.push([0, 1, z]); }
    v.push([0, 0, 1]);
    v
}
fn p1(q: i64) -> Vec<[i64; 2]> {
    let mut v: Vec<[i64; 2]> = (0..q).map(|t| [1, t]).collect();
    v.push([0, 1]);
    v
}
fn blowup(q: i64) -> Vec<Pt> {
    let mut x = vec![];
    for p in p2(q) { for d in p1(q) { if (p[0] * d[1] - p[1] * d[0]).rem_euclid(q) == 0 { x.push((p, d)); } } }
    x
}
fn on(name: &str, (p, d): &Pt, q: i64) -> bool {
    let r = match name {
        "E" => return p[0] % q == 0 && p[1] % q == 0,
        "H1" => p[2],
        "H2" => p[0] + p[1] - p[2],
        "H3" => p[0] - 3 * p[2],
        "L1" => d[1],
        "L2" => d[1] - d[0],
        _ => (d[1] * d[1] - d[0] * d[0]) * p[2] - p[0] * d[0] * d[0],
    };
    r.rem_euclid(q) == 0
}
fn dot(a: &[i64], b: &[i64], m: &[Vec<i64>]) -> i64 {
    let mut s = 0;
    for i in 0..a.len() { for j in 0..b.len() { s += a[i] * m[i][j] * b[j]; } }
    s
}
fn genus(c: &[i64], m: &[Vec<i64>], k: &[i64]) -> (i64, f64) {
    let t = dot(c, c, m) + dot(k, c, m);
    (t, (t + 2) as f64 / 2.0)
}

fn main() {
    let pairs = [("H1", "H2"), ("H1", "E"), ("L1", "E"), ("L1", "L2"), ("C", "E"), ("C", "L1"), ("C", "H3")];
    let mut all: Vec<Vec<usize>> = vec![];
    for q in [7i64, 11] {
        let x = blowup(q);
        let cs: Vec<usize> = pairs.iter().map(|(a, b)| x.iter().filter(|pt| on(a, pt, q) && on(b, pt, q)).count()).collect();
        let txt: Vec<String> = pairs.iter().zip(&cs).map(|((a, b), v)| format!("{}.{} {}", a, b, v)).collect();
        println!("over F_{}: X has {} points = ({} + 1)^2; meeting points {}", q, x.len(), q, txt.join(", "));
        assert!(x.len() as i64 == (q + 1) * (q + 1) && x.len() == p2(q).len() - 1 + p1(q).len());
        all.push(cs);
    }
    assert!(all[0] == all[1]);
    let c: Vec<i64> = all[0].iter().map(|&v| v as i64).collect();
    let (hh, he) = (c[0], c[1]);
    let e2_one = he - c[2];
    let e2_two = c[3] - hh + 2 * he;
    println!("road 1: H^2 = {}, H.E = {}; (H - E).E = {} gives E^2 = {}; (H - E)^2 = {} gives E^2 = {}", hh, he, c[2], e2_one, c[3], e2_two);
    let m = vec![vec![hh, he], vec![he, e2_one]];
    let (h, e) = ([1i64, 0], [0i64, 1]);
    println!("Gram matrix in the basis H, E: {:?}, signature (1, 1)", m);
    let cubic = [3i64, -2];
    let pred = vec![dot(&cubic, &e, &m), dot(&cubic, &[1, -1], &m), dot(&cubic, &h, &m)];
    let counted = vec![c[4], c[5], c[6]];
    println!("nodal cubic 3H - 2E: predicted .E, .(H - E), .H = {:?}; counted {:?}", pred, counted);
    assert!(e2_one == -1 && e2_two == -1 && pred == counted);

    let (n, mut wind) = (360, 0.0f64);
    let pi = std::f64::consts::PI;
    for k in 0..n {
        let (a0, a1) = (2.0 * pi * k as f64 / n as f64, 2.0 * pi * (k + 1) as f64 / n as f64);
        let inv = |a: f64| { let (c, s) = (a.cos(), a.sin()); let n2 = c * c + s * s; (c / n2, -s / n2) }; // 1/t
        let ((x0, y0), (x1, y1)) = (inv(a0), inv(a1));
        let n0 = x0 * x0 + y0 * y0;
        let (re, im) = ((x1 * x0 + y1 * y0) / n0, (y1 * x0 - x1 * y0) / n0); // g1 / g0
        wind += im.atan2(re);
    }
    let w = wind / (2.0 * pi);
    let deg = w.round() as i64;
    println!("road 2: gluing rule 1/t once round |t| = 1 winds {:.6} times, so deg O(E)|E = E^2 = {}", w, deg);
    assert!((w - deg as f64).abs() < 1e-9 && deg == m[1][1]);

    let kk = [-3i64, 1];
    let (k2, euler) = (dot(&kk, &kk, &m), 3 - 1 + 2);
    println!("K = -3H + E: K^2 = 9 - 1 = {}; e(X) = 3 - 1 + 2 = {}; Noether K^2 + e = {} = 12 x chi(O_X), chi(O_X) = 1", k2, euler, k2 + euler);
    assert!(k2 + euler == 12);
    println!("adjunction 2g - 2 = C^2 + K.C:");
    let list: [(&str, [i64; 2]); 6] = [("E", [0, 1]), ("line H", [1, 0]), ("line through p, H - E", [1, -1]),
        ("conic through p, 2H - E", [2, -1]), ("nodal cubic, 3H - 2E", [3, -2]), ("cubic missing p, 3H", [3, 0])];
    for (name, cc) in list.iter() {
        let (t, g) = genus(cc, &m, &kk);
        println!("  {}: C^2 = {}, K.C = {}, 2g - 2 = {}, g = {}", name, dot(cc, cc, &m), dot(&kk, cc, &m), t, g);
        assert!(g == g.trunc() && g >= 0.0);
    }
    assert!(genus(&[0, 1], &m, &kk).1 == 0.0 && genus(&[3, -2], &m, &kk).1 == 0.0 && genus(&[3, 0], &m, &kk).1 == 1.0);

    let mut tested = 0;
    for a in 0..7i64 {
        for b in 0..a + 2 {
            let mut forms = 0;
            for i in 0..=a { for j in 0..=(a - i) { if i + j >= b { forms += 1; } } }
            let dd = [a, -b];
            let top = dot(&dd, &dd, &m) - dot(&kk, &dd, &m);
            assert!(forms == 1 + top / 2 && top % 2 == 0);
            tested += 1;
        }
    }
    let conic = [2i64, -1];
    println!("road 3: forms vanishing to order b at p = 1 + (D^2 - K.D)/2 for all {} classes aH - bE, 0 <= a <= 6, b <= a + 1; conics through p: {}",
        tested, 1 + (dot(&conic, &conic, &m) - dot(&kk, &conic, &m)) / 2);

    let amp = [3i64, -1];
    let mut boxx = vec![];
    for x in -6..7i64 { for y in -6..7i64 { if (x, y) != (0, 0) { boxx.push([x, y]); } } }
    let perp: Vec<[i64; 2]> = boxx.iter().cloned().filter(|d| dot(&amp, d, &m) == 0).collect();
    let ptup: Vec<(i64, i64)> = perp.iter().map(|d| (d[0], d[1])).collect();
    let sq: Vec<i64> = perp.iter().map(|d| dot(d, d, &m)).collect();
    let atxt = format!("{}H {} {}E", amp[0], if amp[1] < 0 { "-" } else { "+" }, if amp[1].abs() == 1 { String::new() } else { amp[1].abs().to_string() });
    println!("Hodge index: A = {}, A^2 = {}; classes in the box with A.D = 0: {:?}, squares {:?}", atxt, dot(&amp, &amp, &m), ptup, sq);
    assert!(dot(&amp, &amp, &m) > 0 && sq.iter().all(|&s| s < 0));
    assert!(boxx.iter().all(|d| dot(&amp, d, &m).pow(2) >= dot(&amp, &amp, &m) * dot(d, d, &m)));

    let m6: Vec<Vec<i64>> = (0..7).map(|i| (0..7).map(|j| if i == j && i == 0 { 1 } else if i == j { -1 } else { 0 }).collect()).collect();
    let k6 = [-3i64, 1, 1, 1, 1, 1, 1];
    let mut ex = 0;
    for idx in 0..4 * 5i64.pow(6) {
        let mut cl = [idx / 5i64.pow(6), 0, 0, 0, 0, 0, 0];
        let mut r = idx % 5i64.pow(6);
        for i in (1..7).rev() { cl[i] = r % 5 - 2; r /= 5; }
        if dot(&cl, &cl, &m6) == -1 && dot(&k6, &cl, &m6) == -1 { ex += 1; }
    }
    println!("six points (the cubic surface): K^2 = {}, classes with C^2 = -1 and K.C = -1: {}", dot(&k6, &k6, &m6), ex);
    assert!(dot(&k6, &k6, &m6) == 3 && ex == 27);

    let (m2, k2b) = (vec![vec![1i64, 0, 0], vec![0, -1, 0], vec![0, 0, -1]], [-3i64, 1, 1]);
    let cm = [0i64, 1, -1];
    let kp2 = dot(&[-3], &[-3], &[vec![1]]);
    println!("contract E: K^2 goes from {} to {}, and K^2 of P^2 = (-3)^2 = {}", k2, k2 + 1, kp2);
    assert!(dot(&cm, &cm, &m2) == -2 && dot(&k2b, &cm, &m2) == 0 && k2 + 1 == kp2);
    let mbad = vec![vec![1i64, 0], vec![0, 1]];
    println!("mistake 1, E^2 = +1 like a line: (H - E).E = {}, a negative count; Noether {}, not 12", dot(&[1, -1], &e, &mbad), dot(&kk, &kk, &mbad) + euler);
    let t2 = dot(&e, &e, &m) + dot(&[-3, 0], &e, &m);
    println!("mistake 2, K = -3H (no E): 2g - 2 for E = {}, so g = {}", t2, (t2 + 2) as f64 / 2.0);
    println!("mistake 3, a line through p kept as H: two of them meet {} time by H^2, counted after the blow-up {}", hh, c[3]);
    println!("mistake 4, blow up a point of E too and contract E1 - E2: square {}, K.C = {}, g = {}, but Castelnuovo needs -1; the result is a cone point",
        dot(&cm, &cm, &m2), dot(&k2b, &cm, &m2), genus(&cm, &m2, &k2b).1);
    let fib: Vec<String> = [-1i64, 0, 1].iter().map(|t| (490 + 70 * t).to_string()).collect();
    println!("figure, p (160, 150); lines through p at slopes t = -1, 0, 1 end at (70, 60)-(250, 240), (70, 150)-(250, 150), (70, 240)-(250, 60); E at y = 150; fibres H - E at x = {}", fib.join(", "));
    println!("ALL CHECKS PASS");
}
