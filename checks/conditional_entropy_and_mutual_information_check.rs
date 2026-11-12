// Conditional entropy and mutual information -- the same check as the Python,
// in Rust.  No crates.  X is this morning's barometer (falling, steady,
// rising), Y is rain tomorrow (rain, dry), over 100 synthetic mornings.
// Road 1: reading by reading.  Road 2: the chain rule on the joint table.
// Road 3: the direct sum over cells.  Road 4: 200,000 mornings drawn with
// SplitMix64, seed 2026, and counted.
type T = Vec<Vec<f64>>;
const READ: [&str; 3] = ["falling", "steady", "rising"];

fn h(ps: &[f64]) -> f64 {                          // entropy in bits of a list of chances
    -ps.iter().filter(|&&p| p > 0.0).fold(0.0, |a, &p| a + p * p.log2())
}

struct M { px: Vec<f64>, hx: f64, hy: f64, hxy: f64, hy_x: f64, hx_y: f64, direct: f64 }

fn measures(c: &T) -> M {                          // c: a table of counts or chances
    let n = c.iter().fold(0.0, |a, r| a + r.iter().sum::<f64>());
    let p: T = c.iter().map(|r| r.iter().map(|v| v / n).collect()).collect();
    let px: Vec<f64> = p.iter().map(|r| r.iter().sum()).collect();
    let py: Vec<f64> = (0..p[0].len()).map(|j| p.iter().fold(0.0, |a, r| a + r[j])).collect();
    let cells: Vec<f64> = p.iter().flatten().copied().collect();
    let (hx, hy, hxy) = (h(&px), h(&py), h(&cells));
    let mut hy_x = 0.0;
    let mut hx_y = 0.0;
    let mut direct = 0.0;
    for i in 0..p.len() {
        if px[i] > 0.0 {
            let row: Vec<f64> = p[i].iter().map(|v| v / px[i]).collect();
            hy_x += px[i] * h(&row);
        }
        for j in 0..py.len() {
            if p[i][j] > 0.0 { direct += p[i][j] * (p[i][j] / (px[i] * py[j])).log2(); }
        }
    }
    for j in 0..py.len() {
        if py[j] > 0.0 {
            let col: Vec<f64> = p.iter().map(|r| r[j] / py[j]).collect();
            hx_y += py[j] * h(&col);
        }
    }
    M { px, hx, hy, hxy, hy_x, hx_y, direct }
}

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}

fn draw(rng: &mut SplitMix64, p: &T, days: usize) -> T {   // count `days` mornings drawn from p
    let cells: Vec<f64> = p.iter().flatten().copied().collect();
    let mut out = vec![0.0; cells.len()];
    for _ in 0..days {
        let (mut u, mut k) = (rng.unif(), 0);
        while k < cells.len() - 1 && u >= cells[k] { u -= cells[k]; k += 1; }
        out[k] += 1.0;
    }
    vec![out[0..2].to_vec(), out[2..4].to_vec(), out[4..6].to_vec()]
}

fn radio(c: &T, keep: f64) -> T {                  // the reading as received over a noisy link
    let q = |x: usize, z: usize| if z == x { keep } else { (1.0 - keep) / 2.0 };
    (0..3).map(|z| (0..2).map(|y| (0..3).fold(0.0, |a, x| a + c[x][y] * q(x, z))).collect()).collect()
}

fn tab(rows: [[f64; 2]; 3]) -> T { rows.iter().map(|r| r.to_vec()).collect() }
fn info(m: &M) -> f64 { m.hy - m.hy_x }

