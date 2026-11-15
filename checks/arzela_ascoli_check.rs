// Arzela-Ascoli -- the same check as the Python, in Rust.  No crates.
// Simulated archive: 100 weather stations x 200 days = 20,000 daily
// temperature curves f_k(t) = m_k + a_k cos(pi (t - 15) / 12), t in hours,
// mean m_k from 12 to 18 C, half-swing a_k from 3 to 6 C, stepped by two
// irrational numbers.  Check the two hypotheses, extract a subsequence by
// nested balls, name its limit; closed form, minute grid and off-peak readings agree.
use std::f64::consts::PI;

const N: usize = 20000;
const K: f64 = PI / 2.0; // shared slope bound, C per hour

fn frac(x: f64) -> f64 { x - x.floor() }

fn temp(p: &[(f64, f64)], k: usize, t: f64) -> f64 {
    p[k].0 + p[k].1 * (PI * (t - 15.0) / 12.0).cos()
}

fn formula_dist(p: &[(f64, f64)], j: usize, k: usize) -> f64 { // exact sup distance
    (p[j].0 - p[k].0).abs() + (p[j].1 - p[k].1).abs()
}

fn minute() -> Vec<f64> { (0..1441).map(|i| i as f64 / 60.0).collect() }

fn grid_dist(p: &[(f64, f64)], j: usize, k: usize) -> f64 { // one-minute grid
    minute().iter().map(|&t| (temp(p, j, t) - temp(p, k, t)).abs()).fold(0.0, f64::max)
}

fn offpeak(p: &[(f64, f64)], j: usize, k: usize, h: f64) -> f64 { // readings half a step off 03:00 and 15:00
    (0..(24.0 / h).round() as usize).map(|i| h / 2.0 + i as f64 * h).map(|t| (temp(p, j, t) - temp(p, k, t)).abs()).fold(0.0, f64::max)
}

fn fast(k: f64, t: f64) -> f64 { 15.0 + 5.0 * (2.0 * PI * k * t / 24.0).sin() }

