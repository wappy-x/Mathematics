// Conditional expectation on a sigma-algebra -- the same check as the Python,
// in Rust, std only.  Events are 12-bit masks, one bit per month; exact
// fractions are a numerator and a denominator kept by hand.  Two roads to
// E[X | G]: Radon-Nikodym densities of the positive and negative parts, and a
// brute search that never divides.  Then wet-or-not, an exact date, failures.
const MONTHS: [&str; 12] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const RAIN: [i64; 12] = [30, 24, 45, 60, 75, 100, 95, 75, 55, 40, 25, 36]; // mm in each month
const ALL: u16 = 0xFFF;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i64, d: i64 } // n / d in lowest terms, d > 0

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Q, b: Q) -> Q { add(a, q(-b.n, b.d)) }
fn div(a: Q, b: Q) -> Q { q(a.n * b.d, a.d * b.n) }
fn f2(a: Q) -> String { format!("{:.2}", a.n as f64 / a.d as f64) }

fn mask(ms: &[usize]) -> u16 { ms.iter().fold(0, |m, &i| m | 1 << i) }
fn generated(blocks: &[u16]) -> Vec<u16> { // every union of the blocks
    (0..1usize << blocks.len())
        .map(|c| (0..blocks.len()).filter(|j| c >> j & 1 == 1).fold(0, |m, j| m | blocks[j])).collect()
}
fn integral(f: &[Q], a: u16) -> Q { // each month has probability 1/12
    div((0..12).filter(|i| a >> i & 1 == 1).fold(q(0, 1), |s, i| add(s, f[i])), q(12, 1))
}
fn atoms(events: &[u16]) -> Vec<u16> { // smallest events: intersect all events holding w
    let mut out = Vec::new();
    for w in 0..12 {
        let a = events.iter().filter(|&&e| e >> w & 1 == 1).fold(ALL, |a, &e| a & e);
        if !out.contains(&a) { out.push(a) }
    }
    out
}
fn measurable(f: &[Q], events: &[u16]) -> &'static str {
    let ok = f.iter().all(|&c| events.contains(&(0..12).filter(|&i| sub(f[i], c).n <= 0).fold(0u16, |m, i| m | 1 << i)));
    if ok { "yes" } else { "no" }
}
fn rn_forecast(x: &[Q], events: &[u16]) -> (Vec<Q>, Vec<(Q, Q)>) { // road one
    let pos: Vec<Q> = x.iter().map(|v| q(v.n.max(0), v.d)).collect();
    let neg: Vec<Q> = x.iter().map(|v| q((-v.n).max(0), v.d)).collect();
    let one = vec![q(1, 1); 12];
    let (mut m, mut parts) = (vec![q(0, 1); 12], Vec::new());
    for a in atoms(events) {
        let hp = div(integral(&pos, a), integral(&one, a)); // d(nu+)/dP on the atom
        let hm = div(integral(&neg, a), integral(&one, a)); // d(nu-)/dP on the atom
        parts.push((hp, hm));
        for i in 0..12 { if a >> i & 1 == 1 { m[i] = sub(hp, hm) } }
    }
    (m, parts)
}
fn brute(blocks: &[u16], events: &[u16]) -> Vec<Vec<i64>> { // road two: 0, 5, ..., 100 per block
    let mut hits = Vec::new();
    for code in 0..21i64.pow(blocks.len() as u32) {
        let vals: Vec<i64> = (0..blocks.len()).map(|j| 5 * (code / 21i64.pow(j as u32) % 21)).collect();
        let mut m = [0i64; 12];
        for (v, b) in vals.iter().zip(blocks) { for i in 0..12 { if b >> i & 1 == 1 { m[i] = *v } } }
        let sum = |f: &[i64; 12], a: u16| (0..12).filter(|i| a >> i & 1 == 1).map(|i| f[i]).sum::<i64>();
        if events.iter().all(|&a| sum(&m, a) == sum(&RAIN, a)) { hits.push(vals) }
    }
    hits
}
fn r(u: f64) -> f64 { [30.0, 60.0, 90.0, 40.0][((u * 4.0) as usize).min(3)] }
fn grid(a: f64, b: f64) -> f64 { // integral of X(u, v) = r(u) * 2v over [a, b) x [0, 1)
    let (nu, nv) = (((b - a) * 400.0).round() as usize, 50);
    let mut s = 0.0;
    for i in 0..nu {
        let u = a + (b - a) * (i as f64 + 0.5) / nu as f64;
        for j in 0..nv { s += r(u) * 2.0 * (j as f64 + 0.5) / nv as f64 }
    }
    s * (b - a) / nu as f64 / nv as f64
}
fn exact(a: f64, b: f64) -> f64 { // integral of the candidate r(u) over [a, b)
    let mut cuts = vec![a];
    for c in [0.25, 0.5, 0.75] { if a < c && c < b { cuts.push(c) } }
    cuts.push(b);
    cuts.windows(2).map(|w| r((w[0] + w[1]) / 2.0) * (w[1] - w[0])).sum()
}

