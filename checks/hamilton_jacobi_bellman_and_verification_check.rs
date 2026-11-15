// HJB and verification -- the check behind the card.  Rust std only.
// A car must cover x km with tau hours left before a deadline, burning least fuel.
// Fuel burn rate at speed u km/h: F(u) = a + c u + b u^3 litres per hour
// (illustrative: idling, rolling, air drag).  Roads to the least fuel V(tau, x):
// the guessed value W; a scan over arrival times (Hopf-Lax); Bellman's backward
// recursion over every schedule on a grid of speeds; the HJB residual by centred
// differences with the Hamiltonian found by a search; and the dynamic programming
// principle over a whole 30-minute first stretch.
const A: f64 = 1.08; // L/h idling
const C: f64 = 0.02; // L/km rolling
const B: f64 = 2.5e-6; // L h^2/km^3 drag

fn fa(u: f64, a: f64, b: f64) -> f64 { a + C * u + b * u.powf(3.0) }
fn f(u: f64) -> f64 { fa(u, A, B) }
fn eco(a: f64, b: f64) -> (f64, f64) {
    // speed of least fuel per km, and that fuel per km
    let u = (a / (2.0 * b)).powf(1.0 / 3.0);
    (u, fa(u, a, b) / u)
}

fn wab(tau: f64, x: f64, a: f64, b: f64) -> f64 {
    // the guessed value: two pieces, glued on x = u_eco tau
    let (u, ce) = eco(a, b);
    if x <= 0.0 { return 0.0; }
    if x <= u * tau { return ce * x; }
    tau * fa(x / tau, a, b)
}
fn w(tau: f64, x: f64) -> f64 { wab(tau, x, A, B) }

fn ham(p: f64) -> (f64, f64) {
    // Hamiltonian max_u (p u - F(u)), by ternary search
    let (mut lo, mut hi) = (0.0f64, 400.0f64);
    for _ in 0..200 {
        let m1 = lo + (hi - lo) / 3.0;
        let m2 = hi - (hi - lo) / 3.0;
        if p * m1 - f(m1) < p * m2 - f(m2) { lo = m1; } else { hi = m2; }
    }
    let u = (lo + hi) / 2.0;
    (p * u - f(u), u)
}

fn hopf_lax(tau: f64, x: f64) -> (f64, f64) {
    // least over arrival times theta <= tau of theta F(x/theta)
    let (mut lo, mut hi) = (1e-6f64, tau);
    for _ in 0..200 {
        let m1 = lo + (hi - lo) / 3.0;
        let m2 = hi - (hi - lo) / 3.0;
        if m1 * f(x / m1) < m2 * f(x / m2) { hi = m2; } else { lo = m1; }
    }
    let t = (lo + hi) / 2.0;
    (t * f(x / t), t)
}

fn bellman(steps: usize) -> Vec<Vec<f64>> {
    // speeds u = k dx/dt = 5k km/h; arriving mid-step costs distance times fuel per km
    let (dt, dx, nx, kmax) = (0.05f64, 0.25f64, 401usize, 40usize);
    let mut v = vec![f64::INFINITY; nx];
    v[0] = 0.0;
    let mut out = vec![v.clone()];
    for _ in 0..steps {
        let mut new = vec![0.0f64; nx];
        for i in 1..nx {
            let mut best = dt * A + v[i];
            for k in 1..=kmax {
                let u = k as f64 * dx / dt;
                let cost = if k >= i { i as f64 * dx * f(u) / u } else { dt * f(u) + v[i - k] };
                if cost < best { best = cost; }
            }
            new[i] = best;
        }
        v = new;
        out.push(v.clone());
    }
    out
}

