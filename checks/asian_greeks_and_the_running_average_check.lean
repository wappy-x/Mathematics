-- Asian Greeks and the average already banked: once k of n fixings are in, the average call is exactly the open weight (n - k)/n times a call on the open average struck at K* = (K - (k/n)·ā)/w, it becomes a sure-paying forward when K* ≤ 0, and the moment-matched (Lévy) price has delta e^(-rτ) w (M₁/S) N(d₁).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals

open Real MeasureTheory ProbabilityTheory Finset

/-! ## The banked part

Fixings are numbered `0, 1, …, n - 1`; `x i` is the price read at fixing `i`. The first `k`
are already in; the `m = n - k` from `k` to `n - 1` are still to come. -/

/-- The final average of all `n` fixings, `A`. -/
noncomputable def finalAvg (x : ℕ → ℝ) (n : ℕ) : ℝ := (∑ i ∈ range n, x i) / n

/-- `ā`: the average of the `k` fixings already in. -/
noncomputable def bankedAvg (x : ℕ → ℝ) (k : ℕ) : ℝ := (∑ i ∈ range k, x i) / k

/-- `A_rest`: the average of the `m = n - k` fixings still to come. -/
noncomputable def openAvg (x : ℕ → ℝ) (k n : ℕ) : ℝ :=
  (∑ i ∈ Ico k n, x i) / ((n - k : ℕ) : ℝ)

/-- `w = m/n`: the weight of the open part. -/
noncomputable def openWeight (k n : ℕ) : ℝ := ((n - k : ℕ) : ℝ) / n

/-- `K* = (K - (k/n) ā) / w`: the strike the open average must beat. -/
noncomputable def newStrike (x : ℕ → ℝ) (k n : ℕ) (K : ℝ) : ℝ :=
  (K - (k : ℝ) / n * bankedAvg x k) / openWeight k n

/-- Helper: the final average split into banked and open parts. -/
lemma finalAvg_split (x : ℕ → ℝ) (k n : ℕ) (hk : k < n) :
    finalAvg x n = (k : ℝ) / n * bankedAvg x k + openWeight k n * openAvg x k n := by
  have hn : (0 : ℝ) < n := by exact_mod_cast (lt_of_le_of_lt (Nat.zero_le k) hk)
  have hm : (0 : ℝ) < ((n - k : ℕ) : ℝ) := by exact_mod_cast Nat.sub_pos_of_lt hk
  have hsplit := Finset.sum_range_add_sum_Ico x hk.le
  unfold finalAvg bankedAvg openWeight openAvg
  rw [← hsplit]
  rcases Nat.eq_zero_or_pos k with h0 | hpos
  · subst h0
    field_simp
    simp
  · have hk' : (0 : ℝ) < k := by exact_mod_cast hpos
    field_simp

/-- Helper: the call payoff on the full average equals the open weight times the payoff on
the open average at the new strike, before taking the positive part. -/
lemma finalAvg_sub_eq (x : ℕ → ℝ) (k n : ℕ) (hk : k < n) (K : ℝ) :
    finalAvg x n - K = openWeight k n * (openAvg x k n - newStrike x k n K) := by
  have hn : (0 : ℝ) < n := by exact_mod_cast (lt_of_le_of_lt (Nat.zero_le k) hk)
  have hm : (0 : ℝ) < ((n - k : ℕ) : ℝ) := by exact_mod_cast Nat.sub_pos_of_lt hk
  have hw : openWeight k n ≠ 0 := by unfold openWeight; positivity
  rw [finalAvg_split x k n hk, newStrike]
  field_simp
  ring

/-- **The banked fixings turn the rest into a smaller Asian** (The formula, "The banked part";
Why it works, Step 4). With `n` fixings in all, `k < n` of them already in, any fixing prices and
any strike `K`: the final average splits as `A = (k/n) ā + w A_rest`, and the call's payoff is
the open weight times a call on the open average struck at the new strike,
`(A - K)⁺ = w (A_rest - K*)⁺`. -/
theorem banked_fixings_leave_smaller_asian
    (x : ℕ → ℝ) (k n : ℕ) (hk : k < n) (K : ℝ) :
    finalAvg x n = (k : ℝ) / n * bankedAvg x k + openWeight k n * openAvg x k n ∧
      max (finalAvg x n - K) 0
        = openWeight k n * max (openAvg x k n - newStrike x k n K) 0 := by
  refine ⟨finalAvg_split x k n hk, ?_⟩
  have hn : (0 : ℝ) < n := by exact_mod_cast (lt_of_le_of_lt (Nat.zero_le k) hk)
  have hw : 0 ≤ openWeight k n := by unfold openWeight; positivity
  rw [finalAvg_sub_eq x k n hk K, mul_max_of_nonneg _ _ hw, mul_zero]