fn main() {
    let names = ["winter", "spring", "summer", "autumn"];
    let seasons = [mask(&[11, 0, 1]), mask(&[2, 3, 4]), mask(&[5, 6, 7]), mask(&[8, 9, 10])];
    let wet = [mask(&[8, 9, 10, 11, 0, 1]), mask(&[2, 3, 4, 5, 6, 7])];
    let first = |b: u16| (0..12).find(|i| b >> i & 1 == 1).unwrap();
    let rain: Vec<Q> = RAIN.iter().map(|&v| q(v, 1)).collect();
    let g = generated(&seasons);
    let (m, _) = rn_forecast(&rain, &g);
    let mean = integral(&rain, ALL);
    let z: Vec<Q> = rain.iter().map(|&v| sub(v, mean)).collect();
    let (mz, zparts) = rn_forecast(&z, &g);
    let found = brute(&seasons, &g);
    println!("months 12, events in the season sigma-algebra {}, atoms {}", g.len(), atoms(&g).len());
    println!("yearly mean E[X] = {}", f2(mean));
    let tot: Vec<i64> = seasons.iter().chain(wet.iter()).map(|&b| (0..12).filter(|i| b >> i & 1 == 1).map(|i| RAIN[i]).sum()).collect();
    println!("totals, mm: winter {}, spring {}, summer {}, autumn {}, dry {}, wet {}, year {}; P(winter) = {}",
             tot[0], tot[1], tot[2], tot[3], tot[4], tot[5], RAIN.iter().sum::<i64>(), f2(integral(&vec![q(1, 1); 12], g[1])));
    let spring: Vec<i64> = [2, 3, 4].iter().map(|&i| z[i].n).collect(); // whole mm, since the mean is 55
    let yr: i64 = z.iter().map(|v| v.n.max(0)).sum();
    println!("anomaly totals, mm: spring surplus {}, spring shortfall {}, year surplus {}; all sets of months {}",
             spring.iter().map(|v| v.max(&0)).sum::<i64>(), spring.iter().map(|v| (-v).max(0)).sum::<i64>(), yr, 1 << 12);
    let road: Vec<String> = (0..4).map(|k| format!("{} {}", names[k], f2(m[first(seasons[k])]))).collect();
    println!("road one, Radon-Nikodym on the atoms: {}", road.join(", "));
    let zp: Vec<Q> = z.iter().map(|v| q(v.n.max(0), v.d)).collect();
    let zn: Vec<Q> = z.iter().map(|v| q((-v.n).max(0), v.d)).collect();
    println!("anomaly Z = X - {}: nu+(Omega) = {}, nu-(Omega) = {}", f2(mean), f2(integral(&zp, ALL)), f2(integral(&zn, ALL)));
    for (k, &(hp, hm)) in zparts.iter().enumerate() {
        let d = sub(hp, hm);
        println!("  {}: h+ = {}, h- = {}, h+ - h- = {}, plus mean = {}", names[k], f2(hp), f2(hm), f2(d), f2(add(d, mean)));
    }
    println!("road two, brute search over {} forecasts, no division: {} passes, {:?}", 21i64.pow(4), found.len(), found);
    println!("property 1, E[X | G] is G-measurable: {}", measurable(&m, &g));
    let ok = g.iter().filter(|&&a| integral(&m, a) == integral(&rain, a)).count();
    println!("property 2, integrals match on {} of {} events", ok, g.len());
    for (name, a) in [("winter", g[1]), ("wet half", g[6]), ("Omega", g[15])] {
        println!("  {}: integral of X {}, of E[X | G] {}", name, f2(integral(&rain, a)), f2(integral(&m, a)));
    }
    let low: Vec<&str> = (0..12).filter(|&i| RAIN[i] <= 30).map(|i| MONTHS[i]).collect();
    println!("candidate X itself: G-measurable {}, since {{X <= 30}} = {}", measurable(&rain, &g), low.join(" "));
    let flat = vec![mean; 12];
    let fm = g.iter().filter(|&&a| integral(&flat, a) == integral(&rain, a)).count();
    println!("candidate constant {}: G-measurable {}, integrals match {} of 16; winter {} against {}",
             f2(mean), measurable(&flat, &g), fm, f2(integral(&flat, g[1])), f2(integral(&rain, g[1])));
    let g2 = generated(&wet);
    let (c, _) = rn_forecast(&rain, &g2);
    let (t, _) = rn_forecast(&m, &g2); // forecast the forecast
    let b2 = brute(&wet, &g2);
    println!("wet season or not: dry {}, wet {}; from the season forecast: dry {}, wet {}; brute search {:?}",
             f2(c[0]), f2(c[2]), f2(t[0]), f2(t[2]), b2);
    let show = |f: &[Q]| f.iter().map(|v| (v.n / v.d).to_string()).collect::<Vec<_>>().join(" ");
    println!("figure, rain {}", show(&rain));
    println!("figure, season forecast {}", show(&m));
    println!("figure, wet-or-not forecast {}", show(&c));
    let rows: Vec<(f64, f64, f64, f64)> = [(0.0, 0.1), (0.2, 0.3), (0.45, 0.8)].iter().map(|&(a, b)| (a, b, grid(a, b), exact(a, b))).collect();
    for &(a, b, gr, e) in &rows { println!("date in [{:?}, {:?}): integral of X {:.4}, of r(U) {:.4}", a, b, gr, e) }
    println!("exact date U = 0.5: P(U = 0.5) = 0, so the partition rule asks for 0/0");
    let (mut sums, mut acc, mut absacc) = (Vec::new(), q(0, 1), q(0, 1));
    for n in 1..7u32 { // X(n) = (-2)^n with probability 2^-n
        acc = add(acc, q((-2i64).pow(n), 2i64.pow(n)));
        absacc = add(absacc, q(2i64.pow(n), 2i64.pow(n)));
        sums.push(acc.n / acc.d);
    }
    println!("no integrability: partial sums of E[X] {:?}; of E|X| up to {} and rising", sums, absacc.n / absacc.d);

    let seasonal: Vec<i64> = seasons.iter().map(|&b| m[first(b)].n).collect();
    assert!(found == vec![vec![30, 60, 90, 40]] && seasonal == found[0]);
    let signed: Vec<Q> = seasons.iter().map(|&b| add(mz[first(b)], mean)).collect();
    assert!(signed.iter().zip(&found[0]).all(|(s, &v)| *s == q(v, 1))); // signed road agrees
    assert!(c[0] == t[0] && c[2] == t[2] && c[0] == q(35, 1) && c[2] == q(75, 1) && b2 == vec![vec![35, 75]]);
    assert!(rows.iter().all(|&(_, _, gr, e)| (gr - e).abs() < 1e-9));
    assert!(measurable(&m, &g) == "yes" && measurable(&rain, &g) == "no" && integral(&flat, g[1]) != integral(&rain, g[1]));
    assert!(ok == g.len() && fm == 2);
    println!("ALL CHECKS PASS");
}
