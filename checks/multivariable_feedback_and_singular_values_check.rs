// Multivariable feedback and singular values -- the same check as multivariable_feedback_and_singular_values_check.py.
// Standard library only, no crates.  Complex numbers are a small struct written out.
// Two drives share one belt.  u1, u2: drive speed commands, % of full speed; y1, y2: belt speed at the
// two drive pulleys, % of the nominal 2.0 m/s.  G(s) = g [[1, k h], [k h, 1]], g = 1/(TAU s + 1), h = 1/(TC s + 1).
use std::f64::consts::PI;
const TAU: f64 = 0.2; const TC: f64 = 0.5; const KC: f64 = 0.8; const KP: f64 = 1.0; const KI: f64 = 5.0;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn r(x: f64) -> C { C::new(x, 0.0) }
    fn add(self, o: C) -> C { C::new(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { C::new(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
type M2 = [[C; 2]; 2];

fn gm(s: C, k: f64) -> M2 {
    let (g, h) = (C::r(1.0).div(C::r(TAU).mul(s).add(C::r(1.0))), C::r(1.0).div(C::r(TC).mul(s).add(C::r(1.0))));
    let c = C::r(k).mul(g).mul(h); [[g, c], [c, g]]
}
fn svals(m: &M2) -> (f64, f64) {
    let p: f64 = m.iter().flatten().map(|x| x.abs().powi(2)).sum();
    let q = m[0][0].mul(m[1][1]).sub(m[0][1].mul(m[1][0])).abs().powi(2);
    let r = (p * p / 4.0 - q).max(0.0).sqrt(); ((p / 2.0 + r).sqrt(), (p / 2.0 - r).max(0.0).sqrt())
}
fn stretch(m: &M2) -> (f64, f64) {
    let (n, k, mut hi, mut lo) = (360, 72, 0.0f64, 1e9f64);
    for i in 0..=n {
        let t = PI / 2.0 * i as f64 / n as f64;
        for f in 0..k {
            let a = 2.0 * PI * f as f64 / k as f64;
            let (v0, v1) = (C::r(t.cos()), C::new(a.cos(), a.sin()).mul(C::r(t.sin())));
            let y0 = m[0][0].mul(v0).add(m[0][1].mul(v1)); let y1 = m[1][0].mul(v0).add(m[1][1].mul(v1));
            let n2 = (y0.abs().powi(2) + y1.abs().powi(2)).sqrt(); hi = hi.max(n2); lo = lo.min(n2);
        }
    }
    (hi, lo)
}
fn rga11(m: &M2) -> C { m[0][0].div(m[0][0].sub(m[0][1].mul(m[1][0]).div(m[1][1]))) }
fn pmul(p: &[f64], q: &[f64]) -> Vec<f64> {
    let mut r = vec![0.0; p.len() + q.len() - 1];
    for (i, x) in p.iter().enumerate() { for (j, y) in q.iter().enumerate() { r[i + j] += x * y; } } r
}
fn padd(p: &[f64], q: &[f64]) -> Vec<f64> {
    let n = p.len().max(q.len());
    (0..n).map(|i| (if i + p.len() >= n { p[i + p.len() - n] } else { 0.0 }) + (if i + q.len() >= n { q[i + q.len() - n] } else { 0.0 })).collect()
}
fn roots(p: &[f64]) -> Vec<C> {
    let (n, p, mut z) = (p.len() - 1, p.iter().map(|c| c / p[0]).collect::<Vec<f64>>(), vec![C::r(1.0)]);
    for _ in 1..n { let l = *z.last().unwrap(); z.push(l.mul(C::new(0.4, 0.9))); }
    for _ in 0..500 {
        for i in 0..n {
            let (mut den, mut num) = (C::r(1.0), C::r(0.0));
            for j in 0..n { if j != i { den = den.mul(z[i].sub(z[j])); } }
            for c in &p { num = num.mul(z[i]).add(C::r(*c)); }
            z[i] = z[i].sub(num.div(den));
        }
    }
    let mut z: Vec<C> = z.into_iter().map(|r| C::new(r.re, if r.im.abs() > 1e-6 { r.im } else { 0.0 })).collect();
    z.sort_by(|a, b| ((a.re * 1e6).round(), a.im).partial_cmp(&((b.re * 1e6).round(), b.im)).unwrap()); z
}
fn closed_poly(swap: bool, k: f64) -> Vec<f64> {
    let (sd, kn) = (pmul(&[TAU, 1.0], &pmul(&[TC, 1.0], &[1.0, 0.0])), [KP, KI]);
    let (diag, off) = if swap { (padd(&sd, &pmul(&[k], &kn)), pmul(&[TC, 1.0], &kn)) }
                      else { (padd(&sd, &pmul(&[TC, 1.0], &kn)), pmul(&[k], &kn)) };
    padd(&pmul(&diag, &diag), &pmul(&off, &off).iter().map(|c| -c).collect::<Vec<f64>>())
}
fn winding(swap: bool) -> i64 {
    let mut pts: Vec<C> = (0..=4000).map(|i| C::new(0.0, -(10f64.powf(4.0 - 8.0 * i as f64 / 4000.0)))).collect();
    for i in 1..2000 { let a = -PI / 2.0 + PI * i as f64 / 2000.0; pts.push(C::new(1e-4 * a.cos(), 1e-4 * a.sin())); }
    for i in 0..=4000 { pts.push(C::new(0.0, 10f64.powf(-4.0 + 8.0 * i as f64 / 4000.0))); }
    let (mut total, mut prev): (f64, Option<C>) = (0.0, None);
    for s in pts {
        let (kk, m, one) = (C::r(KP).add(C::r(KI).div(s)), gm(s, KC), C::r(1.0));
        let (a, b, c, d) = if swap { (m[0][1], m[0][0], m[1][1], m[1][0]) } else { (m[0][0], m[0][1], m[1][0], m[1][1]) };
        let v = one.add(a.mul(kk)).mul(one.add(d.mul(kk))).sub(b.mul(c).mul(kk).mul(kk));
        if let Some(pv) = prev { let q = v.div(pv); total += q.im.atan2(q.re); } prev = Some(v);
    }
    (-total / (2.0 * PI)).round() as i64
}
// mode 0 separate loops, 1 decoupled, 2 swapped pairing.  Returns (log of t, y1, y2, u1, u2), settle, peak |y2|.
fn simulate(mode: u8, eps1: f64, t_end: f64) -> (Vec<[f64; 5]>, f64, f64) {
    let (dt, r) = (1e-3, [1.0, 0.0]);
    let f = |x: &[f64; 8]| -> ([f64; 8], [f64; 4]) {
        let (y1, y2) = (x[0] + KC * x[3], x[1] + KC * x[2]);
        let (e1, e2) = (r[0] - y1, r[1] - y2);
        let (w1, w2) = (KP * e1 + KI * x[4], KP * e2 + KI * x[5]);
        let (u1, u2) = match mode { 2 => (w2, w1), 1 => (w1 - KC * x[6], w2 - KC * x[7]), _ => (w1, w2) };
        ([((1.0 + eps1) * u1 - x[0]) / TAU, (u2 - x[1]) / TAU, (x[0] - x[2]) / TC, (x[1] - x[3]) / TC,
          e1, e2, (u2 - x[6]) / TC, (u1 - x[7]) / TC], [y1, y2, u1, u2])
    };
    let mv = |x: &[f64; 8], d: &[f64; 8], h: f64| -> [f64; 8] { let mut o = *x; for i in 0..8 { o[i] += h * d[i]; } o };
    let (mut x, mut lg) = ([0.0f64; 8], vec![]);
    for k in 0..=((t_end / dt) as f64).round() as usize {
        let (d, o) = f(&x); lg.push([k as f64 * dt, o[0], o[1], o[2], o[3]]);
        let k2 = f(&mv(&x, &d, dt / 2.0)).0; let k3 = f(&mv(&x, &k2, dt / 2.0)).0; let k4 = f(&mv(&x, &k3, dt)).0;
        for i in 0..8 { x[i] += dt / 6.0 * (d[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    }
    let settle = lg.iter().filter(|w| (w[1] - r[0]).abs() > 0.02).map(|w| w[0]).fold(0.0, f64::max) + dt;
    let pk = lg.iter().map(|w| w[2].abs()).fold(0.0, f64::max); (lg, settle, pk)
}

fn main() {
    let g0 = gm(C::r(0.0), KC);
    let (s1, s2) = svals(&g0); let (b1, b2) = stretch(&g0);
    println!("steady gain G(0) = [[{:.1}, {:.1}], [{:.1}, {:.1}]] (% per %)", g0[0][0].re, g0[0][1].re, g0[1][0].re, g0[1][1].re);
    println!("singular values: {:.4} together, {:.4} against; condition number {:.4}; measured {:.4}, {:.4}", s1, s2, s1 / s2, b1, b2);
    assert!((s1 - (1.0 + KC)).abs() < 1e-12 && (s2 - (1.0 - KC)).abs() < 1e-12 && (b1 - s1).abs() < 1e-3 && (b2 - s2).abs() < 1e-3);
    println!("inputs for a 1 % speed difference: +-{:.2} %; for 1 % together: {:.4} % each", 0.5 / s2, 1.0 / s1);
    let w1 = gm(C::new(0.0, 1.0), KC); let (a, b) = svals(&w1); let (m1, m2) = stretch(&w1);
    println!("at 1 rad/s: |g| = {:.4}, |h| = {:.4}; sigma {:.4}, {:.4}; measured {:.4}, {:.4}", w1[0][0].abs(), C::r(1.0).div(C::new(1.0, TC)).abs(), a, b, m1, m2);
    assert!((m1 - a).abs() < 2e-3 && (m2 - b).abs() < 2e-3);
    println!("chart: w (rad/s), sigma_max, sigma_min, |lambda11|");
    for w in [0.01, 0.03, 0.1, 0.3, 1.0, 3.0, 10.0, 30.0, 100.0] {
        let (m, h) = (gm(C::new(0.0, w), KC), C::r(1.0).div(C::new(1.0, TC * w))); let ((a, b), g) = (svals(&m), m[0][0].abs());
        assert!((a - g * C::r(1.0).add(C::r(KC).mul(h)).abs()).abs() < 1e-9 && (b - g * C::r(1.0).sub(C::r(KC).mul(h)).abs()).abs() < 1e-9);
        println!("chart, {:6.2}, {:.3}, {:.3}, {:.3}", w, a, b, rga11(&m).abs());
    }
    let lam = rga11(&g0).re;
    println!("RGA at s = 0: lambda11 = {:.4}, lambda12 = {:.4}; 1/lambda11 = {:.4}", lam, 1.0 - lam, 1.0 / lam);
    let z = [(-1.0 - KC) / TC, (-1.0 + KC) / TC];
    let (f, mut found) = (|s: f64| (TC * s + 1.0).powi(2) - KC * KC, vec![]);
    for (mut lo, mut hi) in [(-1.9999, -1e-9), (-10.0, -2.0001)] {
        for _ in 0..80 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) > 0.0 { lo = mid; } else { hi = mid; } } found.push(lo);
    }
    let mz = gm(C::r(z[1]), KC);
    println!("transmission zeros: {:.4} and {:.4} rad/s; bisection {:.4}, {:.4}; |G(z) (1, -1)| = {:.6}, sigma_min there {:.6}",
             z[1], z[0], found[0], found[1], mz[0][0].sub(mz[0][1]).abs(), svals(&mz).1);
    assert!((found[0] - z[1]).abs() < 1e-9 && (found[1] - z[0]).abs() < 1e-9 && svals(&mz).1 < 1e-9);
    for swap in [false, true] {
        let rt = roots(&closed_poly(swap, KC));
        let ps: Vec<String> = rt.iter().map(|p| format!("{:.4}{:+.4}j", p.re, p.im)).collect();
        println!("{} pairing: det(I+L) turns clockwise round 0: {}; closed-loop poles {}", if swap { "swapped" } else { "diagonal" }, winding(swap), ps.join(", "));
        assert!(winding(swap) == rt.iter().filter(|p| p.re > 0.0).count() as i64 && winding(swap) == if swap { 1 } else { 0 });
    }
    println!("by hand: s^2 + 7 s + 2 -> {:.4}, {:.4}; s^2 + 7 s + 18 -> -3.5000 +- {:.4}j; s^2 - 3 s - 2 -> {:.4}; one swapped loop alone: s^2 + 2 s + 8 -> -1.0000 +- {:.4}j",
             (-7.0 + 41f64.sqrt()) / 2.0, (-7.0 - 41f64.sqrt()) / 2.0, 23f64.sqrt() / 2.0, (3.0 + 17f64.sqrt()) / 2.0, 7f64.sqrt());
    for (mode, name) in [(0u8, "separate"), (1u8, "decoupled")] {
        let (lg, ts, pk2) = simulate(mode, 0.0, 30.0);
        let (e10, e20, last) = (1.0 - lg[10000][1], 1.0 - lg[20000][1], lg[lg.len() - 1]);
        println!("{:9} step r1 = 1 %: y1(0.5 s) = {:.3} %, 2% settle {:.2} s, peak |y2| {:.3} %, final u = {:.3}, {:.3} %", name, lg[500][1], ts, pk2, last[3], last[4]);
        if mode == 0 {
            println!("  slow mode from the run: {:.4} rad/s; in m/s: y2 peak {:.4} m/s", -(e10 / e20).ln() / 10.0, pk2 * 0.02);
            assert!((-(e10 / e20).ln() / 10.0 - (-7.0 + 41f64.sqrt()) / 2.0).abs() < 1e-3 && (last[3] - lam).abs() < 1e-3);
        } else {
            assert!(pk2 < 1e-6 && ts < 1.0 && (last[3] - lam).abs() < 5e-3);
        }
    }
    let (lg, _, _) = simulate(2, 0.0, 4.0); let gr = (lg[4000][1] / lg[3000][1]).abs().ln();
    println!("swapped pairing: y1 at 1 s {:.1} %, at 2 s {:.1} %; growth {:.4} per s", lg[1000][1], lg[2000][1], gr);
    assert!((gr - (3.0 + 17f64.sqrt()) / 2.0).abs() < 1e-3);
    let ((_, tw, dw), (_, _, sw)) = (simulate(1, -0.2, 30.0), simulate(0, -0.2, 30.0));
    println!("drive 1 20 % weak: G (I+E) G^-1 at s = 0 = [[{:.4}, {:.4}], [{:.4}, {:.4}]]; decoupled: y1 settles {:.2} s, peak |y2| {:.3} %; separate: peak |y2| {:.3} %",
             1.0 - 0.2 * lam, 0.2 * KC * lam, -0.2 * KC * lam, 1.0 + 0.2 * KC * KC * lam, tw, dw, sw);
    let lvm = [[C::r(87.8), C::r(-86.4)], [C::r(108.2), C::r(-109.6)]]; let ((a, b), lv) = (svals(&lvm), rga11(&lvm).re);
    println!("distillation LV: sigma {:.2}, {:.4}; condition number {:.1}; lambda11 {:.2}; decoupled loop gain with a 20 % weak input {:.2}",
             a, b, a / b, lv, 1.0 - 0.2 * lv);
    assert!(1.0 - 0.2 * lam > 0.0 && 0.0 > 1.0 - 0.2 * lv);
    for k in [0.5, 0.95] {
        let p = roots(&closed_poly(false, k)).iter().filter(|r| r.im.abs() < 1e-9).map(|r| r.re).fold(f64::MIN, f64::max);
        println!("try k = {}: sigma {:.2}, {:.2}; condition {:.1}; lambda11 {:.3}; slowest pole {:.4} rad/s",
                 k, 1.0 + k, 1.0 - k, (1.0 + k) / (1.0 - k), rga11(&gm(C::r(0.0), k)).re, p);
    }
    println!("ALL CHECKS PASS");
}
