// Integrable functions -- the same check as the Python, in Rust, no crates.
// River bed against a 0.5 m marker: h(x) = 4x(1 - x) - 0.5 metres, 0 <= x <= 1 km.
// Road 1: exact algebra on numbers p + q*sqrt(2), p and q fractions kept by hand
//   (i128 numerator over denominator), using the antiderivative and the crossings.
// Road 2: Lebesgue's road, chopping the depth axis: lower simple functions built
//   from the lengths of the level sets {h >= t}, which are square roots.
// Road 3: Riemann's road, chopping the x axis: midpoint sums on 2^16 cells.
// The code checks these functions and finite stages; the theorems are the proof's work.
use std::fmt;

#[derive(Clone, Copy, PartialEq)]
struct Rat { n: i128, d: i128 }             // n/d with d > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Rat { let g = gcd(n, d).max(1) * d.signum(); Rat { n: n / g, d: d / g } }
impl Rat {
    fn add(self, o: Rat) -> Rat { q(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn sub(self, o: Rat) -> Rat { q(self.n * o.d - o.n * self.d, self.d * o.d) }
    fn mul(self, o: Rat) -> Rat { q(self.n * o.n, self.d * o.d) }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
    fn pos(self) -> Rat { if self.n > 0 { self } else { q(0, 1) } }
    fn abs(self) -> Rat { q(self.n.abs(), self.d) }
    fn le(self, o: Rat) -> bool { self.n * o.d <= o.n * self.d }
}
impl fmt::Display for Rat {
    fn fmt(&self, w: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(w, "{}", self.n) } else { write!(w, "{}/{}", self.n, self.d) } }
}
#[derive(Clone, Copy)]
struct R2 { p: Rat, q: Rat }                  // p + q*sqrt(2), kept exact
fn r2(p: Rat, qq: Rat) -> R2 { R2 { p, q: qq } }   fn c(p: Rat) -> R2 { r2(p, q(0, 1)) }
impl R2 {
    fn add(self, o: R2) -> R2 { r2(self.p.add(o.p), self.q.add(o.q)) }
    fn sub(self, o: R2) -> R2 { r2(self.p.sub(o.p), self.q.sub(o.q)) }
    fn mul(self, o: R2) -> R2 { r2(self.p.mul(o.p).add(q(2, 1).mul(self.q).mul(o.q)), self.p.mul(o.q).add(self.q.mul(o.p))) }
    fn f(self) -> f64 { self.p.f() + self.q.f() * 2f64.sqrt() }
    fn s(self) -> String { format!("{} + ({})sqrt2", self.p, self.q) }
}
fn big_h(x: R2) -> R2 {                       // antiderivative of h: 2x^2 - (4/3)x^3 - x/2
    let x2 = x.mul(x);
    c(q(2, 1)).mul(x2).sub(c(q(4, 3)).mul(x2).mul(x)).sub(c(q(1, 2)).mul(x))
}
fn join(v: &[Rat]) -> String { v.iter().map(|r| r.to_string()).collect::<Vec<_>>().join(", ") }
fn mean(v: &[Rat]) -> Rat { v.iter().fold(q(0, 1), |s, &r| s.add(q(1, 4).mul(r))) }
fn pos(v: &[Rat]) -> Rat { mean(&v.iter().map(|r| r.pos()).collect::<Vec<_>>()) }
fn neg(v: &[Rat]) -> Rat { mean(&v.iter().map(|r| q(-r.n, r.d).pos()).collect::<Vec<_>>()) }
fn absm(v: &[Rat]) -> Rat { mean(&v.iter().map(|r| r.abs()).collect::<Vec<_>>()) }

fn main() {
    println!("four reaches of 250 m, midpoint depths | d | h = d - 0.5");
    let d4 = [q(7, 16), q(15, 16), q(15, 16), q(7, 16)];
    let h4: Vec<Rat> = d4.iter().map(|v| v.sub(q(1, 2))).collect();
    println!("four reaches: d = {} | h = {}", join(&d4), join(&h4));
    println!("four reaches: h+ {}, h- {}, net {}, |h| {}, d {}, d - 1/2 {}", pos(&h4), neg(&h4),
             pos(&h4).sub(neg(&h4)), absm(&h4), mean(&d4), mean(&d4).sub(q(1, 2)));
    assert!(pos(&h4).sub(neg(&h4)) == mean(&d4).sub(q(1, 2)) && mean(&d4).sub(q(1, 2)) == q(3, 16));
    for a in -3..=3i128 {
        for b in -3..=3i128 {
            let z: Vec<Rat> = (0..4).map(|j| q(a, 1).mul(d4[j]).add(q(b, 1).mul(h4[j]))).collect();
            assert!(pos(&z).sub(neg(&z)) == q(a, 1).mul(mean(&d4)).add(q(b, 1).mul(mean(&h4))));
            assert!(mean(&z).abs().le(absm(&z)));
        }
    }
    println!("four reaches: 49 pairs (a, b), a*d + b*h: parts difference equals a*int d + b*int h");

    let (a, b, zero, one) = (r2(q(1, 2), q(-1, 4)), r2(q(1, 2), q(1, 4)), c(q(0, 1)), c(q(1, 1)));
    let p = big_h(b).sub(big_h(a));                             // h+ lives between the crossings
    let n = zero.sub(big_h(a).sub(big_h(zero)).add(big_h(one).sub(big_h(b)))); // h- lives outside them
    let by_d = c(q(2, 1).sub(q(4, 3))).sub(c(q(1, 2)));         // linearity: int d - int 0.5
    assert!(p.p == q(0, 1) && p.q == q(1, 6) && n.p == q(-1, 6) && p.sub(n).q == q(0, 1));
    assert!(p.sub(n).p == by_d.p);
    println!("crossings: x = {:.10} and {:.10} km; channel {:.10} km, shoals together {:.10} km",
             a.f(), b.f(), b.f() - a.f(), 1.0 - (b.f() - a.f()));
    println!("exact: int h+ = {} = {:.10}", p.s(), p.f());
    println!("exact: int h- = {} = {:.10}", n.s(), n.f());
    println!("exact: int h = {} = {:.10}; int d - 0.5 = {}; int |h| = {} = {:.10}",
             p.sub(n).s(), p.sub(n).f(), by_d.p, p.add(n).s(), p.add(n).f());
    let m3: Vec<f64> = [p, n, p.add(n), p.sub(n)].iter().map(|v| 1000.0 * v.f()).collect();
    println!("per metre of width, m^3: fill {:.1}, dredge {:.1}, moved {:.1}, net {:.1}", m3[0], m3[1], m3[2], m3[3]);

    println!("Lebesgue lower sums, levels 2^-n: n | h+ | gap | h- | gap");
    for nn in [2, 4, 8, 12, 16, 20] {
        let step = 2f64.powi(-nn);
        let (mut sp, mut sn, mut k) = (0.0f64, 0.0f64, 1.0f64);
        while k * step <= 0.5 {
            sp += step * (0.5 - k * step).sqrt();          // length of {h >= t} is sqrt(0.5 - t)
            sn += step * (1.0 - (0.5 + k * step).sqrt());  // length of {h <= -t} is 1 - sqrt(0.5 + t)
            k += 1.0;
        }
        let (gp, gn) = (p.f() - sp, n.f() - sn);
        assert!(0.0 <= gp && gp <= step * 2f64.sqrt() / 2.0 && 0.0 <= gn && gn <= step * (1.0 - 2f64.sqrt() / 2.0));
        println!("lower sums, n = {}: {:.10} | {:.10} | {:.10} | {:.10}", nn, sp, gp, sn, gn);
    }

    let (cells, mut rp, mut rn) = (65536.0f64, 0.0f64, 0.0f64);
    for i in 0..65536 {
        let x = (i as f64 + 0.5) / cells;
        let v = 4.0 * x * (1.0 - x) - 0.5;
        rp += v.max(0.0) / cells;
        rn += (-v).max(0.0) / cells;
    }
    assert!((rp - p.f()).abs() < 1e-8 && (rn - n.f()).abs() < 1e-8);
    println!("midpoint sums, 2^16 cells: h+ {:.10}, h- {:.10}, net {:.10}, |h| {:.10}", rp, rn, rp - rn, rp + rn);
    assert!(p.sub(n).f() <= 2.0 / 3.0 && p.sub(n).f().abs() <= p.add(n).f());
    println!("monotone: int h = {:.10} <= int d = 0.6666666667; triangle: |int h| <= int |h| = {:.10}",
             p.sub(n).f(), p.add(n).f());

    println!("spike s(x) = 1/(2 sqrt x) on (0, 1], int s = 1: eps | N | tail 1/(4N) | tail by cells | delta | worst window");
    for den in [10i128, 100] {
        let eps = q(1, den);
        let nc = den / 2 + 1;                                   // smallest whole N with 1/(4N) < eps/2
        let delta = eps.mul(q(1, 2 * nc));
        let mut capped = 0.0f64;
        for i in 0..65536 {
            capped += (1.0 / (2.0 * ((i as f64 + 0.5) / cells).sqrt())).min(nc as f64) / cells;
        }
        let (tail, worst) = (1.0 - capped, (0..1000).map(|cc| (cc as f64 / 1000.0 + delta.f()).sqrt() - (cc as f64 / 1000.0).sqrt())
            .fold(f64::MIN, f64::max));
        assert!((tail - 1.0 / (4.0 * nc as f64)).abs() < 1e-6);   // truncation tail: cells against 1/(4N)
        assert!(worst < eps.f());                                  // every window of length delta carries less than eps
        println!("spike, eps {}: N {} | {:.6} | {:.6} | {} | {:.10}", eps, nc, 1.0 / (4.0 * nc as f64), tail, delta, worst);
    }

    let ln2 = (1..61).fold(0.0f64, |s, k| s + 1.0 / (k as f64 * 2f64.powi(k)));
    println!("ln 2 by the series sum 1/(k 2^k): {:.6}; 1.5 ln 2: {:.6}", ln2, 1.5 * ln2);
    for k in [10i32, 20, 40] {
        let low = (0..k).fold(q(0, 1), |s, j| s.add(q(1i128 << j, 1i128 << (j + 1)))); // piece length times least value
        let cs = (0..k).fold(0.0f64, |s, j| {                 // delta = 1: midpoint sums of 1/x, 200 cells per piece
            let (a0, wd) = (2f64.powi(-(j + 1)), 2f64.powi(-(j + 1)) / 200.0);
            s + (0..200).map(|i| wd / (a0 + (i as f64 + 0.5) * wd)).sum::<f64>() });
        println!("1/x on (delta/2^{}, delta]: at least {}; by cells {:.4}; exactly {} ln 2 = {:.4}", k, low, cs, k, k as f64 * ln2);
        assert!(low.f() <= cs && (cs - k as f64 * ln2).abs() < 1e-4);
    }

    println!("endless bed w = +1, -1/2, +1/3, ... one km each: km | int w, in order | int w+ | int w-");
    let (mut s, mut wp, mut wm) = (0.0f64, 0.0f64, 0.0f64);
    let mut chart_order = Vec::new();
    for k in 1..=100000i64 {
        let v = (if k % 2 == 1 { 1.0 } else { -1.0 }) / k as f64;
        s += v; wp += v.max(0.0); wm += (-v).max(0.0);
        if k % 3 == 0 && k <= 30 { chart_order.push(s); }
        if [10, 100, 1000, 10000, 100000].contains(&k) { println!("in order, {} km: {:.6} | {:.6} | {:.6}", k, s, wp, wm); }
    }
    assert!((s - ln2).abs() < 1.0 / 100000.0);
    for j in 1..17 {                                     // each dyadic block of km adds at least 1/4 to both parts
        let blk = (1i64 << j) + 1..=(1i64 << (j + 1));
        assert!(blk.clone().filter(|m| m % 2 == 1).map(|m| 1.0 / m as f64).sum::<f64>() >= 0.25);
        assert!(blk.filter(|m| m % 2 == 0).map(|m| 1.0 / m as f64).sum::<f64>() >= 0.25);
    }
    let (mut r, mut chart_re, mut odd, mut even) = (0.0f64, Vec::new(), 1.0f64, 2.0f64);
    for m in 1..=100000i64 {                             // two pools, then one bar
        r += 1.0 / odd + 1.0 / (odd + 2.0) - 1.0 / even;
        odd += 4.0; even += 2.0;
        if m <= 10 { chart_re.push(r); }
        if [10, 1000, 100000].contains(&m) { println!("two pools then a bar, {} pieces: {:.6}", 3 * m, r); }
    }
    assert!((r - 1.5 * ln2).abs() < 1e-4);
    let f2 = |v: &[f64]| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, in order after 3..30 km: {}", f2(&chart_order));
    println!("chart, rearranged after 1..10 blocks: {} | levels {:.2} {:.2}", f2(&chart_re), ln2, 1.5 * ln2);

    let px = |x: f64, dep: f64| (30.0 + 300.0 * x, 30.0 + 160.0 * dep);
    let ctrl = r2(q(1, 4), q(-1, 8)).f();                // (2 - sqrt2)/8: tangents at 0 and at the crossing meet here
    let (sh, cr) = (1.0 - 2f64.sqrt() / 2.0, 1.0 - ctrl);
    let pts = [px(a.f(), 0.5), px(b.f(), 0.5), px(ctrl, sh), px(cr, sh)];
    let fp = |v: &[(f64, f64)]| v.iter().map(|(u, w)| format!("{:.2} {:.2}", u, w)).collect::<Vec<_>>().join(" ");
    println!("figure, crossings {} | shoal controls {} | bed 30 30 Q 180 350 330 30 | channel control 180 270",
             fp(&pts[..2]), fp(&pts[2..]));
    println!("ALL CHECKS PASS");
}