fn main() {
    let (u_eco, ce) = eco(A, B);
    println!("economy speed u_eco (km/h)              {:.4}", u_eco);
    println!("fuel per km at u_eco (L/km)             {:.6}", ce);
    println!("F(60), F(80) (L/h)                      {:.4} {:.4}", f(60.0), f(80.0));
    let (v_main, v_free) = (w(1.25, 100.0), w(2.0, 100.0));
    println!("W(1.25 h, 100 km), needs 80 km/h (L)    {:.4}", v_main);
    println!("W(2 h, 100 km), drives 60 km/h (L)      {:.4}", v_free);
    println!("80 km/h parts: idle, rolling, drag (L)  {:.4} {:.4} {:.4}", 1.25 * A, 100.0 * C, 1.25 * B * 80.0f64.powf(3.0));
    let (hl, th) = hopf_lax(1.25, 100.0);
    let (hl2, th2) = hopf_lax(2.0, 100.0);
    println!("Hopf-Lax 1.25 h: fuel, arrival (h)      {:.4} {:.4}", hl, th);
    println!("Hopf-Lax 2 h: fuel, arrival (h)         {:.4} {:.4}", hl2, th2);
    let g = bellman(40);
    let (g125, g2, g90) = (g[25][400], g[40][400], g[25][360]);
    println!("Bellman grid 1.25 h, 100 km (L)         {:.4}", g125);
    println!("Bellman grid 2 h, 100 km (L)            {:.4}", g2);
    println!("Bellman grid 1.25 h, 90 km; W (L)       {:.4} {:.4}", g90, w(1.25, 90.0));
    let mut beat = f64::NEG_INFINITY;
    for n in 1..41 {
        for i in 0..401 {
            if g[n][i] < 1e9 { beat = beat.max(w(n as f64 * 0.05, i as f64 * 0.25) - g[n][i]); }
        }
    }
    println!("most any grid schedule beats W by (L)   {:.9}", beat.max(0.0));
    let (mut dpp, mut arg) = (f64::INFINITY, 0.0f64);
    for k in 0..20001 {
        let u = k as f64 / 100.0;
        let val = 0.5 * f(u) + w(0.75, 100.0 - 0.5 * u);
        if val < dpp { dpp = val; arg = u; }
    }
    println!("DPP over first 0.5 h: min, at u (km/h)  {:.4} {:.2}", dpp, arg);
    let pts = [(1.25, 100.0), (1.25, 50.0), (2.0, 100.0), (1.0, 30.0), (0.5, 45.0)];
    let mut res = Vec::new();
    for &d in &[1e-2f64, 1e-3, 1e-4] {
        let mut r = 0.0f64;
        for &(tau, x) in &pts {
            let wt = (w(tau + d, x) - w(tau - d, x)) / (2.0 * d);
            let wx = (w(tau, x + d) - w(tau, x - d)) / (2.0 * d);
            r = r.max((wt + ham(wx).0).abs());
        }
        res.push(r);
        println!("max HJB residual, step {:.4}           {:.9}", d, r);
    }
    let wt = (w(1.25 + 1e-4, 100.0) - w(1.25 - 1e-4, 100.0)) / 2e-4;
    let wx = (w(1.25, 100.0 + 1e-4) - w(1.25, 100.0 - 1e-4)) / 2e-4;
    println!("V_tau, V_x at 1.25 h, 100 km            {:.4} {:.4}", wt, wx);
    println!("best speed for that V_x (km/h)          {:.4}", ham(wx).1);
    println!("slack: fuel saved per extra minute (L)  {:.4}", -wt / 60.0);
    let e = 1e-6; // the seam x = 60 tau, at tau = 1.25 h, x = 75 km
    let s1 = (w(1.25, 75.0) - w(1.25, 75.0 - e)) / e;
    let s2 = (w(1.25, 75.0 + e) - w(1.25, 75.0)) / e;
    println!("seam 75 km: W; slope left, right        {:.4} {:.4} {:.4}", w(1.25, 75.0), s1, s2);
    println!("seam: W_xx left, right (L/km^2)         {:.6} {:.6}", 0.0, 6.0 * B * 75.0 / 1.25f64.powf(2.0));
    println!("trip at 1.25 h: clock (min), km left, fuel used, W left, sum");
    for m in (0..76).step_by(15) {
        let mf = m as f64;
        let x = 100.0 - 80.0 * mf / 60.0;
        let used = f(80.0) * mf / 60.0;
        let wl = w(1.25 - mf / 60.0, x);
        println!("  {:3} {:6.1} {:7.4} {:7.4} {:7.4}", m, x, used, wl, used + wl);
    }
    let jam = f(80.0) * 0.5 + A / 6.0;
    let tl = 1.25 - 0.5 - 1.0 / 6.0;
    println!("10-min jam at 30 min: new speed, total  {:.4} {:.4}", 60.0 / tl, jam + w(tl, 60.0));
    println!("value at 1.25 h, x = 0..120 km step 10 (L):");
    let row1: Vec<String> = (0..13).map(|j| format!("{:.2}", w(1.25, 10.0 * j as f64))).collect();
    let row2: Vec<String> = (0..13).map(|j| format!("{:.2}", ce * 10.0 * j as f64)).collect();
    println!("  W      {}", row1.join(" "));
    println!("  0.047x {}", row2.join(" "));
    let late = 100.0 / u_eco - 1.25;
    let exact = 2.0 * f(50.0);
    let sprint = 45.0 * ce + 0.5 * f(110.0);
    let p = v_main / 100.0f64.powf(2.0);
    println!("wrong: drop deadline: fuel, late (min)  {:.4} {:.4}", ce * 100.0, late * 60.0);
    println!("wrong: arrive exactly at 2 h (L)        {:.4}", exact);
    println!("wrong: 45 min at 60, then 110 (L)       {:.4}", sprint);
    println!("wrong: square P x^2 at 50 km; W (L)     {:.4} {:.4}", p * 2500.0, w(1.25, 50.0));
    println!("try: deadline 1 h, 1.5 h (L)            {:.4} {:.4}", w(1.0, 100.0), w(1.5, 100.0));
    let (u2, _) = eco(A, 2.0 * B);
    println!("try: double drag: u_eco, W(1.25,100)    {:.4} {:.4}", u2, wab(1.25, 100.0, A, 2.0 * B));
    assert!((v_main - 4.95).abs() < 1e-9); // 1.25 h x 3.96 L/h, by hand
    assert!((hl - v_main).abs() < 1e-6 && (hl2 - v_free).abs() < 1e-6); // Hopf-Lax road agrees
    assert!((g125 - v_main).abs() < 1e-9 && (g2 - v_free).abs() < 1e-9); // grid schedules reach W
    assert!(beat < 1e-9); // verification: no schedule on the grid beats W
    assert!(g90 >= w(1.25, 90.0)); // off the grid's speeds, the grid can only lose
    assert!((dpp - v_main).abs() < 1e-6 && (arg - 80.0).abs() < 0.02); // DPP over 30 minutes
    assert!(res[2] < 1e-6 && res[1] < 0.02 * res[0]); // HJB holds; residual falls as step^2
    assert!((ham(wx).1 - 80.0).abs() < 1e-3); // the Hamiltonian's best speed is the trip's speed
    assert!((s1 - s2).abs() < 1e-4); // the glued value has one slope across the seam
    assert!(exact > v_free && sprint > v_main); // the two wrong plans cost more
    println!("ALL CHECKS PASS");
}
