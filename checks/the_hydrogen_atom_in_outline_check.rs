// Hydrogen in outline -- the check behind the card.  std only, no crates.
// One electron, one proton, the Coulomb pull.  Three roads to the levels:
// 1 the closed form from SI constants, 2 the radial power series that must
// stop, 3 a shooting solve of the radial equation itself (Numerov, bisection).
const H: f64 = 6.62607015e-34; // Planck constant, J s (exact in SI)
const Q: f64 = 1.602176634e-19; // elementary charge, C (exact); also 1 eV in J
const C: f64 = 299792458.0; // speed of light, m/s (exact)
const EPS0: f64 = 8.8541878188e-12; // electric constant, F/m (CODATA 2022)
const ME: f64 = 9.1093837139e-31; // electron mass, kg (CODATA 2022)
const MP: f64 = 1.67262192595e-27; // proton mass, kg (CODATA 2022)
const MD: f64 = 3.3435837768e-27; // deuteron mass, kg (CODATA 2022)
const ALPHA: f64 = 7.2973525643e-3; // fine-structure constant (CODATA 2022)
const RYD_CODATA: f64 = 13.605693122990; // R_inf h c in eV, electron mass (CODATA 2022)
const IE_NIST: f64 = 13.598434599702; // measured ionization energy of H, eV (NIST ASD)
const A0_CODATA: f64 = 0.0529177210544; // Bohr radius in nm, electron mass (CODATA 2022)
const HA_NIST: (f64, f64) = (656.460, 656.279); // H-alpha, observed blend, vacuum and air, nm (NIST ASD)

