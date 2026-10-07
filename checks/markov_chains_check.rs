// Markov chains -- the same check in Rust.  No crates.
// Weather, one step a day: 0 sunny, 1 cloudy, 2 rainy.  Every chance is held
// as whole tenths, so a path's weight is an exact integer over a power of 10.
// Three roads to the two-day chances: the matrix product; every path listed
// and summed; a seeded simulation (SplitMix64, seed 20260929).
const P: [[u64; 3]; 3] = [[6, 3, 1], [3, 4, 3], [2, 4, 4]]; // tenths: row = today, column = tomorrow
const SPELL: [u64; 3] = [1, 2, 7];     // memory weather: the row after two rainy days
const START: [u64; 3] = [5, 3, 2];     // a start law: today's forecast, in tenths
const L: [&str; 3] = ["S", "C", "R"];
const NAME: [&str; 3] = ["sunny", "cloudy", "rainy"];
const RUNS: usize = 100_000;
const DAYS: usize = 300_000;

fn dec(n: u64, places: usize) -> String {  // the exact decimal n / 10^places
    let s = format!("{:0>w$}", n, w = places + 1);
    format!("{}.{}", &s[..s.len() - places], &s[s.len() - places..])
}

struct Rng(u64);
impl Rng {
    fn digit(&mut self) -> usize {          // SplitMix64, cut down to one digit 0..9
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) % 10) as usize
    }
    fn draw(&mut self, row: &[u64; 3]) -> usize { // the digit falls in one entry's slice of 0..9
        let (d, mut edge) = (self.digit() as u64, 0);
        for j in 0..3 {
            edge += row[j];
            if d < edge { return j }
        }
        panic!("row does not cover 0..9")
    }
}

fn row_for(memory: bool, yesterday: usize, today: usize) -> &'static [u64; 3] {
    if memory && yesterday == 2 && today == 2 { &SPELL } else { &P[today] }
}

fn weight(path: &[usize], memory: bool) -> u64 { // start law times one row entry per day
    let mut w = START[path[0]];
    for k in 1..path.len() {
        let y = if k > 1 { path[k - 2] } else { 9 };
        w *= row_for(memory, y, path[k - 1])[path[k]];
    }
    w
}

fn breaks(memory: bool) -> usize {        // 3-day histories whose next-day chances differ from today's row
    let mut bad = 0;
    for a in 0..3 { for b in 0..3 { for c in 0..3 {
        let ws: Vec<u64> = (0..3).map(|j| weight(&[a, b, c, j], memory)).collect();
        let sum: u64 = ws.iter().sum();
        if (0..3).any(|j| 10 * ws[j] != sum * P[c][j]) { bad += 1 }
    }}}
    bad
}

fn triples(rng: &mut Rng, memory: bool) -> [[[u64; 3]; 3]; 3] { // one long path: (yesterday, today, tomorrow)
    let (mut c, mut y, mut t) = ([[[0u64; 3]; 3]; 3], 0, 0);
    for _ in 0..DAYS {
        let n = rng.draw(row_for(memory, y, t));
        c[y][t][n] += 1;
        y = t;
        t = n;
    }
    c
}

fn cond(c: &[[[u64; 3]; 3]; 3], y: usize, t: usize, j: usize) -> (f64, f64) {
    let n = c[y][t].iter().sum::<u64>() as f64;
    let f = c[y][t][j] as f64 / n;
    (f, (f * (1.0 - f) / n).sqrt())
}

