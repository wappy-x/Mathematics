// Closed and exact forms -- the same check as the Python, in Rust.  No crates.
// A market maker sells three contracts on tomorrow's weather in a valley: Rain,
// Wind, Calm.  x = (x1, x2, x3) counts shares sold; a trade dx costs the price
// one-form w = p1 dx1 + p2 dx2 + p3 dx3 dollars.  Is w closed?  Exact?  Then the
// same two questions for a two-form: the wind's flux through a gate.
use std::f64::consts::PI;
type F<'a> = &'a dyn Fn(&[f64]) -> Vec<f64>;
const B: f64 = 100.0; // liquidity, dollars

fn lmsr(x: &[f64]) -> Vec<f64> { lmsr_b(x, B) }
fn lmsr_b(x: &[f64], b: f64) -> Vec<f64> { // prices from the log cost function
    let e: Vec<f64> = x.iter().map(|xi| (xi / b).exp()).collect();
    let z: f64 = e.iter().sum();
    e.iter().map(|ei| ei / z).collect()
}
fn naive(x: &[f64]) -> Vec<f64> { naive_s(x, 300.0) }
fn naive_s(x: &[f64], s: f64) -> Vec<f64> { // a desk's straight-line rule
    (0..3).map(|i| 1.0 / 3.0 + (x[i] - x[(i + 1) % 3]) / s).collect()
}
fn cost(x: &[f64]) -> f64 { B * x.iter().map(|xi| (xi / B).exp()).sum::<f64>().ln() }
fn rate(f: F, x: &[f64], i: usize, j: usize) -> f64 { // d f_i / d x_j, central difference
    let h = 1e-3;
    let (mut up, mut dn) = (x.to_vec(), x.to_vec());
    up[j] += h;
    dn[j] -= h;
    (f(&up)[i] - f(&dn)[i]) / (2.0 * h)
}
fn simpson(g: &dyn Fn(f64) -> f64, n: usize) -> f64 { // integral of g over [0, 1], n even
    let mut s = g(0.0) + g(1.0);
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(k as f64 / n as f64) }
    s / (3.0 * n as f64)
}
fn leg(f: F, a: &[f64], b: &[f64], n: usize) -> f64 { // line integral of f . dx, a to b
    let d: Vec<f64> = (0..a.len()).map(|i| b[i] - a[i]).collect();
    simpson(&|t| {
        let m: Vec<f64> = (0..a.len()).map(|i| a[i] + t * d[i]).collect();
        f(&m).iter().zip(&d).map(|(c, e)| c * e).sum()
    }, n)
}
fn route(f: F, pts: &[Vec<f64>], n: usize) -> f64 {
    pts.windows(2).map(|w| leg(f, &w[0], &w[1], n)).sum()
}
fn radial(f: F, x: &[f64], n: usize) -> f64 { // Poincare's potential: the straight ray
    simpson(&|t| {
        let m: Vec<f64> = x.iter().map(|xi| t * xi).collect();
        f(&m).iter().zip(x).map(|(c, e)| c * e).sum()
    }, n)
}
fn fx(v: f64) -> String { format!("{:.6}", v + 0.0).replace("-0.000000", "0.000000") }
fn wind(q: &[f64]) -> Vec<f64> { vec![q[0], q[1], -2.0 * q[2]] } // m/s at q in km
fn cross(a: &[f64], b: &[f64]) -> Vec<f64> {
    vec![a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn alpha(q: &[f64], weight: bool) -> Vec<f64> { // K(beta): integral of t^(k-1) (v(tq) x q)
    (0..3).map(|i| simpson(&|t| {
        let tq: Vec<f64> = q.iter().map(|c| t * c).collect();
        (if weight { t } else { 1.0 }) * cross(&wind(&tq), q)[i]
    }, 20)).collect()
}
fn curl(f: F, q: &[f64]) -> Vec<f64> {
    let r = |i, j| rate(f, q, i, j);
    vec![r(2, 1) - r(1, 2), r(0, 2) - r(2, 0), r(1, 0) - r(0, 1)]
}
fn angle(c: &[f64]) -> Vec<f64> { // d(theta) round a carousel's centre
    let r2 = c[0] * c[0] + c[1] * c[1];
    vec![-c[1] / r2, c[0] / r2]
}
fn src(c: &[f64]) -> Vec<f64> {
    let r3 = c.iter().map(|e| e * e).sum::<f64>().powf(1.5);
    c.iter().map(|ci| ci / r3).collect()
}
fn sph(n: usize) -> f64 { // flux out of the unit sphere, n rings
    let mut total = 0.0;
    for k in 0..n {
        let ph = (k as f64 + 0.5) * PI / n as f64;
        for m in 0..2 * n {
            let th = (m as f64 + 0.5) * PI / n as f64;
            let c = [ph.sin() * th.cos(), ph.sin() * th.sin(), ph.cos()];
            let dot: f64 = src(&c).iter().zip(&c).map(|(u, w)| u * w).sum();
            total += dot * ph.sin() * (PI / n as f64).powi(2);
        }
    }
    total
}
fn join(v: &[f64], f: &dyn Fn(f64) -> String) -> String {
    v.iter().map(|c| f(*c)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let x = vec![60.0, 30.0, 0.0];
    let p = lmsr(&x);
    println!("trade: buy 60 Rain and 30 Wind from x = (0, 0, 0); b = 100 dollars");
    println!("prices at (60, 30, 0): Rain {}, Wind {}, Calm {}", fx(p[0]), fx(p[1]), fx(p[2]));
    let ex: Vec<f64> = x.iter().map(|xi| (xi / B).exp()).collect();
    println!("exp(x/b): {}; sum Z {}; C(0) {}, C(x) {}", join(&ex, &fx), fx(ex.iter().sum()),
             fx(cost(&[0.0, 0.0, 0.0])), fx(cost(&x)));
    for (i, j) in [(0, 1), (1, 2), (0, 2)] {
        println!("closed test x{},x{}: dp{}/dx{} {}, dp{}/dx{} {}, formula -p{}p{}/b {}", i + 1, j + 1,
                 i + 1, j + 1, fx(rate(&lmsr, &x, i, j)), j + 1, i + 1, fx(rate(&lmsr, &x, j, i)),
                 i + 1, j + 1, fx(-p[i] * p[j] / B));
    }
    let exact = cost(&x) - cost(&[0.0, 0.0, 0.0]);
    let stairs = route(&lmsr, &[vec![0.0, 0.0, 0.0], vec![60.0, 0.0, 0.0], vec![60.0, 30.0, 0.0]], 20);
    let (r10, r20) = (radial(&lmsr, &x, 10), radial(&lmsr, &x, 20));
    println!("potential C(x) - C(0), closed form: {} dollars", fx(exact));
    println!("radial formula, Simpson 10 / 20 steps: {} / {}", fx(r10), fx(r20));
    println!("radial formula errors, 10 / 20 steps: {:.10} / {:.10}", (r10 - exact).abs(), (r20 - exact).abs());
    println!("staircase route, Rain first then Wind: {}", fx(stairs));
    let sq: Vec<Vec<f64>> = [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]]
        .iter().map(|c| vec![c[0], c[1], 0.0]).collect();
    let mut pts: Vec<Vec<f64>> = (0..8).map(|k| (0..3).map(|i|
        sq[k / 2][i] + (k % 2) as f64 * (sq[k / 2 + 1][i] - sq[k / 2][i]) / 2.0).collect()).collect();
    pts.push(sq[4].clone());
    let (mut cum_l, mut cum_n) = (vec![0.0], vec![0.0]);
    for w in pts.windows(2) {
        cum_l.push(cum_l.last().unwrap() + leg(&lmsr, &w[0], &w[1], 20));
        cum_n.push(cum_n.last().unwrap() + leg(&naive, &w[0], &w[1], 20));
    }
    let two = |v: f64| format!("{:.2}", v + 0.0).replace("-0.00", "0.00");
    println!("chart, shares traded: {}", (0..9).map(|k| (50 * k).to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, cash paid, log-cost maker: {}", join(&cum_l, &two));
    println!("chart, cash paid, straight-line rule: {}", join(&cum_n, &two));
    let defect = rate(&naive, &x, 1, 0) - rate(&naive, &x, 0, 1);
    println!("straight-line rule: dp1/dx2 {}, dp2/dx1 {}, defect {} per share squared",
             fx(rate(&naive, &x, 0, 1)), fx(rate(&naive, &x, 1, 0)), fx(defect));
    let (net_l, net_n) = (-cum_l[8], -cum_n[8]);
    println!("round trip, log-cost maker: trader nets {} dollars", fx(net_l));
    println!("round trip, straight-line rule: trader nets {} dollars; defect x area {}", fx(net_n), fx(defect * 1e4));
    let rev: Vec<Vec<f64>> = sq.iter().rev().cloned().collect();
    println!("reverse lap on the straight-line rule: trader nets {}", fx(-route(&naive, &rev, 20)));
    let (lap50, lap150) = (-route(&|c: &[f64]| lmsr_b(c, 50.0), &sq, 20), -route(&|c: &[f64]| naive_s(c, 150.0), &sq, 20));
    println!("try: b = 50, log-cost lap: trader nets {}; straight-line rule over 150: trader nets {}", fx(lap50), fx(lap150));
    let q = vec![1.0, 1.0, 0.5];
    let div: f64 = (0..3).map(|i| rate(&wind, &q, i, i)).sum();
    println!("wind at (1, 1, 0.5) km: {} m/s; closed test d(beta) = div {}", join(&wind(&q), &fx), fx(div));
    let a = alpha(&q, true);
    let al = |c: &[f64]| alpha(c, true);
    let da = curl(&al, &q);
    println!("potential alpha = K(beta) at that point: {}; formula (yz, -xz, 0)", join(&a, &fx));
    println!("d(alpha) by finite differences: {}", join(&da, &fx));
    let gate: Vec<Vec<f64>> = [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]]
        .iter().map(|c| vec![1.0, c[0], c[1]]).collect();
    let mut flux = 0.0;
    for j in 0..40 { for k in 0..40 {
        flux += wind(&[1.0, (j as f64 + 0.5) / 40.0, (k as f64 + 0.5) / 40.0])[0];
    } }
    flux /= 1600.0;
    let circ = route(&al, &gate, 20);
    let bad = route(&|c: &[f64]| alpha(c, false), &gate, 20);
    println!("gate x = 1 km, 1 km by 1 km: flux {}, circulation of alpha {} (m/s)km^2", fx(flux), fx(circ));
    println!("mistake, dropping the t weight: circulation {}", fx(bad));
    println!("angle form at (1, 2): dP/dy {}, dQ/dx {}", fx(rate(&angle, &[1.0, 2.0], 0, 1)),
             fx(rate(&angle, &[1.0, 2.0], 1, 0)));
    let bx: Vec<Vec<f64>> = vec![vec![1.0, -1.0], vec![1.0, 1.0], vec![-1.0, 1.0], vec![-1.0, -1.0], vec![1.0, -1.0]];
    let (l8, l64) = (route(&angle, &bx, 8), route(&angle, &bx, 64));
    println!("lap round the centre, Simpson 8 / 64 steps a side: {} / {}; 2 pi {}", fx(l8), fx(l64), fx(2.0 * PI));
    let dsrc: f64 = (0..3).map(|i| rate(&src, &[1.0, 2.0, 2.0], i, i)).sum();
    let (s50, s100) = (sph(50), sph(100));
    println!("point source: div at (1, 2, 2) {}; sphere flux 50 / 100 rings {} / {}; 4 pi {}",
             fx(dsrc), fx(s50), fx(s100), fx(4.0 * PI));
    assert!((rate(&lmsr, &x, 0, 1) - rate(&lmsr, &x, 1, 0)).abs() < 1e-9); // closed, by differences
    assert!((rate(&lmsr, &x, 0, 1) + p[0] * p[1] / B).abs() < 1e-8); // against the formula
    assert!((r20 - exact).abs() < 1e-6 && (stairs - exact).abs() < 1e-6); // three roads, one potential
    assert!(cum_l[8].abs() < 1e-6 && (net_n - defect * 1e4).abs() < 1e-6); // loop = defect x area
    assert!(lap50.abs() < 1e-6 && (lap150 - 2.0 * defect * 1e4).abs() < 1e-6); // exact at any b; half the 300, twice the defect
    assert!((a[0] - q[1] * q[2]).abs() < 1e-6 && (a[1] + q[0] * q[2]).abs() < 1e-6 && a[2].abs() < 1e-6);
    assert!(da.iter().zip(wind(&q)).all(|(u, w)| (u - w).abs() < 1e-6)); // d(alpha) = beta
    assert!((flux - circ).abs() < 1e-9 && (bad - 1.5).abs() < 1e-9);
    assert!((l64 - 2.0 * PI).abs() < 1e-6 && (s100 - 4.0 * PI).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
