// Birth-and-death processes -- the check behind the card.  std only.
// Switchboard: 3 lines, no waiting room, calls at 4 an hour, each lasting 30 minutes on average.
// Outbreak: each case infects others at 0.3 a day and recovers at 0.2 a day.  Runaway: births at n^2 an hour.
// Roads: detailed balance; a generic solve of pi G = 0; Erlang's recursion; seeded simulations; the branching fixed point; Euler steps; an exact series.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
const LAM: i64 = 4; const MU: i64 = 2; const C: usize = 3;
type M = Vec<Vec<f64>>;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64); // an exact fraction, kept in lowest terms with a positive denominator
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl Q { fn f(self) -> f64 { self.0 as f64 / self.1 as f64 } fn s(self) -> String { if self.1 == 1 { format!("{}", self.0) } else { format!("{}/{}", self.0, self.1) } } }
fn qsum(v: &[Q]) -> Q { v.iter().fold(q(0, 1), |s, &x| s + x) }
fn fsum<I: Iterator<Item = f64>>(it: I) -> f64 { // compensated sum, as Python's sum() does for floats
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s }; s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn expo(&mut self, rate: f64) -> f64 { -(1.0 - self.uniform()).ln() / rate }
}
fn gen(birth: &dyn Fn(usize) -> f64, death: &dyn Fn(usize) -> f64, cap: usize) -> M { // tridiagonal, rows add to 0
    let mut g = vec![vec![0.0; cap + 1]; cap + 1];
    for n in 0..=cap {
        if n < cap { g[n][n + 1] = birth(n); } if n > 0 { g[n][n - 1] = death(n); }
        g[n][n] = -fsum(g[n].iter().cloned());
    }
    g
}
fn solve(a: &M, b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = a.len();
    let mut m: M = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let piv = (c..n).fold(c, |p, r| if m[r][c].abs() > m[p][c].abs() { r } else { p });
        m.swap(c, piv);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            if f != 0.0 { for k in c..=n { m[r][k] -= f * m[c][k]; } }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - fsum((i + 1..n).map(|k| m[i][k] * x[k]))) / m[i][i]; }
    x
}
fn stationary(g: &M) -> Vec<f64> { // pi G = 0 with the last equation swapped for "shares add to 1"
    let n = g.len();
    let mut a: M = (0..n).map(|j| (0..n).map(|i| g[i][j]).collect()).collect();
    a[n - 1] = vec![1.0; n];
    solve(&a, &(0..n).map(|i| if i == n - 1 { 1.0 } else { 0.0 }).collect::<Vec<_>>())
}
fn mse(xs: &[f64]) -> (f64, f64) {
    let (n, m) = (xs.len() as f64, fsum(xs.iter().cloned()) / xs.len() as f64);
    (m, (fsum(xs.iter().map(|x| (x - m) * (x - m))) / (n - 1.0) / n).sqrt())
}
fn thetas(death: &dyn Fn(i64) -> i64, top: usize) -> Vec<Q> { // product of birth rate / death rate along 0 -> n
    (1..=top).fold(vec![q(1, 1)], |mut th, n| { let last = th[n - 1]; th.push(last * q(LAM, death(n as i64))); th })
}
fn js(v: &[String]) -> String { v.join(", ") }
fn board(seed: u64, fixed: bool) -> (Vec<f64>, f64, f64) { // a call finding 3 lines busy is lost
    let (hours, nb, mut g, mut t, mut ends, mut seen) = (100000.0, 100usize, SplitMix64(seed), 0.0, Vec::<f64>::new(), vec![0usize; C + 1]);
    let mut blk = vec![[0usize; 2]; nb];
    loop {
        t += g.expo(LAM as f64);
        if t >= hours { break; }
        ends.retain(|&e| e > t);
        let k = (t * nb as f64 / hours) as usize;
        seen[ends.len()] += 1; blk[k][0] += 1;
        if ends.len() == C { blk[k][1] += 1; } else { let e = t + if fixed { 0.5 } else { g.expo(MU as f64) }; ends.push(e); }
    }
    let (tot, (m, se)) = (seen.iter().sum::<usize>(), mse(&blk.iter().map(|b| b[1] as f64 / b[0] as f64).collect::<Vec<_>>()));
    (seen.iter().map(|&s| s as f64 / tot as f64).collect(), m, se)
}
fn p0(t: f64, b: f64, d: f64) -> f64 { if b == d { b * t / (1.0 + b * t) } else { d * (((b - d) * t).exp() - 1.0) / (b * ((b - d) * t).exp() - d) } }
fn euler(b: f64, d: f64, t: f64) -> Vec<f64> { // forward equations on 0..300, step 0.002 day
    let (nn, h, mut p) = (300usize, 0.002, (0..301).map(|n| if n == 1 { 1.0 } else { 0.0 }).collect::<Vec<f64>>());
    for _ in 0..(t / h).round() as usize {
        p = (0..=nn).map(|n| { let nf = n as f64;
            p[n] + h * ((if n > 1 { b * (nf - 1.0) * p[n - 1] } else { 0.0 }) + (if n < nn { d * (nf + 1.0) * p[n + 1] } else { 0.0 })
                - (if n < nn { (b + d) * nf * p[n] } else { d * nf * p[n] })) }).collect();
    }
    p
}
fn main() {
    let gm = gen(&|_| LAM as f64, &|n| (n as i64 * MU) as f64, C);
    println!("switchboard G, rows 0..3 lines busy: {}", gm.iter().map(|r| js(&r.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>())).collect::<Vec<_>>().join("; "));
    let theta = thetas(&|n| n * MU, C);
    let s = qsum(&theta); let pi: Vec<Q> = theta.iter().map(|&t| t / s).collect();
    println!("road 1, detailed balance: theta = {}, total {}; pi = {}", js(&theta.iter().map(|x| x.s()).collect::<Vec<_>>()), s.s(), js(&pi.iter().map(|x| x.s()).collect::<Vec<_>>()));
    println!("figure, pi per 100, n = 0..3: {}", js(&pi.iter().map(|p| format!("{:.2}", 100.0 * p.f())).collect::<Vec<_>>()));
    let pi2 = stationary(&gm);
    println!("road 2, generic solve of pi G = 0: {}", js(&pi2.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>()));
    assert!((0..=C).fold(0.0f64, |m, n| m.max((pi2[n] - pi[n].f()).abs())) < 1e-12);
    let a = q(LAM, MU);
    let bl = (1..8).fold(vec![q(1, 1)], |mut v, c| { let last = v[c - 1]; v.push(a * last / (q(c as i64, 1) + a * last)); v });
    println!("road 3, Erlang recursion B(c), c = 0..7: {}", js(&bl.iter().map(|b| format!("{:.4}", b.f())).collect::<Vec<_>>()));
    assert_eq!(bl[C], pi[C]);
    let busy = qsum(&pi.iter().enumerate().map(|(n, &p)| q(n as i64, 1) * p).collect::<Vec<_>>());
    println!("all lines busy: {} = {:.4}; lost calls per hour {:.4}; mean lines busy {:.4} = a (1 - B) {:.4}", pi[C].s(), pi[C].f(), (q(LAM, 1) * pi[C]).f(), busy.f(), (a * (q(1, 1) - bl[C])).f());
    assert_eq!(busy, a * (q(1, 1) - bl[C]));
    println!("fewest lines with B under 1 percent: {}", (0..8).find(|&c| bl[c].f() < 0.01 && (bl[c] - q(1, 100)).0 < 0).unwrap());
    for (seed, fixed, name) in [(20261123u64, false, "exponential"), (20261124, true, "fixed 30-minute")] {
        let (sh, m, se) = board(seed, fixed);
        println!("road 4, {} calls, 100000 hours: lost share {:.4} +- {:.4}; lines busy as seen by callers, per 100: {}", name, m, se, js(&sh.iter().map(|x| format!("{:.2}", 100.0 * x)).collect::<Vec<_>>()));
        assert!((m - pi[C].f()).abs() < 4.0 * se);
    }
    let (r, one) = (q(LAM, C as i64 * MU), q(1, 1)); // M/M/3: the same lines, now with a waiting room; theta_n = theta_3 r^(n-3)
    let z = qsum(&theta[..C]) + theta[C] / (one - r);
    let (pw, lq) = (theta[C] / (one - r) / z, theta[C] / z * r / ((one - r) * (one - r)));
    println!("M/M/3 with a waiting room, road 1: pi_0 = {}, chance to wait {} = {:.4}, mean queue {} = {:.4}, mean wait {:.2} min, mean wait of those who wait {:.2} min",
        (one / z).s(), pw.s(), pw.f(), lq.s(), lq.f(), ((lq + pw) / q(C as i64 * MU, 1) * q(60, 1)).f(), ((lq + pw) / q(C as i64 * MU, 1) / pw * q(60, 1)).f());
    let gf = gen(&|_| LAM as f64, &|n| (MU * n.min(C) as i64) as f64, 120);
    let mut am: M = (0..120).map(|j| (0..121).map(|i| gf[i][j]).collect()).collect();
    am.push(vec![1.0; 121]);
    let pf = solve(&am, &(0..121).map(|i| if i == 120 { 1.0 } else { 0.0 }).collect::<Vec<_>>());
    let (w3, l3) = (fsum(pf[3..].iter().cloned()), fsum((3..121).map(|n| (n - 3) as f64 * pf[n])));
    println!("M/M/3, road 2, generic solve on 121 states: chance to wait {:.4}, mean queue {:.4}", w3, l3);
    assert!((w3 - pw.f()).abs() < 1e-9 && (l3 - lq.f()).abs() < 1e-9);
    let (b, d) = (0.3f64, 0.2f64);
    let mut qq = 0.0f64;
    for _ in 0..500 { qq = (d + b * qq * qq) / (b + d); }
    println!("outbreak, extinction from 1 case: road 1 (d/b) = {:.4}; road 2 branching fixed point {:.4}; from 3 cases {:.4}, {:.4}", d / b, qq, (d / b).powf(3.0), qq.powf(3.0));
    assert!((qq - d / b).abs() < 1e-12);
    let (mut g, rr, mut dead) = (SplitMix64(20261125), 20000usize, 0usize);
    for _ in 0..rr {
        let mut n = 1i64;
        while 0 < n && n < 60 { n += if g.uniform() < b / (b + d) { 1 } else { -1 }; }
        if n == 0 { dead += 1; }
    }
    let (ph, se) = (dead as f64 / rr as f64, (dead as f64 / rr as f64 * (1.0 - dead as f64 / rr as f64) / rr as f64).sqrt());
    println!("road 3, {} simulated outbreaks from 1 case (jump chain, stop at 0 or 60): extinct {:.4} +- {:.4}", rr, ph, se);
    assert!((ph - d / b).abs() < 4.0 * se);
    for (bb, dd) in [(b, d), (0.25, 0.25)] {
        let e = euler(bb, dd, 10.0);
        let me = fsum(e.iter().enumerate().map(|(n, x)| n as f64 * x));
        println!("road 4, Euler steps 0.002 day, b {:.2}, d {:.2}: extinct by day 10 {:.4} (formula {:.4}); mean cases {:.4} (formula e^((b-d)t) = {:.4})", bb, dd, e[0], p0(10.0, bb, dd), me, ((bb - dd) * 10.0).exp());
        assert!((e[0] - p0(10.0, bb, dd)).abs() < 2e-3 && (me - ((bb - dd) * 10.0).exp()).abs() < 1e-2);
    }
    println!("figure, extinct by day 0, 5, ..., 60, per 100, b 0.3 d 0.2: {}", js(&(0..13).map(|k| format!("{:.2}", 100.0 * p0((5 * k) as f64, b, d))).collect::<Vec<_>>()));
    println!("figure, same days, b = d = 0.25: {}", js(&(0..13).map(|k| format!("{:.2}", 100.0 * p0((5 * k) as f64, 0.25, 0.25))).collect::<Vec<_>>()));
    println!("critical outbreak: mean stays 1, but extinct by day 100 {:.4}, by day 1000 {:.4}", p0(100.0, 0.25, 0.25), p0(1000.0, 0.25, 0.25));
    let et = fsum((1..1000000u64).map(|n| 1.0 / (n * n) as f64));
    let cdf = |t: f64| 1.0 - fsum((1..60i64).map(|k| (2 * if k % 2 == 1 { 1 } else { -1 }) as f64 * (-(k * k) as f64 * t).exp()));
    println!("runaway births at n^2 an hour: road 1, mean time to infinity, sum 1/n^2 = {:.4}, pi^2/6 = {:.4}", et, PI.powf(2.0) / 6.0); assert!((et - PI.powf(2.0) / 6.0).abs() < 1e-5);
    println!("road 2, exact series: P(T <= 0.5 h) {:.4}, P(T <= 1 h) {:.4}, P(T <= 2 h) {:.4}; E e^-T = pi / sinh pi = {:.4}", cdf(0.5), cdf(1.0), cdf(2.0), PI / PI.sinh());
    let tail = fsum((201..1000000u64).map(|n| 1.0 / (n * n) as f64));
    let mut g = SplitMix64(20261126); let ts: Vec<f64> = (0..rr).map(|_| fsum((1..201u64).map(|n| g.expo((n * n) as f64))) + tail).collect();
    let ((mt, st), c1) = (mse(&ts), ts.iter().filter(|&&t| t <= 1.0).count() as f64 / rr as f64);
    let (et2, s1) = (mse(&ts.iter().map(|t| (-t).exp()).collect::<Vec<_>>()), (c1 * (1.0 - c1) / rr as f64).sqrt());
    println!("road 3, {} simulated runs: mean T {:.4} +- {:.4}, P(T <= 1 h) {:.4} +- {:.4}, E e^-T {:.4} +- {:.4}", rr, mt, st, c1, s1, et2.0, et2.1);
    assert!((mt - PI.powf(2.0) / 6.0).abs() < 4.0 * st && (c1 - cdf(1.0)).abs() < 4.0 * s1 && (et2.0 - PI / PI.sinh()).abs() < 4.0 * et2.1);
    let yp = fsum((1..1000000u64).map(|n| (n as f64 / (n + 1) as f64).ln())).exp();
    println!("Yule births at n an hour: mean hours to reach a million {:.4}; E e^-T, product n/(n+1), to a million {:.6}", fsum((1..1000000u64).map(|n| 1.0 / n as f64)), yp);
    assert!((yp - 1e-6).abs() < 1e-10);
    let w = thetas(&|_| MU, C); let wb = w[C] / qsum(&w);
    println!("mistake, one death rate for all lines: B = {} = {:.4}; Poisson tail P(N >= 3), mean 2: {:.4}", wb.s(), wb.f(), 1.0 - 5.0 * (-2.0f64).exp());
    println!("mistake, extinction from 3 cases read as d/b: {:.4}; true {:.4}", d / b, (d / b).powf(3.0));
    println!("ALL CHECKS PASS");
}
