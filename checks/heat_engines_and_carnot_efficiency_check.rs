// Heat engines and Carnot efficiency -- the same check as the Python, in Rust.
// Standard library only, no crates.  Boiler water at 90 C, room at 20 C, a
// heat pump scoring 4.  Roads to the limit: (1) the formula 1 - Tc/Th; (2) an
// ideal-gas Carnot cycle simulated leg by leg, its work found by adding up
// p dV with Simpson's rule; (3) entropy bookkeeping, best work by bisection.
const K0: f64 = 273.15; // kelvin = degrees Celsius + 273.15
const R: f64 = 8.314462618; // molar gas constant, J/(mol K), NIST CODATA (exact)
const TH: f64 = 90.0 + K0; // boiler water, K
const TC: f64 = 20.0 + K0; // room, K
const QH: f64 = 10.0; // heat taken from the boiler water, kW
const COP_REAL: f64 = 4.0; // kW of heat per kW of electricity
const GAP: f64 = 5.0; // temperature gap across each heat exchanger, K

fn carnot_eta(th: f64, tc: f64) -> f64 { 1.0 - tc / th }
fn carnot_cop(th: f64, tc: f64) -> f64 { th / (th - tc) }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

// road 2: one mole of ideal gas, hot isotherm v1->v2, adiabat down to tc,
// cold isotherm, adiabat back up.  Returns (Qh, Qc, W, T3).
fn gas_cycle(th: f64, tc: f64, gamma: f64) -> (f64, f64, f64, f64) {
    let (n, v1, v2) = (1.0, 0.010, 0.020);
    let k = (th / tc).powf(1.0 / (gamma - 1.0));
    let (v3, v4) = (v2 * k, v1 * k);
    let (p2, p4) = (n * R * th / v2, n * R * tc / v4);
    let w12 = simpson(|v| n * R * th / v, v1, v2, 2000);
    let w23 = simpson(|v| p2 * (v2 / v).powf(gamma), v2, v3, 2000);
    let w34 = -simpson(|v| n * R * tc / v, v4, v3, 2000);
    let w41 = -simpson(|v| p4 * (v4 / v).powf(gamma), v1, v4, 2000);
    let t3 = p2 * (v2 / v3).powf(gamma) * v3 / (n * R);
    (w12, -w34, w12 + w23 + w34 + w41, t3)
}

// road 3: largest W with total entropy change -qh/th + (qh - W)/tc >= 0
fn best_work(qh: f64, th: f64, tc: f64) -> f64 {
    let (mut lo, mut hi) = (0.0, qh);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if -qh / th + (qh - mid) / tc >= 0.0 { lo = mid } else { hi = mid }
    }
    lo
}

// a tank cooled from th to tc, each slice run through a perfect engine
fn tank_eta(th: f64, tc: f64, steps: usize) -> f64 {
    let dt = (th - tc) / steps as f64;
    let mut w = 0.0;
    for i in 0..steps { w += dt * carnot_eta(th - (i as f64 + 0.5) * dt, tc); }
    w / (th - tc)
}

fn show(label: &str, value: f64, unit: &str) {
    println!("{}", format!("{:<46}{:>12.4} {}", label, value, unit).trim_end());
}

