// Complex steps and dual numbers -- the check behind the card.  Rust std only.
// Road one: the exact slope -(F/y)(1 - 1.05^-30) and a term-by-term sum.
// Road two: the complex step Im P(y + ih) / h at many steps h.  Road three: a
// dual number carried through the same pricing code.  For contrast: the central
// difference.  Each number type counts its real operations (flops).
use std::sync::atomic::{AtomicUsize, Ordering::Relaxed};
static OPS: AtomicUsize = AtomicUsize::new(0);
fn tick(n: usize) { OPS.fetch_add(n, Relaxed); }
fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
trait Num: Copy {
    fn addc(self, k: f64) -> Self;
    fn add(self, o: Self) -> Self;
    fn mul(self, o: Self) -> Self;
    fn scal(self, k: f64) -> Self;
    fn recip(self) -> Self;
    fn mag(self) -> Self;
}
#[derive(Clone, Copy)] struct R { a: f64 } // a plain real number, counted
impl Num for R {
    fn addc(self, k: f64) -> R { tick(1); R { a: self.a + k } }
    fn add(self, o: R) -> R { tick(1); R { a: self.a + o.a } }
    fn mul(self, o: R) -> R { tick(1); R { a: self.a * o.a } }
    fn scal(self, k: f64) -> R { tick(1); R { a: k * self.a } }
    fn recip(self) -> R { tick(1); R { a: 1.0 / self.a } }
    fn mag(self) -> R { R { a: self.a.abs() } }
}
#[derive(Clone, Copy)] struct Cx { a: f64, b: f64 } // a + b i, i * i = -1
impl Num for Cx {
    fn addc(self, k: f64) -> Cx { tick(1); Cx { a: self.a + k, b: self.b } }
    fn add(self, o: Cx) -> Cx { tick(2); Cx { a: self.a + o.a, b: self.b + o.b } }
    fn mul(self, o: Cx) -> Cx { tick(6); Cx { a: self.a * o.a - self.b * o.b, b: self.a * o.b + self.b * o.a } }
    fn scal(self, k: f64) -> Cx { tick(2); Cx { a: k * self.a, b: k * self.b } }
    fn recip(self) -> Cx {
        tick(5); let den = self.a * self.a + self.b * self.b;
        Cx { a: self.a / den, b: -self.b / den }
    }
    fn mag(self) -> Cx { Cx { a: (self.a * self.a + self.b * self.b).sqrt(), b: 0.0 } } // abs() of a complex
}
#[derive(Clone, Copy)] struct Dual { a: f64, b: f64 } // a + b eps, eps * eps = 0
impl Num for Dual {
    fn addc(self, k: f64) -> Dual { tick(1); Dual { a: self.a + k, b: self.b } }
    fn add(self, o: Dual) -> Dual { tick(2); Dual { a: self.a + o.a, b: self.b + o.b } }
    fn mul(self, o: Dual) -> Dual { tick(4); Dual { a: self.a * o.a, b: self.a * o.b + self.b * o.a } }
    fn scal(self, k: f64) -> Dual { tick(2); Dual { a: k * self.a, b: k * self.b } }
    fn recip(self) -> Dual {
        tick(3); let r = 1.0 / self.a;
        Dual { a: r, b: -self.b * r * r }
    }
    fn mag(self) -> Dual { Dual { a: self.a.abs(), b: if self.a >= 0.0 { self.b } else { -self.b } } }
}
const C: f64 = 5.0; const F: f64 = 100.0; const N: usize = 30; const Y: f64 = 0.05;
const EX: f64 = -1537.2451026882836; // exact dP/dy, rounded once
fn legs<T: Num>(y: T, guard: bool) -> (T, T, T) { // ONE pricing routine for every number type
    let y = if guard { y.mag() } else { y }; // "a negative yield is a typo": take abs
    let v = y.addc(1.0).recip(); // one year's discount factor 1/(1+y)
    let mut d = v; let mut s = d.scal(C);
    for _ in 0..N - 1 { d = d.mul(v); s = s.add(d.scal(C)); } // coupon t is worth C v^t today
    (v, d, s) // v, v^30, the coupons' value
}
fn price<T: Num>(y: T, guard: bool) -> T { let (_, d, s) = legs(y, guard); s.add(d.scal(F)) }
fn cs(h: f64) -> f64 { price(Cx { a: Y, b: h }, false).b / h } // the complex step
fn pr(y: f64) -> f64 { price(R { a: y }, false).a }
fn cd(h: f64) -> f64 { (pr(Y + h) - pr(Y - h)) / (2.0 * h) }
fn rel(x: f64) -> f64 { (x - EX) / EX }
fn ten(k: i32) -> f64 { format!("1e-{}", k).parse().unwrap() }
fn main() {
    let mut g = 1.0;
    for _ in 0..N { g *= 1.0 + Y; } // road one: 1.05^30, then the closed form
    let cf = -(F / Y) * (1.0 - 1.0 / g);
    let (mut d1, mut d2, mut d3) = (0.0f64, 0.0f64, 0.0f64);
    let v = 1.0 / (1.0 + Y); let mut vt = 1.0;
    for ti in 1..=N { // road one again: term by term
        let t = ti as f64; vt *= v; let c = C + if ti == N { F } else { 0.0 };
        d1 -= c * t * vt * v; d2 += c * t * (t + 1.0) * vt * v * v; d3 -= c * t * (t + 1.0) * (t + 2.0) * vt * v * v * v;
    }
    let (p0, p1, k3) = (pr(Y), pr(Y + 1e-4), d3 / (6.0 * EX));
    println!("bond: price at 5% = {:.12}; 1.05^30 = {:.12}; u = 2^-53 = {}", p0, g, sci(2f64.powi(-53), 2));
    println!("exact dP/dy {:.10}; closed form in doubles rel err {}, term by term {}", EX, sci(rel(cf), 2), sci(rel(d1), 2));
    println!("d2P/dy2 = {:.6}, d3P/dy3 = {:.6}; complex-step law: rel err = -{:.6} h^2", d2, d3, k3);
    println!("1bp bump: P(5.01%) = {:.12}, change {:.12}; true DV01 {:.12}", p1, p1 - p0, -EX * 1e-4);
    println!("k   complex step      rel err     central difference  rel err");
    let mut er = std::collections::HashMap::new(); let mut ec = Vec::new();
    let (mut lc, mut ld) = (Vec::new(), Vec::new());
    for k in (1..17).chain([20, 100, 300]) {
        let h = ten(k); let a = cs(h); er.insert(k, rel(a));
        let mut tail = String::new();
        if k <= 16 {
            ec.push(rel(cd(h))); tail = format!("{:18.9}  {:>9}", cd(h), sci(rel(cd(h)), 2));
            lc.push(format!("{:.2}", rel(a).abs().log10())); ld.push(format!("{:.2}", rel(cd(h)).abs().log10()));
        }
        println!("{}", format!("{:<3} {:16.9}  {:>9}  {}", k, a, sci(rel(a), 2), tail).trim_end());
    }
    println!("chart complex step log10 |rel err|: {}", lc.join(", "));
    println!("chart central log10 |rel err|: {}", ld.join(", "));
    let ord: Vec<String> = (2..6).map(|k| format!("{:.4}", (er[&k] / er[&(k + 1)]).log10())).collect();
    println!("complex step: order from k to k+1 (theory 2): {}; law at h=1e-3 {}", ord.join(", "), sci(-k3 * 1e-6, 2));
    OPS.store(0, Relaxed); let du = price(Dual { a: Y, b: 1.0 }, false); let n_du = OPS.load(Relaxed);
    OPS.store(0, Relaxed); pr(Y); let n_r = OPS.load(Relaxed);
    OPS.store(0, Relaxed); let c20 = price(Cx { a: Y, b: 1e-20 }, false); let n_cx = OPS.load(Relaxed);
    println!("dual: P(5% + eps) = {:.12} + ({:.10}) eps, rel err {}", du.a, du.b, sci(rel(du.b), 2));
    println!("complex at h=1e-20: real {:.12}, imag {}; imag/h minus dual {}", c20.a, sci(c20.b, 9), sci(c20.b / 1e-20 - du.b, 2));
    let (v, d, s) = legs(Dual { a: Y, b: 1.0 }, false);
    println!("by hand (dual): v = {:.12} + ({:.12}) eps; v^30 = {:.12} + ({:.9}) eps", v.a, v.b, d.a, d.b);
    println!("by hand (dual): coupons {:.9} + ({:.9}) eps; face 100 v^30 = {:.9} + ({:.9}) eps", s.a, s.b, F * d.a, F * d.b);
    println!("flops: one price {}, central difference {}, complex step {}, dual {}", n_r, 2 * n_r + 2, n_cx + 1, n_du);
    let gc = price(Cx { a: Y, b: 1e-20 }, true).b / 1e-20 + 0.0; // the abs() guard left in the code
    let gd = price(Dual { a: Y, b: 1.0 }, true);
    let sr = 2.0 * (p0 - price(Cx { a: Y, b: 1e-20 }, false).a) / 1e-40;
    let s4 = 2.0 * (p0 - price(Cx { a: Y, b: 1e-4 }, false).a) / 1e-8;
    println!("break, abs() guard: complex step {:.9}, dual {:.9}", gc, gd.b);
    println!("break, 2nd derivative from the real part: h=1e-20 {}, h=1e-4 {:.6} (exact {:.6})", sci(sr, 2), s4, d2);
    let avg = (cs(1e-2) + cd(1e-2)) / 2.0;
    let s320 = cs(ten(320));
    println!("try: mean of complex step and central at h=1e-2 {:.9}, rel err {}", avg, sci(rel(avg), 2));
    println!("try: h=1e-320 (subnormal) gives {:.9}, rel err {}; seed 1e-4: {:.12}", s320, sci(rel(s320), 2), price(Dual { a: Y, b: 1e-4 }, false).b);
    assert!(rel(cf).abs() < 1e-14 && rel(d1).abs() < 1e-14); // two roads to the exact slope
    assert!(er[&20].abs() < 4e-15 && rel(du.b).abs() < 4e-15); // complex step and dual: full accuracy
    assert!(ec.iter().all(|e| e.abs() > 1e-11)); // the best central difference is 1000x worse
    assert!((er[&3] / (-k3 * 1e-6) - 1.0).abs() < 1e-3); // error follows -h^2 f'''/(6 f')
    assert!((er[&3] + ec[2]).abs() < 1e-3 * er[&3].abs()); // equal size, opposite sign
    assert!(gc == 0.0 && rel(gd.b).abs() < 4e-15); // abs() kills the complex step, not the dual
    println!("ALL CHECKS PASS");
}
