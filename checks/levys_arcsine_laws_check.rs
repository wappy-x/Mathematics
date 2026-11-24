// Levy's arcsine laws for a year-long fair coin game: the last tie and the time in the lead, by five roads.
const S: f64 = 0.1; // fraction of the year
const N: usize = 364; // tosses, one a day
const PATHS: usize = 10000; // simulated years
const SEED: u64 = 20261123;

fn arcsine(s: f64) -> f64 { 2.0 / std::f64::consts::PI * s.sqrt().asin() } // road 1

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut acc = 0.0;
    for i in 1..m { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + acc)
}
fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn big_phi(x: f64) -> f64 { 0.5 + simpson(&phi, 0.0, x, 200) }

fn reflection_road(s: f64) -> f64 { // road 2: P(|fresh motion over 1 - s| < |W_s|), no arcsin
    let r = (s / (1.0 - s)).sqrt();
    simpson(&|z: f64| 2.0 * phi(z) * (2.0 * big_phi(r * z) - 1.0), 0.0, 9.0, 600)
}

fn u_list(m: usize) -> Vec<f64> { // u[k] = chance of a tie on day 2k = C(2k, k) / 4^k
    let mut u = vec![1.0];
    for k in 1..=m { let last = u[k - 1]; u.push(last * (2 * k - 1) as f64 / (2 * k) as f64); }
    u
}

fn walk_product(m: usize, s: f64) -> f64 { // road 3a
    let u = u_list(m);
    let top = (s * m as f64 + 1e-9) as usize;
    let mut acc = 0.0;
    for k in 0..=top { acc += u[k] * u[m - k]; }
    acc
}

fn walk_flow(days: usize, d: usize, p: f64) -> f64 { // road 3b: probability flow, no reflection
    let (size, off) = (2 * days + 3, days + 1);
    let mut f = vec![1.0; size];
    for _ in 0..(days - d) {
        let mut g = vec![1.0; size];
        for i in 1..size - 1 {
            let up = if i + 1 == off { 0.0 } else { f[i + 1] };
            let down = if i - 1 == off { 0.0 } else { f[i - 1] };
            g[i] = p * up + (1.0 - p) * down;
        }
        f = g;
    }
    let mut q = vec![0.0; size];
    q[off] = 1.0;
    for _ in 0..d {
        let mut g = vec![0.0; size];
        for i in 1..size - 1 { g[i] = p * q[i - 1] + (1.0 - p) * q[i + 1]; }
        q = g;
    }
    let mut acc = 0.0;
    for i in 0..size { acc += q[i] * f[i]; }
    acc
}

fn show(label: &str, v: f64) { println!("{:<44}{:>10.4}", label, v); }

