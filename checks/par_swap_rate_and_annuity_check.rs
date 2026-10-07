// The par swap rate and its annuity on a five-year annual swap, by three roads.
// std only: no crates, no imported root finder.

const FWD: [f64; 5] = [0.050, 0.046, 0.043, 0.041, 0.040]; // one-year forwards, years 1..5
const N: f64 = 10_000_000.0; // notional, dollars
const K_HOUSE: f64 = 0.045; // the house swap's fixed rate

/// D(i): chain the one-year growth factors and invert.
fn discount_factors(fwd: &[f64]) -> Vec<f64> {
    let mut out = Vec::new();
    let mut d = 1.0;
    for f in fwd {
        d /= 1.0 + f;
        out.push(d);
    }
    out
}

/// Pay k, receive the forward, valued backwards: W(i-1) = (W(i) + f_i - k) / (1 + f_i).
fn payer_value_per_unit(fwd: &[f64], k: f64) -> f64 {
    let mut w = 0.0;
    for f in fwd.iter().rev() {
        w = (w + f - k) / (1.0 + f);
    }
    w
}

/// A bond paying coupon c each year and 1 at the end, valued backwards.
fn par_bond_price(fwd: &[f64], c: f64) -> f64 {
    let mut v = 1.0 + c;
    for i in (1..fwd.len()).rev() {
        v = v / (1.0 + fwd[i]) + c;
    }
    v / (1.0 + fwd[0])
}

fn bisect<F: Fn(f64) -> f64>(g: F, mut lo: f64, mut hi: f64) -> f64 {
    let mut glo = g(lo);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        let gm = g(mid);
        if (gm > 0.0) == (glo > 0.0) {
            lo = mid;
            glo = gm;
        } else {
            hi = mid;
        }
        if hi - lo < 1e-15 {
            break;
        }
    }
    0.5 * (lo + hi)
}

fn par_and_annuity(fwd: &[f64]) -> (f64, f64) {
    let d = discount_factors(fwd);
    let a: f64 = d.iter().sum();
    ((1.0 - d[d.len() - 1]) / a, a)
}

