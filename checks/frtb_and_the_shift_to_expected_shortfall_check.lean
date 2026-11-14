-- Market-risk capital: the bell-curve and Student t tail integrals behind expected shortfall, and the Basel liquidity-horizon cascade equal to stretching each factor to its own horizon.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Fin.VecNotation

open MeasureTheory Real

open Filter Topology in
/-- A tail integral from an antiderivative, when the integrand is continuous and nonnegative
for nonnegative arguments. -/
lemma tail_integral_of_deriv (G g : ℝ → ℝ) (q L : ℝ) (hG : ∀ x, HasDerivAt G (g x) x)
    (hg : Continuous g) (hpos : ∀ x, 0 ≤ x → 0 ≤ g x) (hlim : Tendsto G atTop (𝓝 L)) :
    ∫ x in Set.Ioi q, g x = L - G q := by
  refine integral_Ioi_of_hasDerivAt_of_tendsto' (fun x _ => hG x) ?_ hlim
  have h1 : IntegrableOn g (Set.Ioi (max q 0)) :=
    integrableOn_Ioi_deriv_of_nonneg' (fun x _ => hG x)
      (fun x hx => hpos x (le_trans (le_max_right _ _) (le_of_lt hx))) hlim
  have h2 : IntegrableOn g (Set.Ioc q (max q 0)) :=
    (hg.integrableOn_Icc).mono_set Set.Ioc_subset_Icc_self
  rw [← Set.Ioc_union_Ioi_eq_Ioi (le_max_left q 0)]
  exact h2.union h1

#print axioms tail_integral_of_deriv

