// Mortgage-backed securities in outline -- the same check as the Python, in
// Rust.  No crates: the random numbers, the rate model and the waterfall are
// written here.  Pool: $100 of 30-year loans at 6%, monthly.  Slices: sequential
// A, B, C and an interest-only / principal-only pair, priced by simulation.
const FACE: f64 = 100.0;
const N: usize = 360;
const DT: f64 = 1.0 / 12.0;
const I: f64 = 0.06 / 12.0;                           // the note rate, per month
const SIZES: [f64; 3] = [40.0, 35.0, 25.0];           // tranches A, B, C, paid in this order
const KAPPA: f64 = 0.15;
const THETA: f64 = 0.05;
const SIG: f64 = 0.01;
const R0: f64 = 0.05;
const SPREAD: f64 = 0.01;
const PAIRS: usize = 500;

fn smm(cpr: f64) -> f64 { 1.0 - (1.0 - cpr).powf(1.0 / 12.0) }  // yearly prepayment rate -> monthly

fn cpr_of(m: f64) -> f64 { (0.08 + 8.0 * (0.06 - m)).max(0.03).min(0.50) }  // cheaper loans, faster

fn month(bal: f64, k: usize, s: f64) -> (f64, f64) {  // one month: interest and all principal
    let sched = bal * I / (1.0 - (1.0 + I).powf(-((N - k + 1) as f64))) - I * bal;
    (I * bal, sched + s * (bal - sched))
}

fn split(tb: &mut [f64; 3], mut prin: f64) -> [f64; 3] {  // principal to A, then B, then C
    let mut out = [0.0; 3];
    for j in 0..3 {
        let x = tb[j].min(prin);
        tb[j] -= x;
        prin -= x;
        out[j] = x;
    }
    out
}

// road 1: one fixed path, monthly prepayment s, monthly discount vm
fn det(s: f64, vm: f64) -> (f64, f64, f64, Vec<[f64; 3]>, [f64; 3]) {
    let (mut bal, mut tb, mut d, mut pool, mut io) = (FACE, SIZES, 1.0, 0.0, 0.0);
    let (mut wal, mut bals) = ([0.0; 3], Vec::new());
    for k in 1..=N {
        if (k - 1) % 24 == 0 { bals.push(tb) }
        d *= vm;
        let (interest, prin) = month(bal, k, s);
        let paid = split(&mut tb, prin);
        for j in 0..3 { wal[j] += k as f64 / 12.0 * paid[j] / SIZES[j] }
        pool += d * (interest + prin);
        io += d * interest;
        bal -= prin;
    }
    bals.push(tb);
    (pool, io, pool - io, bals, wal)
}

fn io_closed(s: f64, v: f64) -> f64 {                 // road 2: two geometric sums, no month loop
    let (g, q, n) = (1.0 + I, (1.0 - s) * v, N as f64);
    let first = v * (1.0 - q.powf(n)) / (1.0 - q);
    let second = g.powf(-n) * v * (1.0 - (q * g).powf(n)) / (1.0 - q * g);
    I * FACE / (1.0 - g.powf(-n)) * (first - second)
}

struct Rng { s: u64 }                                 // splitmix64, then Box-Muller
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {
        let u1 = self.u();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.u()).cos()
    }
}

// road 3: one simulated rate path, every slice priced on it
fn path(zs: &[f64], shift: f64, sig: f64, fixed: Option<f64>) -> [f64; 7] {
    let a = (-KAPPA * DT).exp();
    let sd = sig * ((1.0 - a * a) / (2.0 * KAPPA)).sqrt();
    let (mut r, mut d, mut bal, mut tb, mut v) = (R0 + shift, 1.0, FACE, SIZES, [0.0; 7]);
    for k in 1..=N {
        let rn = THETA + shift + (r - THETA - shift) * a + sd * zs[k - 1];
        d *= (-0.5 * (r + rn) * DT).exp();            // trapezoid rule along the month
        let s = smm(fixed.unwrap_or_else(|| cpr_of(r + SPREAD)));
        let (interest, prin) = month(bal, k, s);
        let coupons = [I * tb[0], I * tb[1], I * tb[2]];
        let paid = split(&mut tb, prin);
        for j in 0..3 { v[1 + j] += d * (coupons[j] + paid[j]) }
        v[0] += d * (interest + prin);
        v[4] += d * interest;
        v[5] += d * prin;
        if k == 120 { v[6] = d }
        bal -= prin;
        r = rn;
    }
    v
}

fn price(shift: f64, sig: f64, fixed: Option<f64>) -> [f64; 7] {  // antithetic pairs, same seed
    let (mut g, mut tot) = (Rng { s: 2026 }, [0.0; 7]);
    for _ in 0..PAIRS {
        let zs: Vec<f64> = (0..N).map(|_| g.normal()).collect();
        for sign in [1.0, -1.0] {
            let zz: Vec<f64> = zs.iter().map(|z| sign * z).collect();
            for (j, x) in path(&zz, shift, sig, fixed).iter().enumerate() { tot[j] += x / (2 * PAIRS) as f64 }
        }
    }
    tot
}

