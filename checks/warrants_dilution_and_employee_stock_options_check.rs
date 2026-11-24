// Warrants and employee stock options -- the check behind the card, in Rust with no
// crates.  The same series, Simpson grids, tree, generator and labels as the Python
// check, so the two outputs agree line for line.  House market: r = 5%, q = 2%, sigma = 20%.
const R: f64 = 0.05; const Q: f64 = 0.02; const VOL: f64 = 0.20; const K: f64 = 100.0;
const N_SH: f64 = 1_000_000.0; const M_W: f64 = 100_000.0; // Acme's shares, the warrants it writes
const PI: f64 = std::f64::consts::PI;

fn phi(x: f64) -> f64 { // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) { n += 1.0; term *= x * x / (2.0 * n + 1.0); total += term; }
    0.5 + total * (-x * x / 2.0).exp() / (2.0 * PI).sqrt()
}

fn bs_call(s: f64, k: f64, t: f64, vol: f64) -> f64 {
    if t <= 0.0 { return (s - k).max(0.0); }
    let d1 = ((s / k).ln() + (R - Q + vol * vol / 2.0) * t) / (vol * t.sqrt());
    s * (-Q * t).exp() * phi(d1) - k * (-R * t).exp() * phi(d1 - vol * t.sqrt())
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let w = |i: usize| if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=n).map(|i| w(i) * f(a + i as f64 * h)).sum::<f64>()
}

fn warrant_by_average(v0: f64) -> f64 { // payoff from the diluted share price itself, one year
    let (mu, sd) = (R - Q - VOL * VOL / 2.0, VOL);
    let pay = |z: f64| {
        let v_t = v0 * (mu + sd * z).exp(); // equity per old share at expiry
        let price_after = (N_SH * v_t + M_W * K) / (N_SH + M_W);
        (price_after - K).max(0.0) * (-z * z / 2.0).exp() / (2.0 * PI).sqrt()
    };
    let z_k = ((K / v0).ln() - mu) / sd; // below this the warrants lapse
    (-R).exp() * simpson(&pay, z_k, 10.0, 2000)
}

fn warrant_from_share_price(s: f64, vol: f64) -> f64 { // W = N/(N+M) C(S + (M/N) W), by iteration
    let mut w = 0.0;
    for _ in 0..60 { w = N_SH / (N_SH + M_W) * bs_call(s + M_W / N_SH * w, K, 1.0, vol); }
    w
}

fn eso_tree(steps: usize, vest: f64, mult: f64, leave: f64, forfeit: bool) -> f64 { // false: nobody leaves before vesting
    let dt = 10.0 / steps as f64; // ten years
    let (u, df) = ((VOL * dt.sqrt()).exp(), (-R * dt).exp());
    let p = (((R - Q) * dt).exp() - 1.0 / u) / (u - 1.0 / u);
    let lv = 1.0 - (-leave * dt).exp(); // chance of leaving in one step
    let mut val: Vec<f64> =
        (0..=steps).map(|j| (100.0 * u.powf(2.0 * j as f64 - steps as f64) - K).max(0.0)).collect();
    for i in (0..steps).rev() {
        let vested = i as f64 * dt >= vest - 1e-9; let li = if vested || forfeit { lv } else { 0.0 };
        for j in 0..=i {
            let s = 100.0 * u.powf(2.0 * j as f64 - i as f64);
            let x = (s - K).max(0.0);
            let hold = df * (p * val[j + 1] + (1.0 - p) * val[j]);
            val[j] = if vested && s >= mult * K { x } // exercise at the multiple
                else { (1.0 - li) * hold + li * (if vested { x } else { 0.0 }) }; // leave: exercise or forfeit
        }
    }
    val[0]
}