/-- **New strike at or below zero: the call pays for certain** (When it holds, "New strike above
zero"; Where you meet it, "The swap next door"). With `k < n` fixings in, prices that cannot go
below zero, and a banked average so high that `K* ≤ 0`: the payoff is the straight line
`(A - K)⁺ = w (A_rest - K*)`, an average-price forward, with no kink left. -/
theorem nonpos_new_strike_pays_for_certain
    (x : ℕ → ℝ) (k n : ℕ) (hk : k < n) (K : ℝ)
    (hx : ∀ i ∈ Ico k n, 0 ≤ x i) (hKs : newStrike x k n K ≤ 0) :
    max (finalAvg x n - K) 0 = openWeight k n * (openAvg x k n - newStrike x k n K) := by
  have hm : (0 : ℝ) < ((n - k : ℕ) : ℝ) := by exact_mod_cast Nat.sub_pos_of_lt hk
  have hw : 0 ≤ openWeight k n := by unfold openWeight; positivity
  have hA : 0 ≤ openAvg x k n := by
    unfold openAvg
    exact div_nonneg (Finset.sum_nonneg hx) hm.le
  rw [finalAvg_sub_eq x k n hk K]
  exact max_eq_left (mul_nonneg hw (by linarith))

/-! ## The moment-matched price and its delta

The `m` fixings still to come sit at times `t i > 0` years from today. Jet fuel is `S`; the forward
for fixing `i` is `F_i = S e^(r t_i)`, so the whole curve moves in proportion with `S`. -/

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `M₁ = (1/m) Σ F_i`: the expected open average. -/
noncomputable def asianM1 {m : ℕ} (S r : ℝ) (t : Fin m → ℝ) : ℝ :=
  (∑ i, S * exp (r * t i)) / m

/-- `M₂ = (1/m²) Σ_i Σ_j F_i F_j e^(σ² min(t_i, t_j))`: the expected square of the open average. -/
noncomputable def asianM2 {m : ℕ} (S r σ : ℝ) (t : Fin m → ℝ) : ℝ :=
  (∑ i, ∑ j, S * exp (r * t i) * (S * exp (r * t j)) * exp (σ ^ 2 * min (t i) (t j))) / (m : ℝ) ^ 2

/-- `v = √(ln(M₂/M₁²))`: the log-spread of the matched lognormal. -/
noncomputable def asianV {m : ℕ} (S r σ : ℝ) (t : Fin m → ℝ) : ℝ :=
  √(log (asianM2 S r σ t / asianM1 S r t ^ 2))

/-- `d₁ = (ln(M₁/K*) + v²/2)/v`. -/
noncomputable def levyD1 {m : ℕ} (S r σ : ℝ) (t : Fin m → ℝ) (Ks : ℝ) : ℝ :=
  (log (asianM1 S r t / Ks) + asianV S r σ t ^ 2 / 2) / asianV S r σ t

/-- The moment-matched (Lévy) price `V = e^(-rτ) w [M₁ N(d₁) - K* N(d₁ - v)]`, with discount time
`τ`, open weight `w` and new strike `K*`. -/
noncomputable def levyAsianCall {m : ℕ} (S r σ : ℝ) (t : Fin m → ℝ) (τ w Ks : ℝ) : ℝ :=
  exp (-r * τ) * w *
    (asianM1 S r t * stdNormalCDF (levyD1 S r σ t Ks)
      - Ks * stdNormalCDF (levyD1 S r σ t Ks - asianV S r σ t))

/-- Helper: `N(x)` as the integral of the standard normal density over `(-∞, x]`. -/
lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ y in Set.Iic x, gaussianPDFReal 0 1 y := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg (fun y => gaussianPDFReal_nonneg _ _ _))]

/-- Helper: the standard normal density is continuous. -/
lemma continuous_stdNormalPDF : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]
  fun_prop

