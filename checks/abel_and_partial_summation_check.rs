// Partial summation (Abel's identity) in both directions: prime count pi(x) <-> log sum theta(x).
// Roads: a direct sum over sieved primes; Abel's identity with its integral done exactly on the steps;
// Abel's identity with the integral done by a midpoint rule that knows nothing about where the steps are.
const X: usize = 1_000_000;

// theta(x) = pi(x) log x - integral_2^x pi(t)/t dt, integral exact: pi(t) = k on [p_k, p_k+1).
fn abel_theta(x: f64, ps: &[usize]) -> (f64, f64) {
    let mut integral = 0.0;
    for k in 1..ps.len() {
        integral += k as f64 * ((ps[k] as f64).ln() - (ps[k - 1] as f64).ln());
    }
    let n = ps.len() as f64;
    integral += n * (x.ln() - (ps[ps.len() - 1] as f64).ln());
    (n * x.ln() - integral, integral)
}

// pi(x) = theta(x)/log x + integral_2^x theta(t)/(t log^2 t) dt; on a step, antiderivative is -1/log t.
fn abel_pi(x: f64, ps: &[usize]) -> (f64, f64) {
    let (mut run, mut integral) = (0.0, 0.0);
    for k in 0..ps.len() {
        run += (ps[k] as f64).ln();
        let top = if k + 1 < ps.len() { ps[k + 1] as f64 } else { x };
        integral += run * (1.0 / (ps[k] as f64).ln() - 1.0 / top.ln());
    }
    (run / x.ln() + integral, integral)
}

fn midpoint(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = 0.0;
    for i in 0..m {
        s += g(a + (i as f64 + 0.5) * h);
    }
    h * s
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = 0.0;
    for i in 1..m {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h);
    }
    h / 3.0 * (g(a) + g(b) + s)
}

