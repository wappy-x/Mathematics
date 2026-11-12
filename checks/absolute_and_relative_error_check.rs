// Absolute and relative error -- the same check as absolute_and_relative_error_check.py,
// in Rust.  No crates.  A 3,000 mm beam and a 20 mm bolt, each cut 2 mm short.
// Misses are whole millimetres held exactly in f64; powers of ten are built by
// repeated multiplication, so every comparison matches the Python run bit for bit.
fn sci(v: f64, d: usize) -> String {       // e-notation, the same text as Python's: 6.667e-4
    format!("{:.*e}", d, v)
}

fn pow10(n: i32) -> f64 {                  // exact for the powers used here
    let mut p = 1.0;
    for _ in 0..n {
        p *= 10.0;
    }
    p
}

fn lead_power(x: f64) -> i32 {             // k with 10^k <= x < 10^(k+1)
    let mut k = 0;
    while pow10(k + 1) <= x {
        k += 1;
    }
    k
}

fn digits(x: f64, miss: f64) -> i32 {      // road 1: miss <= half a unit in digit p
    let (k, mut p) = (lead_power(x), 0);
    while p < 17 && 2.0 * miss * pow10(p) <= pow10(k) {
        p += 1;
    }
    p
}

fn half_unit(x: f64, p: i32) -> f64 {      // half a unit in digit p of x: 1/2 x 10^(k-p+1)
    let k = lead_power(x);
    if k >= p { 5.0 * pow10(k - p) } else { 5.0 / pow10(p - k) }
}

fn bracket(rel: f64) -> (i32, i32) {       // road 2: what the relative error alone allows
    let (mut lo, mut hi) = (0, 0);
    while lo < 17 && rel * pow10(lo + 2) <= 5.0 {
        lo += 1;
    }
    while hi < 17 && rel * pow10(hi + 1) <= 5.0 {
        hi += 1;
    }
    (lo, hi)
}

fn matching(a: i64, b: i64) -> usize {     // the wrong test: leading characters that agree
    let (sa, sb) = (a.to_string(), b.to_string());
    sa.chars().zip(sb.chars()).take_while(|(c, d)| c == d).count()
}

fn report(name: &str, x: i64, xhat: i64) -> (f64, f64, i32) {
    let miss = (xhat - x).abs() as f64;
    let xf = x as f64;
    let rel = miss / xf;
    let (p, (lo, hi)) = (digits(xf, miss), bracket(rel));
    println!("{}: true {}, got {}, abs {}, rel {}, percent {:.4}, digits {}, bracket {}-{}, -log10 {:.3}, \
              half-units at digits {} and {}: {}, {}",
             name, x, xhat, miss, sci(rel, 3), 100.0 * rel, p, lo, hi, -rel.log10(),
             p, p + 1, half_unit(xf, p), half_unit(xf, p + 1));
    assert!((rel * xf - miss).abs() < 1e-12 * xf);
    assert!((p == 0 || miss <= half_unit(xf, p)) && miss > half_unit(xf, p + 1));
    assert!(lo <= p && p <= hi && hi - lo <= 1);
    let pf = p as f64;
    assert!(-rel.log10() - 1.302 < pf && pf <= -rel.log10() + 0.699);
    (miss, rel, p)
}

fn main() {
    let (beam_abs, beam_rel, beam_p) = report("beam", 3000, 2998);
    let (bolt_abs, bolt_rel, bolt_p) = report("bolt", 20, 18);
    println!("same miss, bolt rel / beam rel = {:.1}", bolt_rel / beam_rel);
    println!("kept digits: beam {:.*} m, bolt {} mm", (beam_p - 1) as usize, 2998.0 / 1000.0,
             sci(18.0, (bolt_p - 1) as usize));
    assert!(beam_abs == 2.0 && bolt_abs == 2.0 && beam_p == 3 && bolt_p == 1);
    assert!((bolt_rel / beam_rel - 3000.0 / 20.0).abs() < 1e-9);

    let m_abs = (2.998f64 - 3.0).abs();
    let m_rel = m_abs / 3.0;
    println!("beam in metres: abs {:.6} m, rel {}", m_abs, sci(m_rel, 3));
    assert!((m_rel - beam_rel).abs() < 1e-12 && (m_abs * 1000.0 - beam_abs).abs() < 1e-9);

    for (name, x) in [("beam", 3000.0), ("bolt", 20.0)] {
        println!("0.1 percent of the {}: {:.3} mm", name, 0.001 * x);
    }

    let (r1, r2) = (report("10 m rail", 10000, 9996), report("97.5 m rail", 97500, 97461));
    assert!(r1.1 == 4e-4 && r2.1 == 4e-4 && r1.2 == 4 && r2.2 == 3);

    println!("wrong: divide by the cut length, bolt {:.4} percent, beam {}",
             100.0 * 2.0 / 18.0, sci(2.0 / 2998.0, 3));
    assert!((2.0 / 18.0 - bolt_rel / (1.0 - bolt_rel)).abs() < 1e-15);
    println!("wrong: count matching digits of 2998 and 3000: {}", matching(2998, 3000));
    let gap = report("clearance in a 3001 mm opening", 3001 - 3000, 3001 - 2998);
    assert!(gap.1 == 2.0 && gap.2 == 0);

    let mut tries = Vec::new();
    for (name, x, xhat) in [("beam, 1 mm miss", 3000, 2999), ("beam, 6 mm miss", 3000, 2994),
                            ("200 mm bolt, 2 mm miss", 200, 198), ("30 m girder, 2 mm miss", 30000, 29998)] {
        tries.push(report(name, x, xhat).2);
    }
    assert!(tries == vec![3, 2, 2, 4]);                // the digit counts found by hand

    let mut total = 0.0f64;
    for _ in 0..10_000_000 {
        total += 0.1;
    }
    let t_abs = (total - 1_000_000.0).abs();
    let t_rel = t_abs / 1_000_000.0;
    let (t_p, (t_lo, t_hi)) = (digits(1_000_000.0, t_abs), bracket(t_rel));
    println!("tracker: total {:.6}, abs {}, rel {}, digits {}, bracket {}-{}",
             total, sci(t_abs, 3), sci(t_rel, 3), t_p, t_lo, t_hi);
    assert!(1e-4 < t_abs && t_abs < 2e-4 && t_p == 10 && t_lo <= t_p && t_p <= t_hi);
    println!("ALL CHECKS PASS");
}