fn main() {
    let counts = tab([[16.0, 9.0], [11.0, 34.0], [3.0, 27.0]]);   // rows: barometer; columns: rain, dry
    let m = measures(&counts);
    let per: Vec<f64> = counts.iter().map(|r| h(&[r[0] / (r[0] + r[1]), r[1] / (r[0] + r[1])])).collect();
    let i1 = m.hy - m.hy_x;                        // road 1: what the reading removes
    let i2 = m.hx + m.hy - m.hxy;                  // road 2: chain rule, overlap of the two
    let hx_y = m.hx_y;
    let i_sym = m.hx - hx_y;                       // the same overlap, seen from the barometer
    let mut rng = SplitMix64 { s: 2026 };
    let p: T = counts.iter().map(|r| r.iter().map(|v| v / 100.0).collect()).collect();
    let i4 = info(&measures(&draw(&mut rng, &p, 200000)));
    let py = [p[0][0] + p[1][0] + p[2][0], p[0][1] + p[1][1] + p[2][1]];
    let indep: T = (0..3).map(|i| (0..2).map(|j| m.px[i] * py[j]).collect()).collect();
    let short: Vec<f64> = (0..2000).map(|_| info(&measures(&draw(&mut rng, &indep, 20)))).collect();
    let bias = short.iter().sum::<f64>() / 2000.0;
    let se = (short.iter().fold(0.0, |a, s| a + (s - bias).powi(2)) / 1999.0 / 2000.0).sqrt();
    let (mut worst, mut raised) = (1.0_f64, 0);
    for _ in 0..10000 {                            // random 3-by-2 tables: does knowing ever hurt on average?
        let t: T = (0..3).map(|_| (0..2).map(|_| rng.unif()).collect()).collect();
        let mt = measures(&t);
        worst = worst.min(info(&mt));
        raised += t.iter().filter(|r| h(&[r[0] / (r[0] + r[1]), r[1] / (r[0] + r[1])]) > mt.hy).count();
    }
    let rad = info(&measures(&radio(&counts, 0.9)));

    println!("reading   days  rain  P(x)    P(x,rain)  P(rain|x)  H(Y|X=x)  P(x) x H(Y|X=x)");
    for i in 0..3 {
        let r = &counts[i];
        println!("{:<8}  {:>4}  {:>4}  {:.4}  {:.4}     {:.4}     {:.4}    {:.4}", READ[i], r[0] + r[1], r[0],
                 m.px[i], r[0] / 100.0, r[0] / (r[0] + r[1]), per[i], m.px[i] * per[i]);
    }
    let rows: Vec<(&str, f64)> = vec![
        ("H(Y)    rain tomorrow, nothing known", m.hy), ("H(X)    the barometer", m.hx),
        ("H(X,Y)  the pair", m.hxy), ("H(Y|X)  rain once the barometer is read", m.hy_x),
        ("H(X|Y)  barometer once the rain is known", hx_y), ("1 I = H(Y) - H(Y|X)", i1),
        ("2 I = H(X) + H(Y) - H(X,Y)", i2), ("3 I = sum P(x,y) log2 P(x,y)/(P(x)P(y))", m.direct),
        ("  I = H(X) - H(X|Y)", i_sym), ("4 I from 200,000 simulated mornings", i4),
        ("chain: H(X) + H(Y|X)", m.hx + m.hy_x), ("share of rain uncertainty removed", i1 / m.hy),
        ("I in nats (ln, not log2)", i1 * 2f64.ln()),
        ("wrong: H(X) + H(Y) taken as H(X,Y)", m.hx + m.hy), ("wrong: one reading, H(Y|X=falling)", per[0]),
        ("short record: mean I, useless barometer", bias), ("  standard error of that mean", se),
        ("  first-order bias 2/(2 x 20 x ln 2)", 2.0 / (40.0 * 2f64.ln())),
        ("random tables: smallest H(Y) - H(Y|X)", worst),
    ];
    for (name, v) in &rows { println!("{:<41} {:.4}", name, v); }
    println!("  single readings that raised H: {} of 30000", raised);
    println!("{:<41} {:.4}", "radio, 90% kept: I(Z;Y) received", rad);
    let t1 = info(&measures(&tab([[6.0, 14.0], [15.0, 35.0], [9.0, 21.0]])));
    let t2 = info(&measures(&tab([[30.0, 0.0], [0.0, 45.0], [0.0, 25.0]])));
    let t3 = info(&measures(&radio(&counts, 0.4)));
    println!("{:<41} {:.4}", "try: useless barometer, I", t1);
    println!("{:<41} {:.4}", "try: barometer settles rain, I", t2);
    println!("{:<41} {:.4}", "try: radio keeps only 40%, I(Z;Y)", t3);
    println!("bars: H(Y|X=x) {:.2} {:.2} {:.2}; H(Y) {:.2}; H(Y|X) {:.2}", per[0], per[1], per[2], m.hy, m.hy_x);
    let bar = |a: f64, b: f64| "█".repeat((20.0 * a + 0.5) as usize) + &"▒".repeat((20.0 * b + 0.5) as usize);
    println!("the pair, {:.4} bits, split two ways (█ first reading, ▒ what is left)", m.hxy);
    println!("barometer, then rain   {}   {:.4} + {:.4}", bar(m.hx, m.hy_x), m.hx, m.hy_x);
    println!("rain, then barometer   {}   {:.4} + {:.4}", bar(m.hy, hx_y), m.hy, hx_y);
    assert!((i1 - 0.143862).abs() < 1e-6);                         // pinned to the worked table
    assert!((i1 - i2).abs() < 1e-12 && (i1 - m.direct).abs() < 1e-12);  // three roads agree
    assert!((i_sym - i1).abs() < 1e-12);                           // symmetric: I(X;Y) = I(Y;X)
    assert!((hx_y - (m.hxy - m.hy)).abs() < 1e-12);                // chain rule, rain first
    assert!((i4 - i1).abs() < 0.005);                              // simulation within a few standard errors
    assert!(worst > -1e-12 && m.hy_x < m.hy);                       // conditioning never raises entropy on average
    assert!(per[0] > m.hy && raised > 0);                           // but one reading can
    assert!(bias > 0.03 && bias > 10.0 * se);                       // short records invent information
    assert!(rad < i1);                                             // the radio cannot add information
    assert!((rad - 0.099289).abs() < 1e-6);                        // pinned: Bayes through the radio, by hand
    println!("ALL CHECKS PASS");
}