fn chart(p: &[(f64, f64)], k: usize) -> String {
    (0..25).map(|h| format!("{:.1}", temp(p, k, h as f64))).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (al, be) = ((5f64.sqrt() - 1.0) / 2.0, 2f64.sqrt() - 1.0);
    let mut p = vec![(0.0, 0.0)];
    for k in 1..=N {
        let (x, y) = (k as f64 * al, k as f64 * be);
        p.push((12.0 + 6.0 * frac(x), 3.0 + 3.0 * frac(y)));
    }
    let mt = minute();
    for k in [2, 27] { println!("chart #{}: {}", k, chart(&p, k)); }

    // Hypothesis 1, pointwise bounded; hypothesis 2, equicontinuous
    let top = p[1..].iter().map(|q| q.0 + q.1).fold(f64::MIN, f64::max);
    let bottom = p[1..].iter().map(|q| q.0 - q.1).fold(f64::MAX, f64::min);
    let mut grid_top = f64::MIN;
    let mut steep: f64 = 0.0;
    for k in 1..=500 {
        for (i, &t) in mt.iter().enumerate() {
            grid_top = grid_top.max(temp(&p, k, t));
            if i < 1440 { steep = steep.max((temp(&p, k, t + 1.0 / 60.0) - temp(&p, k, t)).abs() * 60.0); }
        }
    }
    let top500 = p[1..501].iter().map(|q| q.0 + q.1).fold(f64::MIN, f64::max);
    assert!((grid_top - top500).abs() < 1e-12);
    assert!(top < 24.0);
    let steep_formula = p[1..501].iter().map(|q| q.1 * PI / 12.0).fold(0.0, f64::max);
    assert!(steep_formula - steep >= 0.0 && steep_formula - steep < 1e-4);
    assert!(steep_formula < K);
    println!("bounded: every curve between {:.3} and {:.3} C; minute grid, first 500: top {:.3}", bottom, top, grid_top);
    println!("equicontinuous, first 500: steepest minute step {:.4} C/h; formula a*pi/12 {:.4}; shared K = {:.4}", steep, steep_formula, K);
    println!("  so one delta serves every curve: for 1 C, delta = 1/K = {:.1} minutes", 60.0 / K);
    println!("  in Fahrenheit (F = 1.8 C + 32): ceiling {:.1} F, K = {:.4} F/h", 1.8 * 24.0 + 32.0, 1.8 * K);

    // Extraction: stage s keeps the fullest ball of radius r around one of the
    // first 30 kept curves, measured at readings every h hours, with K h <= r.
    let mut pool: Vec<usize> = (1..=N).collect();
    let (mut picks, mut centres, mut rows): (Vec<usize>, Vec<usize>, Vec<(f64, f64, f64)>) = (vec![], vec![], vec![]);
    for s in 0..6 {
        let (r, h) = (1.6 / 2f64.powi(s), 1.0 / 2f64.powi(s));
        let ts: Vec<f64> = (0..=(24.0 / h).round() as usize).map(|i| i as f64 * h).collect();
        let vals: Vec<Vec<f64>> = pool.iter().map(|&k| ts.iter().map(|&t| temp(&p, k, t)).collect()).collect();
        let mut best: (usize, Vec<usize>) = (0, vec![]);
        for ci in 0..30.min(pool.len()) {
            let ball: Vec<usize> = (0..pool.len())
                .filter(|&i| vals[i].iter().zip(&vals[ci]).all(|(x, y)| (x - y).abs() <= r))
                .map(|i| pool[i]).collect();
            if best.1.is_empty() || ball.len() > best.1.len() { best = (pool[ci], ball); }
        }
        let c = best.0;
        pool = best.1;
        let last = *picks.last().unwrap_or(&0);
        let pick = *pool.iter().find(|&&k| k > last).unwrap();
        picks.push(pick);
        centres.push(c);
        let hi: Vec<f64> = pool.iter().map(|&k| p[k].0 + p[k].1).collect();
        let lo: Vec<f64> = pool.iter().map(|&k| p[k].0 - p[k].1).collect();
        let range = |v: &Vec<f64>| v.iter().cloned().fold(f64::MIN, f64::max) - v.iter().cloned().fold(f64::MAX, f64::min);
        let diam = range(&hi).max(range(&lo)); // closed form
        let band = mt.iter().map(|&t| {
            let v: Vec<f64> = pool.iter().map(|&k| temp(&p, k, t)).collect();
            range(&v)
        }).fold(0.0, f64::max);
        let bound = 2.0 * r + K * h; // three pieces
        assert!((diam - band).abs() < 1e-9 && diam <= bound);
        rows.push((r, h, bound));
        println!("stage {}: r {:.2} C, readings every {} min, centre #{}, kept {}, pick #{}, widest pair {:.3} <= {:.3}",
            s + 1, r, 60.0 * h, c, pool.len(), pick, diam, bound);
    }
    let g = *centres.last().unwrap();
    let named = rows[5].0 + K * rows[5].1;
    println!("limit: within {:.4} C everywhere of curve #{}: {:.4} + {:.4} cos(pi (t - 15) / 12)", named, g, p[g].0, p[g].1);
    for (s, &k) in picks.iter().enumerate() {
        let (d, off) = (formula_dist(&p, k, g), offpeak(&p, k, g, rows[s].1));
        assert!((d - grid_dist(&p, k, g)).abs() < 1e-9 && off <= d && d <= off + K * rows[s].1 && d <= rows[s].2);
        println!("  pick #{}: mean {:.3}, half-swing {:.3}, distance to #{} {:.3} (allowed {:.3})", k, p[k].0, p[k].1, g, d, rows[s].2);
    }
    let (o1, d1) = (offpeak(&p, picks[0], g, 1.0), formula_dist(&p, picks[0], g));
    assert!(o1 < d1 && d1 <= o1 + K); // the readings alone fall short; K h covers it
    println!("readings moved half an hour off the peaks: #{} to #{} reads {:.4}, true {:.4} <= {:.4} + K = {:.4}",
        picks[0], g, o1, d1, o1, o1 + K);
    println!("chart limit #{}: {}", g, chart(&p, g));
    println!("centres in order: {:?} (not increasing: not a subsequence)", centres);
    println!("whole sequence: #{} to #{} distance {:.3} C", N - 1, N, formula_dist(&p, N - 1, N));

    // What breaks
    for n in [10, 100, 1000] {
        let x = 2f64.powf(-1.0 / n as f64);
        println!("x^n, n={}: inputs {:.6} apart, values {:.6} apart", n, 1.0 - x, 1.0 - x.powi(n));
    }
    let mut closest = f64::MAX;
    for j in 1..=20 {
        for k in j + 1..=20 {
            let diffs: Vec<f64> = mt[..1440].iter().map(|&t| fast(j as f64, t) - fast(k as f64, t)).collect();
            assert!((diffs.iter().map(|d| d * d).sum::<f64>() / 1440.0 - 25.0).abs() < 1e-9); // mean square 25
            closest = closest.min(diffs.iter().map(|d| d.abs()).fold(0.0, f64::max));
        }
    }
    assert!(closest >= 5.0);
    println!("fast sensor 15 + 5 sin(2 pi k t / 24), k = 1..20: closest pair at least {:.3} C apart", closest);
    println!("  delta for 1 C: k=1 {:.1} min, k=20 {:.1} min; slope at k=20 {:.2} C/h",
        60.0 * 24.0 / (10.0 * PI), 60.0 * 24.0 / (200.0 * PI), 10.0 * PI * 20.0 / 24.0);
    let at_read = (0..145).map(|i| (fast(144.0, i as f64 / 6.0) - 15.0).abs()).fold(0.0, f64::max);
    println!("k=144: off 15 C by {:.6} at every 10-min reading, by {:.6} at 00:02:30", at_read, (fast(144.0, 1.0 / 24.0) - 15.0).abs());
    println!("drift 0.5 C a day: any two days at least 0.5 C apart; day 200 reads {:.1} C high", 0.5 * 199.0);
    println!("ALL CHECKS PASS");
}