fn vasicek_zero(t: f64) -> f64 {                      // the bond formula for the same rate model
    let b = (1.0 - (-KAPPA * t).exp()) / KAPPA;
    ((THETA - SIG * SIG / (2.0 * KAPPA * KAPPA)) * (b - t) - SIG * SIG * b * b / (4.0 * KAPPA) - b * R0).exp()
}

fn row(label: &str, x: f64) { println!("{:<44} {:>12.6}", label, x) }

fn main() {
    let (s8, v5, vn) = (smm(0.08), (-0.05 * DT).exp(), 1.0 / (1.0 + I));
    let (pool5, io5, po5, bals, wal) = det(s8, v5);
    let (it, pr) = month(FACE, 1, 0.0);
    row("monthly prepayment rate at 8% CPR", s8);
    println!("first month per $100: payment {:.6} = interest {:.6} + principal {:.6}; prepaid {:.6}", it + pr, it, pr, month(FACE, 1, s8).1 - pr);
    row("flat 5%, 8% CPR: pass-through (loop)", pool5);
    row("flat 5%, 8% CPR: IO (loop)", io5);
    row("flat 5%, 8% CPR: IO (geometric sums)", io_closed(s8, v5));
    row("flat 5%, 8% CPR: PO (loop)", po5);
    let par30 = det(smm(0.3), vn).0;
    println!("at the 6% note rate: pass-through {:.6} at 8% CPR, {:.6} at 30%", det(s8, vn).0, par30);
    println!("chart, years      {}", (0..16).map(|i| format!("{:6}", 2 * i)).collect::<Vec<_>>().join(" "));
    for (j, name) in ["A", "B", "C"].iter().enumerate() {
        println!("chart, balance {}  {}", name, bals.iter().map(|b| format!("{:6.2}", b[j])).collect::<Vec<_>>().join(" "));
    }
    println!("average life, years: A {:.2}  B {:.2}  C {:.2}", wal[0], wal[1], wal[2]);
    let base = price(0.0, SIG, None);
    for (j, label) in ["pool", "tranche A", "tranche B", "tranche C", "IO", "PO"].iter().enumerate() {
        row(&format!("simulated, rates as today: {}", label), base[j]);
    }
    row("  A + B + C", base[1] + base[2] + base[3]);
    row("  IO + PO", base[4] + base[5]);
    row("10-year zero, simulated", base[6]);
    row("10-year zero, Vasicek formula", vasicek_zero(10.0));
    let shifts: Vec<(f64, [f64; 7])> = [-0.02, -0.01, 0.0, 0.01, 0.02].iter()
        .map(|&sh| (sh, if sh == 0.0 { base } else { price(sh, SIG, None) })).collect();
    for (sh, p) in &shifts {
        println!("shift {:+.0}%: pool {:7.2}  IO {:6.2}  PO {:6.2}  A {:6.2}  C {:6.2}", 100.0 * sh, p[0], p[4], p[5], p[1], p[3]);
    }
    let (down, up) = (shifts[1].1, shifts[3].1);
    for (label, j) in [("pool", 0), ("IO", 4), ("PO", 5), ("tranche A", 1), ("tranche C", 3)] {
        row(&format!("effective duration, years: {}", label), (down[j] - up[j]) / (0.02 * base[j]));
    }
    let (flat, fz0, fz1) = (price(0.0, 0.0, None), price(0.0, SIG, Some(0.08)), price(0.01, SIG, Some(0.08)));
    row("wrong: one flat path, no volatility: pool", flat[0]);
    row("wrong: one flat path, no volatility: PO", flat[5]);
    row("  flat-path pool minus simulated pool", flat[0] - base[0]);
    row("wrong: CPR / 12 as the monthly rate: IO", det(0.08 / 12.0, v5).1);
    println!("wrong: prepayment frozen at 8%: pool {:.6}, IO today {:.6}", fz0[0], fz0[4]);
    row("wrong: prepayment frozen at 8%: IO at +1%", fz1[4]);
    row("wrong: pro rata, A's average life", (0..3).map(|j| wal[j] * SIZES[j]).sum::<f64>() / FACE);
    assert!(((1.0 - s8).powi(12) - 0.92).abs() < 1e-12, "twelve months at the monthly rate must leave 92%");
    assert!((io5 - io_closed(s8, v5)).abs() < 1e-9, "loop IO must equal the geometric-sum IO");
    assert!((par30 - FACE).abs() < 1e-9, "at the note rate a pass-through is par");
    assert!((base[6] - vasicek_zero(10.0)).abs() < 1e-3, "simulated zero must match the rate model's formula");
    assert!((flat[4] - io_closed(s8, v5)).abs() < 1e-9, "zero volatility must collapse to the fixed path");
    assert!((base[1] + base[2] + base[3] - base[0]).abs() < 1e-9, "tranches share out the pool");
    assert!(up[4] > base[4] && base[4] > down[4], "the IO gains when rates rise");
    assert!(bals[1][0] < SIZES[0] && bals.iter().all(|b| b[0] == 0.0 || b[1] == SIZES[1]), "A is paid first; B waits");
    println!("ALL CHECKS PASS");
}