open Filter Topology in
/-- The Student t tail integral with constant `1`. -/
lemma student_t_tail_integral_one (ν q : ℝ) (hν : 1 < ν) :
    ∫ x in Set.Ioi q, x * (1 + x ^ 2 / ν) ^ (-(ν + 1) / 2)
      = (ν + q ^ 2) * (1 + q ^ 2 / ν) ^ (-(ν + 1) / 2) / (ν - 1) := by
  have hν0 : 0 < ν := by linarith
  have hν1 : ν - 1 ≠ 0 := by linarith
  have hA : ∀ x : ℝ, 0 < 1 + x ^ 2 / ν := fun x => by positivity
  rw [tail_integral_of_deriv (fun x => -(ν / (ν - 1)) * (1 + x ^ 2 / ν) ^ ((1 - ν) / 2))
    (fun x => x * (1 + x ^ 2 / ν) ^ (-(ν + 1) / 2)) q 0]
  · have e : (1 - ν) / 2 = -(ν + 1) / 2 + 1 := by ring
    rw [e, rpow_add_one (hA q).ne']
    field_simp
    ring
  · intro x
    have hd : HasDerivAt (fun x : ℝ => 1 + x ^ 2 / ν) (2 * x / ν) x := by
      have := ((hasDerivAt_pow 2 x).div_const ν).const_add 1
      convert this using 1
      ring
    have hr := (hd.rpow_const (p := (1 - ν) / 2) (Or.inl (hA x).ne')).const_mul (-(ν / (ν - 1)))
    convert hr using 1
    rw [show (1 - ν) / 2 - 1 = -(ν + 1) / 2 by ring]
    field_simp
    ring
  · exact continuous_id.mul ((continuous_const.add ((continuous_pow 2).div_const ν)).rpow_const
      (fun x => Or.inl (hA x).ne'))
  · intro x hx
    exact mul_nonneg hx (rpow_nonneg (hA x).le _)
  · have hA' : Tendsto (fun x : ℝ => 1 + x ^ 2 / ν) atTop atTop :=
      tendsto_atTop_add_const_left _ 1 ((tendsto_pow_atTop two_ne_zero).atTop_div_const hν0)
    have hp : Tendsto (fun x : ℝ => (1 + x ^ 2 / ν) ^ ((1 - ν) / 2)) atTop (𝓝 0) := by
      have := (tendsto_rpow_neg_atTop (y := (ν - 1) / 2) (by linarith)).comp hA'
      convert this using 2
      simp only [Function.comp]
      congr 1
      ring
    simpa using hp.const_mul (-(ν / (ν - 1)))

#print axioms student_t_tail_integral_one

/-- Expected shortfall of a bell-curve loss: if the ten-day loss is `σ Z` with `Z` a standard
normal draw, the average loss past the line `z` over the tail of size `1 - α`,
`σ / (1 - α) * ∫_z^∞ x φ(x) dx`, equals `σ φ(z) / (1 - α)`, where
`φ(x) = e^{-x²/2} / √(2π)` is the bell curve's height. -/
theorem normal_expected_shortfall_eq (σ α z : ℝ) :
    σ / (1 - α) * ∫ x in Set.Ioi z, x * (exp (-x ^ 2 / 2) / sqrt (2 * π))
      = σ * (exp (-z ^ 2 / 2) / sqrt (2 * π)) / (1 - α) := by
  have hlim : Filter.Tendsto (fun x : ℝ => -(exp (-x ^ 2 / 2) / sqrt (2 * π)))
      Filter.atTop (nhds 0) := by
    have h1 : Filter.Tendsto (fun x : ℝ => -x ^ 2 / 2) Filter.atTop Filter.atBot :=
      (Filter.tendsto_neg_atTop_atBot.comp (Filter.tendsto_pow_atTop two_ne_zero)).atBot_div_const
        (by norm_num)
    have := ((tendsto_exp_atBot.comp h1).div_const (sqrt (2 * π))).neg
    simpa using this
  rw [tail_integral_of_deriv (fun x => -(exp (-x ^ 2 / 2) / sqrt (2 * π)))
    (fun x => x * (exp (-x ^ 2 / 2) / sqrt (2 * π))) z 0 _ _ _ hlim]
  · ring
  · intro x
    have := (((hasDerivAt_pow 2 x).neg.div_const 2).exp.div_const (sqrt (2 * π))).neg
    convert this using 1
    simp only [Pi.neg_apply]
    ring
  · fun_prop
  · intro x hx
    positivity

/-- The tail integral of a Student t loss: for `ν > 1` and the t density
`f(x) = c (1 + x²/ν)^{-(ν+1)/2}`, the integral of `x f(x)` from the line `q` to infinity is
`(ν + q²) f(q) / (ν - 1)`. Dividing by `1 - α` gives the t loss's expected shortfall. -/
theorem student_t_tail_integral (ν c q : ℝ) (hν : 1 < ν) :
    ∫ x in Set.Ioi q, x * (c * (1 + x ^ 2 / ν) ^ (-(ν + 1) / 2))
      = (ν + q ^ 2) * (c * (1 + q ^ 2 / ν) ^ (-(ν + 1) / 2)) / (ν - 1) := by
  have e : (fun x : ℝ => x * (c * (1 + x ^ 2 / ν) ^ (-(ν + 1) / 2)))
      = fun x => c * (x * (1 + x ^ 2 / ν) ^ (-(ν + 1) / 2)) := by
    funext x; ring
  rw [e, integral_const_mul, student_t_tail_integral_one ν q hν]
  ring

/-- The Basel horizon ladder `LH_1, …, LH_5` = 10, 20, 40, 60, 120 days. -/
def liquidityLadder : Fin 5 → ℕ := ![10, 20, 40, 60, 120]

/-- The liquidity rule (Basel MAR33.4) equals factor-by-factor stretching. Take independent
bell-curve risk factors, each with ten-day standard deviation `s i` and mapped to a horizon
`h i` on the ladder 10, 20, 40, 60, 120 days, so that the ten-day ES of any subset of factors is
`k √(Σ s_i²)` over that subset (with `k ≥ 0`, here 2.338). Then
`√(ES_T(P)² + Σ_{j=2}^{5} (ES_T(P,j) √((LH_j - LH_{j-1}) / T))²) = k √(Σ_i s_i² h_i / T)`
with `T = 10`: each factor's variance stretched to its own horizon. -/
theorem liquidity_cascade_eq_factor_stretch {ι : Type*} (F : Finset ι) (s : ι → ℝ)
    (h : ι → ℕ) (hh : ∀ i ∈ F, ∃ j, h i = liquidityLadder j) (k : ℝ) (hk : 0 ≤ k) :
    sqrt ((k * sqrt (∑ i ∈ F, s i ^ 2)) ^ 2
        + ∑ j : Fin 4,
            (k * sqrt (∑ i ∈ F.filter (fun i => liquidityLadder j.succ ≤ h i), s i ^ 2)
              * sqrt (((liquidityLadder j.succ : ℝ) - liquidityLadder j.castSucc) / 10)) ^ 2)
      = k * sqrt (∑ i ∈ F, s i ^ 2 * (h i : ℝ) / 10) := by
  have hd : ∀ j : Fin 4, 0 ≤ ((liquidityLadder j.succ : ℝ) - liquidityLadder j.castSucc) / 10 := by
    intro j; fin_cases j <;> norm_num [liquidityLadder]
  have hterm : ∀ j : Fin 4,
      (k * sqrt (∑ i ∈ F.filter (fun i => liquidityLadder j.succ ≤ h i), s i ^ 2)
        * sqrt (((liquidityLadder j.succ : ℝ) - liquidityLadder j.castSucc) / 10)) ^ 2
      = k ^ 2 * ∑ i ∈ F, (if liquidityLadder j.succ ≤ h i then
          s i ^ 2 * (((liquidityLadder j.succ : ℝ) - liquidityLadder j.castSucc) / 10) else 0) := by
    intro j
    rw [mul_pow, mul_pow, sq_sqrt (Finset.sum_nonneg (fun i _ => sq_nonneg _)), sq_sqrt (hd j),
      Finset.sum_filter, mul_assoc, Finset.sum_mul]
    congr 1
    apply Finset.sum_congr rfl
    intro i _
    split_ifs <;> simp
  rw [Finset.sum_congr rfl (fun j _ => hterm j), ← Finset.mul_sum, mul_pow,
    sq_sqrt (Finset.sum_nonneg (fun i _ => sq_nonneg _)), ← mul_add, Finset.sum_comm,
    ← Finset.sum_add_distrib]
  rw [sqrt_mul (sq_nonneg k), sqrt_sq hk]
  congr 2
  apply Finset.sum_congr rfl
  intro i hi
  obtain ⟨m, hm⟩ := hh i hi
  rw [hm]
  fin_cases m <;> simp [Fin.sum_univ_four, liquidityLadder] <;> norm_num <;> ring

-- The book's variances: equity 4, IG credit 4, HY credit 1 ($ million squared), total 9.
example : (4 : ℕ) + 4 + 1 = 9 := by decide

-- Stretched variances: 4·10/10 + 4·40/10 + 1·60/10 = 26.
example : (4 : ℚ) * 10 / 10 + 4 * 40 / 10 + 1 * 60 / 10 = 26 := by norm_num

-- The cascade on the book, in units of k²: subset variances 9, 5, 5, 1, 0 weighted by
-- 1 and the extra days over 10 also total 26.
example : (9 : ℚ) + 5 * (20 - 10) / 10 + 5 * (40 - 20) / 10 + 1 * (60 - 40) / 10
    + 0 * (120 - 60) / 10 = 26 := by norm_num

-- Sum of the stretched variances as in the proof: 4·1 + 4·4 + 1·6 = 26.
example : 4 * 1 + 4 * 4 + 1 * 6 = 26 := by decide

#print axioms normal_expected_shortfall_eq
#print axioms student_t_tail_integral
#print axioms liquidity_cascade_eq_factor_stretch
