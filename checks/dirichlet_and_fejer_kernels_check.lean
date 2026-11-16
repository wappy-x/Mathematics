-- Dirichlet and Fejer kernels: for a 2π-periodic signal integrable over one cycle, the Fourier partial sum is the signal smeared by the Dirichlet kernel sin((N+1/2)t)/sin(t/2) and the running average of partial sums is the signal smeared by the Fejér kernel (1/N)(sin(Nt/2)/sin(t/2))², which is never negative and has total size 1, while the Dirichlet kernel's total size exceeds (4/π²)(1 + 1/2 + ⋯ + 1/N) and grows without limit.
import Mathlib
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Order.Filter.AtTopBot.Basic

open Real Finset Filter MeasureTheory

namespace DirichletFejer

/-- The n-th Fourier coefficient on the circle, with the factor `1/2π`:
`f̂(n) = (1/2π) ∫_{−π}^{π} f(y) e^{−iny} dy`. -/
noncomputable def coeff (f : ℝ → ℂ) (n : ℤ) : ℂ :=
  (1 / (2 * π)) * ∫ y in (-π)..π, f y * Complex.exp (-((n : ℂ) * y) * Complex.I)

/-- The partial sum `S_N f(x) = ∑_{n=−N}^{N} f̂(n) e^{inx}` (2N + 1 tones). -/
noncomputable def partialSum (f : ℝ → ℂ) (N : ℕ) (x : ℝ) : ℂ :=
  ∑ n ∈ Icc (-(N : ℤ)) N, coeff f n * Complex.exp ((n : ℂ) * x * Complex.I)

/-- The running average `σ_N f = (S_0 f + S_1 f + ⋯ + S_{N−1} f)/N`. -/
noncomputable def runningAverage (f : ℝ → ℂ) (N : ℕ) (x : ℝ) : ℂ :=
  (1 / (N : ℂ)) * ∑ m ∈ range N, partialSum f m x

/-- Convolution on the circle: `(f * g)(x) = (1/2π) ∫_{−π}^{π} f(x − t) g(t) dt`. -/
noncomputable def circConv (f g : ℝ → ℂ) (x : ℝ) : ℂ :=
  (1 / (2 * π)) * ∫ t in (-π)..π, f (x - t) * g t

/-- The Dirichlet kernel `D_N(t) = ∑_{k=−N}^{N} e^{ikt}`. -/
noncomputable def dirichlet (N : ℕ) (t : ℝ) : ℂ :=
  ∑ k ∈ Icc (-(N : ℤ)) N, Complex.exp ((k : ℂ) * t * Complex.I)

/-- The Fejér kernel `F_N(t) = ∑_{|k|<N} (1 − |k|/N) e^{ikt}`, tone k tapered to `1 − |k|/N`. -/
noncomputable def fejer (N : ℕ) (t : ℝ) : ℂ :=
  ∑ k ∈ Ioo (-(N : ℤ)) N,
    (((1 - |(k : ℝ)| / N : ℝ)) : ℂ) * Complex.exp ((k : ℂ) * t * Complex.I)

/-- The total size of the Dirichlet kernel: `L_N = (1/2π) ∫_{−π}^{π} |D_N(t)| dt`. -/
noncomputable def totalSize (N : ℕ) : ℝ :=
  (1 / (2 * π)) * ∫ t in (-π)..π, ‖dirichlet N t‖

/-- Splitting off the two outer terms of a symmetric integer range. -/
theorem sum_Icc_succ_symm {M : Type*} [AddCommMonoid M] (a : ℤ → M) (n : ℕ) :
    ∑ k ∈ Icc (-((n + 1 : ℕ) : ℤ)) ((n + 1 : ℕ) : ℤ), a k =
      ∑ k ∈ Icc (-(n : ℤ)) n, a k + a ((n + 1 : ℕ) : ℤ) + a (-((n + 1 : ℕ) : ℤ)) := by
  have hset : Icc (-((n + 1 : ℕ) : ℤ)) ((n + 1 : ℕ) : ℤ) =
      insert (-((n + 1 : ℕ) : ℤ)) (insert ((n + 1 : ℕ) : ℤ) (Icc (-(n : ℤ)) n)) := by
    ext k; simp only [mem_Icc, mem_insert]; push_cast; omega
  rw [hset, sum_insert, sum_insert]
  · abel
  · simp only [mem_Icc]; push_cast; omega
  · simp only [mem_insert, mem_Icc]; push_cast; omega
#print axioms sum_Icc_succ_symm

/-- The real Dirichlet kernel `1 + 2 ∑_{j=1}^{N} cos(jt)`. -/
noncomputable def dirR (N : ℕ) (t : ℝ) : ℝ :=
  1 + 2 * ∑ j ∈ range N, Real.cos ((j + 1 : ℝ) * t)

theorem dirR_succ (N : ℕ) (t : ℝ) :
    dirR (N + 1) t = dirR N t + 2 * Real.cos ((N + 1 : ℝ) * t) := by
  simp only [dirR, sum_range_succ]; ring
#print axioms dirR_succ

