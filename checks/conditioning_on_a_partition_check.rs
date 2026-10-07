// Conditioning on a partition -- the same check as the Python, in Rust, std
// only.  Twelve months, equally likely, each with its average rainfall in mm at
// one station.  The information is a partition of the months into cells.  The
// forecast from it is built by three roads that share no arithmetic: the
// within-cell average in exact fractions (a small rational type written here),
// a least-squares search over every cell-constant forecast on a grid, and a
// simulation driven by a SplitMix64 generator written out below.  The code
// checks finite cases exactly; the statements in general are the proof's.
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, Debug, PartialEq)]
struct Q { n: i64, d: i64 }                   // a fraction n/d in lowest terms, d > 0
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
fn z(n: i64) -> Q { q(n, 1) }
fn less(a: Q, b: Q) -> bool { a.n * b.d < b.n * a.d }

const MONTHS: [&str; 12] = ["Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov"];
const RAIN: [i64; 12] = [20, 30, 40, 45, 60, 75, 80, 100, 90, 55, 40, 25];

fn integral(f: &[Q], a: &[usize], p: &[Q]) -> Q {       // E[f 1_A]: the integral of f over the set A
    a.iter().fold(z(0), |s, &i| s + p[i] * f[i])
}

fn cond(x: &[Q], cells: &[Vec<usize>], p: &[Q], null_value: i64) -> Vec<Q> { // road one: E[X 1_B] / P(B)
    let mut y = vec![z(0); x.len()];
    for b in cells {
        let pb = b.iter().fold(z(0), |s, &i| s + p[i]);
        let c = if pb.n > 0 { integral(x, b, p) / pb } else { z(null_value) };
        for &i in b { y[i] = c; }
    }
    y
}

fn least_squares(x: &[Q], cells: &[Vec<usize>], p: &[Q]) -> Vec<Q> { // road two: least squared error
    let mut y = vec![z(0); x.len()];
    for b in cells {
        let err = |c: i64| b.iter().fold(z(0), |s, &i| s + p[i] * (x[i] - z(c)) * (x[i] - z(c)));
        let mut best = 0;
        for c in 1..=120 { if less(err(c), err(best)) { best = c; } }
        for &i in b { y[i] = z(best); }
    }
    y
}

fn unions(cells: &[Vec<usize>]) -> Vec<Vec<usize>> {    // sigma(partition): every union of whole cells
    (0..1usize << cells.len()).map(|m| {
        let mut a: Vec<usize> = cells.iter().enumerate().filter(|(k, _)| m >> k & 1 == 1)
            .flat_map(|(_, b)| b.iter().copied()).collect();
        a.sort();
        a
    }).collect()
}

fn dec(v: Q) -> String {                                // whole number, or rounded to 2 places
    if v.d == 1 { return v.n.to_string(); }
    let r = (200 * v.n + v.d) / (2 * v.d);
    format!("{}.{:02}", r / 100, r % 100)
}

fn splitmix64(state: u64) -> (u64, u64) {              // one step of SplitMix64
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut x = s;
    x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, x ^ (x >> 31))
}

