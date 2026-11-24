-- Kernel density estimation: a kernel estimate built from any density kernel is itself a density, its average is the true density blurred by the kernel, and the bandwidth (R(K) / (σ_K⁴ R(f'') n))^(1/5) minimises the leading error h⁴ σ_K⁴ R(f'')/4 + R(K)/(n h).
import Mathlib.MeasureTheory.Measure.Haar.NormedSpace
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Group.Integral

open MeasureTheory

/-- A kernel density estimate is a true density. If the kernel `K` is a density (never negative,
integrable, total area 1), then for any `n ≥ 1` data points `x₁, …, xₙ` and any bandwidth `h > 0`,
the estimate `f̂_h(t) = (1/(n h)) ∑ᵢ K((t - xᵢ)/h)` is never negative, is integrable, and has
total area 1: each data point contributes a bump of area `1/n`. -/
theorem kde_is_density {n : ℕ} (hn : 0 < n) (x : Fin n → ℝ) {h : ℝ} (hh : 0 < h)
    (K : ℝ → ℝ) (hK0 : ∀ u, 0 ≤ K u) (hKint : Integrable K) (hK1 : ∫ u, K u = 1) :
    (∀ t, 0 ≤ (1 / (n * h)) * ∑ i, K ((t - x i) / h)) ∧
      Integrable (fun t => (1 / (n * h)) * ∑ i, K ((t - x i) / h)) ∧
      ∫ t, (1 / (n * h)) * ∑ i, K ((t - x i) / h) = 1 := by
  have hn' : (0:ℝ) < n := by exact_mod_cast hn
  have hbump : ∀ i, Integrable (fun t => K ((t - x i) / h)) :=
    fun i => (hKint.comp_div hh.ne').comp_sub_right (x i)
  have hbumpint : ∀ i, ∫ t, K ((t - x i) / h) = h := by
    intro i
    rw [integral_sub_right_eq_self (fun t => K (t / h)) (x i), Measure.integral_comp_div, hK1,
      abs_of_pos hh]
    simp
  refine ⟨fun t => ?_, ?_, ?_⟩
  · exact mul_nonneg (by positivity) (Finset.sum_nonneg fun i _ => hK0 _)
  · exact (integrable_finsetSum _ fun i _ => hbump i).const_mul _
  · rw [integral_const_mul, integral_finsetSum _ fun i _ => hbump i]
    simp only [hbumpint, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    field_simp

/-- The estimate's average is the true density blurred by the kernel. One bump
`K_h(x - y) = K((x - y)/h)/h` averaged against a density `f` equals `∫ K(u) f(x - h u) du`
(substitute `u = (x - y)/h`); this is `E f̂_h(x)`, the starting point of the `h²` bias expansion. -/
theorem kde_mean_eq_kernel_blur (K f : ℝ → ℝ) {h : ℝ} (hh : 0 < h) (x : ℝ) :
    ∫ y, (1 / h) * K ((x - y) / h) * f y = ∫ u, K u * f (x - h * u) := by
  set φ : ℝ → ℝ := fun u => K u * f (x - h * u) with hφ
  have key : ∀ y, (1 / h) * K ((x - y) / h) * f y = (1 / h) * φ ((y - x) / (-h)) := by
    intro y
    simp only [hφ]
    have : x - h * ((y - x) / (-h)) = y := by field_simp; ring
    have h2 : (y - x) / (-h) = (x - y) / h := by rw [div_neg, ← neg_div, neg_sub]
    rw [this, h2]; ring
  simp_rw [key]
  rw [integral_const_mul, integral_sub_right_eq_self (fun z => φ (z / (-h))) x,
    Measure.integral_comp_div, abs_neg, abs_of_pos hh, smul_eq_mul, hφ]
  field_simp

/-- Balancing bias and noise. With `σ_K²` the kernel's variance, `R(K)` its total squared height,
`R(f'')` the total squared bend of the true density and `n` points, the leading error
`MISE(h) ≈ h⁴ σ_K⁴ R(f'')/4 + R(K)/(n h)` is smallest over all bandwidths `h > 0` at
`h* = (R(K) / (σ_K⁴ R(f'') n))^(1/5)`. -/
theorem amise_minimized_at_optimal_bandwidth (σK2 RK Rf2 : ℝ) {n : ℕ} (hn : 0 < n)
    (hσ : 0 < σK2) (hRK : 0 < RK) (hRf : 0 < Rf2) :
    0 < (RK / (σK2 ^ 2 * Rf2 * n)) ^ (1 / 5 : ℝ) ∧
      ∀ h : ℝ, 0 < h →
        ((RK / (σK2 ^ 2 * Rf2 * n)) ^ (1 / 5 : ℝ)) ^ 4 / 4 * σK2 ^ 2 * Rf2
            + RK / (n * (RK / (σK2 ^ 2 * Rf2 * n)) ^ (1 / 5 : ℝ))
          ≤ h ^ 4 / 4 * σK2 ^ 2 * Rf2 + RK / (n * h) := by
  have hn' : (0:ℝ) < n := by exact_mod_cast hn
  set B := RK / (σK2 ^ 2 * Rf2 * n) with hB
  have hBpos : 0 < B := by positivity
  set c := B ^ (1 / 5 : ℝ) with hc
  have hcpos : 0 < c := Real.rpow_pos_of_pos hBpos _
  refine ⟨hcpos, fun h hh => ?_⟩
  have hc5 : c ^ 5 = B := by
    rw [hc, show (1 / 5 : ℝ) = ((5 : ℕ) : ℝ)⁻¹ by norm_num]
    exact Real.rpow_inv_natCast_pow hBpos.le (by norm_num)
  have hRK : RK = c ^ 5 * (σK2 ^ 2 * Rf2 * n) := by
    rw [hc5, hB]; field_simp
  set a := σK2 ^ 2 * Rf2 with ha
  have hapos : 0 < a := by positivity
  rw [hRK]
  have e1 : c ^ 5 * (a * n) / (n * c) = c ^ 4 * a := by field_simp
  have e2 : c ^ 5 * (a * n) / (n * h) = c ^ 5 * a / h := by field_simp
  rw [e1, e2]
  have hpoly : 0 ≤ h ^ 5 - 5 * c ^ 4 * h + 4 * c ^ 5 := by
    have : h ^ 5 - 5 * c ^ 4 * h + 4 * c ^ 5
        = (h - c) ^ 2 * (h ^ 3 + 2 * c * h ^ 2 + 3 * c ^ 2 * h + 4 * c ^ 3) := by ring
    rw [this]; positivity
  have : h ^ 4 / 4 * a + c ^ 5 * a / h - (c ^ 4 / 4 * a + c ^ 4 * a)
      = a / (4 * h) * (h ^ 5 - 5 * c ^ 4 * h + 4 * c ^ 5) := by field_simp; ring
  have : 0 ≤ a / (4 * h) * (h ^ 5 - 5 * c ^ 4 * h + 4 * c ^ 5) := by positivity
  linarith

-- Shop A's waits in tenths of a minute: 1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0.
-- One-minute bins starting at 1.0 minutes give counts 2, 2, 2, 1, 1, 0.
example : (List.range 6).map (fun k => (([12, 19, 24, 28, 31, 35, 42, 50] : List ℕ).filter
    (fun v => 10 + 10 * k ≤ v ∧ v < 20 + 10 * k)).length) = [2, 2, 2, 1, 1, 0] := by decide
-- The same bins started at 0.5 minutes give counts 1, 2, 2, 2, 1, 0.
example : (List.range 6).map (fun k => (([12, 19, 24, 28, 31, 35, 42, 50] : List ℕ).filter
    (fun v => 5 + 10 * k ≤ v ∧ v < 15 + 10 * k)).length) = [1, 2, 2, 2, 1, 0] := by decide
-- Mean wait 24.1 / 8 = 3.0125 minutes.
example : ((12 + 19 + 24 + 28 + 31 + 35 + 42 + 50 : ℚ) / 10) / 8 = 241 / 80 := by norm_num
-- Quartiles by medians of the halves: (1.9 + 2.4)/2 = 2.15 and (3.5 + 4.2)/2 = 3.85, IQR 1.70.
example : ((35 + 42) / 2 - (19 + 24) / 2 : ℚ) / 10 = 17 / 10 := by norm_num
-- Interpolated quartiles (R's default): 1.9 + 0.75 × 0.5 and 3.5 + 0.25 × 0.7, IQR 1.40.
example : ((35 + (42 - 35) / 4) - (19 + 3 * (24 - 19) / 4) : ℚ) / 10 = 7 / 5 := by norm_num

#print axioms kde_is_density
#print axioms kde_mean_eq_kernel_blur
#print axioms amise_minimized_at_optimal_bandwidth