theorem dirichlet_eq_dirR (N : ℕ) (t : ℝ) : dirichlet N t = (dirR N t : ℂ) := by
  induction N with
  | zero => simp [dirichlet, dirR]
  | succ n ih =>
    rw [dirichlet, sum_Icc_succ_symm, ← dirichlet, ih, dirR_succ]
    push_cast
    rw [add_assoc, Complex.two_cos]
    congr 3; ring
#print axioms dirichlet_eq_dirR

theorem dirR_mul_sin (N : ℕ) (t : ℝ) :
    dirR N t * Real.sin (t / 2) = Real.sin ((N + 1 / 2) * t) := by
  induction N with
  | zero => simp [dirR]; ring_nf
  | succ n ih =>
    rw [dirR_succ, add_mul, ih]
    have h1 : ((n + 1 : ℕ) + 1 / 2 : ℝ) * t = (n + 1 : ℝ) * t + t / 2 := by push_cast; ring
    have h2 : ((n : ℝ) + 1 / 2) * t = (n + 1 : ℝ) * t - t / 2 := by ring
    rw [h1, h2, Real.sin_add, Real.sin_sub]; ring
#print axioms dirR_mul_sin

theorem sum_dirR_mul_sin_sq (N : ℕ) (t : ℝ) :
    (∑ m ∈ range N, dirR m t) * Real.sin (t / 2) ^ 2 = Real.sin (N * t / 2) ^ 2 := by
  induction N with
  | zero => simp
  | succ n ih =>
    rw [sum_range_succ, add_mul, ih, pow_two (Real.sin (t / 2)), ← mul_assoc, dirR_mul_sin]
    set c := ((n : ℝ) + 1 / 2) * t / 2
    set d := t / 4
    have e1 : ((n + 1 : ℕ) : ℝ) * t / 2 = c + d := by simp only [c, d]; push_cast; ring
    have e2 : (n : ℝ) * t / 2 = c - d := by simp only [c, d]; ring
    have e3 : ((n : ℝ) + 1 / 2) * t = 2 * c := by simp only [c]; ring
    have e4 : t / 2 = 2 * d := by simp only [d]; ring
    rw [e1, e2, e3, e4, Real.sin_add, Real.sin_sub, Real.sin_two_mul, Real.sin_two_mul]
    ring
#print axioms sum_dirR_mul_sin_sq

/-- Summing the symmetric partial sums of any sequence gives the triangular weights. -/
theorem sum_range_sum_Icc (a : ℤ → ℂ) (N : ℕ) :
    ∑ m ∈ range N, ∑ k ∈ Icc (-(m : ℤ)) m, a k =
      ∑ k ∈ Ioo (-(N : ℤ)) N, (((N : ℝ) - |(k : ℝ)| : ℝ) : ℂ) * a k := by
  induction N with
  | zero => simp
  | succ n ih =>
    rw [sum_range_succ, ih]
    have hset : Ioo (-((n + 1 : ℕ) : ℤ)) ((n + 1 : ℕ) : ℤ) = Icc (-(n : ℤ)) n := by
      ext k; simp only [mem_Ioo, mem_Icc]; push_cast; omega
    have hsub : ∑ k ∈ Ioo (-(n : ℤ)) n, (((n : ℝ) - |(k : ℝ)| : ℝ) : ℂ) * a k =
        ∑ k ∈ Icc (-(n : ℤ)) n, (((n : ℝ) - |(k : ℝ)| : ℝ) : ℂ) * a k := by
      apply sum_subset
      · intro k; simp only [mem_Ioo, mem_Icc]; omega
      · intro k hk hk'
        simp only [mem_Ioo, mem_Icc] at hk hk'
        have : |(k : ℝ)| = n := by
          rcases (show k = n ∨ k = -n by omega) with h | h
          · simp [h]
          · simp [h]
        simp [this]
    rw [hset, hsub, ← sum_add_distrib]
    apply sum_congr rfl
    intro k _
    push_cast; ring
#print axioms sum_range_sum_Icc

