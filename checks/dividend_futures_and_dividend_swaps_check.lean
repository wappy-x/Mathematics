-- Dividend futures and swaps: put-call parity at each expiry gives the value today of the dividends before it, the difference of two expiries carried to the payment date is the fair dividend future, the futures summed are the fair dividend swap strike, and in the escrowed model a call's dividend delta is -N(d₁)e^(-r tᵢ).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory Finset

/-! Notation, as on the card, counting years from 0 in Lean. `S` is Acme's price today, `K` the
strike both options share, `r` the bank rate (continuously compounded). Expiry number `n + 1` is
at `T (n + 1)` years, with call `C (n + 1)` and put `P (n + 1)` quoted there; expiry 0 is today.
Year `i` (`i = 0, 1, 2, …`, the card's year `i + 1`) runs from expiry `i` to expiry `i + 1`; its
dividend is paid at `t i` years, `pv i` is its value today and `F i` the fair price of its dividend
future, the dividend's risk-neutral average. So the dividends paid before expiry `n` are years
`0, …, n - 1`, and their value today is `∑ i ∈ range n, pv i`. -/

/-- The implied dividend strip read from the quotes: `D(T₀) = 0` and
`D(T_n) = S - K e^(-r T_n) - (C(T_n) - P(T_n))` at each quoted expiry. -/
noncomputable def impliedStrip (S K r : ℝ) (T C P : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | n + 1 => S - K * exp (-r * T (n + 1)) - (C (n + 1) - P (n + 1))

/-- The year-`i` dividend future read from the strip: `F_i = (D(T_{i+1}) - D(T_i)) e^(r tᵢ)`. -/
noncomputable def futureFromStrip (S K r : ℝ) (T C P t : ℕ → ℝ) (i : ℕ) : ℝ :=
  (impliedStrip S K r T C P (i + 1) - impliedStrip S K r T C P i) * exp (r * t i)

/-- **The card's main claim** (The formula; Steps 1 to 3). Suppose put-call parity holds at every
expiry, `C(T_n) - P(T_n) = S - (value today of the dividends before T_n) - K e^(-r T_n)` (European
options quoted together, a share that costs nothing to borrow), and that with known payment dates
and a known bank rate each year's dividend is worth today its futures price discounted from its
payment date, `PVᵢ = e^(-r tᵢ) Fᵢ`. Then the strip read from the quotes is the value today of the
dividends before each expiry, `D(T_n) = PV₁ + … + PV_n`, and each difference of the strip carried
forward to its payment date is that year's fair dividend future: `(D(T_i) - D(T_{i-1})) e^(r tᵢ) = Fᵢ`. -/
theorem dividend_future_from_parity_strip (S K r : ℝ) (T C P t pv F : ℕ → ℝ)
    (h_parity : ∀ n, C (n + 1) - P (n + 1) = S - ∑ i ∈ range (n + 1), pv i - K * exp (-r * T (n + 1)))
    (h_price : ∀ i, pv i = exp (-r * t i) * F i) :
    (∀ n, impliedStrip S K r T C P n = ∑ i ∈ range n, pv i) ∧
      ∀ i, futureFromStrip S K r T C P t i = F i := by
  have h1 : ∀ n, impliedStrip S K r T C P n = ∑ i ∈ range n, pv i := by
    intro n
    cases n with
    | zero => simp [impliedStrip]
    | succ n => simp only [impliedStrip]; rw [h_parity n]; ring
  refine ⟨h1, fun i => ?_⟩
  rw [futureFromStrip, h1, h1, sum_range_succ, h_price i]
  rw [show (∑ x ∈ range i, pv x + exp (-r * t i) * F i - ∑ x ∈ range i, pv x) * exp (r * t i)
      = F i * (exp (-r * t i) * exp (r * t i)) by ring, ← exp_add]
  simp

/-- **A swap is a bundle of futures** (Step 4). Under the same hypotheses, a dividend swap over
years 1 to `n` pays `div₁ + … + div_n - K_swap` at its end `T_n`; its value today is
`e^(-r T_n) (F₁ + … + F_n - K_swap)`. It is fair (worth zero) exactly when the strike is the sum
of the futures read from the strip: `K_swap = F₁ + … + F_n`. -/
theorem dividend_swap_strike_eq_sum_of_futures (S K r : ℝ) (T C P t pv F : ℕ → ℝ)
    (h_parity : ∀ n, C (n + 1) - P (n + 1) = S - ∑ i ∈ range (n + 1), pv i - K * exp (-r * T (n + 1)))
    (h_price : ∀ i, pv i = exp (-r * t i) * F i) (n : ℕ) (Kswap : ℝ) :
    exp (-r * T n) * (∑ i ∈ range n, F i - Kswap) = 0 ↔
      Kswap = ∑ i ∈ range n, futureFromStrip S K r T C P t i := by
  have h := (dividend_future_from_parity_strip S K r T C P t pv F h_parity h_price).2
  simp_rw [h]
  rw [mul_eq_zero, or_iff_right (exp_pos _).ne', sub_eq_zero, eq_comm]

/-! The dividend delta (Step 5 and its detailed proof). This part needs a model: the escrowed
Black–Scholes model of the card "Known cash dividends", with the volatility on the share net of
the dividends' value today. -/

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The escrowed share with `n` cash dividends before expiry, `div j` paid at `t j`:
`S* = S - ∑_{j<n} div_j e^(-r t_j)`. -/
noncomputable def escrowedSpot (S r : ℝ) (t div : ℕ → ℝ) (n : ℕ) : ℝ :=
  S - ∑ j ∈ range n, div j * exp (-r * t j)

/-- The first distance with no yield, `d₁ = (ln(S*/K) + (r + σ²/2) T) / (σ√T)`. -/
noncomputable def bsD1 (Sstar K r σ T : ℝ) : ℝ :=
  (log (Sstar / K) + (r + σ ^ 2 / 2) * T) / (σ * √T)

/-- The escrowed call: `C = S* N(d₁) - K e^(-rT) N(d₂)`, with `d₂ = d₁ - σ√T`. -/
noncomputable def escrowedCall (S K r σ T : ℝ) (t div : ℕ → ℝ) (n : ℕ) : ℝ :=
  escrowedSpot S r t div n * stdNormalCDF (bsD1 (escrowedSpot S r t div n) K r σ T)
    - K * exp (-r * T) * stdNormalCDF (bsD1 (escrowedSpot S r t div n) K r σ T - σ * √T)


/-- The standard normal density, written out. -/
lemma dfs_phi_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma dfs_phi_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma dfs_N_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma dfs_N_sub (a b : ℝ) :
    stdNormalCDF b - stdNormalCDF a = ∫ t in a..b, gaussianPDFReal 0 1 t := by
  rw [dfs_N_eq_integral, dfs_N_eq_integral]
  exact intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn

lemma dfs_N_hasDerivAt (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have h : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; rw [← dfs_N_sub]; ring
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right (dfs_phi_continuous.intervalIntegrable _ _)
    (dfs_phi_continuous.stronglyMeasurableAtFilter _ _)
    dfs_phi_continuous.continuousAt).const_add _

/-- The cancellation behind delta: `K e^(-rT) φ(d₂) = S* φ(d₁)`. -/
lemma dfs_key (S K r σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-r * T) * gaussianPDFReal 0 1 (bsD1 S K r σ T - σ * √T)
      = S * gaussianPDFReal 0 1 (bsD1 S K r σ T) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  set d := bsD1 S K r σ T with hd_def
  have hd : d * (σ * √T) = log (S / K) + (r + σ ^ 2 / 2) * T := by
    rw [hd_def, bsD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 + -r * T = -d ^ 2 / 2 + log (S / K) := by
    linear_combination hd - (σ ^ 2 / 2) * hsq
  rw [dfs_phi_eq, dfs_phi_eq]
  rw [show K * exp (-r * T) * ((√(2 * π))⁻¹ * exp (-(d - σ * √T) ^ 2 / 2))
      = (√(2 * π))⁻¹ * K * exp (-(d - σ * √T) ^ 2 / 2 + -r * T) by rw [exp_add]; ring,
    hexp, exp_add, exp_log (div_pos hS hK)]
  field_simp

/-- The no-yield call's slope in the (escrowed) share price is `N(d₁)`. -/
lemma dfs_call_hasDerivAt_spot (S K r σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun s => s * stdNormalCDF (bsD1 s K r σ T)
        - K * exp (-r * T) * stdNormalCDF (bsD1 s K r σ T - σ * √T))
      (stdNormalCDF (bsD1 S K r σ T)) S := by
  have hd1 : HasDerivAt (fun x => bsD1 x K r σ T) ((1 / K) / (S / K) / (σ * √T)) S := by
    have h := ((((hasDerivAt_id' S).div_const K).log (div_pos hS hK).ne').add_const
      ((r + σ ^ 2 / 2) * T)).div_const (σ * √T)
    simpa [bsD1] using h
  have hC := ((hasDerivAt_id S).mul ((dfs_N_hasDerivAt _).comp S hd1)).sub
    (((dfs_N_hasDerivAt _).comp S (hd1.sub_const (σ * √T))).const_mul (K * exp (-r * T)))
  have key := dfs_key S K r σ T hS hK hσ hT
  convert hC using 1
  · funext x; simp [Function.comp]
  · simp only [id, Function.comp]
    linear_combination ((1 / K) / (S / K) / (σ * √T)) * key

/-- **Dividend delta of a call** (The formula; Step 5). In the escrowed model, with a positive
escrowed share, strike, volatility and time to expiry, raising any one dividend `divᵢ` paid before
expiry changes the call at the rate `Δᵢ = ∂C/∂divᵢ = -N(d₁) e^(-r tᵢ)`. -/
theorem call_dividend_delta (S K r σ T : ℝ) (t div : ℕ → ℝ) (n i : ℕ) (hi : i < n)
    (hS : 0 < escrowedSpot S r t div n) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => escrowedCall S K r σ T t (Function.update div i x) n)
      (-(stdNormalCDF (bsD1 (escrowedSpot S r t div n) K r σ T)) * exp (-r * t i)) (div i) := by
  set s0 := escrowedSpot S r t div n with hs0
  have hspot : ∀ x, escrowedSpot S r t (Function.update div i x) n
      = s0 - (x - div i) * exp (-r * t i) := by
    intro x
    have hmem : i ∈ range n := mem_range.2 hi
    simp only [hs0, escrowedSpot]
    rw [← add_sum_erase _ _ hmem, ← add_sum_erase _ _ hmem]
    have : ∑ j ∈ (range n).erase i, Function.update div i x j * exp (-r * t j)
        = ∑ j ∈ (range n).erase i, div j * exp (-r * t j) := by
      refine sum_congr rfl fun j hj => ?_
      rw [Function.update_of_ne (ne_of_mem_erase hj)]
    rw [this, Function.update_self]
    ring
  have hin : HasDerivAt (fun x => s0 - (x - div i) * exp (-r * t i)) (-exp (-r * t i)) (div i) := by
    have := ((hasDerivAt_id (div i)).sub_const (div i)).mul_const (exp (-r * t i)) |>.const_sub s0
    simpa using this
  have hval : s0 - (div i - div i) * exp (-r * t i) = s0 := by ring
  have hg := dfs_call_hasDerivAt_spot s0 K r σ T hS hK hσ hT
  rw [← hval] at hg
  have hc := hg.comp (div i) hin
  convert hc using 1
  · funext x; simp only [Function.comp, escrowedCall, hspot]
  · rw [hval]; ring

/-! The card's worked numbers, exactly, in millionths of a dollar. -/

-- 1-year gap C - P: 9.259211 - 6.308542 = 2.950669.
example : (9259211 : ℤ) - 6308542 = 2950669 := by norm_num
-- D(1) = 100 - 95.122942 - 2.950669 = 1.926389.
example : (100000000 : ℤ) - 95122942 - 2950669 = 1926389 := by norm_num
-- 2-year gap 13.566895 - 7.901085 = 5.665810, and D(2) = 100 - 90.483742 - 5.665810 = 3.850448.
example : (13566895 : ℤ) - 7901085 = 5665810 := by norm_num
example : (100000000 : ℤ) - 90483742 - 5665810 = 3850448 := by norm_num
-- 3-year gap 16.894352 - 8.732974 = 8.161378, and D(3) = 100 - 86.070798 - 8.161378 = 5.767824.
example : (16894352 : ℤ) - 8732974 = 8161378 := by norm_num
example : (100000000 : ℤ) - 86070798 - 8161378 = 5767824 := by norm_num
-- 3-year swap strike: 2.000000 + 2.100000 + 2.200000 = 6.300000.
example : (2000000 : ℤ) + 2100000 + 2200000 = 6300000 := by norm_num
-- Dividend delta table, total for the 2-year call: -0.6156 - 0.5856 = -1.2012 (ten-thousandths).
example : (-6156 : ℤ) - 5856 = -12012 := by norm_num

#print axioms dividend_future_from_parity_strip
#print axioms dividend_swap_strike_eq_sum_of_futures
#print axioms dfs_phi_eq
#print axioms dfs_phi_continuous
#print axioms dfs_N_eq_integral
#print axioms dfs_N_sub
#print axioms dfs_N_hasDerivAt
#print axioms dfs_key
#print axioms dfs_call_hasDerivAt_spot
#print axioms call_dividend_delta
