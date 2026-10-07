// Simple functions and the dyadic staircase: the check behind the card.
// Rust std only; a hand-written fraction type keeps lengths and energies exact.
use std::collections::HashSet;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
fn lt(a: Q, b: Q) -> bool { a.n * b.d < b.n * a.d }
fn eq(a: Q, b: Q) -> bool { a.n * b.d == b.n * a.d }
fn mx(a: Q, b: Q) -> Q { if lt(a, b) { b } else { a } }
fn mn(a: Q, b: Q) -> Q { if lt(a, b) { a } else { b } }
fn fl(x: Q) -> f64 { x.n as f64 / x.d as f64 }
fn z(k: i128) -> Q { q(k, 1) }
const W: [i128; 25] = [400, 350, 300, 300, 300, 350, 800, 1900, 1400, 700, 600, 600, 900,
    700, 600, 600, 800, 1600, 2700, 3100, 2400, 1700, 1100, 600, 400];
const U: i64 = 7_200_000;
// hours of one hour-segment where a <= p < b (p linear, in W)
fn band_len(v0: i128, v1: i128, a: Q, b: Q) -> Q {
    if v0 == v1 { return z((!lt(z(v0), a) && lt(z(v0), b)) as i128); }
    let (u, w) = ((a - z(v0)) / z(v1 - v0), (b - z(v0)) / z(v1 - v0));
    let (lo, hi) = if lt(u, w) { (u, w) } else { (w, u) };
    mx(z(0), mn(z(1), hi) - mx(z(0), lo))
}
// hours of one hour-segment where p >= c
fn ge_len(v0: i128, v1: i128, c: Q) -> Q {
    if v0 == v1 { return z((!lt(z(v0), c)) as i128); }
    let u = mn(z(1), mx(z(0), (c - z(v0)) / z(v1 - v0)));
    if v1 > v0 { z(1) - u } else { u }
}
fn pieces(n: u32) -> Vec<(Q, Q)> {
    let d = 1i128 << n;
    (0..=n as i128 * d).map(|j| {
        let a = q(1000 * j, d);
        let b = if j < n as i128 * d { q(1000 * (j + 1), d) } else { z(1_000_000_000) };
        (q(j, d), (0..24).fold(z(0), |s, i| s + band_len(W[i], W[i + 1], a, b)))
    }).collect()
}
fn layers(n: u32) -> Q {
    let d = 1i128 << n;
    (1..=n as i128 * d).fold(z(0), |s, k| s + q(1, d)
        * (0..24).fold(z(0), |t, i| t + ge_len(W[i], W[i + 1], q(1000 * k, d))))
}
fn stair(n: u32, x: i64) -> i64 { (n as i64 * (1 << n)).min(((1i64 << n) * x) / U) }
fn near(n: u32, x: i64) -> i64 { ((1i64 << (n + 1)) * x + U) / (2 * U) }
fn main() {
    let p: Vec<i64> = (0..24).flat_map(|h| (0..3600).map(move |m|
        (7200 * W[h] + (W[h + 1] - W[h]) * (2 * m + 1)) as i64)).collect();
    let r: Vec<String> = W.iter().map(|w| format!("{:.2}", *w as f64 / 1000.0)).collect();
    println!("readings, kW, hours 0 to 24: {}", r.join(" "));
    let e_trap = q((0..24).map(|i| W[i] + W[i + 1]).sum::<i128>(), 2000);
    let e_mid = q(p.iter().map(|&x| x as i128).sum::<i128>(), U as i128 * 3600);
    assert!(eq(e_trap, e_mid));
    println!("energy of the curve: trapezoids {:.6} kWh; 86400 midpoints {:.6} kWh", fl(e_trap), fl(e_mid));
    let mut all_cross = vec![];
    for c in [500i128, 1000] {
        let t: Vec<Q> = (0..24).filter(|&i| (W[i] - c) * (W[i + 1] - c) < 0)
            .map(|i| z(i as i128) + q(c - W[i], W[i + 1] - W[i])).collect();
        let s: Vec<String> = t.iter().map(|x| format!("{:.4}", fl(*x))).collect();
        println!("p = {:.1} kW at hours {}", c as f64 / 1000.0, s.join(", "));
        all_cross.extend(t.iter().map(|x| fl(*x)));
    }
    println!("stage 1 standard form: value kW, hours");
    for (v, l) in pieces(1) { println!("  {:.1}, {:.6}", fl(v), fl(l)); }
    let over = p.iter().all(|&x| 500 * ((1000 * x >= 500 * U) as i64 + (1000 * x >= 1000 * U) as i64) == 500 * stair(1, x));
    println!("stage 1 as 0.5 1{{p >= 0.5}} + 0.5 1{{p >= 1}}, same at all 86400 samples: {}", if over { "yes" } else { "no" });
    assert!(over);
    println!("n, step kW, grid levels, E_n by pieces, by layers, by samples, gap to E, 24/2^n");
    let (mut prev, mut chart) = (z(0), vec![]);
    for n in 1..=8u32 {
        let pc = pieces(n);
        let en = pc.iter().fold(z(0), |s, &(v, l)| s + v * l);
        let ek = layers(n);
        let es = q(p.iter().map(|&x| stair(n, x) as i128).sum::<i128>(), (1i128 << n) * 3600);
        assert!(eq(en, ek) && lt(mx(en - es, es - en), q(1, 1000)) && lt(prev, en));
        assert!(eq(pc.iter().fold(z(0), |s, &(_, l)| s + l), z(24)));
        if n >= 4 { assert!(lt(z(0), e_trap - en) && !lt(q(24, 1 << n), e_trap - en)); }
        prev = en;
        chart.push(format!("{:.2}", fl(en)));
        println!("{}, 1/{}, {}, {:.6}, {:.6}, {:.6}, {:.6}, {:.6}", n, 1 << n, pc.len(), fl(en), fl(ek),
            fl(es), fl(e_trap - en), fl(q(24, 1 << n)));
    }
    println!("chart, E_n in kWh for n = 1 to 8: {}", chart.join(" "));
    println!("largest sampled gap p - s_n, kW, against 2^-n");
    for n in 1..=8u32 {
        assert!(p.iter().all(|&x| 2 * stair(n, x) <= stair(n + 1, x) && U * stair(n, x) <= (1 << n) * x));
        let g = q(p.iter().map(|&x| ((1i64 << n) * x - U * stair(n, x)) as i128).max().unwrap(), U as i128 * (1 << n));
        if n >= 4 { assert!(lt(g, q(1, 1 << n))); }
        println!("  n={}: {:.6} against {:.8}", n, fl(g), fl(q(1, 1 << n)));
    }
    println!("at 19:00, p = 3.1 kW: n, s_n, error, 2^-n");
    for n in 1..=8u32 {
        let s = q((n as i128 * (1 << n)).min(((1i128 << n) * 31) / 10), 1 << n);
        assert!(!lt(q(31, 10), s) && (n < 4 || lt(q(31, 10) - s, q(1, 1 << n))));
        println!("  {}, {:.8}, {:.8}, {:.8}", n, fl(s), fl(q(31, 10) - s), fl(q(1, 1 << n)));
    }
    let above = p.iter().filter(|&&x| near(2, x) * U > 4 * x).count();
    let drop = p.iter().filter(|&&x| near(2, x) < 2 * near(1, x)).count();
    let thirds = p.iter().filter(|&&x| 2 * ((3 * x) / U) < 3 * ((2 * x) / U)).count();
    println!("nearest instead of down, n=2: seconds above the curve {} / seconds below stage 1 {}", above, drop);
    println!("steps of 1/2 then 1/3 kW: seconds where the 1/3 staircase is lower {}", thirds);
    assert!(above > 0 && drop > 0 && thirds > 0);
    let vals: HashSet<i64> = (1..=10000i64).map(|j| (4 * 10000) / j).collect();
    assert!(vals.len() > 2 * 4 + 1);
    println!("1/x on (0,1] at x = j/10000: uncapped stage 2 takes {} values; capped stage 2 at most {}", vals.len(), 2 * 4 + 1);
    let net = q(900 - 1500, 1000);
    let (pos, neg) = (mx(net, z(0)), mx(z(0) - net, z(0)));
    let (sp, sn) = (q(16 * pos.n / pos.d, 16), q(16 * neg.n / neg.d, 16));
    assert!(eq(pos - neg, net) && !lt(sp - sn - net, z(0)) && lt(sp - sn - net, q(1, 16)));
    println!("12:00 with 1.5 kW solar: net {:.4}, parts {:.4} and {:.4}, stage 4 {:.4}", fl(net), fl(pos), fl(neg), fl(sp - sn));
    all_cross.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let fx: Vec<String> = all_cross.iter().map(|t| format!("{:.2}", 36.0 + 13.0 * t)).collect();
    println!("figure, x = 36 + 13 t, y = 210 - 50 p; stage-1 corners at x = {}", fx.join(", "));
}