theorem mean_sum_Icc (a : ℤ → ℂ) (N : ℕ) :
    (1 / (N : ℂ)) * ∑ m ∈ range N, ∑ k ∈ Icc (-(m : ℤ)) m, a k =
      ∑ k ∈ Ioo (-(N : ℤ)) N, (((1 - |(k : ℝ)| / N : ℝ)) : ℂ) * a k := by
  rw [sum_range_sum_Icc, mul_sum]
  apply sum_congr rfl
  intro k hk
  have hN : (N : ℝ) ≠ 0 := by
    simp only [mem_Ioo] at hk
    have : (0 : ℤ) < N := by omega
    exact_mod_cast this.ne'
  rw [← mul_assoc]
  congr 1
  have hN' : (N : ℂ) ≠ 0 := by exact_mod_cast hN
  push_cast
  rw [one_div_mul_eq_div, sub_div, div_self hN']
#print axioms mean_sum_Icc

theorem fejer_eq_mean (N : ℕ) (t : ℝ) :
    fejer N t = (1 / (N : ℂ)) * ∑ m ∈ range N, dirichlet m t := by
  simp only [dirichlet]
  rw [mean_sum_Icc, fejer]
#print axioms fejer_eq_mean

/-- The real Fejér kernel. -/
noncomputable def fejR (N : ℕ) (t : ℝ) : ℝ := (1 / N) * ∑ m ∈ range N, dirR m t

theorem fejer_eq_fejR (N : ℕ) (t : ℝ) : fejer N t = (fejR N t : ℂ) := by
  rw [fejer_eq_mean, fejR]
  simp only [dirichlet_eq_dirR]
  push_cast; ring
#print axioms fejer_eq_fejR

theorem dirR_zero_right (N : ℕ) : dirR N 0 = 2 * N + 1 := by
  simp [dirR]; ring

theorem dirR_of_sin_eq_zero (N : ℕ) (t : ℝ) (h : Real.sin (t / 2) = 0) :
    dirR N t = 2 * N + 1 := by
  obtain ⟨n, hn⟩ := Real.sin_eq_zero_iff.mp h
  have hc : ∀ j : ℕ, Real.cos ((j + 1 : ℝ) * t) = 1 := by
    intro j
    have : (j + 1 : ℝ) * t = (((j + 1 : ℕ) : ℤ) * n : ℤ) * (2 * π) := by
      have ht : t = 2 * (n * π) := by linarith
      rw [ht]; push_cast; ring
    rw [this, Real.cos_int_mul_two_pi]
  simp [dirR, hc]; ring
#print axioms dirR_zero_right
#print axioms dirR_of_sin_eq_zero

theorem sum_dirR_zero (N : ℕ) : ∑ m ∈ range N, dirR m 0 = (N : ℝ) ^ 2 := by
  induction N with
  | zero => simp
  | succ n ih => rw [sum_range_succ, ih, dirR_zero_right]; push_cast; ring
#print axioms sum_dirR_zero

theorem fejR_nonneg (N : ℕ) (t : ℝ) : 0 ≤ fejR N t := by
  rw [fejR]
  apply mul_nonneg (by positivity)
  by_cases h : Real.sin (t / 2) = 0
  · apply sum_nonneg; intro m _; rw [dirR_of_sin_eq_zero m t h]; positivity
  · have hpos : 0 < Real.sin (t / 2) ^ 2 := by positivity
    have := sum_dirR_mul_sin_sq N t
    nlinarith [sq_nonneg (Real.sin (N * t / 2))]
#print axioms fejR_nonneg

/-- Smearing a signal by a trigonometric polynomial multiplies its Fourier coefficients
by the polynomial's coefficients. -/
theorem circConv_trig (f : ℝ → ℂ) (hper : Function.Periodic f (2 * π))
    (hint : IntervalIntegrable f volume (-π) π) (s : Finset ℤ) (c : ℤ → ℂ) (x : ℝ) :
    circConv f (fun t => ∑ k ∈ s, c k * Complex.exp ((k : ℂ) * t * Complex.I)) x =
      ∑ k ∈ s, c k * (coeff f k * Complex.exp ((k : ℂ) * x * Complex.I)) := by
  set K : ℝ → ℂ := fun t => ∑ k ∈ s, c k * Complex.exp ((k : ℂ) * t * Complex.I) with hK
  have hKper : Function.Periodic K (2 * π) := by
    intro t
    simp only [hK]
    apply sum_congr rfl
    intro k _
    congr 1
    have : (k : ℂ) * ((t + 2 * π : ℝ) : ℂ) * Complex.I =
        (k : ℂ) * t * Complex.I + k * (2 * π * Complex.I) := by push_cast; ring
    rw [this, Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one]
  set g : ℝ → ℂ := fun y => f y * K (x - y) with hg
  have hgper : Function.Periodic g (2 * π) := by
    intro y
    simp only [hg]
    rw [hper y, show x - (y + 2 * π) = (x - y) - 2 * π by ring, hKper.sub_eq]
  have step1 : ∫ t in (-π)..π, f (x - t) * K t = ∫ y in (-π)..π, g y := by
    have : ∫ t in (-π)..π, f (x - t) * K t = ∫ t in (-π)..π, g (x - t) := by
      simp only [hg, sub_sub_cancel]
    rw [this, intervalIntegral.integral_comp_sub_left,
      show x - -π = (x - π) + 2 * π by ring, hgper.intervalIntegral_add_eq (x - π) (-π),
      show -π + 2 * π = π by ring]
  have hterm : ∀ k : ℤ, IntervalIntegrable
      (fun y => f y * Complex.exp (-((k : ℂ) * y) * Complex.I)) volume (-π) π := by
    intro k
    apply hint.mul_continuousOn
    apply Continuous.continuousOn
    fun_prop
  have step2 : ∫ y in (-π)..π, g y = ∑ k ∈ s, c k * Complex.exp ((k : ℂ) * x * Complex.I) *
      ∫ y in (-π)..π, f y * Complex.exp (-((k : ℂ) * y) * Complex.I) := by
    have : ∀ y, g y = ∑ k ∈ s, c k * Complex.exp ((k : ℂ) * x * Complex.I) *
        (f y * Complex.exp (-((k : ℂ) * y) * Complex.I)) := by
      intro y
      simp only [hg, hK, mul_sum]
      apply sum_congr rfl
      intro k _
      have : Complex.exp ((k : ℂ) * ((x - y : ℝ) : ℂ) * Complex.I) =
          Complex.exp ((k : ℂ) * x * Complex.I) * Complex.exp (-((k : ℂ) * y) * Complex.I) := by
        rw [← Complex.exp_add]; congr 1; push_cast; ring
      rw [this]; ring
    simp only [this]
    rw [intervalIntegral.integral_finsetSum]
    · apply sum_congr rfl
      intro k _
      rw [intervalIntegral.integral_const_mul]
    · intro k _
      exact (hterm k).const_mul _
  unfold circConv
  rw [step1, step2, mul_sum]
  apply sum_congr rfl
  intro k _
  simp only [coeff]
  ring
#print axioms circConv_trig

theorem continuous_dirR (N : ℕ) : Continuous (dirR N) := by
  unfold dirR; fun_prop
#print axioms continuous_dirR

theorem dirR_neg (N : ℕ) (t : ℝ) : dirR N (-t) = dirR N t := by
  simp only [dirR, mul_neg, Real.cos_neg]
#print axioms dirR_neg

theorem integral_cos_int_mul (j : ℕ) : ∫ t in (-π)..π, Real.cos ((j + 1 : ℝ) * t) = 0 := by
  have hc : ((j : ℝ) + 1) ≠ 0 := by positivity
  rw [intervalIntegral.integral_comp_mul_left (f := Real.cos) hc, integral_cos]
  have : ((j : ℝ) + 1) * π = ((j + 1 : ℕ) : ℝ) * π := by push_cast; ring
  rw [mul_neg, Real.sin_neg, this, Real.sin_nat_mul_pi]; simp
#print axioms integral_cos_int_mul

theorem integral_dirR (N : ℕ) : ∫ t in (-π)..π, dirR N t = 2 * π := by
  unfold dirR
  rw [intervalIntegral.integral_add, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_finsetSum]
  · simp only [integral_cos_int_mul, sum_const_zero, mul_zero, add_zero,
      intervalIntegral.integral_const, smul_eq_mul, mul_one]
    ring
  · intro j _; apply Continuous.intervalIntegrable; fun_prop
  · apply Continuous.intervalIntegrable; fun_prop
  · apply Continuous.intervalIntegrable; fun_prop
#print axioms integral_dirR

theorem totalSize_eq (N : ℕ) : totalSize N = (1 / π) * ∫ t in (0 : ℝ)..π, |dirR N t| := by
  have hn : ∀ t, ‖dirichlet N t‖ = |dirR N t| := by
    intro t; rw [dirichlet_eq_dirR, Complex.norm_real, Real.norm_eq_abs]
  have hint : ∀ a b : ℝ, IntervalIntegrable (fun t => |dirR N t|) volume a b :=
    fun a b => ((continuous_dirR N).abs).intervalIntegrable a b
  unfold totalSize
  simp only [hn]
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint (-π) 0) (hint 0 π)]
  have hneg : ∫ t in (-π)..0, |dirR N t| = ∫ t in (0 : ℝ)..π, |dirR N t| := by
    have := intervalIntegral.integral_comp_neg (a := 0) (b := π) (fun t => |dirR N t|)
    simp only [dirR_neg, neg_zero] at this
    rw [this]
  rw [hneg]
  field_simp
  ring