/-- Helper: the slope of `N` is the standard normal density. -/
lemma hasDerivAt_stdNormalCDF (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hint : ∀ a : ℝ, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have h2 : stdNormalCDF = fun u => stdNormalCDF 0 + ∫ y in (0 : ℝ)..u, gaussianPDFReal 0 1 y := by
    funext u
    rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
      ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint u)]
    ring
  rw [h2]
  exact (intervalIntegral.integral_hasDerivAt_right
    ((integrable_gaussianPDFReal 0 1).intervalIntegrable)
    (continuous_stdNormalPDF.stronglyMeasurableAtFilter _ _)
    continuous_stdNormalPDF.continuousAt).const_add _

/-- Helper: `M₁` is proportional to `S`. -/
lemma asianM1_eq {m : ℕ} (y r : ℝ) (t : Fin m → ℝ) :
    asianM1 y r t = y * asianM1 1 r t := by
  unfold asianM1
  simp only [one_mul]
  rw [← Finset.mul_sum, mul_div_assoc]

/-- Helper: `M₂` is proportional to `S²`. -/
lemma asianM2_eq {m : ℕ} (y r σ : ℝ) (t : Fin m → ℝ) :
    asianM2 y r σ t = y ^ 2 * asianM2 1 r σ t := by
  unfold asianM2
  rw [← mul_div_assoc, Finset.mul_sum]
  congr 1
  refine Finset.sum_congr rfl (fun i _ => ?_)
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl (fun j _ => ?_)
  ring

/-- Helper: the log-spread `v` does not depend on `S`. -/
lemma asianV_eq {m : ℕ} (y r σ : ℝ) (t : Fin m → ℝ) (hy : y ≠ 0) :
    asianV y r σ t = asianV 1 r σ t := by
  unfold asianV
  rw [asianM2_eq y, asianM1_eq y r t, mul_pow, mul_div_mul_left _ _ (pow_ne_zero 2 hy)]

/-- Helper: `M₁` at `S = 1` is positive when a fixing is still to come. -/
lemma asianM1_one_pos {m : ℕ} (hm : 0 < m) (r : ℝ) (t : Fin m → ℝ) : 0 < asianM1 1 r t := by
  unfold asianM1
  have : (0 : ℝ) < m := by exact_mod_cast hm
  have hne : (Finset.univ : Finset (Fin m)).Nonempty := ⟨⟨0, hm⟩, Finset.mem_univ _⟩
  exact div_pos (Finset.sum_pos (fun i _ => by positivity) hne) this

/-- Helper: the density identity `N'(d₁ - v) = (M₁/K*) N'(d₁)`. -/
lemma stdNormalPDF_shift (D v a : ℝ) (hv : v ≠ 0) (ha : 0 < a)
    (hD : D = (log a + v ^ 2 / 2) / v) :
    gaussianPDFReal 0 1 (D - v) = a * gaussianPDFReal 0 1 D := by
  have hDv : D * v = log a + v ^ 2 / 2 := by rw [hD]; field_simp
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  rw [show -(D - v) ^ 2 / 2 = log a + -D ^ 2 / 2 by linear_combination hDv, exp_add, exp_log ha]
  ring

