// Inverse functions -- the same check as inverse_functions_check.py, in Rust.  No crates.  Celsius
// to Fahrenheit, F = 1.8 x C + 32, is undone by C = (F - 32) / 1.8.  The 24-hour clock read onto a
// 12-hour dial is not.  Two roads back: the undo rule, and a search of every input.
const CELSIUS: [f64; 4] = [-40.0, 0.0, 20.0, 100.0];
fn to_f(c: f64) -> f64 { 1.8 * c + 32.0 }                         // forwards: Celsius to Fahrenheit
fn to_c(f: f64) -> f64 { (f - 32.0) / 1.8 }                       // the undo: Fahrenheit to Celsius
fn dial(h: i64) -> i64 { if h % 12 == 0 { 12 } else { h % 12 } }  // forwards: 24-hour clock to dial
fn lands_on(inputs: &[i64], target: i64) -> Vec<i64> {            // the search road: who lands there
    inputs.iter().cloned().filter(|&x| dial(x) == target).collect()
}
fn fmt(x: f64) -> String { format!("{:.10}", x).trim_end_matches('0').trim_end_matches('.').to_string() }
fn join(xs: &[f64]) -> String { xs.iter().map(|&x| fmt(x)).collect::<Vec<String>>().join(", ") }
fn main() {
    let hours: Vec<i64> = (0..24).collect();
    let fahr: Vec<f64> = CELSIUS.iter().map(|&c| to_f(c)).collect();
    let home: Vec<f64> = fahr.iter().map(|&f| to_c(f)).collect();
    let back = CELSIUS.iter().zip(&home).filter(|(c, h)| (*c - *h).abs() < 1e-9).count();
    let found: Vec<i64> = (-50..=100).filter(|&c| to_f(c as f64) == to_f(20.0)).collect();
    let mut readings: Vec<i64> = hours.iter().map(|&h| dial(h)).collect();
    readings.sort_unstable();
    readings.dedup();
    let (one, morning) = (lands_on(&hours, 1), lands_on(&(0..12).collect::<Vec<i64>>(), 1));
    let per: Vec<usize> = readings.iter().map(|&d| lands_on(&hours, d).len()).collect();
    println!("the rule: F = 1.8 x C + 32, so 20 C -> {} F", fmt(to_f(20.0)));
    println!("the undo: C = (F - 32) / 1.8, so 68 F -> {} C", fmt(to_c(68.0)));
    println!("round trip, {} C -> {} F -> {} C -- {} of {} home", join(&CELSIUS), join(&fahr), join(&home), back, CELSIUS.len());
    println!("search road, whole degrees -50 to 100 C landing on 68 F: {} -- {} input", found.iter().map(|c| c.to_string()).collect::<Vec<String>>().join(", "), found.len());
    println!("the one temperature both scales share: 1.8 x -40 + 32 = {}", fmt(to_f(-40.0)));
    println!("the clock: {} hours onto {} dial readings, readings reached {} of 12", hours.len(), readings.len(), readings.len());
    println!("hours landing on dial 1: 01:00 and 13:00 -- {} inputs, so no undo", one.len());
    println!("hours behind each reading: {} -- {} in total", per.iter().map(|p| p.to_string()).collect::<Vec<String>>().join(" "), per.iter().sum::<usize>());
    println!("cut the day at noon, 00:00 to 11:00: hours landing on dial 1 = {}, so the undo exists", morning.len());
    println!("undone in the wrong order, 68 / 1.8 - 32 = {:.4}; only the +32 undone, 68 - 32 = {}", 68.0 / 1.8 - 32.0, 68 - 32);
    assert!(fahr == [-40.0, 32.0, 68.0, 212.0] && to_f(-40.0) == -40.0 && back == 4);
    assert!(found == [20] && found.len() == 1 && fmt(to_c(68.0)) == "20");
    assert!(one == [1, 13] && readings == (1..=12).collect::<Vec<i64>>() && dial(12) == 12 && dial(13) == 1);
    assert!(per == [2; 12] && per.iter().sum::<usize>() == 24 && morning.len() == 1
        && readings.iter().all(|&d| lands_on(&(0..12).collect::<Vec<i64>>(), d).len() == 1));
    println!("ALL CHECKS PASS");
}