#print axioms totalSize_eq

theorem abs_dirR_le (N : ℕ) (t : ℝ) : |dirR N t| ≤ 2 * N + 1 := by
  unfold dirR
  calc |1 + 2 * ∑ j ∈ range N, Real.cos ((j + 1 : ℝ) * t)|
      ≤ |(1 : ℝ)| + |2 * ∑ j ∈ range N, Real.cos ((j + 1 : ℝ) * t)| := abs_add_le _ _
    _ = 1 + 2 * |∑ j ∈ range N, Real.cos ((j + 1 : ℝ) * t)| := by
        rw [abs_mul]; norm_num
    _ ≤ 1 + 2 * ∑ j ∈ range N, |Real.cos ((j + 1 : ℝ) * t)| := by
        gcongr; exact abs_sum_le_sum_abs _ _
    _ ≤ 1 + 2 * ∑ j ∈ range N, (1 : ℝ) := by
        gcongr with j; exact Real.abs_cos_le_one _
    _ = 2 * N + 1 := by simp; ring
#print axioms abs_dirR_le

theorem abs_dirR_mul_sin (N : ℕ) (t : ℝ) (h : 0 ≤ Real.sin (t / 2)) :
    |dirR N t| * Real.sin (t / 2) = |Real.sin ((N + 1 / 2) * t)| := by
  rw [← dirR_mul_sin, abs_mul, abs_of_nonneg h]
#print axioms abs_dirR_mul_sin

