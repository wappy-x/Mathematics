// Birthday problem and coupon collector -- the check behind the card.
// Rust std only. Roads: exact formula, brute-force enumeration on a
// small calendar, a step-by-step count of the chance itself, and a seeded simulation.

struct SplitMix64 { s: u64 } // the random numbers, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn day(&mut self, d: u64) -> usize { (((self.next() >> 32) * d) >> 32) as usize } // 0 .. d-1
}

fn no_match(n: usize, d: usize) -> f64 { // road 1: product of shrinking fractions
    let mut p = 1.0;
    for i in 0..n { p *= (d - i) as f64 / d as f64; }
    p
}

fn brute_no_match(n: u32, d: usize) -> f64 { // road 2: list every way n people can fall
    let total = d.pow(n);
    let mut good = 0usize;
    for code in 0..total {
        let mut seen = vec![false; d];
        let mut ok = true;
        for j in 0..n {
            let day = (code / d.pow(j)) % d;
            if seen[day] { ok = false; }
            seen[day] = true;
        }
        if ok { good += 1; }
    }
    good as f64 / total as f64
}

fn harmonic(d: usize) -> f64 { let mut h = 0.0; for k in 1..=d { h += 1.0 / k as f64; } h }

fn cover_dp(d: usize, tmax: usize) -> (f64, usize, Vec<f64>) { // road 2 for the collector
    let mut p = vec![0.0f64; d + 1];
    p[0] = 1.0;
    let (mut mean, mut median, mut cdf) = (0.0f64, 0usize, Vec::new());
    for t in 1..=tmax {
        mean += 1.0 - p[d]; // E[T] = sum over t of P(T > t-1)
        let mut q = vec![0.0f64; d + 1];
        for k in 0..=d {
            if p[k] == 0.0 { continue; }
            q[k] += p[k] * k as f64 / d as f64;
            if k < d { q[k + 1] += p[k] * (d - k) as f64 / d as f64; }
        }
        p = q;
        cdf.push(p[d]);
        if median == 0 && p[d] >= 0.5 { median = t; }
    }
    (mean, median, cdf)
}

