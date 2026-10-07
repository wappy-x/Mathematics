// The Radon-Nikodym theorem -- the same check as the Python, in Rust, no crates.
// Exact fractions are written by hand: a numerator and denominator in i64.
// Die: fair die P against loaded die Q = (0.1, 0.1, 0.1, 0.1, 0.2, 0.4).
// Road 1: the definition: Q(face) / P(face), then tested on all 64 events.
// Road 2: the Hahn staircase: f(x) is the highest level t with x in the positive
//         set of Q - tP, each positive set found by searching all 64 events.
// Road 3: the proof's recipe: raise g by eps on the positive set of
//         (Q - integral of g) - eps P until nothing is left over.
// L2 check: von Neumann's route, h = dQ/d(P + Q), then h / (1 - h) = Q/P.
// Bus waits, rate 1 (P) against rate 2 (Q): positive sets of Q - tP found by
// maximising over intervals [0, b], and the staircase set against 2e^(-x).
// Failures: a die that never shows 6, and counting measure against length.
// The code checks finite cases and grids; that every sigma-finite pair has a
// density is the proof's work.
#[derive(Clone, Copy, Debug)]
struct Fr(i64, i64); // numerator, denominator > 0
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs().max(1) } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> Fr { let g = gcd(n, d) * d.signum(); Fr(n / g, d / g) }
impl std::ops::Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl std::ops::Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { fr(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl std::ops::Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.0 * o.0, self.1 * o.1) } }
impl std::ops::Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(self.0 * o.1, self.1 * o.0) } }
impl PartialEq for Fr { fn eq(&self, o: &Fr) -> bool { self.0 * o.1 == o.0 * self.1 } }
impl PartialOrd for Fr { fn partial_cmp(&self, o: &Fr) -> Option<std::cmp::Ordering> { (self.0 * o.1).partial_cmp(&(o.0 * self.1)) } }
impl Fr { fn f(self) -> f64 { self.0 as f64 / self.1 as f64 } }

fn events() -> Vec<Vec<usize>> { (0..64).map(|m| (0..6).filter(|i| m >> i & 1 == 1).collect()).collect() }
fn meas(w: &[Fr], a: &[usize]) -> Fr { a.iter().fold(fr(0, 1), |s, &i| s + w[i]) }
fn integ(f: &[Fr], w: &[Fr], a: &[usize]) -> Fr { a.iter().fold(fr(0, 1), |s, &i| s + f[i] * w[i]) }
fn dec(v: &[Fr]) -> String { v.iter().map(|x| format!("{:.4}", x.f())).collect::<Vec<_>>().join(" ") }
fn faces(a: &[usize]) -> String {
    if a.is_empty() { "none".to_string() } else { a.iter().map(|i| (i + 1).to_string()).collect::<Vec<_>>().join(" ") }
}
fn hahn(sig: &[Fr]) -> Vec<usize> { // largest event of greatest signed size
    let ev = events();
    let best = ev.iter().map(|a| meas(sig, a)).fold(fr(-1000, 1), |m, v| if v > m { v } else { m });
    ev.into_iter().filter(|a| meas(sig, a) == best).max_by_key(|a| a.len()).unwrap()
}
fn gold(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // own golden-section search for a maximum
    let r = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..90 {
        let (c, d) = (b - r * (b - a), a + r * (b - a));
        if f(c) > f(d) { b = d } else { a = c }
    }
    (a + b) / 2.0
}
fn bstar(t: f64) -> f64 { gold(&|b: f64| (1.0 - (-2.0 * b).exp()) - t * (1.0 - (-b).exp()), 0.0, 10.0) }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;
    w / 3.0 * (0..=n).map(|i| f(a + i as f64 * w) * if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).sum::<f64>()
}