theorem abs_dirR_le_pi_div (N : ℕ) (t : ℝ) (ht : 0 < t) (htπ : t ≤ π) :
    |dirR N t| ≤ π * t⁻¹ := by
  have hs : 2 / π * (t / 2) ≤ Real.sin (t / 2) :=
    Real.mul_le_sin (by linarith) (by linarith)
  have hs0 : 0 ≤ Real.sin (t / 2) := le_trans (by positivity) hs
  have h1 := abs_dirR_mul_sin N t hs0
  have h2 : |Real.sin ((N + 1 / 2) * t)| ≤ 1 := Real.abs_sin_le_one _
  have h3 := mul_le_mul_of_nonneg_left hs (abs_nonneg (dirR N t))
  have h4 : |dirR N t| * t = π * (|dirR N t| * (2 / π * (t / 2))) := by
    field_simp
  rw [← div_eq_mul_inv, le_div_iff₀ ht, h4]
  nlinarith [Real.pi_pos]
#print axioms abs_dirR_le_pi_div

theorem integral_abs_dirR_le (N : ℕ) :
    ∫ t in (0 : ℝ)..π, |dirR N t| ≤ π * (1 + Real.log (2 * N + 1)) := by
  set a := π / (2 * N + 1) with ha
  have hN : (0 : ℝ) < 2 * N + 1 := by positivity
  have ha0 : 0 < a := by positivity
  have haπ : a ≤ π := by
    rw [ha, div_le_iff₀ hN]; nlinarith [Real.pi_pos, (Nat.cast_nonneg N : (0 : ℝ) ≤ N)]
  have hint : ∀ a b : ℝ, IntervalIntegrable (fun t => |dirR N t|) volume a b :=
    fun a b => ((continuous_dirR N).abs).intervalIntegrable a b
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 a) (hint a π)]
  have e1 : ∫ t in (0 : ℝ)..a, |dirR N t| ≤ π := by
    calc ∫ t in (0 : ℝ)..a, |dirR N t| ≤ ∫ t in (0 : ℝ)..a, (2 * N + 1 : ℝ) := by
          apply intervalIntegral.integral_mono_on ha0.le (hint 0 a) (by simp)
          intro t _; exact abs_dirR_le N t
      _ = π := by
          rw [intervalIntegral.integral_const, smul_eq_mul, ha]; field_simp; ring
  have e2 : ∫ t in a..π, |dirR N t| ≤ π * Real.log (2 * N + 1) := by
    have hinv : IntervalIntegrable (fun t : ℝ => π * t⁻¹) volume a π := by
      apply IntervalIntegrable.const_mul
      apply intervalIntegral.intervalIntegrable_inv
      · intro t ht
        rw [Set.uIcc_of_le haπ] at ht
        exact (lt_of_lt_of_le ha0 ht.1).ne'
      · exact continuousOn_id
    calc ∫ t in a..π, |dirR N t| ≤ ∫ t in a..π, π * t⁻¹ := by
          apply intervalIntegral.integral_mono_on haπ (hint a π) hinv
          intro t ht
          exact abs_dirR_le_pi_div N t (lt_of_lt_of_le ha0 ht.1) ht.2
      _ = π * Real.log (2 * N + 1) := by
          rw [intervalIntegral.integral_const_mul, integral_inv_of_pos ha0 Real.pi_pos, ha]
          congr 2
          field_simp
  linarith
#print axioms integral_abs_dirR_le

theorem integral_abs_sin_period (k : ℕ) :
    ∫ u in (k * π)..((k + 1 : ℕ) * π), |Real.sin u| = 2 := by
  have hper : Function.Periodic (fun u => |Real.sin u|) π := by
    intro u; simp [Real.sin_add_pi]
  have : ((k + 1 : ℕ) : ℝ) * π = k * π + π := by push_cast; ring
  rw [this, hper.intervalIntegral_add_eq (k * π) 0, zero_add]
  have hcongr : ∫ u in (0 : ℝ)..π, |Real.sin u| = ∫ u in (0 : ℝ)..π, Real.sin u := by
    apply intervalIntegral.integral_congr
    intro u hu
    rw [Set.uIcc_of_le Real.pi_pos.le] at hu
    exact abs_of_nonneg (Real.sin_nonneg_of_nonneg_of_le_pi hu.1 hu.2)
  rw [hcongr, integral_sin]; simp; norm_num
#print axioms integral_abs_sin_period

theorem integral_abs_sin_scaled (N k : ℕ) :
    ∫ t in (k * π / (N + 1 / 2))..((k + 1 : ℕ) * π / (N + 1 / 2)),
      |Real.sin ((N + 1 / 2) * t)| = 2 / (N + 1 / 2) := by
  have hc : ((N : ℝ) + 1 / 2) ≠ 0 := by positivity
  rw [intervalIntegral.integral_comp_mul_left (f := fun u => |Real.sin u|) hc]
  rw [mul_div_cancel₀ _ hc, mul_div_cancel₀ _ hc, integral_abs_sin_period, smul_eq_mul]
  field_simp
#print axioms integral_abs_sin_scaled

theorem sum_Icc_one_div (N : ℕ) :
    ∑ k ∈ Icc 1 N, (1 / (k : ℝ)) = ∑ i ∈ range N, (1 / ((i : ℝ) + 1)) := by
  induction N with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih, sum_range_succ]; push_cast; ring
