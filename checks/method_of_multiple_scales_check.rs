// Multiple scales -- the same check as the Python, in Rust.  No crates.
// A 2 kg instrument on a stiffening rubber mount, x'' + x + eps x^3 = 0 (Duffing),
// then the oscillator x'' - eps (1 - x^2) x' + x = 0 (van der Pol).  Roads: the
// two-timing formulas, RK4 stepping, an exact period by Gauss's AGM, and the
// solvability averages done again by numerical quadrature.
use std::f64::consts::PI;

const MASS: f64 = 2.0;                       // kg
const K: f64 = 800.0;                        // N/m
const K3: f64 = 8.0e5;                       // N/m^3
const A: f64 = 0.010;                        // release, m
const H: f64 = 0.001;                        // RK4 step, in time units 1/w0

fn duffing(e: f64) -> impl Fn(f64, f64) -> (f64, f64) { move |x, v| (v, -x - e * x * x * x) }
fn vdp(e: f64) -> impl Fn(f64, f64) -> (f64, f64) { move |x, v| (v, e * (1.0 - x * x) * v - x) }

fn rk4(f: &impl Fn(f64, f64) -> (f64, f64), x: f64, v: f64, h: f64) -> (f64, f64) {
    let (a1, b1) = f(x, v);
    let (a2, b2) = f(x + 0.5 * h * a1, v + 0.5 * h * b1);
    let (a3, b3) = f(x + 0.5 * h * a2, v + 0.5 * h * b2);
    let (a4, b4) = f(x + h * a3, v + h * b3);
    (x + h * (a1 + 2.0 * a2 + 2.0 * a3 + a4) / 6.0, v + h * (b1 + 2.0 * b2 + 2.0 * b3 + b4) / 6.0)
}

fn peaks(f: &impl Fn(f64, f64) -> (f64, f64), mut x: f64, mut v: f64, tmax: f64) -> Vec<(f64, f64)> {
    let (mut out, mut n) = (Vec::new(), 0usize);
    while (n as f64) * H < tmax {
        let (x2, v2) = rk4(f, x, v, H);
        if v > 0.0 && 0.0 >= v2 {            // bisect the step to land on v = 0
            let (mut lo, mut hi) = (0.0, H);
            for _ in 0..50 {
                let mid = 0.5 * (lo + hi);
                if rk4(f, x, v, mid).1 > 0.0 { lo = mid } else { hi = mid }
            }
            out.push((n as f64 * H + lo, rk4(f, x, v, lo).0));
        }
        x = x2;
        v = v2;
        n += 1;
    }
    out
}

fn agm(mut p: f64, mut q: f64) -> f64 {
    for _ in 0..30 {
        let (np, nq) = (0.5 * (p + q), (p * q).sqrt());
        p = np;
        q = nq;
    }
    p
}

fn exact_period(e: f64) -> f64 {             // Duffing from x = 1 at rest, by elliptic K and AGM
    let m = e / (2.0 * (1.0 + e));
    4.0 * (PI / (2.0 * agm(1.0, (1.0 - m).sqrt()))) / (1.0 + e).sqrt()
}

fn tt_period(e: f64) -> f64 { 2.0 * PI / (1.0 + 3.0 * e / 8.0) }  // two-timing: omega = 1 + 3 eps / 8

fn average(h: impl Fn(f64, f64) -> f64, a: f64, sin_part: bool) -> f64 {
    let (n, mut s) = (64, 0.0);
    for k in 0..n {
        let th = 2.0 * PI * (k as f64 + 0.5) / n as f64;
        s += h(a * th.cos(), -a * th.sin()) * if sin_part { th.sin() } else { th.cos() };
    }
    s / n as f64
}

fn plain(t: f64, e: f64) -> f64 {            // regular expansion, two terms: grows like t sin t
    t.cos() + e * (((3.0 * t).cos() - t.cos()) / 32.0 - 3.0 * t * t.sin() / 8.0)
}