fn main() {
    let mut sieve = vec![true; X + 1];
    (sieve[0], sieve[1]) = (false, false);
    let mut i = 2;
    while i * i <= X {
        if sieve[i] {
            let mut j = i * i;
            while j <= X {
                sieve[j] = false;
                j += i;
            }
        }
        i += 1;
    }
    let primes: Vec<usize> = (0..=X).filter(|&n| sieve[n]).collect();
    let (mut pc, mut th) = (vec![0usize; X + 1], vec![0.0f64; X + 1]);
    let (mut c, mut s) = (0usize, 0.0f64);
    for n in 0..=X {
        if sieve[n] {
            c += 1;
            s += (n as f64).ln();
        }
        pc[n] = c;
        th[n] = s;
    }
    let np = primes.len() as f64;

    // ---- by hand: x = 10, primes 2, 3, 5, 7 ----
    let small = [2usize, 3, 5, 7];
    let (th10, i10) = abel_theta(10.0, &small);
    let (pi10, j10) = abel_pi(10.0, &small);
    println!("hand, x = 10, primes 2 3 5 7");
    let ends = [2usize, 3, 5, 7, 10];
    for k in 1..5 {
        let label = format!("hand, pi = {} on [{}, {}): {} log({}/{})", k, ends[k - 1], ends[k], k, ends[k], ends[k - 1]);
        println!("{:<36} {:10.4}", label, k as f64 * (ends[k] as f64 / ends[k - 1] as f64).ln());
    }
    println!("hand, pi(10) log 10                  {:10.4}", 4.0 * 10f64.ln());
    println!("hand, integral of pi(t)/t, 2 to 10   {:10.4}", i10);
    println!("hand, theta(10) by Abel              {:10.4}", th10);
    println!("hand, theta(10) = log 210            {:10.4}", 210f64.ln());
    println!("hand, theta(10)/log 10               {:10.4}", th10 / 10f64.ln());
    println!("hand, integral theta/(t log^2 t)     {:10.4}", j10);
    println!("hand, pi(10) by Abel                 {:10.4}", pi10);

    // ---- a million: count -> log sum ----
    let xf = X as f64;
    let l = xf.ln();
    let theta_direct = th[X];
    let (theta_abel, int1) = abel_theta(xf, &primes);
    let int1_mid = midpoint(&|u: f64| pc[u.exp() as usize] as f64, 2f64.ln(), l, 400_000);
    println!();
    println!("pi(1000000) by sieve                 {:14}", primes.len());
    println!("1 theta, direct sum of log p         {:14.3}", theta_direct);
    println!("  log x                              {:14.4}", l);
    println!("  pi(x) log x                        {:14.3}", np * l);
    println!("  integral pi(t)/t, exact steps      {:14.3}", int1);
    println!("  integral pi(t)/t, midpoint rule    {:14.3}", int1_mid);
    println!("  area / x, the gap between ratios   {:14.4}", int1 / xf);
    println!("2 theta by Abel, exact steps         {:14.3}", theta_abel);
    println!("3 theta by Abel, midpoint rule       {:14.3}", np * l - int1_mid);
    // ---- a million: log sum -> count ----
    let (pi_abel, int2) = abel_pi(xf, &primes);
    let int2_mid = midpoint(&|u: f64| th[u.exp() as usize] / (u * u), 2f64.ln(), l, 400_000);
    println!("  theta(x)/log x                     {:14.3}", theta_direct / l);
    println!("  integral theta/(t log^2 t), steps  {:14.3}", int2);
    println!("  integral, midpoint rule            {:14.3}", int2_mid);
    println!("2 pi by Abel, exact steps            {:14.3}", pi_abel);
    println!("3 pi by Abel, midpoint rule          {:14.3}", theta_direct / l + int2_mid);
    // ---- where x/log x loses 7.8 percent: pi = x/log x + (theta - x)/log x + integral ----
    let li_off = simpson(&|u: f64| u.exp() / u, 2f64.ln(), l, 20_000);
    let sub = xf / l + simpson(&|u: f64| u.exp() / (u * u), 2f64.ln(), l, 20_000);
    println!("  x/log x                            {:14.3}", xf / l);
    println!("  (theta(x) - x)/log x               {:14.3}", (theta_direct - xf) / l);
    println!("  theta(t) = t put in: x/log x + int {:14.3}", sub);
    println!("  Li(x) by Simpson                   {:14.3}", li_off);
    println!("  Li(x) + 2/log 2                    {:14.3}", li_off + 2.0 / 2f64.ln());

    // ---- the two ratios at several sizes ----
    println!();
    println!("{:>9} {:>7} {:>12} {:>8} {:>10} {:>11}", "x", "pi(x)", "theta(x)", "theta/x", "x - theta", "pi log x/x");
    for &x in &[100usize, 1000, 10_000, 100_000, X] {
        let f = x as f64;
        println!("{:>9} {:>7} {:>12.3} {:>8.4} {:>10.3} {:>11.4}", x, pc[x], th[x], th[x] / f, f - th[x], pc[x] as f64 * f.ln() / f);
    }

    // ---- what breaks ----
    let half = pc[X / 2];
    let jump_true: usize = primes.iter().map(|&p| if p <= X / 2 { 1 } else { 2 }).sum();
    let jump_naive = 2 * primes.len();
    let jump_stieltjes = jump_naive - half;
    println!();
    println!("wrong: theta = pi(x) log x           {:14.3}", np * l);
    println!("  overshoot, percent of theta        {:14.3}", 100.0 * (np * l - theta_direct) / theta_direct);
    println!("wrong: integral added, not taken     {:14.3}", np * l + int1);
    println!("wrong: pi = theta(x)/log x           {:14.3}", theta_direct / l);
    println!("  shortfall, percent of pi(x)        {:14.3}", 100.0 * (np - theta_direct / l) / np);
    println!("  x/log x shortfall, percent         {:14.3}", 100.0 * (np - xf / l) / np);
    println!("jump weight: A(500000) = pi(500000)  {:14}", half);
    println!("jump weight: true sum                {:14}", jump_true);
    println!("jump weight: f' only, jump ignored   {:14}", jump_naive);
    println!("jump weight: jump term -A(500000)    {:14}", jump_stieltjes);
    // ---- try changing ----
    let recip_direct = primes.iter().fold(0.0, |acc, &p| acc + 1.0 / p as f64);
    let mut steps = 0.0;
    for k in 1..primes.len() {
        steps += k as f64 * (1.0 / primes[k - 1] as f64 - 1.0 / primes[k] as f64);
    }
    let recip_abel = np / xf + steps + np * (1.0 / primes[primes.len() - 1] as f64 - 1.0 / xf);
    println!("try: sum of 1/p, direct              {:14.6}", recip_direct);
    println!("try: sum of 1/p, Abel                {:14.6}", recip_abel);
    let coarse = midpoint(&|u: f64| pc[u.exp() as usize] as f64, 2f64.ln(), l, 4000);
    println!("try: theta by midpoint, 4000 steps  {:14.3}", np * l - coarse);

    assert!(primes.len() == 78498, "the published count of primes below a million");
    assert!((th10 - 210f64.ln()).abs() < 1e-12, "hand case: Abel equals the log of 2*3*5*7");
    assert!((theta_abel - theta_direct).abs() < 1e-6, "Abel with exact steps vs direct sum");
    assert!((np * l - int1_mid - theta_direct).abs() < 0.5, "Abel by blind midpoint rule vs direct sum");
    assert!((pi_abel - np).abs() < 1e-6, "reverse direction returns the sieve count");
    assert!((theta_direct / l + int2_mid - np).abs() < 0.5, "reverse, midpoint rule");
    assert!((sub - (li_off + 2.0 / 2f64.ln())).abs() < 1e-6, "theta = t gives Li(x) + 2/log 2");
    assert!(jump_stieltjes == jump_true && jump_true != jump_naive, "a jump in the weight needs its own term");
    assert!((recip_abel - recip_direct).abs() < 1e-9, "sum of 1/p two ways");
    println!("ALL CHECKS PASS");
}