#print axioms sum_Icc_one_div

theorem integral_abs_dirR_gt (N : ℕ) :
    4 / π * ∑ k ∈ Icc 1 N, (1 / (k : ℝ)) < ∫ t in (0 : ℝ)..π, |dirR N t| := by
  have hc : (0 : ℝ) < N + 1 / 2 := by positivity
  set b : ℕ → ℝ := fun k => k * π / (N + 1 / 2) with hb
  have hint : ∀ a b : ℝ, IntervalIntegrable (fun t => |dirR N t|) volume a b :=
    fun a b => ((continuous_dirR N).abs).intervalIntegrable a b
  have hb0 : b 0 = 0 := by simp [hb]
  have hbN : b N < π := by
    simp only [hb]; rw [div_lt_iff₀ hc]; nlinarith [Real.pi_pos]
  have hbmono : ∀ k, b k ≤ b (k + 1) := by
    intro k; simp only [hb]; gcongr; linarith
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 (b N)) (hint (b N) π)]
  rw [← hb0, ← intervalIntegral.sum_integral_adjacent_intervals (fun k _ => hint _ _)]
  -- each piece
  have piece : ∀ k ∈ range N, 4 / π * (1 / ((k : ℝ) + 1)) ≤ ∫ t in b k..b (k + 1), |dirR N t| := by
    intro k hk
    have hkN : k + 1 ≤ N := by simpa using hk
    have hk1 : (0 : ℝ) < k + 1 := by positivity
    have hbk1 : b (k + 1) ≤ b N := by
      simp only [hb]; gcongr
    set C : ℝ := 2 * (N + 1 / 2) / ((k + 1) * π) with hC
    have hpt : ∀ t ∈ Set.Icc (b k) (b (k + 1)),
        C * |Real.sin ((N + 1 / 2) * t)| ≤ |dirR N t| := by
      intro t ht
      have ht0 : 0 ≤ t := le_trans (by simp only [hb]; positivity) ht.1
      rcases ht0.eq_or_lt with h0 | h0
      · subst h0; simp
      have htπ : t < π := lt_of_le_of_lt (ht.2.trans hbk1) hbN
      have hs0 : 0 < Real.sin (t / 2) :=
        Real.sin_pos_of_pos_of_lt_pi (by linarith) (by linarith)
      have hsle : Real.sin (t / 2) ≤ t / 2 := Real.sin_le (by linarith)
      have h1 := abs_dirR_mul_sin N t hs0.le
      have htb : t ≤ (k + 1) * π / (N + 1 / 2) := by
        have := ht.2; simp only [hb] at this; push_cast at this; exact this
      have h2 : |Real.sin ((N + 1 / 2) * t)| ≤ |dirR N t| * ((k + 1) * π / (N + 1 / 2) / 2) := by
        rw [← h1]
        apply mul_le_mul_of_nonneg_left _ (abs_nonneg _)
        linarith
      calc C * |Real.sin ((N + 1 / 2) * t)|
          ≤ C * (|dirR N t| * ((k + 1) * π / (N + 1 / 2) / 2)) := by
            apply mul_le_mul_of_nonneg_left h2; positivity
        _ = |dirR N t| := by
            simp only [hC]; field_simp
    calc 4 / π * (1 / ((k : ℝ) + 1))
        = C * (2 / (N + 1 / 2)) := by simp only [hC]; field_simp; ring
      _ = ∫ t in b k..b (k + 1), C * |Real.sin ((N + 1 / 2) * t)| := by
          rw [intervalIntegral.integral_const_mul]
          simp only [hb]
          rw [integral_abs_sin_scaled]
      _ ≤ ∫ t in b k..b (k + 1), |dirR N t| := by
          apply intervalIntegral.integral_mono_on (hbmono k) _ (hint _ _) hpt
          apply Continuous.intervalIntegrable; fun_prop
  have hsum : 4 / π * ∑ k ∈ Icc 1 N, (1 / (k : ℝ)) ≤
      ∑ k ∈ range N, ∫ t in b k..b (k + 1), |dirR N t| := by
    rw [sum_Icc_one_div, mul_sum]
    exact sum_le_sum piece
  have hlast : 0 < ∫ t in b N..π, |dirR N t| := by
    apply intervalIntegral.intervalIntegral_pos_of_pos_on (hint _ _) _ hbN
    intro t ht
    have ht0 : 0 < t := lt_of_le_of_lt (by simp only [hb]; positivity) ht.1
    have hs0 : 0 < Real.sin (t / 2) :=
      Real.sin_pos_of_pos_of_lt_pi (by linarith) (by linarith [ht.2])
    have h1 := abs_dirR_mul_sin N t hs0.le
    have hne : Real.sin ((N + 1 / 2) * t) ≠ 0 := by
      intro h
      obtain ⟨n, hn⟩ := Real.sin_eq_zero_iff.mp h
      have hlo : (N : ℝ) * π < n * π := by
        rw [hn]
        have := ht.1; simp only [hb] at this; rw [div_lt_iff₀ hc] at this; linarith
      have hhi : (n : ℝ) * π < (N + 1) * π := by
        rw [hn]; nlinarith [ht.2, Real.pi_pos]
      have h3 : ((N : ℤ) : ℝ) < n := by
        have := lt_of_mul_lt_mul_right hlo Real.pi_pos.le; exact_mod_cast this
      have h4 : (n : ℝ) < ((N + 1 : ℤ) : ℝ) := by
        have := lt_of_mul_lt_mul_right hhi Real.pi_pos.le; push_cast; exact this
      have h5 : (N : ℤ) < n := by exact_mod_cast h3
      have h6 : n < N + 1 := by exact_mod_cast h4
      omega
    have : 0 < |dirR N t| * Real.sin (t / 2) := by rw [h1]; exact abs_pos.mpr hne
    exact pos_of_mul_pos_left this hs0.le
  linarith
