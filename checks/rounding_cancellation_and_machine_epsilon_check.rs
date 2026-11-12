// Machine epsilon and cancellation -- the check behind the card.  std only.
// A runner's watch loses the fraction f = 1 - sqrt(1 - z) of each second, z = (v/c)^2.
// That is the small root of f^2 - 2f + z = 0.  The school formula loses its digits;
// the rewrite z / (1 + sqrt(1 - z)) keeps them, and the standard model bounds both.
const C: f64 = 299792458.0; // speed of light, m/s (exact by definition)
const CC: i128 = 299792458 * 299792458; // c^2 as a whole number
const U: f64 = 1.0 / 9007199254740992.0; // unit roundoff 2^-53: half the gap next to one

fn sci(x: f64, p: usize) -> String {
    format!("{:.*e}", p, x) // 2.220446049250313e-16, the same as Python
}
fn naive(z: f64) -> f64 { 1.0 - (1.0 - z).sqrt() } // the school formula's small root
fn safe(z: f64) -> f64 { z / (1.0 + (1.0 - z).sqrt()) } // product of roots: small = z / big
fn series(z: f64) -> f64 { z / 2.0 + z * z / 8.0 } // 1 - sqrt(1 - z) = z/2 + z^2/8 + ...
// (fhat - f)/f against the exact f for speed v, with fhat = m / 2^k read from its bits
fn rel_err(fhat: f64, v: i128) -> f64 {
    if fhat == 0.0 { return -1.0; }
    let bits = fhat.to_bits();
    let m = ((bits & ((1u64 << 52) - 1)) | (1u64 << 52)) as i128;
    let k = 1075 - ((bits >> 52) & 0x7ff) as i32;
    let den = v * v * (1i128 << k);
    let r = (m * 2 * CC - den) as f64 / den as f64;
    let vf = v as f64;
    let zt = (vf * vf) / (C * C);
    let w = zt / 4.0 + zt * zt / 8.0; // next terms are below 1e-30 here
    (r - w) / (1.0 + w)
}

fn main() {
    // ---- machine epsilon, three ways ----
    let eps_bits = f64::from_bits(1.0f64.to_bits() + 1) - 1.0;
    let mut e = 1.0f64;
    while 1.0 + e / 2.0 > 1.0 { e /= 2.0; } // stop when adding half of e changes nothing
    println!("eps_mach from the bits of 1,{}", sci(eps_bits, 15));
    println!("eps_mach by halving,{}", sci(e, 15));
    println!("eps_mach library cross-check,{}", sci(f64::EPSILON, 15));
    println!("unit roundoff u,{}", sci(U, 15));
    println!("fl(1 + u) - 1 in u,{:.0}", (1.0 + U - 1.0) / U);
    println!("fl(1 + 3u) - 1 in u,{:.0}", (1.0 + 3.0 * U - 1.0) / U);
    let mut gap = 2.0f64.powi(-52);
    while gap * 2.0f64.powi(52) * 2.0 <= 1e6 { gap *= 2.0; } // power of two at or below 1e6
    println!("gap near 1000000,{},largest rounding,{}", sci(gap, 3), sci(gap / 2.0, 3));
    assert!(eps_bits == e && e == 2.0f64.powi(-52) && e == f64::EPSILON);
    assert!(1.0 + U == 1.0 && 1.0 + 3.0 * U == 1.0 + 4.0 * U); // ties go to the even neighbour

    // ---- the runner, three roads to f ----
    let v: i128 = 5;
    let z = (v * v) as f64 / (C * C);
    let x = 1.0 - z;
    let s = x.sqrt();
    let (fn_, fs, fr) = (naive(z), safe(z), series(z));
    let (en, es, er) = (rel_err(fn_, v), rel_err(fs, v), rel_err(fr, v));
    let fu = fs / U;
    let bound_n = 1.5 / fu + 2.0 * U; // 1.5u of absolute error, over f; plus z's 2u
    println!("runner speed,{} m/s,speed of light,{:.0} m/s", v, C);
    println!("z = (v/c)^2,{},in u,{:.4}", sci(z, 15), z / U);
    println!("fl(1 - z),1 - {:.0}u,rounding error in u,{:.4}", (1.0 - x) / U, (z - 3.0 * U) / U / (1.0 - z));
    println!("fl(sqrt(1 - z)),1 - {:.0}u,fl(1 + s),2 - {:.0}u", (1.0 - s) / U, (2.0 - (1.0 + s)) / U);
    println!("f naive,{}", sci(fn_, 15));
    println!("f safe,{}", sci(fs, 15));
    println!("f series,{}", sci(fr, 15));
    println!("f in u,{:.4}", fu);
    println!("naive error,{:.2}%,bound,{:.2}%,ratio,{:.3}", en * 100.0, bound_n * 100.0, en / bound_n);
    println!("safe error in u,{:.4},bound 4.75u,ratio,{:.3}", es / U, es / U / 4.75);
    println!("series error in u,{:.4}", er / U);
    println!("lag over a 1-hour run,{} s", sci(fs * 3600.0, 3));
    assert!((fs - fr).abs() <= 4.75 * U * fr); // safe meets the series
    assert!(0.5 < en && en < bound_n); // naive: 60% off, inside its bound
    assert!(es.abs() <= 4.75 * U); // safe: inside its bound

    // ---- five speeds: the naive error grows as f shrinks; the safe one does not ----
    for (v, name) in [(2i128, "walk"), (5, "run"), (30, "car"), (250, "airliner"), (3874, "GPS satellite")] {
        let vf = v as f64;
        let z = (vf * vf) / (C * C);
        let fs = safe(z);
        let (en, es) = (rel_err(naive(z), v), rel_err(fs, v));
        let bound_n = 1.5 * U / fs + 2.0 * U;
        assert!(en.abs() <= bound_n && es.abs() <= 4.75 * U);
        assert!((fs - series(z)).abs() <= 4.75 * U * fs); // the series meets the rewrite
        println!("speed,{},{},f,{},naive error,{},bound,{},safe error in u,{:.3}",
            v, name, sci(fs, 3), sci(en.abs(), 3), sci(bound_n, 3), es / U);
        println!("chart,{},log10 naive,{:.2},log10 bound,{:.2},log10 safe,{:.2}",
            v, en.abs().log10(), bound_n.log10(), es.abs().log10());
    }

    // ---- what breaks ----
    let z = 25.0 / (C * C);
    println!("flipped rewrite z/(1 - s),{},should be,{}", sci(z / (1.0 - (1.0 - z).sqrt()), 4), sci(1.0 + (1.0 - z).sqrt(), 4));
    let z = 3874.0 * 3874.0 / (C * C);
    let t = rel_err(z / 2.0, 3874);
    println!("first term z/2 only at 3874 m/s,error,{},in u,{:.0}", sci(t.abs(), 3), t.abs() / U);
    assert!(t.abs() > 1e5 * U);
    println!("ALL CHECKS PASS");
}
