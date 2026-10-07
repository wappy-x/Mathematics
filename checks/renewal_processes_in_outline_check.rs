// Renewal processes in outline -- the check behind the card.  Rust std only.
// Buses leave a stop with gaps of 5 or 15 minutes, each with chance 0.5, the
// gaps independent.  Three roads: the formulas; an exact recursion over every
// bus pattern (in steps of 5 minutes, since every gap is a multiple of 5); and
// seeded simulations, each printed with its standard error.
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // SplitMix64 -> a number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn bus_gap(&mut self) -> f64 { if self.unif() < 0.5 { 5.0 } else { 15.0 } }
    fn exp_gap(&mut self) -> f64 { -15.0 * (1.0 - self.unif()).ln() } // house example: 4 calls an hour
}

fn passengers(r: &mut Rng, n: usize, bus: bool, horizon: f64) -> (f64, f64, f64) {
    let (mut w, mut w2, mut hit) = (0.0, 0.0, 0.0); // each passenger gets a fresh bus run
    for _ in 0..n {
        let s = horizon * r.unif();
        let (mut a, mut b) = (0.0, 0.0);
        while b < s { a = b; b += if bus { r.bus_gap() } else { r.exp_gap() }; }
        w += b - s; w2 += (b - s) * (b - s); if b - a > 10.0 { hit += 1.0; }
    }
    let nf = n as f64; let mean = w / nf;
    (mean, ((w2 / nf - mean * mean) / (nf - 1.0)).sqrt(), hit / nf)
}