#print axioms integral_abs_dirR_gt

/-- The card's two identities. If a signal repeats every 2π and has finite area under `|f|`
over one cycle, then for every number of tones N and every point x, the partial sum is the
signal smeared by the Dirichlet kernel, `S_N f = f * D_N`, and the running average of the first
N partial sums is the signal smeared by the Fejér kernel, `σ_N f = f * F_N`. -/
theorem partial_sum_and_running_average_are_kernel_smears (f : ℝ → ℂ)
    (hper : Function.Periodic f (2 * π)) (hint : IntervalIntegrable f volume (-π) π)
    (N : ℕ) (x : ℝ) :
    partialSum f N x = circConv f (dirichlet N) x ∧
      runningAverage f N x = circConv f (fejer N) x := by
  have hD : ∀ m : ℕ, dirichlet m =
      fun (t : ℝ) => ∑ k ∈ Icc (-(m : ℤ)) m, (1 : ℂ) * Complex.exp ((k : ℂ) * t * Complex.I) := by
    intro m; funext t; simp [dirichlet]
  have hS : ∀ m : ℕ, partialSum f m x = circConv f (dirichlet m) x := by
    intro m
    rw [hD, circConv_trig f hper hint]
    simp [partialSum]
  refine ⟨hS N, ?_⟩
  have hF : fejer N = fun (t : ℝ) => ∑ k ∈ Ioo (-(N : ℤ)) N,
      (((1 - |(k : ℝ)| / N : ℝ)) : ℂ) * Complex.exp ((k : ℂ) * t * Complex.I) := rfl
  rw [hF, circConv_trig f hper hint, runningAverage]
  simp only [partialSum]
  rw [mean_sum_Icc]

/-- The closed forms. Where `sin(t/2) ≠ 0`, `D_N(t) = sin((N+½)t)/sin(t/2)` and
`F_N(t) = (1/N)(sin(Nt/2)/sin(t/2))²`; at `t = 0` the kernels take their peak values `2N + 1`
and `N`; and the Fejér kernel is the mean of the Dirichlet kernels `D_0, …, D_{N−1}`. -/
theorem dirichlet_and_fejer_closed_forms (N : ℕ) (t : ℝ) :
    (Real.sin (t / 2) ≠ 0 →
      dirichlet N t = ((Real.sin ((N + 1 / 2) * t) / Real.sin (t / 2) : ℝ) : ℂ) ∧
      fejer N t = (((1 / N) * (Real.sin (N * t / 2) / Real.sin (t / 2)) ^ 2 : ℝ) : ℂ)) ∧
    dirichlet N 0 = 2 * N + 1 ∧ fejer N 0 = N ∧
    fejer N t = (1 / (N : ℂ)) * ∑ m ∈ range N, dirichlet m t := by
  refine ⟨fun h => ⟨?_, ?_⟩, ?_, ?_, fejer_eq_mean N t⟩
  · rw [dirichlet_eq_dirR, eq_div_of_mul_eq h (dirR_mul_sin N t)]
  · rw [fejer_eq_fejR, fejR, div_pow,
      eq_div_of_mul_eq (pow_ne_zero 2 h) (sum_dirR_mul_sin_sq N t)]
  · rw [dirichlet_eq_dirR, dirR_zero_right]; push_cast; ring
  · rw [fejer_eq_fejR, fejR, sum_dirR_zero]
    rcases Nat.eq_zero_or_pos N with h | h
    · simp [h]
    · have : (N : ℝ) ≠ 0 := by positivity
      push_cast; field_simp