fn ryd(m: f64) -> f64 { m * Q.powi(4) / (8.0 * EPS0 * EPS0 * H * H) / Q } // road 1, eV
fn bohr(m: f64) -> f64 { let hbar = H / (2.0 * std::f64::consts::PI); 4.0 * std::f64::consts::PI * EPS0 * hbar * hbar / (m * Q * Q) * 1e9 } // nm
fn reduced(m: f64) -> f64 { ME * m / (ME + m) }
fn lam(e1: f64, hi: f64, lo: f64) -> f64 { H * C / (e1 * (1.0 / (lo * lo) - 1.0 / (hi * hi)) * Q) * 1e9 }
fn series(nu: f64, l: f64, terms: usize) -> Vec<f64> { // road 2: coefficients c_k
    let mut c = vec![1.0];
    for k in 0..terms {
        let k = k as f64;
        let last = c[c.len() - 1];
        c.push(last * 2.0 * (k + l + 1.0 - nu) / (nu * (k + 1.0) * (k + 2.0 * l + 2.0)));
    }
    c
}
fn r_series(nu: f64, l: f64, r: f64) -> f64 { // the same series summed term by term
    let (mut total, mut t) = (0.0, 1.0);
    for k in 0..200 {
        let k = k as f64;
        total += t;
        t *= 2.0 * (k + l + 1.0 - nu) / (nu * (k + 1.0) * (k + 2.0 * l + 2.0)) * r;
    }
    r.powf(l) * (-r / nu).exp() * total
}
fn shoot(en: f64, l: f64) -> f64 { // road 3: u = r R, u'' = (l(l+1)/r^2 - 2/r - 2E) u
    let (rmax, h): (f64, f64) = (50.0, 0.01);
    let (w, ll) = (h * h / 12.0, l * (l + 1.0));
    let (r0, r1) = (h, 2.0 * h);
    let a = -1.0 / (l + 1.0);
    let b = (-2.0 * a - 2.0 * en) / (4.0 * l + 6.0);
    let mut u0 = r0.powf(l + 1.0) * (1.0 + a * r0 + b * r0 * r0);
    let mut u1 = r1.powf(l + 1.0) * (1.0 + a * r1 + b * r1 * r1);
    let mut f0 = ll / (r0 * r0) - 2.0 / r0 - 2.0 * en;
    let mut f1 = ll / (r1 * r1) - 2.0 / r1 - 2.0 * en;
    let steps = (rmax / h).round() as usize;
    for i in 2..steps {
        let r2 = (i as f64 + 1.0) * h;
        let f2 = ll / (r2 * r2) - 2.0 / r2 - 2.0 * en;
        let u2 = (2.0 * u1 * (1.0 + 5.0 * w * f1) - u0 * (1.0 - w * f0)) / (1.0 - w * f2);
        u0 = u1; u1 = u2; f0 = f1; f1 = f2;
    }
    u1
}
fn levels(l: f64) -> Vec<f64> { // scan for sign changes, then bisect
    let (lo, hi, step) = (-0.6, -0.04, 0.01);
    let (mut out, mut e, mut prev) = (vec![], lo, shoot(lo, l));
    while e + step <= hi + 1e-12 {
        let nxt = shoot(e + step, l);
        if (prev < 0.0) != (nxt < 0.0) {
            let (mut a, mut b, mut fa) = (e, e + step, prev);
            for _ in 0..45 {
                let m = (a + b) / 2.0;
                let fm = shoot(m, l);
                if (fm < 0.0) == (fa < 0.0) { a = m; fa = fm; } else { b = m; }
            }
            out.push((a + b) / 2.0);
        }
        e += step; prev = nxt;
    }
    out
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 2000;
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (f(a) + f(b) + s) * h / 3.0
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x + 0.0)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mu = reduced(MP);
    let (e1e, e1) = (ryd(ME), ryd(mu));
    let a0 = bohr(mu); // Bohr radius with the reduced mass, nm
    let en: Vec<f64> = (1..6).map(|n| -e1 / (n * n) as f64).collect();
    println!("constants: m_e 9.1093837139e-31 kg, m_p 1.67262192595e-27 kg, eps0 8.8541878188e-12 F/m");
    println!("reduced mass mu / m_e                {:.8}", mu / ME);
    println!("hc                                   {:.6} eV nm", H * C / Q * 1e9);
    println!("|E_1| electron mass, from constants  {:.6} eV", e1e);
    println!("|E_1| electron mass, CODATA R_inf hc {:.6} eV", RYD_CODATA);
    println!("|E_1| reduced mass                   {:.6} eV", e1);
    println!("levels n = 1..5 (eV)  {}", join(&en, 6));
    println!("bars |E_n| (eV)       {}", join(&en.iter().map(|e| -e).collect::<Vec<_>>(), 2));
    println!("Bohr radius a0 with mu               {:.6} nm", a0);
    println!("Bohr radius with m_e                 {:.6} nm (CODATA {:.6} nm)", bohr(ME), A0_CODATA);
    println!("H-alpha 3->2: energy {:.6} eV, wavelength {:.3} nm", e1 * (1.0 / 4.0 - 1.0 / 9.0), lam(e1, 3.0, 2.0));
    println!("H-beta 4->2 {:.2} nm, Lyman-alpha 2->1 {:.2} nm, Balmer limit {:.2} nm",
        lam(e1, 4.0, 2.0), lam(e1, 2.0, 1.0), lam(e1, 1e9, 2.0));
    println!("measured ionization energy {:.6} eV, outline misses by {:.6} eV", IE_NIST, IE_NIST - e1);
    println!("H-alpha measured {:.3} nm vacuum, {:.3} nm air; outline is {:.3} nm long", HA_NIST.0, HA_NIST.1, lam(e1, 3.0, 2.0) - HA_NIST.0);
    for (nu, l) in [(2.0, 0.0), (3.0, 0.0), (3.0, 1.0)] {
        println!("series nu={} l={}: {}", nu, l, join(&series(nu, l, 200)[..4], 6));
    }
    println!("log10 |R(40 a0)|: nu = 2.00 gives {:.2}, nu = 2.50 gives {:.2}",
        r_series(2.0, 0.0, 40.0).abs().log10(), r_series(2.5, 0.0, 40.0).abs().log10());
    let shot: Vec<Vec<f64>> = (0..3).map(|l| levels(l as f64)).collect();
    for l in 0..3 {
        println!("shooting l={} (eV): {}", l, join(&shot[l].iter().map(|e| 2.0 * e1 * e).collect::<Vec<_>>(), 6));
    }
    let count: Vec<usize> = (1..5).map(|n: i64| (0..n).map(|l| (2 * l + 1) as usize).sum()).collect();
    println!("states per shell n = 1..4: {}; with spin {}",
        count.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "),
        count.iter().map(|c| (2 * c).to_string()).collect::<Vec<_>>().join(" "));
    let p1s = |r: f64| r * r * r_series(1.0, 0.0, r).powi(2);
    let n1 = simpson(&p1s, 0.0, 40.0);
    let r_mean = simpson(&|r: f64| r * p1s(r), 0.0, 40.0) / n1;
    println!("1s: normalising constant squared {:.6}, mean radius {:.6} a0", 1.0 / n1, r_mean);
    let norm = |n: f64, l: f64| simpson(&|r: f64| r * r * r_series(n, l, r).powi(2), 0.0, 80.0);
    let (n10, n20, n21) = (norm(1.0, 0.0), norm(2.0, 0.0), norm(2.0, 1.0));
    let overlap = simpson(&|r: f64| r * r * r_series(1.0, 0.0, r) * r_series(2.0, 0.0, r), 0.0, 80.0);
    println!("1s-2s overlap (should be 0)          {:.6}", overlap / (n10 * n20).sqrt() + 0.0);
    println!("chart r (a0)  {}", (0..15).map(|r| format!("{:5}", r)).collect::<Vec<_>>().join(" "));
    for (n, l, nm, name) in [(1.0, 0.0, n10, "1s"), (2.0, 0.0, n20, "2s"), (2.0, 1.0, n21, "2p")] {
        let v: Vec<String> = (0..15).map(|r| { let r = r as f64; format!("{:5.2}", r * r * r_series(n, l, r).powi(2) / nm) }).collect();
        println!("chart P {}    {}", name, v.join(" "));
    }
    let (mut peak3, mut best) = (0.0, f64::MIN);
    for i in 1..20001 {
        let r = i as f64 * 0.001;
        let p = r * r * r_series(3.0, 2.0, r).powi(2);
        if p > best { best = p; peak3 = r; }
    }
    println!("3d most likely radius {:.3} a0 (n^2 = 9)", peak3);
    let bx: Vec<f64> = [1.0, 2.0, 3.0].iter().map(|n: &f64| n * n * H * H / (8.0 * ME * 1e-18) / Q).collect();
    println!("1 nm box levels (eV) {}", join(&bx, 3));
    println!("wrong: electron mass, |E_1| {:.6} eV, H-alpha {:.3} nm", e1e, lam(e1e, 3.0, 2.0));
    println!("wrong: 1/n not 1/n^2, H-alpha {:.2} nm", H * C / (e1 * (1.0 / 2.0 - 1.0 / 3.0) * Q) * 1e9);
    println!("wrong: forget m, n=2 shell holds {} not {}", 2 * 2, 2 * count[1]);
    let split = e1 / 4.0 * ALPHA * ALPHA / 4.0; // Dirac: n=2, j=1/2 versus j=3/2
    println!("outside the outline: n=2 fine split {:.2} micro-eV, {:.4} nm in H-alpha",
        split * 1e6, lam(e1, 3.0, 2.0).powi(2) * split / (H * C / Q * 1e9));
    let d_d = lam(ryd(reduced(MD)), 3.0, 2.0);
    println!("try: deuterium H-alpha {:.3} nm, {:.3} nm below hydrogen", d_d, lam(e1, 3.0, 2.0) - d_d);
    println!("try: n=100 circular state radius {:.2} nm, energy {:.3} meV", 1e4 * a0, -e1 / 1e4 * 1e3);

    assert!((e1e - RYD_CODATA).abs() < 1e-7, "road 1: constants must give CODATA's Rydberg energy");
    assert!((IE_NIST - e1).abs() < 2e-4 && IE_NIST > e1, "outline within 0.0002 eV of measured");
    assert!((bohr(ME) - A0_CODATA).abs() < 1e-9, "road 1: constants must give CODATA's Bohr radius");
    assert!((lam(e1, 3.0, 2.0) - HA_NIST.0).abs() < 0.02, "H-alpha within 0.02 nm of the measured line");
    assert!(series(2.0, 0.0, 200)[1] == -0.5 && (series(3.0, 0.0, 200)[2] - 2.0 / 27.0).abs() < 1e-15, "textbook R20, R30");
    assert!(series(3.0, 1.0, 200)[2..].iter().all(|c| c.abs() < 1e-300), "series stops at k = n - l - 1");
    for l in 0..3 { // road 3 against road 1: lowest n is l+1, E = -1/(2 n^2)
        let want: Vec<f64> = (l + 1..4).map(|n| -0.5 / (n * n) as f64).collect();
        assert!(shot[l].len() == want.len() && shot[l].iter().zip(&want).all(|(s, w)| (s - w).abs() < 1e-6));
    }
    assert!(count == (1..5).map(|n| n * n).collect::<Vec<usize>>(), "n^2 shapes per shell");
    assert!((r_mean - 1.5).abs() < 1e-6 && (n1 - 0.25).abs() < 1e-6, "mean radius 3/2 a0, R10 = 2 e^-r");
    assert!(overlap.abs() < 1e-6 && (peak3 - 9.0).abs() < 1e-3, "orthogonal, circular peak at n^2");
    println!("ALL CHECKS PASS");
}