/-- **Asian delta from the moment-matched formula** (The formula, "Its Greeks"; detailed proof,
"Delta and gamma"). With one volatility `σ > 0` for every fixing, all fixings driven by one
random path, at least one fixing still to come, every open fixing at a time `t i > 0`, jet fuel
`S > 0` with the forward curve moving in proportion, and a new strike `K* > 0`: the slope of the
moment-matched price in `S` is `Δ = e^(-rτ) w (M₁/S) N(d₁)`. -/
theorem levy_asian_delta
    {m : ℕ} (hm : 0 < m) (S r σ τ w Ks : ℝ) (t : Fin m → ℝ)
    (hS : 0 < S) (hσ : 0 < σ) (ht : ∀ i, 0 < t i) (hKs : 0 < Ks) :
    HasDerivAt (fun y => levyAsianCall y r σ t τ w Ks)
      (exp (-r * τ) * w * (asianM1 S r t / S) * stdNormalCDF (levyD1 S r σ t Ks)) S := by
  set c := asianM1 1 r t with hc_def
  set v := asianV 1 r σ t with hv_def
  have hc : 0 < c := asianM1_one_pos hm r t
  set D : ℝ → ℝ := fun y => (log (y * c / Ks) + v ^ 2 / 2) / v with hD_def
  have hlog : HasDerivAt (fun y => log (y * c / Ks)) (1 / S) S := by
    have h := (((hasDerivAt_id' S).mul_const c).div_const Ks).log
      (show S * c / Ks ≠ 0 by positivity)
    convert h using 1
    field_simp
  have hD : HasDerivAt D (1 / S / v) S := (hlog.add_const (v ^ 2 / 2)).div_const v
  have hN1 := (hasDerivAt_stdNormalCDF (D S)).comp S hD
  have hN2 := (hasDerivAt_stdNormalCDF (D S - v)).comp S (hD.sub_const v)
  have H := ((((hasDerivAt_id S).mul_const c).mul hN1).sub (hN2.const_mul Ks)).const_mul
    (exp (-r * τ) * w)
  refine (H.congr_of_eventuallyEq ?_).congr_deriv ?_
  · filter_upwards [Ioi_mem_nhds hS] with y hy
    simp only [levyAsianCall, levyD1, Pi.mul_apply, Pi.sub_apply, Function.comp_apply, id_eq]
    rw [asianV_eq y r σ t (ne_of_gt hy), asianM1_eq y r t]
  · rw [levyD1, asianV_eq S r σ t hS.ne', asianM1_eq S r t, ← hc_def, ← hv_def,
      show (log (S * c / Ks) + v ^ 2 / 2) / v = D S from rfl]
    simp only [id_eq, Function.comp_apply]
    by_cases hv : v = 0
    · simp only [hv, div_zero, mul_zero, sub_zero, add_zero, one_mul]
      field_simp
    · rw [stdNormalPDF_shift (D S) v (S * c / Ks) hv (by positivity) rfl]
      generalize D S = d
      field_simp
      ring

-- Worked numbers, by hand: 26 of 52 weekly fixings in at an average of $103.
-- Settled money: (26/52) × 103 = 51.50.
example : ((26 : ℚ) / 52) * 103 = 103 / 2 := by norm_num
-- Open weight w = 26/52 = 0.50.
example : ((52 - 26 : ℚ)) / 52 = 1 / 2 := by norm_num
-- New strike K* = (100 - 51.50) / 0.5 = 97.
example : ((100 : ℚ) - 26 / 52 * 103) / (26 / 52) = 97 := by norm_num
-- The same, through the card's own definitions, with every banked fixing at $103.
example : newStrike (fun _ => 103) 26 52 100 = 97 := by
  simp [newStrike, bankedAvg, openWeight, Finset.sum_const]
  norm_num
-- The picture: the true payoff 0.5 (A_rest - 97)⁺ at A_rest = 100, 105, 110, 115 is
-- 1.50, 4.00, 6.50, 9.00; and it matches (A - 100)⁺ with A = 51.50 + 0.5 A_rest.
example : (1 / 2 : ℚ) * (100 - 97) = 3 / 2 ∧ (1 / 2 : ℚ) * (105 - 97) = 4 ∧
    (1 / 2 : ℚ) * (110 - 97) = 13 / 2 ∧ (1 / 2 : ℚ) * (115 - 97) = 9 := by norm_num
example : (103 / 2 : ℚ) + 1 / 2 * 105 - 100 = 1 / 2 * (105 - 97) := by norm_num
-- Banked at $205: (100 - 26/52 × 205) / 0.5 = -5, so the call pays for certain.
example : ((100 : ℚ) - 26 / 52 * 205) / (26 / 52) = -5 := by norm_num
-- What breaks: subtracting the banked $51.50 without dividing by the weight leaves 48.50, not 97.
example : (100 : ℚ) - 26 / 52 * 103 = 97 / 2 := by norm_num

#print axioms finalAvg_split
#print axioms finalAvg_sub_eq
#print axioms banked_fixings_leave_smaller_asian
#print axioms nonpos_new_strike_pays_for_certain
#print axioms stdNormalCDF_eq_integral
#print axioms continuous_stdNormalPDF
#print axioms hasDerivAt_stdNormalCDF
#print axioms asianM1_eq
#print axioms asianM2_eq
#print axioms asianV_eq
#print axioms asianM1_one_pos
#print axioms stdNormalPDF_shift
#print axioms levy_asian_delta
