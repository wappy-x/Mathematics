// Von Neumann analysis and the CFL condition -- the check behind the card.  Rust std only.
// A 1 m steel bar, ends held at 0, nodes h = 1 cm apart (j = 0..100).
// Road 1: run each scheme in a loop.  Road 2: feed one wave e^(i xi j h) into the
// scheme's stencil, read off g, and project the loop's output onto that wave.
// Road 3: closed forms, the bar's exact Fourier series and d'Alembert's formula.
use std::f64::consts::PI;
const H: f64 = 0.01; const J: usize = 100; const ALPHA: f64 = 1.25e-5; const C: f64 = 5000.0;
type St = Vec<(i32, f64)>;

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Cx {
    fn mul(self, o: Cx) -> Cx { Cx { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn add(self, o: Cx) -> Cx { Cx { re: self.re + o.re, im: self.im + o.im } }
    fn scale(self, s: f64) -> Cx { Cx { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn div(self, o: Cx) -> Cx { let d = o.re * o.re + o.im * o.im;
        Cx { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
    fn sqrt(self) -> Cx { let m = self.abs(); let re = ((m + self.re) / 2.0).sqrt();
        let im = ((m - self.re) / 2.0).sqrt(); Cx { re, im: if self.im < 0.0 { -im } else { im } } }
}
fn s2(p: f64) -> f64 { (p / 2.0).sin().powi(2) }
fn phis() -> Vec<f64> { (1..J).map(|k| k as f64 * PI / J as f64).collect() }
fn poly(w: &St, phi: f64) -> Cx {     // sum of w[m] e^(i m phi): the stencil seen by one wave
    let (mut re, mut im) = (0.0, 0.0);
    for &(m, a) in w { re += a * (m as f64 * phi).cos(); im += a * (m as f64 * phi).sin(); }
    Cx { re, im }
}
fn g_feed(st: &[St], phi: f64) -> f64 {   // largest |g| that solves the stencil's equation
    if st.len() == 2 { return poly(&st[1], phi).div(poly(&st[0], phi)).abs(); }
    let b = poly(&st[2], phi);              // three levels: g^2 = mid g + old
    let d = b.mul(b).add(poly(&st[1], phi).scale(4.0)).sqrt();
    b.add(d).scale(0.5).abs().max(b.add(d.scale(-1.0)).scale(0.5).abs())
}
fn heat(r: f64, steps: usize) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let mut u: Vec<f64> = (0..=J).map(|j| if (46..=54).contains(&j) { 100.0 }
        else if j == 45 || j == 55 { 50.0 } else { 0.0 }).collect();
    let (mut hist, mut prev) = (vec![], u.clone());
    for n in 0..=steps {
        if n % 30 == 0 { hist.push(u.iter().fold(0.0f64, |m, x| m.max(x.abs())).log10()); }
        if n < steps {
            let mut v = vec![0.0; J + 1];
            for j in 1..J { v[j] = r * u[j - 1] + (1.0 - 2.0 * r) * u[j] + r * u[j + 1]; }
            prev = u; u = v;
        }
    }
    (u, prev, hist)
}
fn mode(u: &[f64], k: usize) -> f64 {
    let mut s = 0.0;
    for j in 1..J { s += u[j] * (k as f64 * PI * j as f64 / J as f64).sin(); }
    2.0 / J as f64 * s
}
fn tent(x: f64, c0: f64, w: f64) -> f64 {
    let x = (x + 1.0).rem_euclid(2.0) - 1.0;
    if x >= 0.0 { 0.0f64.max(1.0 - (x - c0).abs() / w) } else { -(0.0f64.max(1.0 - (-x - c0).abs() / w)) }
}
fn exact_wave(j: usize, t: f64, c0: f64, w: f64) -> f64 {
    (tent(j as f64 * H - C * t, c0, w) + tent(j as f64 * H + C * t, c0, w)) / 2.0 + 0.0
}
fn wave(nu: f64, steps: usize, c0: f64, w: f64) -> (Vec<f64>, Vec<f64>) {
    let mut u0: Vec<f64> = (0..=J).map(|j| tent(j as f64 * H, c0, w)).collect();
    let d2 = |u: &[f64], j: usize| u[j - 1] - 2.0 * u[j] + u[j + 1];
    let mut u = vec![0.0; J + 1];
    for j in 1..J { u[j] = u0[j] + nu * nu / 2.0 * d2(&u0, j); }
    for _ in 0..steps - 1 {
        let mut v = vec![0.0; J + 1];
        for j in 1..J { v[j] = 2.0 * u[j] - u0[j] + nu * nu * d2(&u, j); }
        u0 = u; u = v;
    }
    (u0, u)
}
fn sci(x: f64, d: usize) -> String {    // Python's e-notation: 5.783e-02
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn ftcs(r: f64) -> Vec<St> { vec![vec![(0, 1.0)], vec![(-1, r), (0, 1.0 - 2.0 * r), (1, r)]] }
fn lf(nu: f64, p: f64) -> f64 {
    let beta = 1.0 - 2.0 * nu * nu * s2(p);
    1.0f64.max(beta.abs() + 0.0f64.max(beta * beta - 1.0).sqrt())
}
fn main() {
    let ph = phis(); let last = ph[J - 2];
    println!("== heat: 1 m steel bar, ends at 0 C, alpha = 1.25e-5 m^2/s, h = 0.01 m, middle 10 cm at 100 C ==");
    println!("limit h^2/(2 alpha) = {:.4} s; on this grid exactly r <= {:.6}, dt <= {:.5} s",
             H * H / (2.0 * ALPHA), 1.0 / (2.0 * s2(last)), H * H / (2.0 * ALPHA * s2(last)));
    let (mut chart, mut u, mut gk) = (vec![], vec![], vec![]);
    for &r in &[0.4, 0.5, 0.51] {
        let dt = r * H * H / ALPHA;
        gk = ph.iter().map(|&p| 1.0 - 4.0 * r * s2(p)).collect::<Vec<f64>>();
        let fed = ph.iter().zip(&gk).fold(0.0f64, |m, (&p, a)| m.max((a.abs() - g_feed(&ftcs(r), p)).abs()));
        assert!(fed < 1e-12);                                         // fed = formula
        let (uu, prev, hist) = heat(r, 300);
        u = uu; chart.push(hist);
        let u0 = heat(r, 0).0;
        let mut spect = 0.0;
        for k in 1..J { spect += mode(&u0, k) * gk[k - 1].powi(300) * (k as f64 * PI / 2.0).sin(); }
        assert!((spect - u[50]).abs() < 1e-9 * 1.0f64.max(u[50].abs()));   // loop = waves times g^n
        let k = if r > 0.45 { 99 } else { 1 };
        let ratio = mode(&u, k) / mode(&prev, k);
        assert!((ratio - gk[k - 1]).abs() < 1e-9);                    // measured growth = predicted g
        let t = 300.0 * dt;
        let mut tr = 0.0;
        for k in 1..400 { let kp = k as f64 * PI;
            tr += 200.0 / kp * ((0.45 * kp).cos() - (0.55 * kp).cos()) * (-ALPHA * kp.powi(2) * t).exp() * (kp / 2.0).sin(); }
        println!("r = {:.2}: dt = {:.2} s; g(k=1) = {:.6}, g(k=99) = {:.6}, measured g(k={}) = {:.6}", r, dt, gk[0], gk[98], k, ratio);
        println!("  300 steps = {:.0} s: middle {:.4} C, true bar {:.4} C, true error {:.4} C", t, u[50], tr, u[50] - tr);
        assert!(r > 0.5 || (u[50] - tr).abs() < 0.03);                // stable grid tracks the true bar
    }
    assert!(u[50] > 1000.0 && gk[0].abs() < 1.0);                     // r = 0.51: k = 1 alone looks safe
    println!("r = 0.51 at 1224 s: neighbour reads {:.1} C", u[49]);
    for (r, h) in ["0.40", "0.50", "0.51"].iter().zip(&chart) {
        let pts: Vec<String> = h.iter().map(|v| format!("{:.3}", v)).collect();
        println!("chart log10 max|U|, r = {}, n = 0..300 by 30: {}", r, pts.join(" "));
    }
    println!("== max |g| over the 99 modes: one wave fed through each stencil ==");
    let mut rows: Vec<(&str, &str, Vec<St>, Box<dyn Fn(f64) -> f64>)> = vec![
        ("heat explicit", "r = 0.51", ftcs(0.51), Box::new(|p| (1.0 - 2.04 * s2(p)).abs())),
        ("heat implicit", "r = 5", vec![vec![(-1, -5.0), (0, 11.0), (1, -5.0)], vec![(0, 1.0)]], Box::new(|p| 1.0 / (1.0 + 20.0 * s2(p))))];
    for &(nu, s) in &[(0.5, "nu = 0.5"), (1.2, "nu = 1.2")] {
        rows.push(("transport centred", s, vec![vec![(0, 1.0)], vec![(-1, nu / 2.0), (0, 1.0), (1, -nu / 2.0)]],
                   Box::new(move |p: f64| (1.0 + (nu * p.sin()).powi(2)).sqrt())));
        rows.push(("transport upwind", s, vec![vec![(0, 1.0)], vec![(-1, nu), (0, 1.0 - nu)]],
                   Box::new(move |p| (1.0 - 4.0 * nu * (1.0 - nu) * s2(p)).sqrt())));
        rows.push(("transport Lax-Wendroff", s, vec![vec![(0, 1.0)], vec![(-1, (nu * nu + nu) / 2.0), (0, 1.0 - nu * nu), (1, (nu * nu - nu) / 2.0)]],
                   Box::new(move |p| (1.0 - 4.0 * nu * nu * (1.0 - nu * nu) * s2(p).powi(2)).sqrt())));
    }
    for &(nu, s) in &[(0.9, "nu = 0.9"), (1.0, "nu = 1"), (1.02, "nu = 1.02")] {
        rows.push(("wave leapfrog", s, vec![vec![(0, 1.0)], vec![(0, -1.0)], vec![(-1, nu * nu), (0, 2.0 - 2.0 * nu * nu), (1, nu * nu)]],
                   Box::new(move |p| lf(nu, p))));
    }
    for (name, s, st, closed) in &rows {
        let mx = ph.iter().fold(0.0f64, |m, &p| m.max(g_feed(st, p)));
        assert!((mx - ph.iter().fold(0.0f64, |m, &p| m.max(closed(p)))).abs() < 1e-9);  // fed = closed form
        println!("{:22} {:9} max|g| = {:.6}  {}", name, s, mx, if mx <= 1.0 + 1e-12 { "stable" } else { "grows" });
    }
    println!("== sound in the bar: c = 5000 m/s, tent pulse 1 um high, 10 cm wide ==");
    println!("CFL limit h/c = {:.2} us; on this grid exactly nu <= {:.7}", H / C * 1e6, 1.0 / (last / 2.0).sin());
    let (mut prev, mut err) = (vec![], 0.0);
    for &(nu, s, n) in &[(0.9, "0.9", 100), (1.0, "1", 100), (1.02, "1.02", 50)] {
        let (p, uu) = wave(nu, n, 0.5, 0.05);
        prev = p; u = uu;
        let t = n as f64 * nu * H / C;
        err = (0..=J).fold(0.0f64, |m, j| m.max((u[j] - exact_wave(j, t, 0.5, 0.05)).abs()));
        println!("nu = {}: dt = {:.2} us, {} steps = {:.0} us; middle {:.6} um, exact {:.6}; worst true error {} um",
                 s, nu * H / C * 1e6, n, t * 1e6, u[50], exact_wave(50, t, 0.5, 0.05), sci(err, 3));
    }
    assert!(err > 1e5);                                               // nu = 1.02 has blown up
    let b = 1.0 - 2.0 * 1.02 * 1.02 * s2(last);
    let ratio = mode(&u, 99) / mode(&prev, 99);
    println!("nu = 1.02: mode k = 99 grows by {:.6} a step; root of g^2 - 2 beta g + 1 = {:.6}", ratio, b - (b * b - 1.0).sqrt());
    assert!((ratio - (b - (b * b - 1.0).sqrt())).abs() < 1e-6);
    let u1 = wave(1.0, 70, 0.5, 0.05).1;
    assert!((0..=J).all(|j| (u1[j] - exact_wave(j, 1.4e-4, 0.5, 0.05)).abs() < 1e-12));   // nu = 1: exact at 70 steps too
    let u2 = wave(2.0, 5, 0.40, 0.03).1;                              // pulse outside the stencil's reach
    let ex = exact_wave(50, 5.0 * 2.0 * H / C, 0.40, 0.03);
    println!("nu = 2 (dt = {:.2} us), pulse at 0.40 m: after 5 steps (20 us) the middle computes {:.6} um; exact {:.6} um", 2.0 * H / C * 1e6, u2[50], ex);
    assert!(u2[50] == 0.0 && ex > 0.4);
    for &hh in &[0.01, 0.001] {
        let dt = 0.5 * hh * hh / ALPHA;
        let flops = (1200.0 / dt).round() as u64 * ((1.0 / hh).round() as u64 - 1) * 5;
        println!("heat, r = 0.5, h = {} m: dt = {:.3} s, reach h/dt = {:.2} cm/s, 1200 s costs {} flops", hh, dt, hh / dt * 100.0, flops);
    }
    println!("figure, 5 steps: stencil reach 5 cells; sound reach 2.5 cells at nu = 0.5, 10 cells at nu = 2");
    println!("ALL CHECKS PASS");
}
