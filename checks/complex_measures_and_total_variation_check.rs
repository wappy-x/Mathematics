// Complex measures and total variation -- the same check as the Python, in
// Rust, no crates.  Complex numbers are a small struct written here.
// The runner: x is km run on a circular path of radius 1 km, so the heading
// at x is e^(ix).  nu(E) = integral over E of e^(ix) dx is the net
// displacement (east + i north) over the stretches E; |nu|(E) is the km run.
// Road 1: closed forms from the antiderivative e^(ix) / i.
// Road 2: midpoint sums for nu, |nu|, the real and imaginary parts, integrals.
// Road 3: total variation as a supremum: cut into n equal stretches and add
//         |nu(piece)| (inscribed polygons); all 203 cuts of six stretches;
//         |nu(E)| <= length(E) on all 4095 non-empty unions of twelve stretches.
// Polar form: h = nu(I) / |nu|(I) on short stretches I, against e^(ix).
// The code checks this example; the proofs cover every complex measure.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
const TAU: f64 = 2.0 * PI;
const ZERO: C = C { re: 0.0, im: 0.0 };
fn snap(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }
fn r4(x: f64) -> String { format!("{:.4}", snap(x)) }
fn r6(x: f64) -> String { format!("{:.6}", snap(x)) }
fn c4(z: C) -> String {
    let (re, im) = (snap(z.re), snap(z.im));
    format!("{:.4} {} {:.4}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn expi(x: f64) -> C { C { re: x.cos(), im: x.sin() } }
fn nu(a: f64, b: f64) -> C { let d = expi(b).sub(expi(a)); C { re: d.im, im: -d.re } } // divide by i: road 1
fn midpoint(g: &dyn Fn(f64) -> C, a: f64, b: f64, n: usize) -> C { // road 2
    let h = (b - a) / n as f64;
    let mut s = ZERO;
    for k in 0..n { s = s.add(g(a + (k as f64 + 0.5) * h)); }
    s.scale(h)
}
fn real(x: f64) -> C { C { re: x, im: 0.0 } }
fn cut(a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;
    (0..n).map(|k| nu(a + k as f64 * w, a + (k + 1) as f64 * w).abs()).sum()
}
// every way to cut six items into blocks: block labels in restricted-growth form
fn partitions(labels: &mut Vec<usize>, top: usize, out: &mut Vec<Vec<usize>>) {
    if labels.len() == 6 { out.push(labels.clone()); return; }
    for b in 0..=top {
        labels.push(b);
        partitions(labels, if b == top { top + 1 } else { top }, out);
        labels.pop();
    }
}

fn main() {
    // the lap and the half lap
    let (lap, lap_m) = (nu(0.0, TAU), midpoint(&expi, 0.0, TAU, 200000));
    let run_m = midpoint(&|x| real(expi(x).abs()), 0.0, TAU, 200000).re;
    let (half, half_m) = (nu(0.0, PI), midpoint(&expi, 0.0, PI, 200000));
    let two_i = C { re: 0.0, im: 2.0 };
    assert!(lap.abs() < 1e-12 && lap_m.abs() < 1e-9 && (run_m - TAU).abs() < 1e-9);
    assert!(half.sub(two_i).abs() < 1e-12 && half_m.sub(two_i).abs() < 1e-9);
    println!("lap, nu([0, 2 pi]) closed form: {} | midpoint: {}", c4(lap), c4(lap_m));
    println!("lap, |nu|([0, 2 pi]) = km run: {} | midpoint of |e^(ix)|: {}", r4(TAU), r4(run_m));
    println!("half lap, nu([0, pi]) closed form: {} | midpoint: {}", c4(half), c4(half_m));
    println!("half lap, |nu([0, pi])| = {} km apart | |nu|([0, pi]) = {} km run", r4(half.abs()), r4(PI));

    // road 3: the supremum over cuts, approached by inscribed polygons
    for n in [1usize, 2, 4, 6, 12, 96, 1000] {
        let (s, poly) = (cut(0.0, TAU, n), 2.0 * n as f64 * (PI / n as f64).sin());
        assert!((s - poly).abs() < 1e-9 && s <= TAU + 1e-12);
        println!("cut lap into n = {} stretches: sum |nu(piece)| = {}", n, r6(s));
    }
    for n in [1usize, 2, 1000] { println!("cut half lap into n = {}: {}", n, r6(cut(0.0, PI, n))); }
    assert!((cut(0.0, PI, 1000) - PI).abs() < 1e-5);
    assert!(TAU - cut(0.0, TAU, 1000) < 2e-5);

    let six: Vec<C> = (0..6).map(|k| nu(k as f64 * TAU / 6.0, (k + 1) as f64 * TAU / 6.0)).collect();
    let mut parts = Vec::new();
    partitions(&mut Vec::new(), 0, &mut parts);
    let sums: Vec<f64> = parts.iter().map(|pt| {
        let nb = pt.iter().max().unwrap() + 1;
        (0..nb).map(|b| (0..6).filter(|&i| pt[i] == b).fold(ZERO, |z, i| z.add(six[i])).abs()).sum()
    }).collect();
    let best = sums.iter().cloned().fold(f64::MIN, f64::max);
    assert!(parts.len() == 203 && (best - 6.0).abs() < 1e-12 && sums.iter().filter(|&&s| s == best).count() == 1);
    println!("all {} cuts of six 60-degree stretches: best {}, from the finest cut only", parts.len(), r4(best));

    // real and imaginary parts: two signed measures, cos x dx and sin x dx
    let tv_r = midpoint(&|x| real(x.cos().abs()), 0.0, TAU, 200000).re;
    let tv_i = midpoint(&|x| real(x.sin().abs()), 0.0, TAU, 200000).re;
    assert!((tv_r - 4.0).abs() < 1e-8 && (tv_i - 4.0).abs() < 1e-8);
    assert!(tv_r.max(tv_i) <= TAU && TAU <= tv_r + tv_i);
    println!("parts, |nu_r|([0, 2 pi]) = integral |cos x|: {} | |nu_i| = integral |sin x|: {}", r4(tv_r), r4(tv_i));
    println!("parts, max {} <= |nu| {} <= sum {} | square root of the sum of squares {}",
             r4(tv_r.max(tv_i)), r4(TAU), r4(tv_r + tv_i), r4(tv_r.hypot(tv_i)));

    // domination: length dominates nu on every union of twelve 30-degree stretches
    let twelve: Vec<C> = (0..12).map(|k| nu(k as f64 * TAU / 12.0, (k + 1) as f64 * TAU / 12.0)).collect();
    let mut top = 0.0f64;
    for m in 1usize..4096 {
        let z = (0..12).filter(|k| m >> k & 1 == 1).fold(ZERO, |z, k| z.add(twelve[k]));
        top = top.max(z.abs() / (m.count_ones() as f64 * TAU / 12.0));
    }
    assert!(top <= 1.0 && (top - 2.0 * (PI / 12.0).sin() / (PI / 6.0)).abs() < 1e-12);
    println!("dominate, |nu(E)| <= length(E) on all 4095 non-empty unions of twelve stretches; largest ratio {}", r6(top));
    let short = nu(0.0, 0.1).abs();
    assert!(short > 0.99 * 0.1);
    println!("dominate, 0.99 x length fails on [0, 0.1]: |nu| = {} > {}", r6(short), r6(0.99 * 0.1));

    // polar form: h = nu(I) / |nu|(I) on I = [x - 0.0005, x + 0.0005]
    for x in [0.0, 1.0, PI / 2.0, PI] {
        let h = nu(x - 0.0005, x + 0.0005).scale(1.0 / 0.001);
        assert!(h.sub(expi(x)).abs() < 1e-7 && (h.abs() - 1.0).abs() < 1e-7);
        println!("polar, x = {}: h = {}, |h| = {}, e^(ix) = {}", r4(x), c4(h), r6(h.abs()), c4(expi(x)));
    }

    // integrals against nu: integral f dnu = integral f(x) e^(ix) dx
    let fs: [(&str, Box<dyn Fn(f64) -> C>, C, f64); 3] = [
        ("e^(-ix)", Box::new(|x: f64| expi(-x)), real(TAU), TAU),
        ("cos x", Box::new(|x: f64| real(x.cos())), real(PI), 4.0),
        ("x", Box::new(|x: f64| real(x)), C { re: 0.0, im: -TAU }, TAU * PI),
    ];
    for (name, f, closed, bound) in fs.iter() {
        let val = midpoint(&|x| f(x).mul(expi(x)), 0.0, TAU, 200000);
        let rhs = midpoint(&|x| real(f(x).abs()), 0.0, TAU, 200000).re;
        assert!(val.sub(*closed).abs() < 1e-8 && (rhs - bound).abs() < 1e-8 && val.abs() <= rhs + 1e-9);
        println!("integral, f = {}: integral f dnu = {}, size {} <= integral |f| d|nu| = {}", name, c4(val), r4(val.abs()), r4(rhs));
    }

    // what breaks
    println!("breaks, |nu([0, 2 pi])| read as |nu|: {}", r4(lap.abs()));
    println!("breaks, |nu_r| + |nu_i| read as |nu|: {}", r4(tv_r + tv_i));
    println!("breaks, the hexagon cut read as |nu|: {}", r4(cut(0.0, TAU, 6)));
    let grow: Vec<f64> = [1.0, 10.0, 100.0].iter().map(|&k| midpoint(&|x| real(expi(x).abs()), 0.0, TAU * k, 20000).re).collect();
    assert!((grow[2] - 100.0 * TAU).abs() < 1e-6);
    println!("breaks, whole line: |nu|([0, 2 pi k]) for k = 1, 10, 100: {}", grow.iter().map(|&g| r4(g)).collect::<Vec<_>>().join(" "));
    println!("breaks, whole line: nu([0, t]) for t = 1, 2, 3: {}", [1.0, 2.0, 3.0].iter().map(|&t| c4(nu(0.0, t))).collect::<Vec<_>>().join(" ; "));

    // try changing
    let tq = nu(0.0, 1.5 * PI);
    println!("try, three-quarter lap: nu([0, 3 pi/2]) = {}, size {} | |nu| = {}", c4(tq), r4(tq.abs()), r4(1.5 * PI));
    println!("try, cut lap into n = 3 stretches: {}", r6(cut(0.0, TAU, 3)));
    let vs = midpoint(&|x| real(x.sin()).mul(expi(x)), 0.0, TAU, 200000);
    assert!(vs.sub(C { re: 0.0, im: PI }).abs() < 1e-8);
    println!("try, f = sin x: integral f dnu = {}, size {} <= {}", c4(vs), r4(vs.abs()), r4(tv_i));
    println!("try, 0.9999 x length: on [0, 0.1] {:.8} vs {:.8}; on [0, 0.01] {:.8} vs {:.8}",
             nu(0.0, 0.1).abs(), 0.9999 * 0.1, nu(0.0, 0.01).abs(), 0.9999 * 0.01);

    // chart: distance apart against km run along the lap
    let ts: Vec<f64> = (0..9).map(|k| k as f64 * PI / 4.0).collect();
    println!("chart, km run t: {}", ts.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, |nu([0, t])| km apart: {}", ts.iter().map(|&t| format!("{:.2}", nu(0.0, t).abs())).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