fn main() {
    let eta = carnot_eta(TH, TC);
    let mono = gas_cycle(TH, TC, 5.0 / 3.0);
    let dia = gas_cycle(TH, TC, 1.4);
    let w_bis = best_work(QH, TH, TC);
    let cop = carnot_cop(TH, TC);
    let cop_gap = carnot_cop(TH + GAP, TC - GAP);
    let tank_closed = 1.0 - TC * (TH / TC).ln() / (TH - TC);
    let tank_sim = tank_eta(TH, TC, 70000);
    let ca = 1.0 - (TC / TH).sqrt();
    let t_max = COP_REAL * TC / (COP_REAL - 1.0);

    show("boiler water Th", TH, "K"); show("room Tc", TC, "K"); show("gap Th - Tc", TH - TC, "K");
    show("1 Carnot efficiency, formula", eta, "");
    show("2 gas cycle, monatomic: Qh", mono.0, "J"); show("  Qc", mono.1, "J"); show("  W", mono.2, "J");
    show("  W / Qh", mono.2 / mono.0, ""); show("  gas temperature after adiabat", mono.3, "K");
    show("2 gas cycle, diatomic: W / Qh", dia.2 / dia.0, "");
    show("3 entropy bisection: best W from 10 kW", w_bis, "kW");
    show("  formula: eta x 10 kW", eta * QH, "kW"); show("  heat dumped in room", QH - eta * QH, "kW");
    show("heat pump limit Th/(Th - Tc)", cop, ""); show("  same, from the gas cycle Qh / W", mono.0 / mono.2, "");
    show("  fridge limit Tc/(Th - Tc)", TC / (TH - TC), "");
    show("electricity for 10 kW of heat: perfect pump", QH / cop, "kW");
    show("  pump scoring 4", QH / COP_REAL, "kW"); show("  electric heater", QH, "kW");
    show("pump scoring 4 as share of its limit", COP_REAL / cop, "");
    show("limit with 5 K exchanger gaps, 368.15/80", cop_gap, "");
    show("  pump scoring 4 as share of that", COP_REAL / cop_gap, "");
    show("hottest delivery a score of 4 allows", t_max, "K"); show("  in Celsius", t_max - K0, "C");
    show("finite tank 90 -> 20 C, closed form", tank_closed, ""); show("  same, stepped 70000 slices", tank_sim, "");
    show("Curzon-Ahlborn, engine at best power", ca, "");
    show("power station, 600 C steam to 35 C: Tc/Th", (35.0 + K0) / (600.0 + K0), "");
    show("  nuclear, 285 C steam to 35 C: Tc/Th", (35.0 + K0) / (285.0 + K0), "");
    show("wrong: Celsius efficiency 1 - 20/90", 1.0 - 20.0 / 90.0, "");
    show("wrong: Celsius pump limit 90/70", 90.0 / 70.0, "");
    show("wrong: tank treated as fixed 90 C", eta, "");
    show("try: flow at 70 C, efficiency", carnot_eta(70.0 + K0, TC), ""); show("  pump limit", carnot_cop(70.0 + K0, TC), "");
    show("try: source 5 C outdoors, pump limit", carnot_cop(TH, 5.0 + K0), "");
    show("  pump scoring 4 as share", COP_REAL / carnot_cop(TH, 5.0 + K0), "");
    show("try: 10 K exchanger gaps, limit", carnot_cop(TH + 10.0, TC - 10.0), "");
    show("try: tank stepped 2 slices", tank_eta(TH, TC, 2), "");
    let flows = [40, 50, 60, 70, 80, 90, 100, 110, 120];
    let head: Vec<String> = flows.iter().map(|t| format!("{:6}", t)).collect();
    println!("chart, flow C       {}", head.join(" "));
    let vals: Vec<String> = flows.iter().map(|&t| format!("{:6.2}", carnot_cop(t as f64 + K0, TC))).collect();
    println!("chart, pump limit   {}", vals.join(" "));
    let score: Vec<String> = flows.iter().map(|_| format!("{:6.2}", COP_REAL)).collect();
    println!("chart, pump score   {}", score.join(" "));

    assert!((eta - 70.0 / 363.15).abs() < 1e-12);
    assert!((mono.2 / mono.0 - eta).abs() < 1e-9);
    assert!((mono.0 - R * TH * 2.0_f64.ln()).abs() < 1e-6); // hot leg vs n R Th ln(V2/V1), 1 mol
    assert!((mono.1 - R * TC * 2.0_f64.ln()).abs() < 1e-6); // cold leg vs n R Tc ln(V3/V4), 1 mol
    assert!((dia.2 / dia.0 - eta).abs() < 1e-9);
    assert!((mono.3 - TC).abs() < 1e-9);
    assert!((w_bis - eta * QH).abs() < 1e-9);
    assert!((mono.0 / mono.2 - cop).abs() < 1e-9);
    assert!((tank_sim - tank_closed).abs() < 1e-9);
    assert!(tank_closed < eta);
    assert!(COP_REAL < cop_gap && cop_gap < cop);
    assert!((carnot_cop(t_max, TC) - COP_REAL).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
