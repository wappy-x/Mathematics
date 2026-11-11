// States as vectors -- the check behind the card.  Rust std only, no crates.
// A photon polarised at 30 degrees meets a polariser whose axis is at 45 degrees.
// Roads to the pass probability: (1) eigenvectors of the Hermitian matrix, found
// by the 2x2 quadratic written out, then the Born rule; (2) the expected value
// psi* A psi against the eigenvalue average; (3) Malus's law from the angles
// alone; (4) photons simulated one at a time with a seeded generator.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
impl C {
    fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn conj(self) -> C { c(self.re, -self.im) }
    fn scale(self, k: f64) -> C { c(self.re * k, self.im * k) }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}
type V = [C; 2];
type M = [[C; 2]; 2];

fn dot(u: &V, v: &V) -> C { u[0].conj().mul(v[0]).add(u[1].conj().mul(v[1])) } // conjugate the first
fn apply(a: &M, v: &V) -> V {
    [a[0][0].mul(v[0]).add(a[0][1].mul(v[1])), a[1][0].mul(v[0]).add(a[1][1].mul(v[1]))]
}
fn rnd(x: f64) -> f64 { (x * 1e12).round() / 1e12 + 0.0 } // 0, not -6e-17
fn polariser(alpha: f64) -> M { // reading +1 along the axis at angle alpha, -1 across it
    let (co, si) = (rnd((2.0 * alpha).cos()), rnd((2.0 * alpha).sin()));
    [[c(co, 0.0), c(si, 0.0)], [c(si, 0.0), c(0.0 - co, 0.0)]]
}
fn eigen(a: &M) -> Vec<(f64, V)> { // 2x2 Hermitian [[a, b], [conj b, d]]: the quadratic
    let (aa, b, d) = (a[0][0].re, a[0][1], a[1][1].re);
    let r = (((aa - d) / 2.0).powi(2) + b.abs().powi(2)).sqrt();
    let mut out = Vec::new();
    for lam in [(aa + d) / 2.0 + r, (aa + d) / 2.0 - r] {
        let v: V = if b.abs() > 1e-12 { [b, c(lam - aa, 0.0)] }
            else if (lam - aa).abs() < 1e-12 { [c(1.0, 0.0), c(0.0, 0.0)] } else { [c(0.0, 0.0), c(1.0, 0.0)] };
        let n = dot(&v, &v).re.sqrt();
        out.push((lam, [v[0].scale(1.0 / n), v[1].scale(1.0 / n)]));
    }
    out
}
fn measure(a: &M, psi: &V) -> Vec<(f64, f64, V)> { // Born rule: reading, probability, state after
    eigen(a).into_iter().map(|(lam, u)| (lam, dot(&u, psi).abs().powi(2), u)).collect()
}
struct Rng(u64); // SplitMix64, so Python and Rust draw the same numbers
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
}
fn sim(psi: &V, alphas: &[f64], n: usize, rng: &mut Rng) -> usize { // through a chain of polarisers
    let mut passed = 0;
    for _ in 0..n {
        let mut state = *psi;
        let mut through = true;
        for &al in alphas {
            let m = measure(&polariser(al), &state);
            if rng.next() >= m[0].1 { through = false; break; }
            state = m[0].2; // a photon that got through now carries the axis's state
        }
        if through { passed += 1; }
    }
    passed
}
fn rad(d: f64) -> f64 { d * PI / 180.0 }

