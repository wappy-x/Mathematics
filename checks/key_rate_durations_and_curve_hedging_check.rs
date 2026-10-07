// Key-rate durations and curve hedging -- the same check as the Python, in Rust.  Std only, no crates.
// Bootstrap the curve, key-rate DV01s by bump and by cash-flow mapping, the hedge by elimination
// and by Cramer's rule, then the hedged book under scenarios and 2,000 random moves.

const QUOTES: [f64; 10] = [0.042, 0.044, 0.0455, 0.0462, 0.0465, 0.0467, 0.0468, 0.0469, 0.0470, 0.0471];
const BP: f64 = 0.0001;
const F: f64 = 10_000_000.0; const C: f64 = 0.05; const NB: usize = 7;   // bond face, coupon, years
const PILLARS: [f64; 3] = [2.0, 5.0, 10.0];
const SWAPS: [usize; 3] = [2, 5, 10];

fn c2(x: f64) -> String {                              // 1234567.891 -> "1,234,567.89"
    let s = format!("{:.2}", x.abs());
    let (int, frac) = s.split_at(s.len() - 3);
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    format!("{}{}{}", if x < 0.0 && s != "0.00" { "-" } else { "" }, out, frac)
}

fn w(k: usize, t: f64) -> f64 {                        // tent k: 1 at its pillar, 0 at the neighbours
    let p = PILLARS[k];
    if t <= p {
        if k == 0 { 1.0 } else { ((t - PILLARS[k - 1]) / (p - PILLARS[k - 1])).max(0.0) }
    } else if k == 2 { 1.0 } else { ((PILLARS[k + 1] - t) / (PILLARS[k + 1] - p)).max(0.0) }
}

type Flows = Vec<(usize, f64)>;
fn flows_bond() -> Flows { (1..=NB).map(|t| (t, F * C + if t == NB { F } else { 0.0 })).collect() }
fn flows_payer(n: usize, k: f64) -> Flows { (1..=n).map(|t| (t, -k - if t == n { 1.0 } else { 0.0 })).collect() }
fn pv(fl: &Flows, z: &[f64]) -> f64 { fl.iter().map(|&(t, cf)| cf * (-z[t - 1] * t as f64).exp()).sum() }

fn gauss(a: &Vec<Vec<f64>>, b: &[f64]) -> Vec<f64> {   // elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            for j in 0..=n { m[r][j] -= f * m[c][j]; }
        }
    }
    let mut x = vec![0.0; n];
    for r in (0..n).rev() {
        let s: f64 = (r + 1..n).map(|j| m[r][j] * x[j]).sum();
        x[r] = (m[r][n] - s) / m[r][r];
    }
    x
}
fn det3(m: &Vec<Vec<f64>>) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn cramer(a: &Vec<Vec<f64>>, b: &[f64]) -> Vec<f64> {
    let d = det3(a);
    (0..3).map(|j| det3(&(0..3).map(|r| (0..3).map(|c| if c == j { b[r] } else { a[r][c] }).collect()).collect()) / d).collect()
}

