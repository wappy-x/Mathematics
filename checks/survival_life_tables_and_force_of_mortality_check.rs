// Life tables and the force of mortality -- the check behind the card.  Rust std only.
// Mortality basis: Makeham's law mu(x) = A + B c^x with the Standard Ultimate Survival Model
// parameters.  The 10,000 policyholders aged 40 are the shelf's life office.
const A: f64 = 0.00022;
const B: f64 = 2.7e-6;
const C: f64 = 1.124;
const X0: usize = 40;
const N0: f64 = 10000.0;
const TOP: usize = 130;

fn mu(x: f64) -> f64 { A + B * C.powf(x) }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn surv(x: f64, t: f64, a: f64, b: f64, c: f64) -> f64 {   // road 1: exponent integrated by hand
    (-a * t - b / c.ln() * c.powf(x) * (c.powf(t) - 1.0)).exp()
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {                               // splitmix64, top 53 bits -> [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}

fn main() {
    // road 2: the life table, year by year, integrating mu numerically inside each year
    let mut l = vec![0.0f64; TOP + 1];
    l[X0] = N0;
    for x in X0..TOP { l[x + 1] = l[x] * (-simpson(mu, x as f64, x as f64 + 1.0, 20)).exp(); }
    let p = |x: usize| l[x + 1] / l[x];
    let q = |x: usize| 1.0 - p(x);
    let d = |x: usize| l[x] - l[x + 1];

    // road 3: simulate the 10,000 lives month by month using only the definition of mu
    let mut rng = Rng(20260928);
    let dt = 1.0 / 12.0;
    let mut lives = Vec::new();
    for _ in 0..N0 as usize {
        let mut m = 0usize;
        while m < 12 * (TOP - X0) && rng.next() >= mu(X0 as f64 + (m as f64 + 0.5) * dt) * dt { m += 1; }
        lives.push((m as f64 + 0.5) * dt);
    }
    let alive65 = lives.iter().filter(|&&t| t > 25.0).count();

    let p25 = surv(40.0, 25.0, A, B, C);
    println!("chance a 40-year-old reaches 65");
    println!("  1 closed form exp(-integral)     {:.6}", p25);
    println!("  2 life table l65 / l40           {:.6}", l[65] / l[40]);
    println!("  3 simulated, of 10,000 at 40     {:.6}  ({} lives)", alive65 as f64 / N0, alive65);
    println!("  expected survivors of 10,000     {:.2}", N0 * p25);
    let g = B / C.ln() * C.powf(40.0) * (C.powf(25.0) - 1.0);
    println!("  by hand: ln c {:.6}   B / ln c, times 10^5 {:.6}", C.ln(), 1e5 * B / C.ln());
    println!("  by hand: c^40 {:.4}   c^25 - 1 {:.4}", C.powf(40.0), C.powf(25.0) - 1.0);
    println!("  by hand: Gompertz part {:.6}   Makeham part {:.6}   total {:.6}", g, A * 25.0, g + A * 25.0);
    println!("life table, radix 10,000 at age 40");
    println!("  age      q_x        l_x       d_x     mu_x");
    for x in [40usize, 50, 60, 64, 65, 66, 80, 90, 100] {
        println!("  {:>3} {:>10.6} {:>10.2} {:>9.2} {:>8.6}", x, q(x), l[x], d(x), mu(x as f64));
    }
    let e_curt: f64 = (1..=TOP - X0).map(|k| l[X0 + k]).sum::<f64>() / N0;
    let e_curt_d: f64 = (0..TOP - X0).map(|k| k as f64 * d(X0 + k)).sum::<f64>() / N0;
    let e_comp = simpson(|t| surv(40.0, t, A, B, C), 0.0, 90.0, 2000);
    let e_sim: f64 = lives.iter().sum::<f64>() / N0;
    let se_sim = (lives.iter().map(|t| (t - e_sim).powi(2)).sum::<f64>() / (N0 - 1.0) / N0).sqrt();
    println!("life expectancy at 40, years");
    println!("  curtate, sum of l(40+k)/l40      {:.6}", e_curt);
    println!("  curtate, sum of k d(40+k)/l40    {:.6}", e_curt_d);
    println!("  complete, integral of survival   {:.6}", e_comp);
    println!("  curtate + 1/2                    {:.6}", e_curt + 0.5);
    println!("  expected age at death, 40 + e    {:.6}", 40.0 + e_comp);
    println!("  complete, simulated mean         {:.6}  (standard error {:.6})", e_sim, se_sim);
    let mu65_tab = (l[64].ln() - l[66].ln()) / 2.0;
    println!("force of mortality at 65, per year");
    println!("  formula A + B c^65               {:.6}", mu(65.0));
    println!("  from table (ln l64 - ln l66)/2   {:.6}", mu65_tab);
    println!("  q65 for comparison               {:.6}", q(65));
    println!("  ratio mu65 / mu40 {:.2}   c^10, growth per decade {:.4}", mu(65.0) / mu(40.0), C.powi(10));
    // Gompertz fit: least squares of ln(-ln p_x) on the year's midpoint, ages 40..99
    let xs: Vec<f64> = (40..100).map(|x| x as f64 + 0.5).collect();
    let ys: Vec<f64> = (40..100usize).map(|x| (-p(x).ln()).ln()).collect();
    let n = xs.len() as f64;
    let (mx, my) = (xs.iter().sum::<f64>() / n, ys.iter().sum::<f64>() / n);
    let num: f64 = xs.iter().zip(&ys).map(|(u, v)| (u - mx) * (v - my)).sum();
    let den: f64 = xs.iter().map(|u| (u - mx).powi(2)).sum();
    let slope = num / den;
    let (cg, bg) = (slope.exp(), (my - slope * mx).exp());
    let pg = surv(40.0, 25.0, 0.0, bg, cg);
    println!("Gompertz fit to the table, ages 40 to 99");
    println!("  fitted B, times 10^6 {:.6}   fitted c {:.6}", 1e6 * bg, cg);
    println!("  doubling time ln2 / ln c, years  {:.6}", 2f64.ln() / cg.ln());
    println!("  25p40 under the fit              {:.6}", pg);
    println!("  mu40 fit {:.6}   table {:.6}", bg * cg.powf(40.0), mu(40.0));
    println!("what breaks");
    println!("  1 - sum of q, ages 40-64         {:.6}", 1.0 - (40..65).map(|x| q(x)).sum::<f64>());
    println!("  1 - sum of q, ages 40-89         {:.6}", 1.0 - (40..90).map(|x| q(x)).sum::<f64>());
    println!("  right: l90 / l40                 {:.6}", l[90] / l[40]);
    println!("  flat hazard at mu40 for 25 years {:.6}", (-25.0 * mu(40.0)).exp());
    println!("  Gompertz, Makeham constant A = 0 {:.6}", surv(40.0, 25.0, 0.0, B, C));
    let ages: Vec<usize> = (40..115).step_by(5).collect();
    let row = |f: &dyn Fn(usize) -> String| ages.iter().map(|&a| f(a)).collect::<Vec<_>>().join(" ");
    println!("chart ages   {}", row(&|a| format!("{}", a)));
    println!("chart table  {}", row(&|a| format!("{:.2}", surv(40.0, a as f64 - 40.0, A, B, C))));
    println!("chart fit    {}", row(&|a| format!("{:.2}", surv(40.0, a as f64 - 40.0, 0.0, bg, cg))));
    println!("chart deaths {}", row(&|a| format!("{:.0}", (0..5).map(|j| d(a + j)).sum::<f64>())));
    let bars: Vec<String> = (40..101).step_by(10).map(|a| format!("{:.2}", 1000.0 * mu(a as f64))).collect();
    println!("bars mu per 1,000 at 40..100 by 10  {}", bars.join(" "));
    println!("try changing");
    println!("  c = 1.10: 25p40                  {:.6}", surv(40.0, 25.0, A, B, 1.10));
    println!("  from 60 to 85: 25p60             {:.6}", surv(60.0, 25.0, A, B, C));
    println!("  A doubled to 0.00044: 25p40      {:.6}", surv(40.0, 25.0, 2.0 * A, B, C));

    assert!((l[65] / l[40] - p25).abs() < 1e-10);                                // table vs closed form
    assert!((alive65 as f64 / N0 - p25).abs() < 4.0 * (p25 * (1.0 - p25) / N0).sqrt()); // simulation
    assert!((e_curt - e_curt_d).abs() < 1e-8);                                   // two curtate sums
    assert!((e_comp - e_curt - 0.5).abs() < 0.01);                               // complete = curtate + 1/2
    assert!((e_sim - e_comp).abs() < 4.0 * se_sim);                              // simulated mean
    assert!((mu65_tab - mu(65.0)).abs() < 1e-4);                                 // slope of ln l is mu
    assert!((pg - p25).abs() < 0.01);                                            // the fit lands near
    assert!((cg.ln() - C.ln()).abs() < 0.01);                                    // and recovers c
    println!("all checks passed");
}
