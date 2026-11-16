// Convergence in energy -- the same check as the Python, in Rust.  No crates.
// Two signals on one cycle of phase x in [-pi, pi):
//   the house siren, a +-1 V square wave (220 cycles a second), whose
//   coefficients are 2/(i pi n) on odd n;
//   the list 1/n, as cosine amounts in volts, which Riesz-Fischer turns into
//   a signal; the card identifies it as f(x) = -log(2 sin(|x|/2)).
// Every energy is (1/2pi) times the integral of the square over one cycle.
// Roads: the coefficient ledger (sums of |c_n|^2), Simpson's rule on the
// signal itself, and integral bounds on the tails.
use std::f64::consts::PI;

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = g(a) + g(b);
    for k in 1..m {
        s += if k % 2 == 1 { 4.0 } else { 2.0 } * g(a + k as f64 * h);
    }
    s * h / 3.0
}

fn siren(x: f64) -> f64 {                        // the square wave: +1 V on (0, pi), -1 V on (-pi, 0)
    if x > 0.0 { 1.0 } else { -1.0 }
}

fn siren_sum(n: usize, x: f64) -> f64 {          // S_N of the square wave, odd k <= N
    4.0 / PI * (1..=n).step_by(2).map(|k| (k as f64 * x).sin() / k as f64).sum::<f64>()
}

fn siren_gap_ledger(n: usize) -> f64 {           // 1 - energies of harmonics |n| <= N
    1.0 - 8.0 / (PI * PI) * (1..=n).step_by(2).map(|k| 1.0 / (k * k) as f64).sum::<f64>()
}

fn siren_gap_direct(n: usize) -> f64 {           // (1/2pi) int (f - S_N)^2, by symmetry
    simpson(&|x| (1.0 - siren_sum(n, x)).powi(2), 0.0, PI, 4000) / PI
}

fn log_signal(x: f64) -> f64 {                   // the signal the list 1/n builds
    -(2.0 * (x.abs() / 2.0).sin()).ln()
}

fn log_sum(n: usize, x: f64) -> f64 {            // P_N: cosines with amounts 1/n, n <= N
    (1..=n).map(|k| (k as f64 * x).cos() / k as f64).sum()
}

fn cycle_mean(g: &dyn Fn(f64) -> f64) -> f64 {   // (1/pi) int_0^pi g dx for an even g;
    // x = pi u^3 tames the spike at x = 0, where the integrand tends to 0
    simpson(&|u: f64| if u == 0.0 { 0.0 } else { 3.0 * u * u * g(PI * u.powi(3)) }, 0.0, 1.0, 4000)
}

fn tail(n: usize, m: usize) -> f64 {             // (1/2) sum 1/n^2 for N < n <= M
    0.5 * (n + 1..=m).map(|k| 1.0 / (k as f64 * k as f64)).sum::<f64>()
}

fn f6(v: f64) -> String { format!("{:.6}", v) }