fn main() {
    let mut r = Rng(20260929);
    let gaps = [5.0f64, 15.0]; let p = [0.5f64, 0.5];
    // ---- road 1: the formulas ----
    let mu = p[0] * gaps[0] + p[1] * gaps[1];
    let ex2 = p[0] * gaps[0] * gaps[0] + p[1] * gaps[1] * gaps[1];
    let var = ex2 - mu * mu;
    let wait = ex2 / (2.0 * mu);
    let long_share = p[1] * gaps[1] / mu; // length-biased chance of a 15-minute gap
    println!("formula,mean gap mu,{:.6}", mu);
    println!("formula,mean square gap E[X^2],{:.6}", ex2);
    println!("formula,variance of gap,{:.6}", var);
    println!("formula,rate 1/mu per minute,{:.6}", 1.0 / mu);
    println!("formula,rate per hour,{:.6}", 60.0 / mu);
    println!("formula,mean wait E[X^2]/(2 mu),{:.6}", wait);
    println!("formula,mu/2 + var/(2 mu),{:.6}", mu / 2.0 + var / (2.0 * mu));
    println!("formula,share of time in 15-min gaps,{:.6}", long_share);
    println!("formula,mean gap a passenger lands in,{:.6}", ex2 / mu);
    println!("hand,share of time in 5-min gaps,{:.6}", p[0] * gaps[0] / mu);
    println!("hand,mean wait inside a 5-min / 15-min gap,{:.6} {:.6}", gaps[0] / 2.0, gaps[1] / 2.0);
    println!("hand,extra wait var/(2 mu),{:.6}", var / (2.0 * mu));
    println!("hand,sandwich at t=60 lower upper,{:.6} {:.6}", 60.0 / mu - 1.0, 75.0 / mu - 1.0);
    let mut mark = 0.0;
    for i in 0..2 { let l = (gaps[i] / 5.0).floor(); mark += p[i] * l * (l - 1.0) / 2.0; }
    println!("formula,wait at a 5-minute mark,{:.6}", 5.0 * mark / (mu / 5.0));

    // ---- road 2: exact recursion, step = 5 minutes, gaps of 1 or 3 steps ----
    const K: usize = 1200; // 6000 minutes
    let steps = [(1usize, 0.5f64), (3usize, 0.5f64)];
    let mut m = vec![0.0f64; K + 2]; // m[k] = E[N(5k)]
    let mut d = vec![0.0f64; K + 2]; // d[k] = E[first bus at or after 5k] - 5k, in steps
    let mut u = vec![0.0f64; K + 2]; u[0] = 1.0; // chance a bus leaves at exactly 5k
    for k in 1..K + 2 {
        let (mut mk, mut dk, mut uk) = (0.0, 0.0, 0.0);
        for &(s, q) in steps.iter() {
            if s <= k { mk += q * (1.0 + m[k - s]); uk += q * u[k - s]; }
            dk += q * if s >= k { (s - k) as f64 } else { d[k - s] };
        }
        m[k] = mk; d[k] = dk; u[k] = uk;
    }
    // brute force: all 2^12 patterns of 12 gaps (bit i set: gap i + 1 is 3 steps), buses by step 12, whole numbers
    let a12: u64 = (0u64..4096).map(|b| (1..=12u64).filter(|&n| (0..n).map(|i| 1 + 2 * ((b >> i) & 1)).sum::<u64>() <= 12).count() as u64).sum();
    println!("exact,E[N(60)] by brute force over all 4096 patterns of 12 gaps,{}/4096", a12);
    println!("exact,E[N(60)],{:.6}", m[12]);
    let ok_bounds = (1..K + 1).all(|k| 5.0 * k as f64 / mu - 1.0 < m[k] && m[k] <= (5.0 * k as f64 + 15.0) / mu - 1.0);
    for &t in [15usize, 30, 60, 120, 240, 480, 6000].iter() {
        println!("exact,buses per hour m(t)/t*60 at t={},{:.6}", t, 60.0 * m[t / 5] / t as f64);
    }
    let ch: Vec<String> = [15usize, 30, 60, 120, 240, 480].iter().map(|&t| format!("{:.2}", 60.0 * m[t / 5] / t as f64)).collect();
    println!("chart,m(t)/t*60 at t=15 30 60 120 240 480,{}", ch.join(" "));
    let wald_l = (mu / 5.0) * (m[K] + 1.0);
    let wald_r = (K + 1) as f64 + d[K + 1];
    println!("exact,Wald mu*(m(t)+1) at t=6000 (steps),{:.6}", wald_l);
    println!("exact,E[time of first bus after t] (steps),{:.6}", wald_r);
    let window = |k: usize| { let mut s = 0.0; for j in 0..k { s += d[j + 1] + 0.5; } 5.0 * s / k as f64 };
    for &tt in [60usize, 600, 6000].iter() {
        println!("exact,mean wait over arrivals in [0 {}),{:.6}", tt, window(tt / 5));
    }
    let share = |k: usize| {
        let mut s = 0.0;
        for j in 0..k as i64 { let mut c = 0.0; for i in j - 2..=j { if i >= 0 { c += u[i as usize]; } } s += 0.5 * c; }
        s / k as f64
    };
    let ex_share = share(120);
    println!("exact,share of [0 600) in 15-min gaps,{:.6}", ex_share);
    println!("exact,wait arriving exactly at t=6000,{:.6}", 5.0 * d[K]);
    println!("exact,wait arriving at t=6000.001,{:.6}", 5.0 * d[K + 1] + 5.0 - 0.001);

    // ---- road 3: seeded simulation ----
    const NP: usize = 40000;
    let (sw, sse, sh) = passengers(&mut r, NP, true, 600.0);
    let sh_se = (sh * (1.0 - sh) / NP as f64).sqrt();
    println!("sim,mean wait arriving in [0 600),{:.6}", sw);
    println!("sim,standard error,{:.6}", sse);
    println!("sim,share landing in a 15-min gap,{:.6}", sh);
    println!("sim,standard error of share,{:.6}", sh_se);
    let (pw, pse, _) = passengers(&mut r, NP, false, 600.0);
    println!("sim,house example wait (4 calls/hour),{:.6}", pw);
    println!("sim,house standard error,{:.6}", pse);
    println!("formula,house example wait E[X^2]/(2 mu),{:.6}", 2.0 * 15.0f64 * 15.0 / (2.0 * 15.0));
    let batches = 10000.0; // one long run, counted in 100 batches
    let (mut b, mut cnt) = (0.0f64, [0u32; 100]);
    loop {
        b += r.bus_gap();
        if b >= 100.0 * batches { break; }
        cnt[(b / batches).floor() as usize] += 1;
    }
    let rates: Vec<f64> = cnt.iter().map(|&c| 60.0 * c as f64 / batches).collect();
    let rm = rates.iter().fold(0.0, |s, x| s + x) / 100.0;
    let rse = (rates.iter().fold(0.0, |s, x| s + (x - rm) * (x - rm)) / 99.0 / 100.0).sqrt();
    println!("sim,buses per hour over 1000000 min,{:.6}", rm);
    println!("sim,standard error of rate,{:.6}", rse);

    // ---- what breaks ----
    println!("breaks,half the mean gap,{:.6}", mu / 2.0);
    println!("breaks,mean gap counted per bus,{:.6}", mu);
    let dep = 0.5 * (6000 / 5) as f64 / 6000.0 * 60.0 + 0.5 * (6000 / 15) as f64 / 6000.0 * 60.0;
    println!("breaks,every gap = the first gap: buses per hour at t=6000,{:.6}", dep);

    for &(name, g, q) in [("even 10 min", [10.0f64, 10.0], [0.5f64, 0.5]), ("short 0.75", [5.0, 15.0], [0.75, 0.25]), ("1 or 19", [1.0, 19.0], [0.5, 0.5])].iter() {
        let (m1, m2) = (q[0] * g[0] + q[1] * g[1], q[0] * g[0] * g[0] + q[1] * g[1] * g[1]);
        println!("try,{}: mean gap / per hour / wait / half gap,{:.6} {:.6} {:.6} {:.6}", name, m1, 60.0 / m1, m2 / (2.0 * m1), m1 / 2.0);
    }

    // ---- figure: the sawtooth over one hour, gaps 5 15 5 5 15 15 ----
    let (mut fig, mut x, mut area) = (Vec::new(), 0i64, 0.0);
    for &g in [5i64, 15, 5, 5, 15, 15].iter() {
        fig.push(format!("{}:{}", 40 + 5 * x, 190 - 10 * g)); x += g; area += (g * g) as f64 / 2.0;
    }
    println!("figure,tooth start x:top y,{},end x {},mean line y {}", fig.join(" "), 40 + 5 * x, 190.0 - 10.0 * area / 60.0);
    println!("figure,tooth areas small large,{:.6} {:.6}", 5.0 * 5.0 / 2.0, 15.0 * 15.0 / 2.0);
    println!("figure,sawtooth area / 60,{:.6}", area / 60.0);

    assert!(ok_bounds, "sandwich t/mu - 1 < m(t) <= (t + 15)/mu - 1 failed");
    assert!((60.0 * m[K] / 6000.0 - 60.0 / mu).abs() < 60.0 * 1.5 / 6000.0, "elementary renewal theorem");
    assert!((wald_l - wald_r).abs() < 1e-9, "Wald's identity: two recursions disagree");
    assert!(a12 as f64 == m[12] * 4096.0, "brute force over every gap pattern vs recursion");
    assert!((5.0 * d[K] - 5.0 * mark / (mu / 5.0)).abs() < 1e-6, "wait at a 5-minute mark: exact vs formula");
    assert!((window(K) - wait).abs() < 0.01, "exact wait vs formula");
    assert!((sw - window(120)).abs() < 4.0 * sse, "sim wait vs exact");
    assert!((sh - ex_share).abs() < 4.0 * sh_se, "length bias: sim vs exact");
    assert!((share(K) - long_share).abs() < 0.01, "length bias: exact vs formula");
    assert!((pw - 15.0).abs() < 4.0 * pse, "Poisson wait is the full mean gap");
    assert!((rm - 60.0 / mu).abs() < 4.0 * rse, "simulated rate");
    println!("all checks passed");
}
