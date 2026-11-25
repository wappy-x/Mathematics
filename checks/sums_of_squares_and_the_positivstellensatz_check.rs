// Sums of squares and the Positivstellensatz -- the same check as the Python, in Rust.
// No crates.  Polynomials map exponents [ex, ey] to exact fractions, x > y.  Every
// certificate is multiplied out exactly; Gram matrices are tested for positive
// semidefinite by their principal minors and split into squares.
use std::collections::BTreeMap;

#[derive(Clone, Copy, PartialEq, Debug)] struct Fr { n: i128, d: i128 }                // overflow stops the run
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d).max(1) * d.signum(); Fr { n: n / g, d: d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn fa(a: Fr, b: Fr) -> Fr { fr(m(a.n, b.d).checked_add(m(b.n, a.d)).expect("overflow"), m(a.d, b.d)) }
fn fm(a: Fr, b: Fr) -> Fr { fr(m(a.n, b.n), m(a.d, b.d)) }
fn fdv(a: Fr, b: Fr) -> Fr { fr(m(a.n, b.d), m(a.d, b.n)) }
fn neg(a: Fr) -> Fr { fr(-a.n, a.d) }
fn lt(a: Fr, b: Fr) -> bool { m(a.n, b.d) < m(b.n, a.d) }
fn fs(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn q(n: i128) -> Fr { fr(n, 1) }
type Poly = BTreeMap<[u32; 2], Fr>;
fn p(t: &[(Fr, [u32; 2])]) -> Poly {
    let mut o = Poly::new();
    for &(c, e) in t { let v = fa(*o.get(&e).unwrap_or(&q(0)), c); if v.n == 0 { o.remove(&e); } else { o.insert(e, v); } }
    o
}
fn add(fs_: &[&Poly]) -> Poly { p(&fs_.iter().flat_map(|f| f.iter().map(|(&e, &c)| (c, e))).collect::<Vec<_>>()) }
fn mul(fs_: &[&Poly]) -> Poly {
    fs_.iter().fold(k(q(1)), |o, g| p(&o.iter().flat_map(|(a, &c)| g.iter().map(move |(b, &e)| (fm(c, e), [a[0] + b[0], a[1] + b[1]]))).collect::<Vec<_>>()))
}
fn k(c: Fr) -> Poly { p(&[(c, [0, 0])]) }
fn mono(e: [u32; 2]) -> Poly { p(&[(q(1), e)]) }
fn show(f: &Poly, v: &str) -> String {
    let mut ks: Vec<&[u32; 2]> = f.keys().collect();
    ks.sort_by_key(|e| std::cmp::Reverse((e[0] + e[1], e[0], e[1])));
    let mut s = String::new();
    for e in ks {
        let c = f[e];
        let mo: String = v.chars().zip(e.iter()).filter(|(_, &x)| x > 0)
            .map(|(n, &x)| if x > 1 { format!("{}^{}", n, x) } else { n.to_string() }).collect();
        let a = fr(c.n.abs(), c.d);
        let body = if mo.is_empty() { fs(a) } else if a == q(1) { mo } else if a.d == 1 { format!("{}{}", fs(a), mo) } else { format!("({}){}", fs(a), mo) };
        s += &if s.is_empty() { format!("{}{}", if c.n < 0 { "-" } else { "" }, body) } else { format!("{}{}", if c.n < 0 { " - " } else { " + " }, body) };
    }
    if s.is_empty() { "0".into() } else { s }
}
type Mat = Vec<Vec<Fr>>;
fn det(a: &Mat) -> Fr {
    if a.len() == 1 { return a[0][0] }
    (0..a.len()).fold(q(0), |acc, j| { let t = fm(a[0][j], det(&a[1..].iter().map(|r| r.iter().enumerate().filter(|&(c, _)| c != j).map(|(_, &x)| x).collect()).collect()));
        fa(acc, if j % 2 == 0 { t } else { neg(t) }) })
}
fn minors(a: &Mat) -> Vec<Fr> {
    let n = a.len();
    (1..(1usize << n)).map(|b| (0..n).filter(|i| b >> i & 1 == 1).collect::<Vec<_>>()).collect::<Vec<_>>().iter().map(|s| det(&s.iter().map(|&i| s.iter().map(|&j| a[i][j]).collect()).collect())).collect()
}
fn least(v: &[Fr]) -> Fr { v.iter().copied().fold(v[0], |a, b| if lt(b, a) { b } else { a }) }
fn psd(a: &Mat) -> bool { !lt(least(&minors(a)), q(0)) }
fn squares(a0: &Mat, z: &[Poly]) -> Vec<(Fr, Poly)> {
    let (mut a, mut out) = (a0.clone(), Vec::new());
    for pv in (0..a.len()).rev() {
        let d = a[pv][pv];
        if d.n == 0 { continue }
        let l: Vec<Fr> = (0..=pv).map(|i| fdv(a[i][pv], d)).collect();
        out.push((d, (0..=pv).fold(Poly::new(), |acc, i| add(&[&acc, &mul(&[&k(l[i]), &z[i]])]))));
        for i in 0..=pv { for j in 0..=pv { a[i][j] = fa(a[i][j], neg(fm(d, fm(l[i], l[j])))) } }
    }
    out
}
fn sos(parts: &[(Fr, Poly)]) -> Poly { parts.iter().fold(Poly::new(), |acc, (d, g)| add(&[&acc, &mul(&[&k(*d), g, g])])) }
fn ev(f: &Poly, x: Fr, y: Fr) -> Fr {
    let pw = |b: Fr, e: u32| (0..e).fold(q(1), |a, _| fm(a, b));
    f.iter().fold(q(0), |acc, (e, &c)| fa(acc, fm(c, fm(pw(x, e[0]), pw(y, e[1])))))
}
fn says(parts: &[(Fr, Poly)], v: &str) -> String {
    let w: Vec<String> = parts.iter().map(|(d, g)| if *g == k(q(1)) { fs(*d) } else {
        format!("{}({})^2", if *d == q(1) { String::new() } else if d.d == 1 { fs(*d) } else { format!("({})", fs(*d)) }, show(g, v)) }).collect();
    w.join(" + ").replace("+ -", "- ")
}
fn matstr(a: &Mat) -> String { format!("[{}]", a.iter().map(|r| format!("[{}]", r.iter().map(|&x| fs(x)).collect::<Vec<_>>().join(", "))).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (x, y, one) = (mono([1, 0]), mono([0, 1]), k(q(1)));
    let pp = p(&[(q(1), [4, 0]), (q(4), [3, 0]), (q(6), [2, 0]), (q(4), [1, 0]), (q(5), [0, 0])]);
    println!("p = {}", show(&pp, "xy"));
    let x1 = add(&[&x, &one]);  let s1 = add(&[&mul(&[&x1, &x1, &x1, &x1]), &k(q(4))]);
    println!("road 1, ((x + 1)^2)^2 + 2^2 expands to {}", show(&s1, "xy"));
    let z = vec![one.clone(), x.clone(), mul(&[&x, &x])];
    let cons: Vec<String> = (0..5u32).map(|d| format!("x^{}: {} = {}", d, (0..3u32).flat_map(|i| (0..3u32).map(move |j| (i, j)))
        .filter(|&(i, j)| i + j == d).map(|(i, j)| format!("Q{}{}", i, j)).collect::<Vec<_>>().join(" + "), fs(*pp.get(&[d, 0]).unwrap_or(&q(0))))).collect();
    println!("road 2, Gram matrix on (1, x, x^2), coefficients matched: {}", cons.join(" | "));
    let gm = |t: Fr, g: Fr| -> Mat { vec![vec![fa(q(5), neg(g)), q(2), t], vec![q(2), fa(q(6), fm(q(-2), t)), q(2)], vec![t, q(2), q(1)]] };
    for t in [fr(-3, 2), q(-1), q(0), q(1), q(2)] { let a = gm(t, q(0));
        println!("t = {}: Q = {}, least principal minor {}, det {}, PSD {}", fs(t), matstr(&a), fs(least(&minors(&a))), fs(det(&a)), yn(psd(&a)));
    }
    let grid: Vec<Fr> = (-24..=24).map(|j| fr(j, 8)).collect();
    let ok: Vec<Fr> = grid.iter().copied().filter(|&t| psd(&gm(t, q(0)))).collect();
    println!("road 2, PSD on the grid t = j/8, -3 <= t <= 3: from {} to {}, {} points", fs(ok[0]), fs(ok[ok.len() - 1]), ok.len());
    let spl = |t: Fr| squares(&gm(t, q(0)), &z);
    for t in [q(1), q(0), q(-1)] { println!("t = {}: p = {}", fs(t), says(&spl(t), "xy")) }
    let (f1, f2) = (add(&[&mul(&[&x, &x]), &one]), add(&[&mul(&[&x, &x]), &mul(&[&k(q(4)), &x]), &k(q(5))]));
    println!("road 3, (x^2 + 1)(x^2 + 4x + 5) = {}", show(&mul(&[&f1, &f2]), "xy"));
    let (a, b, c, d) = (x.clone(), one.clone(), add(&[&x, &k(q(2))]), one.clone());
    let mk = |sg: i128, u: &Poly, w: &Poly, u2: &Poly, w2: &Poly| add(&[&mul(&[u, w]), &mul(&[&k(q(sg)), u2, w2])]);
    let plus = [mk(1, &a, &c, &b, &d), mk(-1, &a, &d, &b, &c)];
    let minus = [mk(-1, &a, &c, &b, &d), mk(1, &a, &d, &b, &c)];
    println!("road 3, u = x, v = x + 2: (uv + 1)^2 + (u - v)^2 = ({})^2 + ({})^2; (uv - 1)^2 + (u + v)^2 = ({})^2 + ({})^2",
             show(&plus[0], "xy"), show(&plus[1], "xy"), show(&minus[0], "xy"), show(&minus[1], "xy"));
    let vals: Vec<(Fr, Fr)> = (-500..=500).map(|j| (ev(&pp, fr(j, 100), q(0)), fr(j, 100))).collect();
    let vmin = vals.iter().copied().fold(vals[0], |a, b| if lt(b.0, a.0) { b } else { a });
    println!("road 4, p at x = j/100 for -5 <= x <= 5: least value {} at x = {}", fs(vmin.0), fs(vmin.1));
    let best = (12..=20).map(|j| fr(j, 4)).filter(|&g| grid.iter().any(|&t| psd(&gm(t, g)))).last().unwrap();
    let p4 = squares(&gm(q(1), q(4)), &z);
    println!("SOS lower bound: largest gamma = j/4 with p - gamma a sum of squares: {}; p - 4 = {}; p(-1) - 17/4 = {}",
             fs(best), says(&p4, "xy"), fs(fa(ev(&pp, q(-1), q(0)), fr(-17, 4))));
    let mm = p(&[(q(1), [4, 2]), (q(1), [2, 4]), (q(-3), [2, 2]), (q(1), [0, 0])]);
    println!("M = {}; AM-GM at (1, 1): terms x^4y^2, x^2y^4, 1 = 1, 1, 1; mean 1, geometric mean 1, M = {}", show(&mm, "xy"), fs(ev(&mm, q(1), q(1))));
    let mg: Vec<Fr> = (-40..=40).flat_map(|i| (-40..=40).map(move |j| (i, j))).map(|(i, j)| ev(&mm, fr(i, 20), fr(j, 20))).collect();
    let low = least(&mg);
    println!("M on the grid x, y = j/20 in [-2, 2]: least value {}, at {} points, negative at {}", fs(low),
             mg.iter().filter(|&&v| v == low).count(), mg.iter().filter(|&&v| lt(v, q(0))).count());
    let inside = |u: u32, v: u32| v <= 2 * u && u <= 2 * v && u + v <= 6;
    let half: Vec<[u32; 2]> = (0..4).flat_map(|i| (0..4).map(move |j| [i, j])).filter(|e| inside(2 * e[0], 2 * e[1])).collect();
    println!("Newton triangle (0, 0), (4, 2), (2, 4) holds (2, 2): {}; half of it holds the monomials {}", yn(inside(2, 2)),
             half.iter().map(|&e| show(&mono(e), "xy")).collect::<Vec<_>>().join(", "));
    let pairs: Vec<([u32; 2], [u32; 2])> = half.iter().flat_map(|&u| half.iter().map(move |&w| (u, w))).filter(|(u, w)| [u[0] + w[0], u[1] + w[1]] == [2, 2]).collect();
    let sm = |a: [u32; 2], b: [u32; 2]| [a[0] + b[0], a[1] + b[1]];     // Gram entry (a, b) multiplies the monomials a and b
    let gmm: Mat = half.iter().map(|&a| half.iter().map(|&b| fdv(*mm.get(&sm(a, b)).unwrap_or(&q(0)), q(half.iter().flat_map(|&c| half.iter().map(move |&d| sm(c, d))).filter(|&e| e == sm(a, b)).count() as i128))).collect()).collect();
    let zgz = (0..half.len()).flat_map(|i| (0..half.len()).map(move |j| (i, j))).fold(Poly::new(), |acc, (i, j)| add(&[&acc, &mul(&[&k(gmm[i][j]), &mono(half[i]), &mono(half[j])])]));
    println!("products giving x^2y^2: {}, so the Gram diagonal entry for xy must be {}, for M - gamma with any gamma too; the Gram matrix this forces on those monomials gives back M: {}, PSD: {}",
             pairs.iter().map(|&(u, w)| format!("{} times {}", show(&mono(u), "xy"), show(&mono(w), "xy"))).collect::<Vec<_>>().join(", "), fs(gmm[1][1]), yn(zgz == mm), yn(psd(&gmm)));
    let r2 = add(&[&mul(&[&x, &x]), &mul(&[&y, &y])]);
    let (r1, rm2, dxy) = (add(&[&r2, &one]), add(&[&r2, &k(q(-2))]), add(&[&mul(&[&x, &x]), &mul(&[&k(q(-1)), &y, &y])]));
    let art = add(&[&mul(&[&x, &x, &y, &y, &r1, &rm2, &rm2]), &mul(&[&dxy, &dxy])]);
    let artd = add(&[&mul(&[&r2, &r2, &mm]), &mul(&[&k(q(-1)), &art])]);
    println!("Artin: (x^2 + y^2)^2 M - [x^2y^2(x^2 + y^2 + 1)(x^2 + y^2 - 2)^2 + (x^2 - y^2)^2] = {}", show(&artd, "xy"));
    let (h, g) = (add(&[&r2, &k(q(-1))]), add(&[&x, &k(q(-2))]));
    let cert = add(&[&mul(&[&k(fr(1, 3)), &add(&[&mul(&[&g, &g]), &mul(&[&y, &y])])]), &mul(&[&k(fr(4, 3)), &g]), &mul(&[&k(fr(-1, 3)), &h])]);
    println!("system {} = 0, {} >= 0; road 1, (1/3)((x - 2)^2 + y^2) + (4/3)(x - 2) - (1/3)(x^2 + y^2 - 1) = {}", show(&h, "xy"), show(&g, "xy"), show(&cert, "xy"));
    let cmw = |c: Fr, s: Fr, w: Fr| -> Mat { vec![vec![fa(fm(w, c), neg(fa(s, q(1)))), fm(fr(-1, 2), c), q(0)], vec![fm(fr(-1, 2), c), s, q(0)], vec![q(0), q(0), s]] };   // wall at x >= w
    let feas = |w: Fr| -> Vec<(Fr, Fr)> { (0..=24).flat_map(|i| (0..=72).map(move |j| (fr(i, 24), fr(j, 24)))).filter(|&(s, c)| psd(&cmw(c, s, w))).collect() };
    let (s0, c0) = feas(q(2))[0];
    let sig = squares(&cmw(c0, s0, q(2)), &[one.clone(), x.clone(), y.clone()]);
    println!("road 2, Gram search on (1, x, y), s and c in steps of 1/24: first feasible s = {}, c = {}, sigma0 = {}", fs(s0), fs(c0), says(&sig, "xy"));
    let circ: Vec<(Fr, Fr)> = (-30..=30).map(|j| fr(j, 10)).map(|u| { let w = fa(q(1), fm(u, u)); (fdv(fa(q(1), neg(fm(u, u))), w), fdv(fm(q(2), u), w)) }).collect();
    let xmax = least(&circ.iter().map(|&(cx, _)| neg(cx)).collect::<Vec<_>>());
    println!("road 3, circle points ((1 - u^2)/(1 + u^2), 2u/(1 + u^2)), u = j/10: largest x = {}, all on the circle: {}", fs(neg(xmax)),
             yn(circ.iter().all(|&(cx, cy)| ev(&h, cx, cy).n == 0)));
    let (f_1, f_2) = (add(&[&mul(&[&x, &x]), &mul(&[&y, &y]), &k(q(-9))]), add(&[&mul(&[&x, &x]), &mul(&[&k(q(-8)), &x]), &mul(&[&y, &y]), &k(q(12))]));
    let in_i = add(&[&f_1, &mul(&[&k(fr(-1, 8)), &add(&[&x, &k(fr(21, 8))]), &add(&[&f_1, &mul(&[&k(q(-1)), &f_2])])])]);
    let lift = add(&[&y, &k(q(-2))]);  let arm = mul(&[&k(fr(64, 121)), &add(&[&mul(&[&lift, &lift]), &mul(&[&k(q(4)), &lift]), &mul(&[&k(q(-1)), &in_i])])]);
    println!("arm, 3 m and 2 m links, target 4 m: {} = 0, {} = 0; in the ideal: {}; b = +-{:.6} m", show(&f_1, "ab"), show(&f_2, "ab"), show(&in_i, "ab"), (135f64 / 64.0).sqrt());
    println!("arm, elbow at least 2 m up: (64/121)((b - 2)^2 + 4(b - 2) - ({})) = {}", show(&in_i, "ab"), show(&arm, "ab"));
    let s2 = spl(q(2));
    println!("break, t = 2: p = {}", says(&s2, "xy"));
    let cx = add(&[&h, &mul(&[&k(q(-1)), &add(&[&x, &k(q(2))]), &g])]);
    let rc = add(&[&mul(&[&k(fr(1, 3)), &y, &y]), &mul(&[&k(fr(-1, 3)), &cx])]);
    println!("break, over C: x = 2, y^2 = {}; real certificate (1/3)y^2 - (1/3)({}) = {}", fs(neg(ev(&h, q(2), q(0)))), show(&cx, "xy"), show(&rc, "xy"));
    let (s3, c3) = feas(q(3))[0];  let g4: Vec<String> = grid.iter().filter(|&&t| psd(&gm(t, q(4)))).map(|&t| fs(t)).collect();
    println!("try: t = 3 gives least principal minor {}; gamma = 4 leaves t = {}; wall at x >= 3: first s = {}, c = {}; wall at x >= 1: {} feasible pairs",
             fs(least(&minors(&gm(q(3), q(0))))), g4.join(", "), fs(s3), fs(c3), feas(q(1)).len());
    println!("figure, circle centre (0, 0) radius 1; wall x = 2; nearest circle point (1, 0); gap 1");
    assert!(s1 == pp && sos(&spl(q(1))) == pp && sos(&spl(q(0))) == pp && sos(&spl(q(-1))) == pp);
    assert!(mul(&[&f1, &f2]) == pp && add(&[&mul(&[&plus[0], &plus[0]]), &mul(&[&plus[1], &plus[1]])]) == pp && add(&[&mul(&[&minus[0], &minus[0]]), &mul(&[&minus[1], &minus[1]])]) == pp);
    assert!(ok[0] == q(-1) && ok[ok.len() - 1] == q(1) && !psd(&gm(fr(9, 8), q(0))) && det(&gm(q(0), q(0))) == q(6));
    assert!(vmin == (q(4), q(-1)) && best == q(4) && sos(&p4) == add(&[&pp, &k(q(-4))]));
    assert!(ev(&mm, q(1), q(1)).n == 0 && low.n == 0 && !mg.iter().any(|&v| lt(v, q(0))) && pairs.len() == 1 && zgz == mm && gmm[1][1] == q(-3) && !psd(&gmm));
    assert!(artd.is_empty() && cert == k(q(-1)) && arm == k(q(-1)));
    assert!((s0, c0) == (fr(1, 3), fr(4, 3)) && sos(&sig) == add(&[&cert, &mul(&[&k(fr(-4, 3)), &g]), &mul(&[&k(fr(1, 3)), &h])]));
    assert!((s3, c3) == (fr(1, 8), fr(3, 4)) && feas(q(1)).is_empty() && neg(xmax) == q(1) && in_i == add(&[&mul(&[&y, &y]), &k(fr(-135, 64))]) && s2.iter().any(|(d, _)| d.n < 0));
    println!("ALL CHECKS PASS");
}
