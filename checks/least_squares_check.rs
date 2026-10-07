// Least squares -- the same check as the Python, in Rust.  No crates.  Four used
// cars: ages 1, 2, 3, 4 years and prices $20k, $17k, $13k, $10k.  Two roads to the
// same line: the normal equations A^T A x = A^T b, built and solved here by hand,
// and the slope-from-the-means formula that statistics teaches instead.
const AGES: [f64; 4] = [1.0, 2.0, 3.0, 4.0];
const PRICES: [f64; 4] = [20.0, 17.0, 13.0, 10.0];
const LATER: [f64; 4] = [21.0, 18.0, 12.0, 9.0];        // a second lot, same ages
const MISSES: [f64; 4] = [-0.1, 0.3, -0.3, 0.1];        // the four misses, by hand

fn normal_equations(xs: &[f64], ys: &[f64]) -> (f64, f64, Vec<f64>) {
    let n = xs.len() as f64;                            // road 1: A^T A x = A^T b
    let sx: f64 = xs.iter().sum();
    let sy: f64 = ys.iter().sum();
    let sxx: f64 = xs.iter().map(|x| x * x).sum();      // ages column dotted with itself
    let sxy: f64 = xs.iter().zip(ys).map(|(x, y)| x * y).sum();   // ages with prices
    let det = sxx * n - sx * sx;                        // Cramer's rule, written out
    ((sxy * n - sx * sy) / det, (sxx * sy - sx * sxy) / det, vec![sxx, sx, n, sxy, sy])
}
fn from_means(xs: &[f64], ys: &[f64]) -> (f64, f64) {   // road 2: the statistics formula
    let mx: f64 = xs.iter().sum::<f64>() / xs.len() as f64;
    let my: f64 = ys.iter().sum::<f64>() / ys.len() as f64;
    let top: f64 = xs.iter().zip(ys).map(|(x, y)| (x - mx) * (y - my)).sum();
    let slope = top / xs.iter().map(|x| (x - mx) * (x - mx)).sum::<f64>();
    (slope, my - slope * mx)
}
fn squared_miss(xs: &[f64], ys: &[f64], m: f64, k: f64) -> f64 {   // the score
    xs.iter().zip(ys).map(|(x, y)| (y - (m * x + k)) * (y - (m * x + k))).sum()
}
fn row(name: &str, values: &[f64]) {
    let mut line = format!("{:<36}", name);
    for v in values { line.push_str(&format!("{:>8.2}", v)); }
    println!("{}", line);
}
fn one(name: &str, value: String) { println!("{:<36}{:>16}", name, value); }
fn main() {
    let (m1, k1, s) = normal_equations(&AGES, &PRICES);
    let (m2, k2) = from_means(&AGES, &PRICES);
    let fits: Vec<f64> = AGES.iter().map(|x| m1 * x + k1).collect();
    let left: Vec<f64> = PRICES.iter().zip(&fits).map(|(y, f)| y - f).collect();
    let dot_age: f64 = AGES.iter().zip(&left).map(|(x, r)| x * r).sum();
    let dot_one: f64 = left.iter().sum();
    let sse = squared_miss(&AGES, &PRICES, m1, k1);
    row("ages, in years", &AGES);
    row("prices, in $ thousands", &PRICES);
    row("A^T A, first row", &[s[0], s[1]]);
    row("A^T A, second row", &[s[1], s[2]]);
    row("A^T b", &[s[3], s[4]]);
    println!("road 1, the normal equations        slope {:>8.4}   intercept {:>8.4}", m1, k1);
    println!("road 2, from the two means          slope {:>8.4}   intercept {:>8.4}", m2, k2);
    row("fitted prices, in $ thousands", &fits);
    row("misses, price minus fitted price", &left);
    one("total squared miss", format!("{:.4}", sse));
    one("leftover dot ages column", format!("{:.12}", dot_age.abs()));
    one("leftover dot ones column", format!("{:.12}", dot_one.abs()));
    let (m0, mf) = (s[3] / s[0], (PRICES[3] - PRICES[0]) / (AGES[3] - AGES[0]));
    let sse0 = squared_miss(&AGES, &PRICES, m0, 0.0);            // wrong: no ones column
    let ssef = squared_miss(&AGES, &PRICES, mf, PRICES[0] - mf * AGES[0]);  // two cars only
    let plain_5: f64 = AGES.iter().zip(&PRICES).map(|(x, y)| y - (-5.0 * x + 27.5)).sum();
    let sse5 = squared_miss(&AGES, &PRICES, -5.0, 27.5);
    println!("wrong, no ones column: slope {:.4}, squared miss {:.4}", m0, sse0);
    println!("wrong, first and last car only: slope {:.4}, squared miss {:.4}", mf, ssef);
    println!("wrong, misses added not squared: fitted line {:.4}, the -5.0 line {:.4}, \
whose squared miss is {:.4}", dot_one.abs(), plain_5.abs(), sse5);
    let (m3, k3, _) = normal_equations(&AGES, &LATER);
    println!("second case, prices 21, 18, 12, 9: slope {:.4}, intercept {:.4}, \
squared miss {:.4}", m3, k3, squared_miss(&AGES, &LATER, m3, k3));
    assert!(s == vec![30.0, 10.0, 4.0, 133.0, 60.0]);
    assert!((m1 + 3.4).abs() < 1e-12 && (k1 - 23.5).abs() < 1e-12 && (sse - 0.2).abs() < 1e-12
        && left.iter().zip(&MISSES).all(|(r, t)| (r - t).abs() < 1e-12));
    assert!((m1 - m2).abs() < 1e-12 && (k1 - k2).abs() < 1e-12
        && dot_age.abs() < 1e-12 && dot_one.abs() < 1e-12);
    assert!(sse < ssef && ssef < sse5 && sse5 < sse0
        && (m3 + 4.2).abs() < 1e-12 && (k3 - 25.5).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