fn main() {
    let d = discount_factors(&FWD);
    let a: f64 = d.iter().sum();
    let s1 = (1.0 - d[4]) / a; // road 1: floating leg telescopes
    let w: Vec<f64> = d.iter().map(|x| x / a).collect();
    let s2: f64 = w.iter().zip(FWD.iter()).map(|(wi, f)| wi * f).sum(); // road 2
    let s3 = bisect(|c| par_bond_price(&FWD, c) - 1.0, 0.0, 0.2); // road 3: par bond
    let h = 1e-4;
    let a_bump = (payer_value_per_unit(&FWD, s1 - h) - payer_value_per_unit(&FWD, s1 + h)) / (2.0 * h);
    let v_house = N * payer_value_per_unit(&FWD, K_HOUSE);
    let v_formula = N * a * (s1 - K_HOUSE);

    println!("year  forward %   growth G(i)      D(i)    weight %  weight x fwd %");
    for i in 0..5 {
        println!("{:>4}  {:9.2}  {:12.6}  {:9.6}  {:9.4}  {:13.6}", i + 1, 100.0 * FWD[i], 1.0 / d[i], d[i], 100.0 * w[i], 100.0 * w[i] * FWD[i]);
    }
    println!("weights add to                    {:.6}", w.iter().sum::<f64>());
    println!("1 - D(5), per dollar of notional  {:.6}", 1.0 - d[4]);
    println!("annuity A = sum of D(i)           {:.6}", a);
    println!("annuity by bumping the fixed rate {:.6}", a_bump);
    println!("road 1 (1 - D(5)) / A, %          {:.6}", 100.0 * s1);
    println!("road 2 weighted forwards, %       {:.6}", 100.0 * s2);
    println!("road 3 par bond by bisection, %   {:.6}", 100.0 * s3);
    println!("par rate, 2 decimals, %           {:.2}", 100.0 * s1);
    println!("notional $, house fixed rate %    {:.2}  {:.2}", N, 100.0 * K_HOUSE);
    println!("floating leg on 10m, $            {:.2}", N * (1.0 - d[4]));
    println!("fixed leg at par on 10m, $        {:.2}", N * s1 * a);
    println!("one bp of fixed rate on 10m, $    {:.2}", N * a * 1e-4);
    println!("house swap, pay 4.50%, recursion  {:.2}", v_house);
    println!("house swap, pay 4.50%, N A (S-K)  {:.2}", v_formula);
    println!("house fixed above par, bp         {:.4}", 1e4 * (K_HOUSE - s1));

    let z5 = d[4].powf(-1.0 / 5.0) - 1.0;
    println!("what breaks");
    println!("  plain average of forwards, %    {:.6}", 100.0 * FWD.iter().sum::<f64>() / 5.0);
    println!("  par above plain average, bp     {:.4}", 1e4 * (s1 - FWD.iter().sum::<f64>() / 5.0));
    println!("  five-year zero rate, %          {:.6}", 100.0 * z5);
    println!("  annuity = 5, no discounting, %  {:.6}", 100.0 * (1.0 - d[4]) / 5.0);
    println!("  annuity from D(0)..D(4), %      {:.6}", 100.0 * (1.0 - d[4]) / (1.0 + d[..4].iter().sum::<f64>()));

    println!("chart: payer value on 10m against the fixed rate, $ thousands");
    for k in [0.040, 0.042, 0.044, 0.046, 0.048, 0.050] {
        println!("  fixed {:4.1}%   {:9.2}", 100.0 * k, N * payer_value_per_unit(&FWD, k) / 1000.0);
    }

    println!("try changing");
    let up: Vec<f64> = FWD.iter().map(|f| f + 0.01).collect();
    let (s_up, a_up) = par_and_annuity(&up);
    println!("  every forward +1%: par %, A      {:.6}  {:.6}", 100.0 * s_up, a_up);
    let rev: Vec<f64> = FWD.iter().rev().cloned().collect();
    let (s_rev, a_rev) = par_and_annuity(&rev);
    println!("  forwards reversed: par %, A      {:.6}  {:.6}", 100.0 * s_rev, a_rev);
    let (s_flat, a_flat) = par_and_annuity(&[s1; 5]);
    println!("  flat at the par rate: par %, A   {:.6}  {:.6}", 100.0 * s_flat, a_flat);
    let (s_two, a_two) = par_and_annuity(&FWD[..2]);
    println!("  two-year swap: par %, A          {:.6}  {:.6}", 100.0 * s_two, a_two);

    let mut d_e = vec![1.0, 1.0 / 1.042]; // interest-rate-swaps' curve: 4.2% deposit, then par quotes
    for (n, q) in [(2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)] {
        let x = (1.0 - q * d_e[1..n].iter().sum::<f64>()) / (1.0 + q);
        d_e.push(x);
    }
    let f_e: Vec<f64> = (1..6).map(|i| d_e[i - 1] / d_e[i] - 1.0).collect();
    let (s_e, a_e) = par_and_annuity(&f_e);
    let v_e = N * payer_value_per_unit(&f_e, K_HOUSE);
    println!("same swap on the curve of interest-rate-swaps");
    println!("  par %, A                         {:.6}  {:.6}", 100.0 * s_e, a_e);
    println!("  pay 4.50%: recursion, N A (S-K)  {:.2}  {:.2}", v_e, N * a_e * (s_e - K_HOUSE));

    assert!((s_e - 0.0465).abs() < 1e-12, "that curve was built so the five-year par rate is 4.65%");
    assert!((v_e - N * a_e * (s_e - K_HOUSE)).abs() < 1e-6, "value = N A (S - K) on that curve too");
    let lo = FWD.iter().cloned().fold(f64::INFINITY, f64::min);
    let hi = FWD.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    assert!((s2 - s1).abs() < 1e-12, "weighted forwards must equal the telescoped ratio");
    assert!((s3 - s1).abs() < 1e-12, "the par bond coupon must equal the par swap rate");
    assert!((a_bump - a).abs() < 1e-9, "slope of value in the fixed rate must be the annuity");
    assert!((v_house - v_formula).abs() < 1e-6, "recursion and N A (S - K) must agree");
    assert!(lo < s1 && s1 < hi, "a weighted average sits inside its range");
    assert!((s1 - 0.0442).abs() < 5e-5, "the card's quoted 4.42%");
    assert!((a - 4.38).abs() < 5e-3, "the card's quoted 4.38");
    println!("ALL CHECKS PASS");
}