fn main() {
    let (mut d, mut acc) = (Vec::new(), 0.0);
    for s in QUOTES { let x = (1.0 - s * acc) / (1.0 + s); d.push(x); acc += x; }
    let z: Vec<f64> = (0..10).map(|i| -d[i].ln() / (i + 1) as f64).collect();
    let shifted = |k: usize, s: f64| -> Vec<f64> { (0..10).map(|i| z[i] + s * w(k, (i + 1) as f64)).collect() };
    let kr_bump = |fl: &Flows, k: usize| -(pv(fl, &shifted(k, BP)) - pv(fl, &shifted(k, -BP))) / 2.0;
    let kr_map = |fl: &Flows, k: usize| -> f64 {
        fl.iter().map(|&(t, cf)| w(k, t as f64) * t as f64 * cf * (-z[t - 1] * t as f64).exp() * BP).sum()
    };
    let par = |n: usize| (1.0 - d[n - 1]) / d[..n].iter().sum::<f64>();
    let bond = flows_bond();
    let p0 = pv(&bond, &z);
    println!("year  quote %   D(t)        zero %    tent 2  tent 5  tent 10");
    for i in 0..10 {
        let ws: Vec<String> = (0..3).map(|k| format!("{:6.2}", w(k, (i + 1) as f64))).collect();
        println!("{:>4}  {:6.4}  {:.8}  {:7.4}   {}", i + 1, 100.0 * QUOTES[i], d[i], 100.0 * z[i], ws.join("  "));
    }
    println!("bond: 10,000,000 face, 5% annual coupon, 7 years; price {}", c2(p0));
    println!("year  cash flow      D(t)        t*CF*D*1bp   to 2y     to 5y     to 10y");
    for &(t, cf) in &bond {
        let x = t as f64 * cf * d[t - 1] * BP;
        let ws: Vec<String> = (0..3).map(|k| format!("{:>8}", c2(w(k, t as f64) * x))).collect();
        println!("{:>4}  {:>12}  {:.8}  {:>10}  {}", t, c2(cf), d[t - 1], c2(x), ws.join("  "));
    }
    let krb: Vec<f64> = (0..3).map(|k| kr_bump(&bond, k)).collect();
    let krm: Vec<f64> = (0..3).map(|k| kr_map(&bond, k)).collect();
    let par_dv01 = -(pv(&bond, &z.iter().map(|x| x + BP).collect::<Vec<_>>()) - pv(&bond, &z.iter().map(|x| x - BP).collect::<Vec<_>>())) / 2.0;
    println!("\nkey-rate DV01 of the bond, dollars lost per 1bp rise");
    for k in 0..3 { println!("  {:>2}-year pillar   bump {:>10}   mapped {:>10}   duration {:.4}", PILLARS[k], c2(krb[k]), c2(krm[k]), krb[k] / (p0 * BP)); }
    println!("  sum of the three {:>10}   parallel bump of every zero {:>10}   duration {:.4}", c2(krb.iter().sum()), c2(par_dv01), par_dv01 / (p0 * BP));

    let mb: Vec<Vec<f64>> = (0..3).map(|k| SWAPS.iter().map(|&n| -kr_bump(&flows_payer(n, par(n)), k) * 1e6).collect()).collect();
    let mm: Vec<Vec<f64>> = (0..3).map(|k| SWAPS.iter().map(|&n| -kr_map(&flows_payer(n, par(n)), k) * 1e6).collect()).collect();
    println!("\npay-fixed par swaps, dollars gained per 1bp rise per million, by pillar");
    println!("pillar      2y swap    5y swap   10y swap");
    for k in 0..3 {
        let r: Vec<String> = (0..3).map(|j| format!("{:>10}", c2(mb[k][j]))).collect();
        println!("{:>6}  {}", PILLARS[k], r.join(" "));
    }
    let h: Vec<f64> = gauss(&mb, &krb).iter().map(|x| x * 1e6).collect();
    let hc: Vec<f64> = cramer(&mm, &krm).iter().map(|x| x * 1e6).collect();
    println!("\nhedge notionals, pay fixed (negative = receive fixed)");
    for j in 0..3 { println!("  {:>2}-year swap   elimination {:>14}   Cramer {:>14}", SWAPS[j], c2(h[j]), c2(hc[j])); }
    let f10 = flows_payer(10, par(10));
    let h10 = par_dv01 / -(0..3).map(|k| kr_bump(&f10, k)).sum::<f64>();
    println!("  back substitution: 10y swap covers {} of the 5y pillar, leaving {}", c2(h[2] * mb[1][2] / 1e6), c2(krb[1] - h[2] * mb[1][2] / 1e6));
    println!("  one 10-year swap on total DV01 {:>14}   its parallel DV01 per million {}", c2(h10), c2(par_dv01 / h10 * 1e6));

    let pnl = |zz: &[f64], hedge: &[(usize, f64)]| -> f64 {
        let mut v = pv(&bond, zz) - p0;
        for &(n, hh) in hedge { let fl = flows_payer(n, par(n)); v += hh * (pv(&fl, zz) - pv(&fl, &z)); }
        v
    };
    let three: Vec<(usize, f64)> = SWAPS.iter().cloned().zip(h.iter().cloned()).collect();
    let one = vec![(10usize, h10)];
    let two = three[1..].to_vec();
    let diag: Vec<(usize, f64)> = (0..3).map(|j| (SWAPS[j], krb[j] / mb[j][j] * 1e6)).collect();
    let mv = |m2: f64, m5: f64, m10: f64| -> Vec<f64> {
        (0..10).map(|i| { let t = (i + 1) as f64; z[i] + BP * (m2 * w(0, t) + m5 * w(1, t) + m10 * w(2, t)) }).collect()
    };
    let hump: Vec<f64> = (0..10).map(|i| z[i] + if i == 6 { 10.0 * BP } else { 0.0 }).collect();
    let none: Vec<(usize, f64)> = vec![];
    println!("scenario P&L, dollars          bond alone     one swap   5y+10y only   three swaps");
    for (lab, zz) in [("parallel +25bp", mv(25.0, 25.0, 25.0)), ("steepener 2y -20, 10y +20", mv(-20.0, 0.0, 20.0)),
                      ("front end 2y +20", mv(20.0, 0.0, 0.0)), ("7-year zero alone +10", hump.clone())] {
        let cols: Vec<String> = [&none, &one, &two, &three].iter().map(|hh| format!("{:>13}", c2(pnl(&zz, hh)))).collect();
        println!("  {:<26}{}", lab, cols.join(""));
    }
    let sizes = [-40i32, -30, -20, -10, 0, 10, 20, 30, 40];
    let hdr: Vec<String> = sizes.iter().map(|s| format!("{:>7}", s)).collect();
    println!("chart, steepener bp  {}", hdr.join(" "));
    for (lab, hh) in [("chart, bond alone   ", &none), ("chart, one swap     ", &one), ("chart, three swaps  ", &three)] {
        let v: Vec<String> = sizes.iter().map(|&s| { let s = s as f64; format!("{:>7.2}", pnl(&mv(-s, 0.0, s), hh) / 1e3) }).collect();
        println!("{} {}", lab, v.join(" "));
    }
    let left = |hedge: &[(usize, f64)]| -> String {
        (0..3).map(|k| {
            let hs: f64 = hedge.iter().map(|&(n, hh)| hh * mb[k][SWAPS.iter().position(|&m| m == n).unwrap()] / 1e6).sum();
            format!("{}y {:>9}", PILLARS[k], c2(krb[k] - hs))
        }).collect::<Vec<_>>().join("  ")
    };
    println!("what breaks, net key-rate DV01 left after the hedge, dollars per 1bp");
    for (lab, hh) in [("one 10y swap on total DV01", &one), ("5y and 10y only", &two), ("each pillar by its own swap", &diag)] {
        println!("  {:<28}{}", lab, left(hh));
    }

    let mut seed: u64 = 20260928;
    let mut rnd = || -> f64 {                          // 64-bit linear congruential generator, in [-1, 1)
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (seed >> 11) as f64 / (1u64 << 52) as f64 - 1.0
    };
    let mut worst = [0.0f64; 3];
    for _ in 0..2000 {
        let (a, b, c) = (20.0 * rnd(), 20.0 * rnd(), 20.0 * rnd());
        let zz = mv(a, b, c);
        for (i, hh) in [&none, &one, &three].iter().enumerate() { worst[i] = worst[i].max(pnl(&zz, hh).abs()); }
    }
    println!("2,000 random pillar moves up to 20bp, worst |P&L|: bond {}  one swap {}  three {}", c2(worst[0]), c2(worst[1]), c2(worst[2]));
    let t3: f64 = (1..=7).map(|t| w(2, t as f64) * t as f64 * (F * 0.03 + if t == 7 { F } else { 0.0 }) * d[t - 1] * BP).sum();
    println!("try: 7-year bond at a 3% coupon, 10y pillar DV01 {}", c2(t3));

    assert!((d[4] - 0.79621728).abs() < 5e-9, "D(5) must match the swap and bootstrap cards");
    assert!(SWAPS.iter().all(|&n| (par(n) - QUOTES[n - 1]).abs() < 1e-12), "par formula on D(t) must give back each quote");
    assert!((0..3).all(|k| (krb[k] - krm[k]).abs() < 0.01), "bump road vs cash-flow mapping road");
    assert!((krb.iter().sum::<f64>() - par_dv01).abs() < 0.01, "tents sum to one, so key rates sum to the parallel DV01");
    assert!((0..3).all(|j| (h[j] - hc[j]).abs() < 1.0), "elimination on bump matrix vs Cramer on mapped matrix");
    assert!(worst[2] < 0.01 * worst[0], "three-swap hedge must cut every random move by 99%");
    println!("ALL CHECKS PASS");
}