fn main() {
    println!("== the siren: +-1 V square wave, 220 cycles a second ==");
    println!("switches per second {}; odd harmonics at {}, {}, {} Hz and up", 2 * 220, 220, 3 * 220, 5 * 220);
    let int_sq = simpson(&|x| siren(x).powi(2), -PI, PI, 4000); // int f^2 over a cycle, by Simpson
    println!("energy (1/2pi) int f^2 = {} V^2; harmonic pair +-n holds 8/(pi^2 n^2)", f6(int_sq / (2.0 * PI)));
    println!("N | gap by ledger | gap by Simpson | lower 4/(pi^2 (N+2)) | upper 4/(pi^2 N)");
    for n in [1usize, 3, 9, 99] {
        let (led, direct) = (siren_gap_ledger(n), siren_gap_direct(n));
        let (lo, hi) = (4.0 / (PI * PI * (n + 2) as f64), 4.0 / (PI * PI * n as f64));
        println!("{} | {} | {} | {} | {}", n, f6(led), f6(direct), f6(lo), f6(hi));
        assert!((led - direct).abs() < 1e-8);                  // ledger = signal
        assert!(lo < led && led < hi);                        // tail bounds hold
    }
    let (p1, p3) = (8.0 / (PI * PI), 8.0 / (9.0 * PI * PI));
    println!("worked N = 3: pair 1 = {}, pair 3 = {}, kept = {}, gap = {} V^2", f6(p1), f6(p3), f6(p1 + p3), f6(1.0 - p1 - p3));
    println!("CD copy keeps odd harmonics up to 99: {} Hz <= 22050 Hz < {} Hz", 99 * 220, 101 * 220);
    println!("CD copy misses {:.4} % of the siren's energy", 100.0 * siren_gap_ledger(99));
    let odd: f64 = (1..1000usize).step_by(2).map(|k| 1.0 / (k * k) as f64).sum();
    println!("Parseval on the siren: sum of 1/n^2 over odd n <= 999 = {}, tail between {} and {}",
             f6(odd), f6(1.0 / 2002.0), f6(1.0 / 1998.0));
    let p8 = PI * PI / 8.0;
    println!("pi^2/8 = {:.9} lies between {:.9} and {:.9}", p8, odd + 1.0 / 2002.0, odd + 1.0 / 1998.0);
    assert!(odd + 1.0 / 2002.0 < p8 && p8 < odd + 1.0 / 1998.0);
    println!("chart, N | rms gap sqrt(gap) V | overshoot S_N(pi/(N+1)) - 1 V");
    for n in [1usize, 3, 5, 9, 19, 49, 99, 199] {
        let over = siren_sum(n, PI / (n + 1) as f64) - 1.0;
        println!("chart, {} | {:.3} | {:.3}", n, siren_gap_ledger(n).sqrt(), over);
    }
    let peak = siren_sum(999, PI / 1000.0) - 1.0;
    println!("overshoot at N = 999: {} V; it does not go to 0", f6(peak));
    assert!(peak > 0.178);

    println!("== Riesz-Fischer: the list of cosine amounts 1/n V ==");
    let energy_list = PI * PI / 12.0;
    let part = 0.5 * (1..=100000usize).map(|k| 1.0 / (k as f64 * k as f64)).sum::<f64>();
    println!("list energy: (1/2) sum 1/n^2 = pi^2/12 = {} V^2", f6(energy_list));
    println!("list energy summed to n = 100000: {}, tail below {}", f6(part), f6(0.5 / 100000.0));
    let energy_sig = cycle_mean(&|x| log_signal(x).powi(2));
    println!("signal energy by Simpson, -log(2 sin(|x|/2)) squared: {} V^2", f6(energy_sig));
    assert!((energy_sig - energy_list).abs() < 1e-6);         // Parseval, both sides
    assert!(0.0 < energy_list - part && energy_list - part < 0.5 / 100000.0);
    for (n, m) in [(10usize, 100usize), (100, 1000), (1000, 10000)] {
        let g = tail(n, m);
        println!("Cauchy gap ||P_{} - P_{}||^2 = {} <= 1/(2N) = {}", m, n, f6(g), f6(0.5 / n as f64));
        assert!(g < 0.5 / n as f64);
    }
    println!("n | coefficient of the signal by Simpson | list value 1/(2n)");
    for n in [1usize, 2, 3, 10] {
        let c = cycle_mean(&|x| log_signal(x) * (n as f64 * x).cos());
        println!("{} | {} | {}", n, f6(c), f6(1.0 / (2 * n) as f64));
        assert!((c - 1.0 / (2 * n) as f64).abs() < 1e-6);     // rebuilt signal has the list
    }
    println!("N | gap ||f - P_N||^2 by Simpson | by the list's tail");
    for n in [1usize, 3, 10] {
        let direct = cycle_mean(&|x| (log_signal(x) - log_sum(n, x)).powi(2));
        let led = energy_list - 0.5 * (1..=n).map(|k| 1.0 / (k * k) as f64).sum::<f64>();
        println!("{} | {} | {}", n, f6(direct), f6(led));
        assert!((direct - led).abs() < 1e-6);
    }
    println!("at x = pi/2: f = {} V, P_1000 = {} V", f6(log_signal(PI / 2.0)), f6(log_sum(1000, PI / 2.0)));
    for n in [10usize, 1000] {
        println!("at x = 0: P_{}(0) = sum of 1/n = {} V, still rising", n, f6(log_sum(n, 0.0)));
    }
    let bars: Vec<String> = (1..=5).map(|k| f6(0.5 / (k * k) as f64)).collect();
    println!("bars, energy of harmonic n = 1/(2n^2): {}", bars.join(", "));

    println!("== what breaks ==");
    for n in [1000usize, 1000000] {
        let h = 0.5 * (1..=n).map(|k| 1.0 / k as f64).sum::<f64>();
        println!("list 1/sqrt(n): energy of P_{} = {} V^2, no limit", n, f6(h));
    }
    let half = 4.0 / (PI * PI) * (1..1000000usize).step_by(2).map(|k| 1.0 / (k as f64 * k as f64)).sum::<f64>();
    let full = 2.0 * half;                                    // the ledger over both signs of n
    assert!((int_sq / (2.0 * PI) - full).abs() < 1e-6);       // Parseval on the siren, both sides
    println!("no 1/2pi: int f^2 over a cycle = {} against sum |c_n|^2 = {}", f6(int_sq), f6(full));
    println!("positive n only: sum |c_n|^2 = {} against {}", f6(half), f6(full));
    println!("judged by the largest error: N = 99 rms gap {} V, overshoot {} V",
             f6(siren_gap_ledger(99).sqrt()), f6(siren_sum(99, PI / 100.0) - 1.0));
    println!("ALL CHECKS PASS");
}