fn main() {
    let (th, al) = (rad(30.0), rad(45.0));
    let psi: V = [c(th.cos(), 0.0), c(th.sin(), 0.0)];
    let a = polariser(al);
    let m = measure(&a, &psi);
    let ((lp, pp, up), (lm, pm, um)) = (m[0], m[1]);
    println!("state psi at 30 deg: ({:.4}, {:.4}), length squared {:.4}", psi[0].re, psi[1].re, dot(&psi, &psi).re);
    println!("polariser at 45 deg: A = [[{:.4}, {:.4}], [{:.4}, {:.4}]]", a[0][0].re, a[0][1].re, a[1][0].re, a[1][1].re);
    for (lam, u) in [(lp, up), (lm, um)] {
        let au = apply(&a, &u);
        assert!((0..2).all(|k| au[k].sub(u[k].scale(lam)).abs() < 1e-12)); // it really is an eigenvector
        println!("eigenvalue {:+.4}, eigenvector ({:.4}, {:.4})", lam, u[0].re, u[1].re);
    }
    println!("amplitudes: pass port {:.4}, blocked port {:.4}", dot(&up, &psi).re, dot(&um, &psi).re);
    println!("P(pass) {:.4}, P(blocked) {:.4}, sum {:.4}", pp, pm, pp + pm);
    assert!((pp + pm - 1.0).abs() < 1e-12);
    let (ev_sandwich, ev_average) = (dot(&psi, &apply(&a, &psi)).re, lp * pp + lm * pm);
    let malus = (al - th).cos().powi(2);
    println!("expected value: psi* A psi {:.4}, sum of reading x chance {:.4}", ev_sandwich, ev_average);
    println!("Malus's law from the angles: cos^2(15 deg) {:.4}", malus);
    assert!((ev_sandwich - ev_average).abs() < 1e-12 && (pp - malus).abs() < 1e-12);
    let rate = 1_000_000.0;
    println!("of {} photons a second: pass {}, blocked {}, spread {:.0}", rate as u64, (rate * pp).round() as u64, (rate * pm).round() as u64, (rate * pp * pm).sqrt());
    let n = 100_000;
    let k = sim(&psi, &[al], n, &mut Rng(2026));
    let (se, f) = ((pp * (1.0 - pp) / n as f64).sqrt(), k as f64 / n as f64);
    println!("simulated {} photons: {} passed, fraction {:.4}, 4 standard errors {:.4}", n, k, f, 4.0 * se);
    assert!((f - pp).abs() < 4.0 * se);
    let (h, cl, e) = (6.62607015e-34, 299792458.0, 1.602176634e-19); // exact SI values (CODATA)
    let (hbar, lam_m, power) = (h / (2.0 * PI), 633e-9, 1e-3);
    let omega = 2.0 * PI * cl / lam_m;
    let en = hbar * omega;
    println!("hbar {:.6}e-34 J s; 633 nm light: omega {:.4}e15 rad/s, photon energy {:.4}e-19 J = {:.4} eV",
        hbar * 1e34, omega / 1e15, en * 1e19, en / e);
    let flux = power / en;
    println!("1.000 mW beam = {:.4}e15 photons/s; through the polariser {:.4} mW", flux / 1e15, flux * pp * en * 1e3);
    assert!((flux * pp * en - power * malus).abs() < 1e-15 && (en - h * cl / lam_m).abs() < 1e-30);
    let psic: V = [c(th.cos(), 0.0), c(0.0, th.sin())];
    let ph = measure(&polariser(0.0), &psic)[0].1;
    let pc = measure(&a, &psic)[0].1;
    let evc = dot(&psic, &apply(&a, &psic));
    println!("complex state (0.8660, 0.5000i): P(H) {:.4}; at 45 deg P(pass) {:.4}, expected value {:.4}", ph, pc, evc.re);
    assert!((ph - th.cos().powi(2)).abs() < 1e-12 && (pc - (th.cos() * al.cos()).powi(2) - (th.sin() * al.sin()).powi(2)).abs() < 1e-12);
    assert!(evc.sub(c((2.0 * th).cos() * (2.0 * al).cos(), 0.0)).abs() < 1e-12); // elliptical: cos 2theta cos 2alpha
    let pcirc: Vec<f64> = (0..36).map(|i| measure(&polariser(rad(5.0 * i as f64)), &[c(0.5f64.sqrt(), 0.0), c(0.0, 0.5f64.sqrt())])[0].1).collect();
    assert!(pcirc.iter().all(|p| (p - 0.5).abs() < 1e-12)); // circular light: one half at every axis, like unpolarised light
    println!("circular state (0.7071, 0.7071i): P(pass) {:.4} to {:.4} at every axis, 0 to 175 deg", pcirc.iter().cloned().fold(1.0, f64::min), pcirc.iter().cloned().fold(0.0, f64::max));
    // what breaks
    let (ap, am) = (dot(&up, &psi).re, dot(&um, &psi).re);
    println!("breaks, amplitude not squared: {:.4}, two 'chances' sum {:.4}", ap, ap + am);
    let raw: V = [c(3f64.sqrt(), 0.0), c(1.0, 0.0)];
    println!("breaks, state (1.7321, 1) not normalised: P(pass) {:.4}", dot(&up, &raw).abs().powi(2));
    let av = apply(&a, &psic);
    let noconj = psic[0].mul(av[0]).add(psic[1].mul(av[1]));
    println!("breaks, no conjugate on the complex state: 'expected value' {:.4} + {:.4}i", noconj.re, noconj.im);
    println!("breaks, alpha in place of 2 alpha: P(pass) {:.4}", measure(&polariser(al / 2.0), &psi)[0].1);
    let dropped: V = [psic[0], c(psic[1].abs(), 0.0)];
    println!("breaks, phase i dropped: P(pass) {:.4} instead of {:.4}", dot(&up, &dropped).abs().powi(2), pc);
    let nm: M = [[c(1.0, 0.0), c(2.0, 0.0)], [c(0.0, 0.0), c(-1.0, 0.0)]]; // not Hermitian
    let s = 1.0 / 2f64.sqrt();
    let vecs: [V; 2] = [[c(1.0, 0.0), c(0.0, 0.0)], [c(s, 0.0), c(-s, 0.0)]];
    for (lam, v) in [(1.0, vecs[0]), (-1.0, vecs[1])] {
        let nv = apply(&nm, &v);
        assert!((0..2).all(|k| nv[k].sub(v[k].scale(lam)).abs() < 1e-12));
    }
    let fake: f64 = vecs.iter().map(|v| dot(v, &psi).abs().powi(2)).sum();
    let fev = dot(&psi, &apply(&nm, &psi)).re;
    println!("breaks, non-Hermitian [[1, 2], [0, -1]]: 'chances' sum {:.4}, 'expected value' {:.4}", fake, fev);
    assert!((fake - 1.0).abs() > 0.1 && fev > 1.0);
    // a chain of polarisers: 30 deg photon, then 45 deg, then 120 deg
    let p120 = polariser(rad(120.0));
    let (direct, two) = (measure(&p120, &psi)[0].1, pp * measure(&p120, &up)[0].1);
    println!("chain: straight to 120 deg {:.4}; via 45 deg {:.4} x {:.4} = {:.4}", direct, pp, two / pp, two);
    assert!((two - ((al - th).cos() * (rad(120.0) - al).cos()).powi(2)).abs() < 1e-12);
    let k2 = sim(&psi, &[al, rad(120.0)], n, &mut Rng(7));
    let (f2, se2) = (k2 as f64 / n as f64, (two * (1.0 - two) / n as f64).sqrt());
    println!("chain simulated {} photons: {} passed, fraction {:.4}, 4 standard errors {:.4}", n, k2, f2, 4.0 * se2);
    assert!((f2 - two).abs() < 4.0 * se2);
    let bars: Vec<String> = (0..7).map(|i| {
        let md = 30 + 15 * i;
        let first = measure(&polariser(rad(md as f64)), &psi);
        format!("{}:{:.4}", md, first[0].1 * measure(&p120, &first[0].2)[0].1)
    }).collect();
    println!("bars, middle axis deg : fraction through all three  {}", bars.join("  "));
    let angles: Vec<i32> = (0..13).map(|i| 15 * i).collect();
    let row = |st: &V| angles.iter().map(|&d| format!("{:5.3}", measure(&polariser(rad(d as f64)), st)[0].1)).collect::<Vec<_>>().join(" ");
    println!("chart, axis deg      {}", angles.iter().map(|d| format!("{:5}", d)).collect::<Vec<_>>().join(" "));
    println!("chart, linear 30 deg {}", row(&psi));
    println!("chart, complex state {}", row(&psic));
    let (sc, ox, oy) = (160.0, 150.0, 210.0); // figure: 160 px per unit, origin of the plane
    let pts = [("psi", psi[0].re, psi[1].re), ("pass", ap * up[0].re, ap * up[1].re), ("blocked", am * um[0].re, am * um[1].re)];
    println!("figure, px {}", pts.iter().map(|(nm, x, y)| format!("{}:({:.1}, {:.1})", nm, ox + sc * x, oy - sc * y)).collect::<Vec<_>>().join("  "));
    let (p40, m75, k1): (V, _, _) = ([c(rad(40.0).cos(), 0.0), c(rad(40.0).sin(), 0.0)], measure(&polariser(rad(75.0)), &psi), sim(&psi, &[al], n, &mut Rng(1)));
    println!("try: photon at 40 deg P(pass) {:.4}, simulated {} passed", measure(&a, &p40)[0].1, sim(&p40, &[al], n, &mut Rng(2026)));
    println!("try: splitter at 75 deg P(pass) {:.4}, P(blocked) {:.4}, beam {:.4} mW", m75[0].1, m75[1].1, flux * m75[0].1 * en * 1e3);
    println!("try: n = 1000, {} passed, 4 standard errors {:.4}; seed 1, {} passed, fraction {:.4}", sim(&psi, &[al], 1000, &mut Rng(2026)), 4.0 * (pp * pm / 1000.0).sqrt(), k1, k1 as f64 / n as f64);
    println!("ALL CHECKS PASS");
}