fn main() {
    let mut p2 = [[0u64; 3]; 3];                          // road 1: the matrix product, in hundredths
    for i in 0..3 { for j in 0..3 { p2[i][j] = (0..3).map(|k| P[i][k] * P[k][j]).sum() } }
    let (mut total, mut pair) = (0u64, [[0u64; 3]; 3]);   // road 2: all 81 four-day paths
    for a in 0..3 { for b in 0..3 { for c in 0..3 { for d in 0..3 {
        let w = weight(&[a, b, c, d], false);
        total += w;
        pair[a][c] += w;
    }}}}
    let routes: Vec<u64> = (0..3).map(|k| P[0][k] * P[k][2]).collect();
    let week = [0, 0, 1, 1, 2, 2, 0];
    let wk: u64 = week.windows(2).map(|w| P[w[0]][w[1]]).product();
    let mut rng = Rng(20260929);                          // road 3: simulate
    let (mut x, mut fortnight) = (0, String::from("S"));
    for _ in 0..13 {
        x = rng.draw(&P[x]);
        fortnight += &format!(" {}", L[x]);
    }
    let mut end = [0u64; 3];
    for _ in 0..RUNS {
        let first = rng.draw(&P[0]);
        end[rng.draw(&P[first])] += 1;
    }
    let chain = triples(&mut rng, false);
    let mem = triples(&mut rng, true);
    let r = RUNS as f64;

    println!("states: S sunny, C cloudy, R rainy; one step is one day");
    for i in 0..3 {
        let row: Vec<String> = P[i].iter().map(|&v| dec(v, 1)).collect();
        println!("P    row {}: {}   (row sum {})", L[i], row.join(" "), dec(P[i].iter().sum(), 1));
    }
    for i in 0..3 {
        let row: Vec<String> = p2[i].iter().map(|&v| dec(v, 2)).collect();
        println!("P^2  row {}: {}", L[i], row.join(" "));
    }
    let parts: Vec<String> = (0..3).map(|k| format!("S {} R {}", L[k], dec(routes[k], 2))).collect();
    println!("sunny to rainy in two days: {} = {}", parts.join(" + "), dec(routes.iter().sum(), 2));
    let st: Vec<String> = START.iter().map(|&v| dec(v, 1)).collect();
    println!("81 four-day paths from start law {}: weights sum to {}", st.join(" "), dec(total, 4));
    println!("P(today i, day after tomorrow j) / P(today i), from the path list:");
    for i in 0..3 {
        let row: Vec<String> = (0..3).map(|j| dec(pair[i][j] / (10 * START[i]), 2)).collect();
        println!("  from {}: {}", L[i], row.join(" "));
    }
    println!("chain: 3-day histories whose next day differs from today's row: {} of 27", breaks(false));
    println!("week S S C C R R S from a sunny Monday: {}, about 1 in {}", dec(wk, 6), (1e6 / wk as f64).round());
    println!("one sample fortnight from sunny: {}", fortnight);
    let se: Vec<f64> = end.iter().map(|&e| (e as f64 / r * (1.0 - e as f64 / r) / r).sqrt()).collect();
    let sim: Vec<String> = (0..3).map(|j| format!("{} {:.4} +- {:.4}", NAME[j], end[j] as f64 / r, se[j])).collect();
    println!("simulated day-2 law from sunny, {} runs: {}", RUNS, sim.join(", "));
    println!("chain, {}-day path, P(rainy tomorrow | cloudy today, yesterday y):", DAYS);
    for y in 0..3 {
        let (f, s) = cond(&chain, y, 1, 2);
        println!("  y = {}: {:.4} +- {:.4}   (row entry {})", NAME[y], f, s, dec(P[1][2], 1));
    }
    println!("memory weather, {}-day path, P(rainy tomorrow | rainy today, yesterday y):", DAYS);
    for y in 0..3 {
        let (f, s) = cond(&mem, y, 2, 2);
        println!("  y = {}: {:.4} +- {:.4}   (rule {})", NAME[y], f, s, dec(row_for(true, y, 2)[2], 1));
    }
    println!("memory weather: 3-day histories whose next day differs from today's row: {} of 27", breaks(true));
    println!("mistake, one-day entry for two days: {}, not {}", dec(P[0][2], 1), dec(p2[0][2], 2));
    println!("mistake, squaring the entry: {}, not {}", dec(P[0][2] * P[0][2], 2), dec(p2[0][2], 2));
    println!("mistake, days taken as independent: P(S then S | S) = {} x {} = {}, not {}",
             dec(P[0][0], 1), dec(p2[0][0], 2), dec(P[0][0] * p2[0][0], 3), dec(P[0][0] * P[0][0], 2));
    let cols: Vec<String> = (0..3).map(|j| dec((0..3).map(|i| P[i][j]).sum(), 1)).collect();
    println!("mistake, reading columns as rows: column sums {}", cols.join(" "));
    println!("figure, nodes S (85,175) C (180,85) R (275,175), radius 26");
    assert!((0..3).all(|i| (0..3).all(|j| pair[i][j] == START[i] * p2[i][j] * 10)));
    assert!(total == 10u64.pow(4) && breaks(false) == 0 && breaks(true) == 3);
    assert!((0..3).all(|j| (end[j] as f64 / r - p2[0][j] as f64 / 100.0).abs() < 4.0 * se[j]));
    assert!((0..3).all(|y| { let (f, s) = cond(&chain, y, 1, 2); (f - 0.3).abs() < 4.0 * s }));
    let ((f_rr, s_rr), (f_sr, s_sr)) = (cond(&mem, 2, 2, 2), cond(&mem, 0, 2, 2));
    assert!(f_rr - f_sr > 10.0 * (s_rr + s_sr));          // memory shows up in the data
    println!("ALL CHECKS PASS");
}