fn amp(t: f64, a0: f64, e: f64) -> f64 {     // van der Pol slow amplitude, solved exactly
    2.0 / (1.0 + (4.0 / (a0 * a0) - 1.0) * (-e * t).exp()).sqrt()
}

fn join<T>(v: &[T], f: impl Fn(&T) -> String) -> String { v.iter().map(f).collect::<Vec<_>>().join(" ") }

fn main() {
    let w0 = (K / MASS).sqrt();
    let eps = K3 * A * A / K;
    let t0 = 1.0 / w0;
    println!("mount: m = {:.1} kg, k = {:.0} N/m, k3 = {:.0} N/m^3, release A = {:.1} mm", MASS, K, K3, A * 1000.0);
    println!("w0 = sqrt(k/m) = {:.4} rad/s = {:.4} Hz; time unit 1/w0 = {:.4} s", w0, w0 / (2.0 * PI), t0);
    println!("eps = k3 A^2 / k = {:.4}", eps);
    let w = 1.0 + 3.0 * eps / 8.0;
    let pk = peaks(&duffing(eps), 1.0, 0.0, 61.0);
    let (t_rk, t_ex, t_tt) = (pk[9].0 / 10.0, exact_period(eps), tt_period(eps));
    println!("two-timing: 3 eps/8 = {:.6}; omega = {:.6}, times w0 = {:.4} rad/s", 3.0 * eps / 8.0, w, w * w0);
    println!("two-timing: period {:.4} units = {:.5} s; f = {:.4} Hz", t_tt, t_tt * t0, w * w0 / (2.0 * PI));
    println!("exact, by AGM: period {:.4} units = {:.5} s", t_ex, t_ex * t0);
    let (lo_p, hi_p) = pk.iter().fold((f64::MAX, f64::MIN), |(a, b), p| (a.min(p.1), b.max(p.1)));
    println!("RK4, 10 peaks: period {:.4} units; lowest peak {:.6}, highest {:.6}", t_rk, lo_p, hi_p);
    let err1 = (t_ex - tt_period(eps)) / t_ex;
    let err2 = (exact_period(eps / 2.0) - tt_period(eps / 2.0)) / exact_period(eps / 2.0);
    println!("two-timing period short by {:.4}% at eps = 0.1, {:.4}% at eps = 0.05; ratio {:.2}", err1 * 100.0, err2 * 100.0, err1 / err2);
    let c38 = -average(|x, _v| -x * x * x, 1.0, false);
    println!("quadrature: Duffing phase drift per unit slow time at a = 1: {:.6} (3/8 = {:.6})", c38, 3.0 / 8.0);
    let g = |a: f64| average(|x, v| (1.0 - x * x) * v, a, true) * -1.0;
    println!("quadrature: van der Pol growth at a = 1: {:.6} (a/2 - a^3/8 = {:.6})", g(1.0), 0.5 - 1.0 / 8.0);
    let (mut lo, mut hi) = (1.0, 3.0);
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if g(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    println!("quadrature + bisection: growth is zero at a = {:.6}", lo);

    let f = duffing(eps);
    let (mut x, mut v, mut gaps) = (1.0, 0.0, Vec::new());
    for blk in 0..8 {                        // worst gap from RK4 in each 10-unit window
        let mut worst = [0.0f64; 3];
        for k in 0..10000 {
            (x, v) = rk4(&f, x, v, H);
            let t = blk as f64 * 10.0 + (k + 1) as f64 * H;
            for (j, y) in [t.cos(), plain(t, eps), (w * t).cos()].iter().enumerate() {
                worst[j] = worst[j].max((y - x).abs());
            }
        }
        gaps.push(worst);
    }
    println!("chart, window ends at t   {}", join(&(1..=8).collect::<Vec<_>>(), |i| format!("{:5}", 10 * i)));
    for (j, lab) in ["fixed frequency 1  ", "plain expansion    ", "two-timing         "].iter().enumerate() {
        println!("chart, gap {} {}", lab, join(&gaps, |gp| format!("{:5.2}", gp[j])));
    }
    let pmax = (0..=10000).map(|k| plain(70.0 + k as f64 * 0.001, eps).abs()).fold(0.0, f64::max);
    println!("plain expansion reaches {:.4} in t = 70..80; true peak stays 1", pmax);

    let up: Vec<_> = peaks(&vdp(eps), 1.0, 0.0, 76.0).into_iter().take(12).collect();
    let down: Vec<_> = peaks(&vdp(eps), 3.0, 0.0, 76.0).into_iter().take(12).collect();
    println!("chart, peak number        {}", join(&(1..=12).collect::<Vec<_>>(), |i| format!("{:5}", i)));
    println!("chart, peak time from 1   {}", join(&up, |p| format!("{:5.1}", p.0)));
    for (lab, ps, a0) in [("RK4 from 1    ", &up, 1.0), ("formula from 1", &up, 1.0), ("RK4 from 3    ", &down, 3.0), ("formula from 3", &down, 3.0)] {
        let rk = lab.starts_with("RK4");
        println!("chart, {}     {}", lab, join(ps, |p| format!("{:5.2}", if rk { p.1 } else { amp(p.0, a0, eps) })));
    }
    let vgap = [(&up, 1.0), (&down, 3.0)].iter()
        .flat_map(|(ps, a0)| ps.iter().map(move |p| (p.1 - amp(p.0, *a0, eps)).abs())).fold(0.0, f64::max);
    println!("worst gap, RK4 peak vs slow amplitude, both starts: {:.4}", vgap);
    let t19 = (3.0 / (4.0 / (1.9f64 * 1.9) - 1.0)).ln() / eps;
    println!("from a = 1, the amplitude reaches 1.9 at t = {:.2} units", t19);
    let late = peaks(&vdp(eps), 1.0, 0.0, 300.0);
    let nl = late.len();
    let lp = (late[nl - 1].0 - late[nl - 11].0) / 10.0;
    println!("settled: peak {:.4}; period {:.4} (2 pi = {:.4}, 2 pi (1 + eps^2/16) = {:.4})", late[nl - 1].1, lp, 2.0 * PI, 2.0 * PI * (1.0 + eps * eps / 16.0));

    for e in [1.0, 3.0] {
        println!("beyond: eps = {:.0} (release {:.1} mm): two-timing period {:.4}, exact {:.4}, short by {:.2}%", e, (e * K / K3).sqrt() * 1000.0, tt_period(e), exact_period(e), (1.0 - tt_period(e) / exact_period(e)) * 100.0);
    }
    let p34 = 2.0 * PI / (1.0 + 3.0 * eps / 4.0);
    println!("wrong: 3/4 for 3/8        period {:.4} units = {:.5} s", p34, p34 * t0);
    println!("wrong: frequency kept 1   period {:.4} units = {:.5} s, {:.2}% long", 2.0 * PI, 2.0 * PI * t0, (2.0 * PI / t_ex - 1.0) * 100.0);

    assert!((t_rk - t_ex).abs() < 1e-6, "RK4 period must match the AGM period");
    assert!((c38 - 3.0 / 8.0).abs() < 1e-12, "quadrature must give the 3/8 drift coefficient");
    assert!((lo - 2.0).abs() < 1e-9, "van der Pol growth must vanish at amplitude 2");
    assert!(3.5 < err1 / err2 && err1 / err2 < 4.5, "two-timing period error must shrink like eps^2");
    assert!(gaps[7][2] < 0.1 && gaps[7][1] > 2.0, "two-timing must hold where the plain expansion fails");
    assert!(vgap < 0.05, "slow amplitude must track the RK4 peaks of van der Pol");
    assert!((late[nl - 1].1 - 2.0).abs() < 0.01, "van der Pol must settle at amplitude 2");
    println!("ALL CHECKS PASS");
}