fn main() {
    let ev = events();
    let all: Vec<usize> = (0..6).collect();
    let p = vec![fr(1, 6); 6];
    let q = vec![fr(1, 10), fr(1, 10), fr(1, 10), fr(1, 10), fr(2, 10), fr(4, 10)];
    let ratio: Vec<Fr> = (0..6).map(|i| q[i] / p[i]).collect(); // road 1
    println!("die, P: {}; Q: {}", dec(&p), dec(&q));
    println!("die, density by ratio Q/P: {}", dec(&ratio));
    let mut stair = vec![fr(0, 1); 6];
    for k in 0..31 { // road 2
        let t = fr(k, 10);
        let h = hahn(&(0..6).map(|i| q[i] - t * p[i]).collect::<Vec<_>>());
        for &i in &h { if t > stair[i] { stair[i] = t } }
        if [3, 6, 9, 12, 18, 24, 27].contains(&k) {
            println!("hahn, positive set of Q - {:.1} P: faces {}; its size {:.4}", t.f(), faces(&h), (meas(&q, &h) - t * meas(&p, &h)).f());
        }
    }
    println!("die, density by Hahn staircase: {}", dec(&stair));
    let (mut g, eps, mut totals, mut rnd) = (vec![fr(0, 1); 6], fr(3, 10), vec![fr(0, 1)], 0); // road 3
    loop {
        let left: Vec<Fr> = (0..6).map(|i| q[i] - g[i] * p[i]).collect(); // nu_0 on each face
        let h = hahn(&(0..6).map(|i| left[i] - eps * p[i]).collect::<Vec<_>>());
        rnd += 1;
        if h.is_empty() {
            println!("recipe, round {}: positive set empty; left over {:.4}", rnd, meas(&left, &all).f());
            break;
        }
        for &i in &h { g[i] = g[i] + eps }
        assert!(ev.iter().all(|a| integ(&g, &p, a) <= meas(&q, a))); // g stays in the class G
        totals.push(integ(&g, &p, &all));
        assert!(totals[totals.len() - 1] > totals[totals.len() - 2]);
        println!("recipe, round {}: raise faces {}; g = {}; total {:.4}", rnd, faces(&h), dec(&g), totals[totals.len() - 1].f());
    }
    let h: Vec<Fr> = (0..6).map(|i| q[i] / (p[i] + q[i])).collect(); // L2 check
    let vn: Vec<Fr> = h.iter().map(|&x| x / (fr(1, 1) - x)).collect();
    println!("L2 route, h = dQ/d(P+Q): {} | h/(1-h): {}", dec(&h), dec(&vn));
    assert!(ratio == stair && stair == g); // three roads agree
    assert!(vn == ratio); // the L2 formula recovers Q/P
    assert!(ev.iter().all(|a| integ(&g, &p, a) == meas(&q, a)));
    assert!(totals[totals.len() - 1] == meas(&q, &all));
    println!("die, event 'even' = faces 2 4 6: Q {:.4}; integral of f against P {:.4}", meas(&q, &[1, 3, 5]).f(), integ(&g, &p, &[1, 3, 5]).f());
    println!("die, all 64 events: integral of f against P equals Q; best total m = {:.4} = Q(whole die)", totals[totals.len() - 1].f());

    let m = vec![fr(1, 5), fr(1, 5), fr(1, 5), fr(1, 5), fr(1, 5), fr(0, 1)]; // never shows a 6
    let st6: Vec<Fr> = (0..6).map(|i| (0..31).map(|k| fr(k, 10))
        .filter(|&t| hahn(&(0..6).map(|j| q[j] - t * m[j]).collect::<Vec<_>>()).contains(&i))
        .fold(fr(0, 1), |a, t| if t > a { t } else { a })).collect();
    let mut st5 = st6.clone();
    st5[5] = fr(0, 1);
    let got = integ(&st5, &m, &all);
    assert!(got + q[5] == meas(&q, &all)); // short by exactly Q(face 6)
    println!("no abs. continuity, five-face die M: staircase {} (face 6 hits the cap 3.0); integral against M {:.4}; missing Q(6) = {:.4} on a set M calls 0", dec(&st6), got.f(), q[5].f());
    let wr: Vec<Fr> = (0..6).map(|i| p[i] / q[i]).collect();
    println!("wrong way round, dP/dQ: {}; its integral against P {:.4}", dec(&wr), integ(&wr, &p, &all).f());
    let v = vec![fr(1, 10), fr(1, 10), fr(2, 10), fr(2, 10), fr(4, 10), fr(0, 1)];
    let mut f1: Vec<Fr> = (0..5).map(|i| v[i] / m[i]).collect();
    f1.push(fr(0, 1));
    let mut f2 = f1.clone();
    f2[5] = fr(7, 1);
    let agree = ev.iter().filter(|a| integ(&f1, &m, a) == meas(&v, a) && meas(&v, a) == integ(&f2, &m, a)).count();
    let mut bump = g.clone();
    bump[5] = bump[5] + fr(1, 10);
    let differ = ev.iter().filter(|a| integ(&bump, &p, a) != meas(&q, a)).count();
    assert_eq!(agree, 64);
    assert_eq!(differ, 32);
    println!("uniqueness, V = {} against M: versions {} and face-6 value 7 agree on {} of 64 events", dec(&v), dec(&f1), agree);
    println!("uniqueness, fair die: raise face 6 of f by 0.1, events that now disagree: {} of 64", differ);
    println!("counting vs length, k grid points each given length 1/k: density against counting, total");
    for k in [10i64, 100, 1000, 1000000] {
        let t = fr(k, 1) * fr(1, k);
        println!("  k = {}: density {:.6}, total {}", k, 1.0 / k as f64, t.0 / t.1);
    }
    println!("counting vs length on [0, 1]: singletons force f = 0; integral of 0 = 0, length 1");

    for t in [0.25f64, 0.5, 1.0, 1.5] {
        let b = bstar(t);
        assert!((b - (2.0 / t).ln()).abs() < 1e-7);
        println!("bus, positive set of Q - {:?} P is [0, b): best b {:.6}; ln(2/t) {:.6}", t, b, (2.0 / t).ln());
    }
    let cuts: Vec<f64> = (1..200).map(|j| bstar(j as f64 / 100.0)).collect();
    for x in [0.25f64, 0.5, 1.0, 2.0] {
        let s = (0..199).filter(|&j| x < cuts[j]).map(|j| (j + 1) as f64 / 100.0).fold(f64::MIN, f64::max);
        assert!(0.0 <= 2.0 * (-x).exp() - s && 2.0 * (-x).exp() - s < 0.01);
        println!("bus, x = {:?}: staircase {:.2}; 2e^(-x) {:.4}", x, s, 2.0 * (-x).exp());
    }
    let qa = simpson(&|x: f64| 2.0 * (-x).exp() * (-x).exp(), 0.0, 1.0, 1000);
    assert!((qa - (1.0 - (-2.0f64).exp())).abs() < 1e-10);
    println!("bus, Q([0, 1]) as integral of 2e^(-x) against P: {:.4}; closed form 1 - e^(-2) {:.4}", qa, 1.0 - (-2.0f64).exp());
    let pieces: Vec<f64> = (0..20).map(|k| simpson(&|x: f64| 2.0 * (-2.0 * x).exp(), k as f64, k as f64 + 1.0, 1000)).collect();
    assert!((0..20).all(|k| (pieces[k] - ((-2.0 * k as f64).exp() - (-2.0 * k as f64 - 2.0).exp())).abs() < 1e-10));
    println!("sigma-finite, rate-2 wait against length, pieces [k, k+1), k = 0..3: {} | 20 pieces glued: {:.6}",
        pieces[..4].iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "), pieces.iter().sum::<f64>());
    println!("chart, loaded die weights: {}; fair die {:.2}", q.iter().map(|x| format!("{:.2}", x.f())).collect::<Vec<_>>().join(" "), p[0].f());
    println!("chart, recipe totals by round 0..8: {}", totals.iter().map(|x| format!("{:.2}", x.f())).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
