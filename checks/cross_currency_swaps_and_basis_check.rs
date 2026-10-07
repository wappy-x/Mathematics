// Cross-currency swap with a basis -- the check behind the card.  std only, no crates.
// EUR against USD, 5 years, annual payments, EUR 100m against USD 110m at spot 1.10.
// Road 1: bootstrap the dollar-collateral euro curve from the quoted basis, then the par formula.
// Road 2: a ledger in dollars, every euro flow converted at its FX forward; bisection for the spread.
// Road 3: simulated spot paths, every euro flow converted at the simulated spot.
const S: f64 = 1.10;
const NF: f64 = 100e6;
const ND: f64 = 110e6;
const RD: f64 = 0.05;
const RF: f64 = 0.03;
const Q: f64 = -0.0015;
const T: usize = 5;

struct M { dd: Vec<f64>, pf: Vec<f64>, fe: Vec<f64>, fd: Vec<f64> }

impl M {
    fn new() -> M {
        let dd: Vec<f64> = (0..=T).map(|i| (-RD * i as f64).exp()).collect(); // dollar discount factors
        let pf: Vec<f64> = (0..=T).map(|i| (-RF * i as f64).exp()).collect(); // euro OIS curve
        let fe = (1..=T).map(|i| pf[i - 1] / pf[i] - 1.0).collect();         // euro fixing each year
        let fd = (1..=T).map(|i| dd[i - 1] / dd[i] - 1.0).collect();         // dollar fixing each year
        M { dd, pf, fe, fd }
    }
    // euro discount factors that make a q-basis swap fair at every maturity
    fn bootstrap(&self, q: f64) -> Vec<f64> {
        let mut dx = vec![1.0];
        for i in 1..=T { let last = dx[i - 1]; dx.push(last / (1.0 + self.fe[i - 1] + q)); }
        dx
    }
    // road 1: the spread that puts the euro leg at par
    fn par_basis(&self, dx: &[f64], n: usize) -> f64 {
        let fl: f64 = (1..=n).map(|i| self.fe[i - 1] * dx[i]).sum();
        let a: f64 = dx[1..=n].iter().sum();
        (1.0 - dx[n] - fl) / a
    }
    // road 2: value in dollars to the euro lender (receives euro leg, pays dollar leg)
    fn ledger(&self, dx: &[f64], s: f64, x: f64, dsp: f64, principal: bool, fx: Option<&[f64]>) -> f64 {
        let fwd: Vec<f64> = match fx {
            Some(f) => f.to_vec(),
            None => (0..=T).map(|i| x * dx[i] / self.dd[i]).collect(),
        };
        let mut v = 0.0;
        for i in 1..=T {
            v += NF * (self.fe[i - 1] + s) * fwd[i] * self.dd[i] - ND * (self.fd[i - 1] + dsp) * self.dd[i];
        }
        if principal { v += NF * fwd[T] * self.dd[T] - ND * self.dd[T] + (ND - NF * S); }
        v
    }
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.next(), self.next());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn main() {
    let m = M::new();
    let dx = m.bootstrap(Q);
    let ax: f64 = dx[1..].iter().sum();
    let ad: f64 = m.dd[1..].iter().sum();
    let af: f64 = m.pf[1..].iter().sum();
    let b1 = m.par_basis(&dx, T);
    let b2 = bisect(|s| m.ledger(&dx, s, S, 0.0, true, None), -0.01, 0.01);
    let y = -dx[T].ln() / T as f64; // implied euro rate, continuously compounded
    let (f5, f5cip) = (S * dx[T] / m.dd[T], S * m.pf[T] / m.dd[T]);
    let yf_from_fwd = RD - (f5 / S).ln() / T as f64; // the implied-yield card's formula
    let v0_closed = S * NF * (0.0 - Q) * ax;
    let v0_ledger = m.ledger(&dx, 0.0, S, 0.0, true, None);
    let usd_eq_closed = -Q * S * NF * ax / (ND * ad);
    let usd_eq_bisect = bisect(|x| m.ledger(&dx, 0.0, S, x, true, None), -0.01, 0.01);

    // road 3: spot follows a random walk in logs whose average matches the FX forwards
    let (vol, paths) = (0.08, 100000usize);
    let mut rng = Rng(20260927);
    let (mut tot, mut tot2) = (0.0f64, 0.0f64);
    for _ in 0..paths {
        let zs: Vec<f64> = (0..T).map(|_| rng.normal()).collect();
        for sign in [1.0, -1.0] {
            let (mut lx, mut leg) = (S.ln(), 0.0);
            for i in 1..=T {
                lx += (RD - y - 0.5 * vol * vol) + vol * sign * zs[i - 1];
                let last = if i == T { 1.0 } else { 0.0 };
                leg += NF * ((m.fe[i - 1] + Q) + last) * lx.exp() * m.dd[i];
            }
            tot += leg; tot2 += leg * leg;
        }
    }
    let n = (2 * paths) as f64;
    let mc = tot / n;
    let se = (tot2 / n - mc * mc).sqrt() / n.sqrt();
    let leg_fwd = S * NF * ((1..=T).map(|i| (m.fe[i - 1] + Q) * dx[i]).sum::<f64>() + dx[T]);

    // what breaks
    let wb_ois = m.ledger(&m.pf, Q, S, 0.0, true, None);
    let wb_ois_basis = m.par_basis(&m.pf, T);
    let wb_noprin = bisect(|s| m.ledger(&dx, s, S, 0.0, false, None), -0.1, 0.1);
    let dc: Vec<f64> = (0..=T).map(|i| (-(RF + Q) * i as f64).exp()).collect();
    let wb_cc = m.ledger(&dc, Q, S, 0.0, true, None);
    let wb_usd15 = m.ledger(&dx, 0.0, S, -Q, true, None);
    let spot = vec![S; T + 1];
    let wb_spot = m.ledger(&dx, Q, S, 0.0, true, Some(&spot));

    println!("curve by year: t, euro fixing, dollar fixing, D_d, D_x, FX forward, FX forward if CIP held");
    for i in 1..=T {
        println!("  {}  {:.4}%  {:.4}%  {:.6}  {:.6}  {:.6}  {:.6}", i, m.fe[i - 1] * 100.0, m.fd[i - 1] * 100.0,
                 m.dd[i], dx[i], S * dx[i] / m.dd[i], S * m.pf[i] / m.dd[i]);
    }
    let rows: Vec<(&str, f64)> = vec![
        ("euro coupon rate with basis, f + s (%)", (m.fe[0] + Q) * 100.0),
        ("euro coupon paid each year (EUR)", NF * (m.fe[0] + Q)),
        ("dollar coupon paid each year (USD)", ND * m.fd[0]),
        ("euro annuity A_x (years)", ax), ("dollar annuity A_d (years)", ad), ("euro OIS annuity (years)", af),
        ("1 fair basis, par formula (bp)", b1 * 1e4), ("2 fair basis, ledger + bisection (bp)", b2 * 1e4),
        ("3 euro leg in USD, simulated (USD)", mc), ("  simulation standard error (USD)", se),
        ("  euro leg in USD, forwards (USD)", leg_fwd),
        ("implied euro rate y, continuous (%)", y * 100.0), ("  y from the 5-year forward (%)", yf_from_fwd * 100.0),
        ("funding difference y - r_f (bp)", (y - RF) * 1e4),
        ("5-year forward with basis", f5), ("5-year forward if CIP held", f5cip), ("  gap (pips)", (f5 - f5cip) * 1e4),
        ("PV of the basis per year, EUR 150,000 (EUR)", -Q * NF * ax),
        ("value of a zero-basis swap, closed (USD)", v0_closed), ("  same, ledger (USD)", v0_ledger),
        ("dollar-leg equivalent spread, closed (bp)", usd_eq_closed * 1e4),
        ("  same, bisection (bp)", usd_eq_bisect * 1e4),
        ("wrong: euro OIS discounting, swap value (USD)", wb_ois), ("  its fair basis (bp)", wb_ois_basis * 1e4),
        ("wrong: no final principal, fair basis (bp)", wb_noprin * 1e4),
        ("wrong: -15bp as continuous shift (USD)", wb_cc),
        ("wrong: 15bp moved to dollar leg (USD)", wb_usd15),
        ("wrong: euro flows at today's spot (USD)", wb_spot),
    ];
    for (name, v) in &rows { println!("{:<46} {:>16.4}", name, v); }
    println!("spot moves (value to euro lender, USD m): spot, whole swap, coupons only");
    for x in [1.00, 1.05, 1.10, 1.15, 1.20] {
        let coup = m.ledger(&dx, Q, x, 0.0, false, None);
        println!("  {:.2}  {:8.2}  {:8.2}", x, m.ledger(&dx, Q, x, 0.0, true, None) / 1e6, coup / 1e6);
    }
    println!("basis moves (value of the -15bp swap to euro lender, USD k)");
    for qn in [-0.0030, -0.0020, -0.0010, 0.0] {
        println!("  {:6.1}bp  {:10.1}", qn * 1e4, m.ledger(&m.bootstrap(qn), Q, S, 0.0, true, None) / 1e3);
    }

    assert!((b1 - Q).abs() < 1e-12);                     // bootstrap reproduces the 5-year quote
    assert!((m.par_basis(&dx, 3) - Q).abs() < 1e-12);    // and the 3-year one
    assert!((b2 - b1).abs() < 1e-10);                    // road 2 agrees with road 1
    assert!((mc - NF * S).abs() < 4.0 * se);             // road 3: euro leg worth its notional
    assert!((v0_closed - v0_ledger).abs() < 1e-4);       // closed value vs ledger
    assert!((usd_eq_closed - usd_eq_bisect).abs() < 1e-10);
    assert!(((y - RF) - (1.0 + Q / (1.0 + m.fe[0])).ln()).abs() < 1e-12); // funding gap = ln((1+f+s)/(1+f))
    assert!(m.bootstrap(0.0).iter().zip(&m.pf).all(|(a, b)| (a - b).abs() < 1e-14)); // zero basis gives back the euro curve
    println!("all checks passed");
}
