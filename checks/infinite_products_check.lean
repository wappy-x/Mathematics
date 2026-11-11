-- Infinite products: a product of factors 1 + a n with no zero factor and with sizes ‖a n‖ of finite total settles on a nonzero limit, for parts 0 or more that limit lies between 1 + S and e^S, and sin(πz) is πz times the product of 1 - z^2/n^2.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.EulerSineProd
import Mathlib.Analysis.SpecialFunctions.Log.Summable
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.NormNum

open Filter Topology Finset

/-- The product test. Take complex small parts a 0, a 1, a 2, … with no factor 1 + a n equal to
zero. If the sizes ‖a n‖ have a finite total, the partial products (1 + a 0)(1 + a 1)…(1 + a (N-1))
settle on a limit P, and that limit is not zero. -/
theorem product_converges_of_summable_sizes (a : ℕ → ℂ)
    (h_sizes : Summable fun n => ‖a n‖) (h_no_zero : ∀ n, 1 + a n ≠ 0) :
    ∃ P : ℂ, P ≠ 0 ∧
      Tendsto (fun N => ∏ n ∈ range N, (1 + a n)) atTop (𝓝 P) := by
  have hl := Complex.summable_log_one_add_of_summable (Summable.of_norm h_sizes)
  exact ⟨_, Complex.exp_ne_zero _,
    (Complex.hasProd_of_hasSum_log h_no_zero hl.hasSum).tendsto_prod_nat⟩

/-- Positive parts. If every a n is 0 or more and their total S is finite, the partial products
settle on a limit P with 1 + S ≤ P ≤ e^S. -/
theorem product_between_one_add_sum_and_exp (a : ℕ → ℝ)
    (h_nonneg : ∀ n, 0 ≤ a n) (h_sum : Summable a) :
    ∃ P : ℝ, Tendsto (fun N => ∏ n ∈ range N, (1 + a n)) atTop (𝓝 P) ∧
      1 + ∑' n, a n ≤ P ∧ P ≤ Real.exp (∑' n, a n) := by
  have hpos : ∀ n, 0 < 1 + a n := fun n => by linarith [h_nonneg n]
  have hl := Real.summable_log_one_add_of_summable h_sum
  have ht := (Real.hasProd_of_hasSum_log hpos hl.hasSum).tendsto_prod_nat
  refine ⟨_, ht, ?_, ?_⟩
  · refine le_of_tendsto_of_tendsto' (h_sum.hasSum.tendsto_sum_nat.const_add 1) ht ?_
    intro N
    induction N with
    | zero => simp
    | succ N ih =>
      rw [Finset.sum_range_succ, Finset.prod_range_succ]
      have h0 : 0 ≤ ∑ i ∈ range N, a i := Finset.sum_nonneg fun i _ => h_nonneg i
      have h1 : 1 ≤ ∏ i ∈ range N, (1 + a i) := by linarith
      nlinarith [h_nonneg N]
  · exact le_of_tendsto_of_tendsto' ht
      (Real.continuous_exp.continuousAt.tendsto.comp h_sum.hasSum.tendsto_sum_nat)
      (fun N => Real.prod_one_add_le_exp_sum _ h_nonneg)

/-- Euler's sine product. For every complex number z, πz times the product of 1 - z^2/n^2 over
n = 1, 2, …, N tends to sin(πz) as N grows. -/
theorem sin_eq_euler_product (z : ℂ) :
    Tendsto (fun N => (Real.pi : ℂ) * z * ∏ n ∈ range N, (1 - z ^ 2 / ((n : ℂ) + 1) ^ 2))
      atTop (𝓝 (Complex.sin (Real.pi * z))) := by
  exact Complex.tendsto_euler_sin_prod z

-- The 1/n^2 account, years 1, 2, 3: 2, then 5/2, then 25/9 (the card's 2.00, 2.50, 2.78).
example : ∏ n ∈ range 1, (1 + 1 / ((n : ℚ) + 1) ^ 2) = 2 := by
  norm_num [Finset.prod_range_succ]
example : ∏ n ∈ range 2, (1 + 1 / ((n : ℚ) + 1) ^ 2) = 5 / 2 := by
  norm_num [Finset.prod_range_succ]
example : ∏ n ∈ range 3, (1 + 1 / ((n : ℚ) + 1) ^ 2) = 25 / 9 := by
  norm_num [Finset.prod_range_succ]
-- The 1/n account telescopes to N + 1: 11 and 101 after 10 and 100 years.
example : ∏ n ∈ range 10, (1 + 1 / ((n : ℚ) + 1)) = 11 := by
  norm_num [Finset.prod_range_succ]
example : ∏ n ∈ range 100, (1 + 1 / ((n : ℚ) + 1)) = 101 := by
  norm_num [Finset.prod_range_succ]
-- Losses of 1/(n + 1) for 100 years leave 1/101, the card's 0.009901.
example : ∏ n ∈ range 100, (1 - 1 / ((n : ℚ) + 2)) = 1 / 101 := by
  norm_num [Finset.prod_range_succ]
-- At z = 3 the factor for n = 3 is 1 - 9/9 = 0, so the sine product is 0 there.
example : (1 : ℚ) - 3 ^ 2 / 3 ^ 2 = 0 := by
  norm_num

#print axioms product_converges_of_summable_sizes
#print axioms product_between_one_add_sum_and_exp
#print axioms sin_eq_euler_product