fn fig(mm: i64) -> String { format!("{}.{}", (2100 - 15 * mm) / 10, (2100 - 15 * mm) % 10) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: &[Q]) -> String { v.iter().map(|&x| dec(x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let x: Vec<Q> = RAIN.iter().map(|&r| z(r)).collect();
    let p = vec![q(1, 12); 12];
    let all: Vec<usize> = (0..12).collect();
    let partitions: Vec<(&str, Vec<Vec<usize>>)> = vec![
        ("nothing known", vec![all.clone()]),
        ("half-year", vec![vec![9, 10, 11, 0, 1, 2], vec![3, 4, 5, 6, 7, 8]]),
        ("season", vec![vec![0, 1, 2], vec![3, 4, 5], vec![6, 7, 8], vec![9, 10, 11]]),
        ("month", (0..12).map(|i| vec![i]).collect()),
    ];
    let ms: Vec<String> = MONTHS.iter().zip(RAIN.iter()).map(|(m, r)| format!("{} {}", m, r)).collect();
    println!("month rainfall, mm: {}", ms.join(", "));
    println!("plain mean E[X] = {} mm", dec(integral(&x, &all, &p)));
    let mut results = vec![];
    for (name, cells) in &partitions {
        let (y1, y2) = (cond(&x, cells, &p, 0), least_squares(&x, cells, &p));
        let g = unions(cells);
        let matched = g.iter().all(|a| integral(&y1, a, &p) == integral(&x, a, &p));
        let levels_in_g = y1.iter().all(|&v| g.contains(&(0..12).filter(|&i| y1[i] == v).collect::<Vec<usize>>()));
        let sq: Vec<Q> = (0..12).map(|i| (x[i] - y1[i]) * (x[i] - y1[i])).collect();
        let mse = integral(&sq, &all, &p);
        println!("{}: cells {}, sets in sigma {}; forecast by month: {}", name, cells.len(), g.len(), join(&y1));
        println!("  least squares agrees: {}; constant on cells: {}; integrals match on all {} sets: {}; mean squared error {}",
                 yn(y1 == y2), yn(levels_in_g), g.len(), yn(matched), dec(mse));
        let mut h = g.clone(); h.sort(); h.dedup();          // distinct sets in sigma
        results.push((y1.clone(), y1 == y2, h.len(), matched && levels_in_g, mse));
    }
    let season = results[2].0.clone();
    let cells = partitions[2].1.clone();
    let rows: Vec<String> = ["winter", "spring", "summer", "autumn"].iter().zip(cells.iter()).map(|(n, b)|
        format!("{} P = {}, E[X 1_B] = {}, average {}", n, dec(b.iter().fold(z(0), |s, &i| s + p[i])),
                dec(integral(&x, b, &p)), dec(season[b[0]]))).collect();
    println!("season cells: {}", rows.join("; "));
    println!("average of the season forecast: {} mm", dec(integral(&season, &all, &p)));
    let mean = integral(&x, &all, &p);
    let dev: Vec<Q> = season.iter().map(|&v| (v - mean) * (v - mean)).collect();
    let var_y = integral(&dev, &all, &p);
    println!("spread of the season forecast E[(Y - 55)^2] = {}; plus its error {} = {}", dec(var_y), dec(results[2].4), dec(var_y + results[2].4));
    let warm: Vec<usize> = cells[1].iter().chain(cells[2].iter()).copied().collect();
    println!("spring or summer, a set in sigma(season): E[Y 1_A] = {}, E[X 1_A] = {}",
             dec(integral(&season, &warm, &p)), dec(integral(&x, &warm, &p)));
    // road three: simulate months, average the rainfall inside each season
    let (seed, n) = (20260929u64, 120000);
    let mut state = seed;
    let (mut count, mut total, mut square) = ([0i64; 4], [0i64; 4], [0i64; 4]);
    for _ in 0..n {
        let (s, zz) = splitmix64(state);
        state = s;
        let m = (zz % 12) as usize;
        let k = m / 3;
        count[k] += 1;
        total[k] += RAIN[m];
        square[k] += RAIN[m] * RAIN[m];
    }
    let sim: Vec<f64> = (0..4).map(|k| total[k] as f64 / count[k] as f64).collect();
    let se: Vec<f64> = (0..4).map(|k| ((square[k] as f64 / count[k] as f64 - sim[k] * sim[k]) / count[k] as f64).sqrt()).collect();
    println!("simulation, seed {}, {} draws: counts {:?}; season averages {}; standard errors {}", seed, n, count,
             sim.iter().map(|s| format!("{:.2}", s)).collect::<Vec<_>>().join(", "),
             se.iter().map(|s| format!("{:.3}", s)).collect::<Vec<_>>().join(", "));
    // what breaks
    let summer = &cells[2];
    println!("mistake 1, forecast taken as the number 55: on summer E[55 1_B] = {}, E[X 1_B] = {}",
             dec(integral(&vec![z(55); 12], summer, &p)), dec(integral(&x, summer, &p)));
    let raw: Vec<Q> = cells.iter().map(|b| integral(&x, b, &p)).collect();
    println!("mistake 2, no division by P(B): 'forecasts' {}", join(&raw));
    let jul = vec![7usize];
    println!("mistake 3, matching asked on July alone, not in sigma(season): E[Y 1_A] = {}, E[X 1_A] = {}",
             dec(integral(&season, &jul, &p)), dec(integral(&x, &jul, &p)));
    let mut x13 = x.clone(); x13.push(z(500));                 // a 13th outcome: a test record with probability 0
    let mut p13 = p.clone(); p13.push(z(0));
    let mut cells13 = cells.clone(); cells13.push(vec![12]);
    let (v0, v999) = (cond(&x13, &cells13, &p13, 0), cond(&x13, &cells13, &p13, 999));
    let both = unions(&cells13).iter().all(|a| [&v0, &v999].iter().all(|v| integral(v, a, &p13) == integral(&x13, a, &p13)));
    println!("mistake 4, a cell of probability 0 holding a {} mm test record: versions give it {} and {}; both match on all 32 sets: {}",
             dec(x13[12]), dec(v0[12]), dec(v999[12]), yn(both));
    let partial: Vec<Q> = [10u32, 20, 40].iter().map(|&t| (1..=t).fold(z(0), |s, j| s + q(1, 1i64 << j) * z(1i64 << j))).collect();
    println!("mistake 5, X = 2^n with chance 2^-n on one cell: E[X 1_B] after 10, 20, 40 terms = {}", join(&partial));
    let bars: Vec<String> = MONTHS.iter().zip(RAIN.iter()).map(|(m, &r)| format!("{} {}", m, fig(r))).collect();
    let lines: Vec<String> = cells.iter().map(|b| fig(season[b[0]].n)).collect();
    println!("figure, 1.5 units per mm, baseline y 210, bar tops: {}; season lines y {}; mean line y {}",
             bars.join(", "), lines.join(", "), fig(55));
    assert!(results.iter().all(|r| r.1));                               // two roads to every forecast
    assert!(results.iter().all(|r| r.3));                               // the defining property on all of sigma
    assert_eq!(results.iter().map(|r| r.2).collect::<Vec<_>>(), vec![2, 4, 16, 4096]);
    assert!(integral(&season, &all, &p) == q(RAIN.iter().sum(), 12));
    assert!((0..4).all(|k| (sim[k] - season[3 * k].n as f64).abs() < 4.0 * se[k]));
    assert!(integral(&season, &jul, &p) != integral(&x, &jul, &p));      // outside sigma, no match
    assert!(both);                                                      // versions differ only where P is 0
    let summer13 = vec![cells[0].clone(), cells[1].clone(), [cells[2].clone(), vec![12]].concat(), cells[3].clone()];
    assert!(cond(&x13, &summer13, &p13, 0)[12] == z(90));                // a null record leaves summer at 90
    assert!(var_y + results[2].4 == results[0].4);                     // between plus within = total spread
    assert_eq!(results.iter().map(|r| r.4).collect::<Vec<_>>(), vec![q(1900, 3), q(700, 3), q(325, 3), z(0)]);
    println!("ALL CHECKS PASS");
}