/-- The size facts. Both kernels average to 1 over a cycle; the Fejér kernel is real and never
negative, so its total size is 1 for every N; the Dirichlet kernel's total size satisfies
`(4/π²)(1 + 1/2 + ⋯ + 1/N) < L_N ≤ 1 + ln(2N + 1)` and grows without limit. -/
theorem kernel_averages_and_total_sizes (N : ℕ) :
    (1 / (2 * π)) * ∫ t in (-π)..π, dirichlet N t = 1 ∧
    (∀ t, (fejer N t).im = 0 ∧ 0 ≤ (fejer N t).re) ∧
    (1 ≤ N → (1 / (2 * π)) * ∫ t in (-π)..π, fejer N t = 1 ∧
      (1 / (2 * π)) * ∫ t in (-π)..π, ‖fejer N t‖ = 1) ∧
    4 / π ^ 2 * ∑ k ∈ Icc 1 N, (1 / (k : ℝ)) < totalSize N ∧
    totalSize N ≤ 1 + Real.log (2 * N + 1) ∧
    Tendsto totalSize atTop atTop := by
  have hπ := Real.pi_pos
  have hlow : ∀ M : ℕ, 4 / π ^ 2 * ∑ k ∈ Icc 1 M, (1 / (k : ℝ)) < totalSize M := by
    intro M
    rw [totalSize_eq]
    have := integral_abs_dirR_gt M
    have e : 4 / π ^ 2 * ∑ k ∈ Icc 1 M, (1 / (k : ℝ)) =
        1 / π * (4 / π * ∑ k ∈ Icc 1 M, (1 / (k : ℝ))) := by field_simp
    rw [e]
    exact mul_lt_mul_of_pos_left this (by positivity)
  refine ⟨?_, ?_, ?_, hlow N, ?_, ?_⟩
  · simp only [dirichlet_eq_dirR]
    rw [intervalIntegral.integral_ofReal, integral_dirR]
    push_cast
    field_simp
  · intro t
    rw [fejer_eq_fejR]
    exact ⟨Complex.ofReal_im _, by rw [Complex.ofReal_re]; exact fejR_nonneg N t⟩
  · intro hN
    have hN0 : (N : ℝ) ≠ 0 := by positivity
    have hF : ∫ t in (-π)..π, fejR N t = 2 * π := by
      unfold fejR
      rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_finsetSum]
      · simp only [integral_dirR, sum_const, card_range, nsmul_eq_mul]
        field_simp
      · intro m _; exact (continuous_dirR m).intervalIntegrable _ _
    constructor
    · simp only [fejer_eq_fejR]
      rw [intervalIntegral.integral_ofReal, hF]
      push_cast
      field_simp
    · have : ∀ t, ‖fejer N t‖ = fejR N t := by
        intro t
        rw [fejer_eq_fejR, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (fejR_nonneg N t)]
      simp only [this]
      rw [hF]
      field_simp
  · rw [totalSize_eq]
    have := integral_abs_dirR_le N
    calc 1 / π * ∫ t in (0 : ℝ)..π, |dirR N t| ≤ 1 / π * (π * (1 + Real.log (2 * N + 1))) :=
          mul_le_mul_of_nonneg_left this (by positivity)
      _ = 1 + Real.log (2 * N + 1) := by field_simp
  · apply tendsto_atTop_mono (fun M => (hlow M).le)
    simp only [sum_Icc_one_div]
    exact Tendsto.const_mul_atTop (by positivity) tendsto_sum_range_one_div_nat_succ_atTop

-- The card's worked numbers for nine tones: peaks 9 and 5, and the values at t = π/3.
example : dirichlet 4 0 = 9 := by
  rw [(dirichlet_and_fejer_closed_forms 4 0).2.1]; norm_num
example : fejer 5 0 = 5 := by
  rw [(dirichlet_and_fejer_closed_forms 5 0).2.2.1]; norm_num
example : dirichlet 4 (π / 3) = -2 := by
  have h6 : Real.sin (π / 3 / 2) = 1 / 2 := by
    rw [show π / 3 / 2 = π / 6 by ring, Real.sin_pi_div_six]
  rw [((dirichlet_and_fejer_closed_forms 4 (π / 3)).1 (by rw [h6]; norm_num)).1, h6]
  have : ((4 : ℕ) + 1 / 2 : ℝ) * (π / 3) = π / 2 + π := by push_cast; ring
  rw [this, Real.sin_add_pi, Real.sin_pi_div_two]; push_cast; norm_num
example : fejer 5 (π / 3) = 1 / 5 := by
  have h6 : Real.sin (π / 3 / 2) = 1 / 2 := by
    rw [show π / 3 / 2 = π / 6 by ring, Real.sin_pi_div_six]
  rw [((dirichlet_and_fejer_closed_forms 5 (π / 3)).1 (by rw [h6]; norm_num)).2, h6]
  have : ((5 : ℕ) : ℝ) * (π / 3) / 2 = π - π / 6 := by push_cast; ring
  rw [this, Real.sin_pi_sub, Real.sin_pi_div_six]; push_cast; norm_num

-- The Fejér weights on |k| = 0..4 for N = 5, and its peak 1 + 2(0.8 + 0.6 + 0.4 + 0.2) = 5.
example : [(1 : ℚ) - 0 / 5, 1 - 1 / 5, 1 - 2 / 5, 1 - 3 / 5, 1 - 4 / 5] =
    [1, 4/5, 3/5, 2/5, 1/5] := by norm_num
example : (1 : ℚ) + 2 * (4/5 + 3/5 + 2/5 + 1/5) = 5 := by norm_num

#print axioms partial_sum_and_running_average_are_kernel_smears
#print axioms dirichlet_and_fejer_closed_forms
#print axioms kernel_averages_and_total_sizes

end DirichletFejer