fn main() {
    const D: usize = 365;
    let df = D as f64;
    println!("== birthdays: 365 equally likely days ==");
    let p23 = 1.0 - no_match(23, D);
    println!("n=22  P(shared) = {:.6}", 1.0 - no_match(22, D));
    println!("n=23  P(shared) = {:.6}   pairs = {}", p23, 23 * 22 / 2);
    let n50 = (1..D + 2).find(|&n| 1.0 - no_match(n, D) > 0.5).unwrap();
    let root = (2.0 * df * 2f64.ln()).sqrt();
    println!("first n above one half = {}   sqrt(2 d ln 2) = {:.4}", n50, root);
    let approx = 1.0 - (-(23.0 * 22.0) / (2.0 * df)).exp();
    println!("approx 1 - exp(-n(n-1)/2d) at 23 = {:.6}", approx);
    for n in [40, 57, 70] { println!("n={}  P(shared) = {:.6}", n, 1.0 - no_match(n, D)); }
    let c1: Vec<String> = (1..13).map(|i| format!("{:.2}", 1.0 - no_match(5 * i, D))).collect();
    println!("chart1,{}", c1.join(","));

    let mut rng = SplitMix64 { s: 20260928 };
    let rooms = 20000;
    let mut hits = 0;
    for _ in 0..rooms {
        let mut seen = [false; D];
        for _ in 0..23 {
            let k = rng.day(D as u64);
            if seen[k] { hits += 1; break; }
            seen[k] = true;
        }
    }
    let ph = hits as f64 / rooms as f64;
    let se = (ph * (1.0 - ph) / rooms as f64).sqrt();
    println!("simulated 23-person rooms: {:.4}  (standard error {:.4}, {} rooms)", ph, se, rooms);
    assert!((ph - p23).abs() < 4.0 * se, "simulation disagrees with the product formula");

    let (pb, pf) = (1.0 - brute_no_match(4, 12), 1.0 - no_match(4, 12));
    let m50 = (1..14).find(|&n| 1.0 - no_match(n, 12) > 0.5).unwrap();
    println!("birth months, 4 people ({} lists): enumerated {:.6}   formula {:.6}   first n above one half = {}", 12usize.pow(4), pb, pf, m50);
    assert!((pb - pf).abs() < 1e-12, "enumeration disagrees with the product formula");
    assert!(n50 == root.ceil() as usize, "threshold and square-root rule disagree");

    println!("== what breaks ==");
    println!("match one fixed person, 22 others: {:.6}", 1.0 - (364.0f64 / 365.0).powf(22.0));
    println!("add pair chances 253/365: {:.6}", 253.0 / 365.0);
    let mut w = vec![1.2f64; 182];
    w.extend(vec![0.8f64; 183]);
    let tot: f64 = w.iter().sum();
    let mut e = vec![0.0f64; 24];
    e[0] = 1.0;
    for x in &w { for k in (1..24).rev() { e[k] += e[k - 1] * x / tot; } } // e[k]: k distinct days
    let fact23: f64 = (1..=23).map(|k| k as f64).product();
    let uneven = 1.0 - fact23 * e[23];
    println!("uneven calendar (half the year 1.5x the other): {:.6}", uneven);
    assert!(uneven > p23, "an uneven calendar should raise the match chance");

    println!("== collecting all 365 days ==");
    let h = harmonic(D);
    let exact = df * h;
    let mut var = 0.0;
    for i in 0..D { let p = (D - i) as f64 / df; var += (1.0 - p) / (p * p); }
    println!("H_365 = {:.6}   E[T] = 365 H_365 = {:.4}   sd = {:.4}", h, exact, var.sqrt());
    println!("d ln d = {:.4}   d(ln d + gamma) + 1/2 = {:.4}", df * df.ln(), df * (df.ln() + 0.5772156649) + 0.5);
    let waits: Vec<String> = [0, 182, 364].iter().map(|&i| format!("{:.4}", df / (D - i) as f64)).collect();
    println!("wait for new day number 1, 183, 365: {}", waits.join(", "));
    let (mean, med, cdf) = cover_dp(D, 14000);
    println!("step-by-step mean = {:.4}   median = {}   P(done by 2365) = {:.6}", mean, med, cdf[2364]);
    assert!((mean - exact).abs() < 1e-6, "step-by-step mean disagrees with d H_d");
    let mut allp = 1.0f64;
    for k in 1..=D { allp *= k as f64 / df; }
    println!("P(all days covered by 365 people) = {}", sci(allp));
    println!("naive: wait 365 for each day = {}", D * D);
    let c2: Vec<String> = (0..5).map(|j| {
        let a = 73 * j;
        format!("{:.2}", df * (harmonic(D - a) - harmonic(D - a - 73)))
    }).collect();
    println!("chart2,{}", c2.join(","));

    let mut rng = SplitMix64 { s: 365 };
    let runs = 2000;
    let (mut s, mut s2) = (0.0f64, 0.0f64);
    for _ in 0..runs {
        let mut seen = [false; D];
        let (mut got, mut t) = (0, 0u64);
        while got < D {
            t += 1;
            let k = rng.day(D as u64);
            if !seen[k] { seen[k] = true; got += 1; }
        }
        s += t as f64;
        s2 += (t * t) as f64;
    }
    let m = s / runs as f64;
    let sem = ((s2 / runs as f64 - m * m) / runs as f64).sqrt();
    println!("simulated collectors: mean {:.2}  (standard error {:.2}, {} runs)", m, sem, runs);
    assert!((m - exact).abs() < 4.0 * sem, "simulation disagrees with d H_d");

    println!("== a die, all six faces ==");
    println!("E[T] = 6 H_6 = {:.4}", 6.0 * harmonic(6));
}

fn sci(x: f64) -> String { // Python-style 1.234e-157
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { "-" } else { "+" }, ev.abs())
}
