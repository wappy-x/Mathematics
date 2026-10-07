// Paths with a budget -- the same check as the Python, in Rust.  No crates.
// A 6 m chain hangs from hooks 4 m apart at height 0; a 100 m fence encloses
// the most area it can.  Each answer is reached by two roads.
use std::f64::consts::PI;
const D: f64 = 2.0; const L: f64 = 6.0; const FENCE: f64 = 100.0;

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // f(lo) > 0 > f(hi)
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if f(mid) > 0.0 { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {      // Simpson's rule, 2000 panels
    let (m, h) = (2000, (hi - lo) / 2000.0);
    h / 3.0 * (0..=m).map(|i| f(lo + i as f64 * h) * if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).sum::<f64>()
}

fn catenary(length: f64) -> (f64, f64) {                          // road 1: the multiplier rule
    let a = bisect(&|a: f64| 2.0 * a * (D / a).sinh() - length, 0.1, 1e4);
    (a, -a * (D / a).cosh())
}

fn beads(n: usize) -> (f64, f64) {                                // road 2: force balance on beads
    let s = L / n as f64;
    let slopes = |a: f64| -> Vec<f64> { (0..n).map(|k| (k as f64 - (n as f64 - 1.0) / 2.0) * s / a).collect() };
    let a = bisect(&|a: f64| 2.0 * D - slopes(a).iter().map(|t| s / (1.0 + t * t).sqrt()).sum::<f64>(), 0.01, 100.0);
    (a, slopes(a)[..n / 2].iter().map(|t| s * t.abs() / (1.0 + t * t).sqrt()).sum())
}

fn energy(length: f64) -> f64 {                                   // height summed along the chain
    let (a, c) = catenary(length);
    simpson(&|x: f64| (a * (x / a).cosh() + c) * (x / a).cosh(), -D, D)
}

fn polygon(n: usize, perim: f64) -> f64 {                         // shoelace, rescaled to perim
    let p: Vec<(f64, f64)> = (0..n).map(|k| { let t = 2.0 * PI * k as f64 / n as f64; (t.cos(), t.sin()) }).collect();
    let (mut side, mut area) = (0.0, 0.0);
    for i in 0..n {
        let ((x1, y1), (x2, y2)) = (p[i], p[(i + 1) % n]);
        side += (x2 - x1).hypot(y2 - y1);
        area += x1 * y2 - x2 * y1;
    }
    area / 2.0 * (perim / side).powi(2)
}

fn sci(v: f64) -> String {                                        // 1.3e-02, as Python prints it
    let s = format!("{:.1e}", v); let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn main() {
    let (a, c) = catenary(L); let sag = a * ((D / a).cosh() - 1.0);
    println!("chain 6 m, hooks 4 m apart; road 1, multiplier rule: a = {:.4} m, c = lambda = {:.4} m, sag = {:.4} m", a, c, sag);
    for n in [10, 100, 1000] {
        let (an, sn) = beads(n);
        println!("road 2, {:4} beads: a = {:.4} m, sag = {:.4} m, sag error {} m", n, an, sn, sci((sn - sag).abs()));
    }
    println!("cosh(2/a) = {:.4}; tension as a length of chain: bottom {:.4} m, hooks {:.4} m, hook vertical {:.4} m", (D / a).cosh(), a, -c, a * (D / a).sinh());
    let de = (energy(L + 1e-3) - energy(L - 1e-3)) / 2e-3;
    println!("price of chain: dE/dL = {:.4} m against lambda = {:.4} m", de, c);
    let fig: Vec<String> = [-2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0f64].iter()
        .map(|&x| format!("{:.0},{:.1}", 180.0 + 60.0 * x, 40.0 - 60.0 * (a * (x / a).cosh() + c))).collect();
    println!("figure, {}", fig.join(" "));
    let r = FENCE / (2.0 * PI);
    println!("fence: circle radius {:.4} m, area L^2/(4 pi) = {:.4} m^2", r, FENCE * FENCE / (4.0 * PI));
    let gons: Vec<String> = [3, 4, 6, 12, 24, 96].iter().map(|&n| format!("{:.2}", polygon(n, FENCE))).collect();
    println!("regular n-gons, n = 3 4 6 12 24 96: {}", gons.join(" "));
    let (big, da) = (polygon(4096, FENCE), (polygon(4096, FENCE + 0.01) - polygon(4096, FENCE - 0.01)) / 0.02);
    println!("4096-gon area {:.4} m^2; price of fence dA/dL = {:.4} m against radius {:.4} m", big, da, r);
    let k = bisect(&|k: f64| L - simpson(&|x: f64| (1.0 + 4.0 * k * k * x * x).sqrt(), -D, D), 0.0, 5.0);
    println!("mistake 1, a parabola 6 m long: sag {:.4} m; mistake 2, sag read as a cosh(2/a): {:.4} m", 4.0 * k, -c);
    let hyp: Vec<String> = [4.01, 4.001].iter().map(|&x: &f64| format!("chain {} m gives a = {:.1} m", x, catenary(x).0)).collect();
    println!("hypothesis dropped, no slack: {}", hyp.join(", "));
    println!("mistake 3, a square fence: {:.2} m^2, short by {:.2} m^2", polygon(4, FENCE), FENCE * FENCE / (4.0 * PI) - polygon(4, FENCE));
    assert!((beads(1000).1 - sag).abs() < 1e-4);                  // force balance agrees with the multiplier rule
    assert!((de - c).abs() < 1e-4);                               // the multiplier is the price of chain
    assert!((big - FENCE * FENCE / (4.0 * PI)).abs() < 0.01);     // polygons close on the circle
    assert!((da - r).abs() < 1e-3);                               // the fence's multiplier is the radius
    println!("ALL CHECKS PASS");
}