fn comb(a: u64, b: u64) -> u64 { let mut c = 1u64; for i in 0..b { c = c * (a - i) / (i + 1); } c }

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    let n = N / 2;
    let c = arcsine(S);
    show("1 formula (2/pi) arcsin sqrt(0.1)", c);
    show("  sqrt(0.1)", S.sqrt());
    show("  arcsin sqrt(0.1), radians", S.sqrt().asin());
    show("  arctan(1/3), the same angle", (1.0f64 / 3.0).atan());
    let r2 = reflection_road(S);
    show("2 reflection road, no arcsin", r2);
    assert!((r2 - c).abs() < 1e-6, "reflection road disagrees with the arcsine formula");
    show("lead >= 90% of the year, either side, 2 x", 2.0 * c);
    show("density at mid-year, 1/(pi sqrt(0.25))", 1.0 / (std::f64::consts::PI * 0.25f64.sqrt()));
    let (w364, f364) = (walk_product(n, S), walk_flow(N, 36, 0.5));
    show("3 walk 364 days: last tie by day 36, product", w364);
    show("  same, probability flow", f364);
    assert!((w364 - f364).abs() < 1e-12, "product law u u disagrees with the probability flow");
    for m in [n, 10 * n, 100 * n] {
        let v = walk_product(m, S);
        println!("  walk {:>6} tosses: P(last tie <= 10%) {:.4}  gap {:+.4}", 2 * m, v, v - c);
    }
    assert!((walk_product(100 * n, S) - c).abs() < 0.002, "the walk does not approach the arcsine law");
    show("  tilted coin 0.52: last tie by day 36, flow", walk_flow(N, 36, 0.52));
    let u = u_list(n);
    let ties_sum: f64 = u[1..].iter().sum();
    let ties_id = (2 * n + 1) as f64 * u[n] - 1.0;
    show("expected ties in 364 days, sum of u", ties_sum);
    show("  identity (2n + 1) u_n - 1", ties_id);
    assert!((ties_sum - ties_id).abs() < 1e-9);

    const M: usize = 16; // road 4: every 16-toss match
    let (mut counts_last, mut counts_lead) = (vec![0u64; M / 2 + 1], vec![0u64; M / 2 + 1]);
    for bits in 0u32..(1 << M) {
        let (mut pos, mut last, mut lead) = (0i32, 0usize, 0usize);
        for i in 0..M {
            let prev = pos;
            pos += if bits >> i & 1 == 1 { 1 } else { -1 };
            if pos == 0 { last = i + 1; }
            if prev > 0 || pos > 0 { lead += 1; }
        }
        counts_last[last / 2] += 1;
        counts_lead[lead / 2] += 1;
    }
    let law: Vec<u64> = (0..=M / 2).map(|k| comb(2 * k as u64, k as u64) * comb((M - 2 * k) as u64, (M / 2 - k) as u64)).collect();
    println!("4 all 65536 matches of 16, k = 0..8: {}", law.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" "));
    assert!(counts_last == law && counts_lead == law, "16-toss counts break the discrete arcsine law");
    println!("  last tie on day 2k, and Ana in the lead 2k rounds: both match");

    let mut rng = SplitMix(SEED); // road 5: SplitMix64, one bit per toss
    let (mut hit_last, mut hit_lead, mut hit_ana, mut ties_total) = (0usize, 0usize, 0usize, 0usize);
    for _ in 0..PATHS {
        let (mut pos, mut last, mut lead, mut ties, mut word) = (0i32, 0usize, 0usize, 0usize, 0u64);
        for i in 0..N {
            if i % 64 == 0 { word = rng.next(); }
            let prev = pos;
            pos += if word >> (i % 64) & 1 == 1 { 1 } else { -1 };
            if pos == 0 { last = i + 1; ties += 1; }
            if prev > 0 || pos > 0 { lead += 1; }
        }
        if last <= 36 { hit_last += 1; }
        if lead >= 328 || lead <= 36 { hit_lead += 1; }
        if lead >= 328 { hit_ana += 1; }
        ties_total += ties;
    }
    for (label, hits, exact) in [("5 sim: last tie by day 36", hit_last, w364), ("  one side leads >= 328 days", hit_lead, 2.0 * w364)] {
        let p = hits as f64 / PATHS as f64;
        let se = (p * (1.0 - p) / PATHS as f64).sqrt();
        println!("{:<34}{:>8.4}  std err {:.4}  exact walk {:.4}", label, p, se, exact);
        assert!((p - exact).abs() < 4.0 * se, "{}", label);
    }
    show("  Ana alone leads >= 328 days", hit_ana as f64 / PATHS as f64);
    show("  average ties per year", ties_total as f64 / PATHS as f64);
    assert!((ties_total as f64 / PATHS as f64 - ties_id).abs() < 0.5);

    let mut term = 0.5f64.powi(N as i32); // C(364, j) / 2^364, built term by term
    let mut wrong_bin = 0.0;
    for j in 0..37 { wrong_bin += term; term = term * (N - j) as f64 / (j + 1) as f64; }
    wrong_bin *= 2.0;
    show("wrong: last tie uniform over the year", S);
    println!("{:<44}{:>10.2e}", "wrong: lead days as 364 independent coins", wrong_bin);
    show("wrong: one side only (Ana leads >= 90%)", c);
    for s in [0.5, 0.01, 0.99] { show(&format!("try: P(last tie <= {})", s), arcsine(s)); }
    show("try: lead >= 99% either side", 2.0 * arcsine(0.01));
    let tenths: Vec<f64> = (0..=10).map(|j| (arcsine(j as f64 / 10.0) * 100.0 * 100.0).round() / 100.0).collect();
    println!("chart, arcsine CDF %    {}", tenths.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, walk 364 days %  {}", (0..=10).map(|j| format!("{:.2}", walk_product(n, j as f64 / 10.0) * 100.0)).collect::<Vec<_>>().join(" "));
    println!("bars, P(last tie in tenth) % {}", (0..10).map(|j| format!("{:.2}", (arcsine((j + 1) as f64 / 10.0) - arcsine(j as f64 / 10.0)) * 100.0)).collect::<Vec<_>>().join(" "));
    assert!((arcsine(0.5) - 0.5).abs() < 1e-12, "the median of the last tie is not mid-year");
    println!("ALL CHECKS PASS");
}