fn leave_sum(steps: usize, vest: f64, leave: f64) -> f64 { // no multiple: a sum of plain calls
    let (t, dt) = (10.0, 10.0 / steps as f64);
    let lv = 1.0 - (-leave * dt).exp();
    let mut tot = 0.0;
    for i in 0..steps {
        if i as f64 * dt >= vest - 1e-9 { tot += (1.0 - lv).powf(i as f64) * lv * bs_call(100.0, K, i as f64 * dt, VOL); }
    }
    tot + (1.0 - lv).powf(steps as f64) * bs_call(100.0, K, t, VOL)
}

fn eso_sim(pairs: usize) -> (f64, f64) {
    let (steps, vest, mult, leave, t) = (500usize, 3.0, 2.0, 0.05, 10.0);
    let (dt, lv) = (t / steps as f64, 1.0 - (-leave * t / steps as f64).exp());
    let vs = (vest / dt).round() as usize;
    let (drift, sd, g) = ((R - Q - VOL * VOL / 2.0) * dt, VOL * dt.sqrt(), (-R * dt).exp());
    let (mut st, mut tot, mut tot2) = (20261123u64, 0.0, 0.0);
    let mut z = vec![0.0; steps];
    let next = |st: &mut u64| {
        *st = st.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        *st >> 11
    };
    for _ in 0..pairs {
        for i in 0..steps / 2 { // Box-Muller: two uniforms give two normals
            let u1 = (next(&mut st) as f64 + 0.5) / 9007199254740992.0;
            let u2 = next(&mut st) as f64 / 9007199254740992.0;
            let rad = (-2.0 * u1.ln()).sqrt();
            z[2 * i] = rad * (2.0 * PI * u2).cos();
            z[2 * i + 1] = rad * (2.0 * PI * u2).sin();
        }
        let mut pv = 0.0;
        for sign in [1.0, -1.0] { // each path and its mirror image
            let (mut s, mut alive, mut disc, mut v, mut done) = (100.0f64, 1.0, 1.0, 0.0, false);
            for i in 0..steps {
                let x = (s - K).max(0.0);
                if i >= vs {
                    if s >= mult * K { v += alive * disc * x; done = true; break; }
                    v += alive * lv * disc * x;
                }
                alive *= 1.0 - lv; s *= (drift + sign * sd * z[i]).exp(); disc *= g;
            }
            if !done { v += alive * disc * (s - K).max(0.0); }
            pv += v / 2.0;
        }
        tot += pv; tot2 += pv * pv;
    }
    let mean = tot / pairs as f64;
    (mean, ((tot2 / pairs as f64 - mean * mean) / pairs as f64).sqrt())
}

fn out(label: &str, x: f64) { println!("{:<44}{:>12.6}", label, x); }

fn main() {
    println!("part 1: the warrant, one year, strike 100");
    let (call, f) = (bs_call(100.0, K, 1.0, VOL), N_SH / (N_SH + M_W));
    out("plain call on a share at 100", call);
    out("dilution factor N/(N+M)", f);
    let w_free = f * call; out("warrant, equity per old share 100", w_free);
    let w_free_avg = warrant_by_average(100.0); out("  same, diluted payoff averaged", w_free_avg);
    let s_after = 100.0 - M_W / N_SH * w_free; out("  share price after a free grant", s_after);
    out("  warrant solved from that share price", warrant_from_share_price(s_after, VOL));
    let w_cash = warrant_from_share_price(100.0, VOL); out("warrant, share trading at 100", w_cash);
    let v_c = 100.0 + M_W / N_SH * w_cash; out("  equity per old share behind it", v_c);
    let w_cash_avg = warrant_by_average(v_c); out("  same, diluted payoff averaged", w_cash_avg);
    let d1 = ((v_c / K).ln() + R - Q + VOL * VOL / 2.0) / VOL; // one year
    let shrink = M_W / (N_SH + M_W) * (-Q).exp() * phi(d1); out("  each round shrinks the error by", shrink);
    let share = |v: f64| v - M_W / (N_SH + M_W) * bs_call(v, K, 1.0, VOL); // share price behind equity v
    let vol_sh = VOL * v_c / share(v_c) * (share(v_c + 1e-4) - share(v_c - 1e-4)) / 2e-4;
    out("  the share's own volatility, %", 100.0 * vol_sh);
    let w_shvol = warrant_from_share_price(100.0, vol_sh); out("  warrant priced at the share's volatility", w_shvol);
    let after = (N_SH * 120.0 + M_W * K) / (N_SH + M_W); out("expiry at 120: each share after exercise", after);
    out("expiry at 120: plain call pays", 20.0);
    out("expiry at 120: warrant pays", after - K);
    out("plain call overstates the warrant by", call - w_cash);
    assert!((w_free_avg - w_free).abs() < 1e-6 && (w_cash_avg - w_cash).abs() < 1e-6);
    assert!((warrant_from_share_price(s_after, VOL) - w_free).abs() < 1e-9);
    assert!((vol_sh - VOL * v_c / 100.0 * (1.0 - shrink)).abs() < 1e-6 && w_shvol < w_cash);
    assert!((call - 9.227006).abs() < 1e-6 && (w_free - 8.388187).abs() < 1e-6); // the spec's anchors

    println!("part 2: the employee option, ten years, strike 100, 500-step tree");
    let bs10 = bs_call(100.0, K, 10.0, VOL); out("Black-Scholes, ten years", bs10);
    let plain = eso_tree(500, 0.0, 1e9, 0.0, true); out("tree, no employee features", plain);
    out("tree, exercise at 2.0 times strike only", eso_tree(500, 3.0, 2.0, 0.0, true));
    let no_vest = eso_tree(500, 0.0, 1e9, 0.05, true); out("tree, 5% leaving, no vesting", no_vest);
    let lv_vest = eso_tree(500, 3.0, 1e9, 0.05, true); out("tree, 5% leaving, 3-year vesting", lv_vest);
    let lv_sum = leave_sum(500, 3.0, 0.05); out("  same, as a sum of plain calls", lv_sum);
    let eso = eso_tree(500, 3.0, 2.0, 0.05, true); out("tree, all three features", eso);
    for n in [250usize, 1000] { out(&format!("  same on a {}-step tree", n), eso_tree(n, 3.0, 2.0, 0.05, true)); }
    let m3 = eso_tree(500, 3.0, 3.0, 0.05, true); out("  same, exercise at 3.0 times strike", m3);
    let (sim, se) = eso_sim(50000);
    out("simulation, 100,000 paths", sim);
    out("  its standard error", se);
    out("ESO as a share of Black-Scholes, %", 100.0 * eso / bs10);
    out("Black-Scholes overstates the ESO by", bs10 - eso);
    let short = bs_call(100.0, K, 6.5, VOL); out("accounting shortcut: Black-Scholes, 6.5 years", short);
    out("  minus the tree, forfeiture counted twice", short - eso);
    let stay = (-0.05f64 * 3.0).exp(); out("chance of staying to vesting", stay);
    let per_vest = eso_tree(500, 3.0, 2.0, 0.05, false); out("tree, per vested option", per_vest);
    out("  shortcut falls short per vested option by", per_vest - short);
    assert!((plain - bs10).abs() < 0.02 && (lv_vest - lv_sum).abs() < 0.02);
    assert!((sim - eso).abs() < 3.0 * se && eso < lv_vest && lv_vest < no_vest && no_vest < bs10);
    assert!((stay * per_vest - eso).abs() < 1e-9 && eso < lv_vest && lv_vest < m3);
    let rates = [0.0, 0.025, 0.05, 0.075, 0.10, 0.125, 0.15];
    let row = |f: &dyn Fn(f64) -> String| rates.iter().map(|&e| f(e)).collect::<String>();
    println!("chart leaving %   {}", row(&|e| format!("{:>7.1}", 100.0 * e)));
    println!("chart multiple 2  {}", row(&|e| format!("{:>7.2}", eso_tree(500, 3.0, 2.0, e, true))));
    println!("chart no multiple {}", row(&|e| format!("{:>7.2}", eso_tree(500, 3.0, 1e9, e, true))));
    println!("ALL CHECKS PASS");
}
