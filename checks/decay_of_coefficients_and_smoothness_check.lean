-- Smoothness shows in the tail: a wave whose first k - 1 derivatives are continuous round the loop and whose k-th derivative has finite travel V has Fourier coefficients at most V / (2π |n|^(k+1)), so its first N harmonics are within V / (π k N^k) of it everywhere.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Order.Interval.Finset.Defs
import Mathlib.Data.Int.Interval
import Mathlib.Analysis.BoundedVariation
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Order.Filter.AtTopBot.Interval
import Mathlib.Analysis.PSeries

open Real Set Function

noncomputable section

lemma per_pt_eq (g : ℝ → ℂ) (hper : Periodic g (2 * π)) : g π = g (-π) := by
  have := hper (-π)
  rw [show -π + 2 * π = π by ring] at this
  exact this

#print axioms per_pt_eq

lemma fourier_pi_eq (n : ℤ) :
    fourier (-n) ((π : ℝ) : AddCircle (π - -π)) = fourier (-n) ((-π : ℝ) : AddCircle (π - -π)) := by
  have h := AddCircle.coe_add_period (π - -π) (-π)
  rw [show -π + (π - -π) = π by ring] at h
  rw [h]

#print axioms fourier_pi_eq

lemma coeff_deriv_aux (f f' : ℝ → ℂ) (s : Set ℝ)
    (hper : Periodic f (2 * π)) (hcont : Continuous f) (hs : s.Countable)
    (hderiv : ∀ x ∈ Ioo (-π) π, x ∉ s → HasDerivAt f (f' x) x)
    (hint : IntervalIntegrable f' MeasureTheory.volume (-π) π) (n : ℤ) :
    fourierCoeffOn (neg_lt_self pi_pos) f' n = Complex.I * n * fourierCoeffOn (neg_lt_self pi_pos) f n := by
  set T : ℝ := π - -π with hTdef
  have hT2 : T = 2 * π := by rw [hTdef]; ring
  have hTpos : 0 < T := by rw [hT2]; positivity
  set e : ℝ → ℂ := fun y => fourier (-n) (y : AddCircle T) with he
  have hec : Continuous e := (map_continuous (fourier (-n))).comp (AddCircle.continuous_mk' _)
  have hed : ∀ y, HasDerivAt e (-2 * π * Complex.I * n / T * e y) y :=
    fun y => hasDerivAt_fourier_neg T n y
  set G' : ℝ → ℂ := fun y => (-2 * π * Complex.I * n / T * e y) * f y + e y * f' y with hG'
  have hI1 : IntervalIntegrable (fun y => e y * f y) MeasureTheory.volume (-π) π :=
    (hec.mul hcont).intervalIntegrable _ _
  have hI2 : IntervalIntegrable (fun y => e y * f' y) MeasureTheory.volume (-π) π :=
    hint.continuousOn_mul hec.continuousOn
  have hFTC : ∫ y in (-π)..π, G' y = e π * f π - e (-π) * f (-π) := by
    apply MeasureTheory.integral_eq_of_hasDerivAt_off_countable_of_le (fun y => e y * f y) G'
      (neg_le_self pi_pos.le) hs (hec.mul hcont).continuousOn
    · intro x hx
      exact (hed x).mul (hderiv x hx.1 hx.2)
    · convert (hI1.const_mul (-2 * π * Complex.I * n / T)).add hI2 using 1
      ext y; simp only [hG']; ring
  have h0 : e π * f π - e (-π) * f (-π) = 0 := by
    rw [per_pt_eq f hper]
    simp only [he]
    rw [fourier_pi_eq n]; ring
  rw [h0] at hFTC
  have hsplit : ∫ y in (-π)..π, G' y =
      (-2 * π * Complex.I * n / T) * (∫ y in (-π)..π, e y * f y) + ∫ y in (-π)..π, e y * f' y := by
    have := intervalIntegral.integral_add (hI1.const_mul (-2 * π * Complex.I * n / T)) hI2
    rw [intervalIntegral.integral_const_mul] at this
    rw [← this]
    congr 1; ext y; simp only [hG']; ring
  rw [hsplit] at hFTC
  rw [fourierCoeffOn_eq_integral, fourierCoeffOn_eq_integral]
  simp only [smul_eq_mul, Complex.real_smul]
  change (↑(1 / T) : ℂ) * ∫ y in (-π)..π, e y * f' y = Complex.I * n * ((↑(1 / T) : ℂ) * ∫ y in (-π)..π, e y * f y)
  have hTc : (T : ℂ) = 2 * π := by rw [hT2]; push_cast; ring
  have hπ : (π : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr pi_pos.ne'
  rw [hTc] at hFTC
  have : ∫ y in (-π)..π, e y * f' y = Complex.I * n * ∫ y in (-π)..π, e y * f y := by
    have h2 : (-2 * π * Complex.I * n / (2 * π)) = -(Complex.I * n) := by
      field_simp
    rw [h2] at hFTC
    linear_combination hFTC
  rw [this]; ring

#print axioms coeff_deriv_aux

lemma variation_sum_Icc (g : ℝ → ℂ) (x : ℕ → ℝ) (hx : Monotone x) (m : ℕ) :
    ∑ i ∈ Finset.range m, eVariationOn g (Icc (x i) (x (i + 1))) =
      eVariationOn g (Icc (x 0) (x m)) := by
  induction m with
  | zero =>
    rw [Finset.sum_range_zero, Icc_self, eVariationOn.subsingleton g subsingleton_singleton]
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have := eVariationOn.Icc_add_Icc g (s := univ) (hx (Nat.zero_le m)) (hx (Nat.le_succ m))
      (mem_univ _)
    simpa only [univ_inter] using this

#print axioms variation_sum_Icc

lemma norm_integral_le_of_bv_aux (g : ℝ → ℂ) (hper : Periodic g (2 * π))
    (hbv : BoundedVariationOn g (Icc (-π) π)) (n : ℤ) (hn : n ≠ 0) (m : ℕ) (hm : 0 < m) :
    ‖∫ y in (-π)..π, fourier (-n) (y : AddCircle (π - -π)) * g y‖ ≤
      (eVariationOn g (Icc (-π) π)).toReal / |(n : ℝ)| +
        (2 * π / m) * (eVariationOn g (Icc (-π) π)).toReal := by
  have hT2 : π - -π = 2 * π := by ring
  have hT : Fact (0 < π - -π) := ⟨by rw [hT2]; positivity⟩
  set V := (eVariationOn g (Icc (-π) π)).toReal with hV
  set e : ℝ → ℂ := fun y => fourier (-n) (y : AddCircle (π - -π)) with he
  have hec : Continuous e := (map_continuous (fourier (-n))).comp (AddCircle.continuous_mk' _)
  have hen : ∀ y, ‖e y‖ = 1 := fun y => by
    simp only [he, fourier_apply, Circle.norm_coe]
  set c0 : ℂ := ((π - -π : ℝ) : ℂ) / (-2 * π * Complex.I * n) with hc0def
  set Φ : ℝ → ℂ := fun y => c0 * e y with hΦdef
  have hΦ : ∀ y, HasDerivAt Φ (e y) y := fun y => has_antideriv_at_fourier_neg hT hn y
  have hnpos : 0 < |(n : ℝ)| := abs_pos.mpr (Int.cast_ne_zero.mpr hn)
  have hc0 : ‖c0‖ = 1 / |(n : ℝ)| := by
    rw [hc0def, norm_div, norm_mul, norm_mul, norm_mul, Complex.norm_I, Complex.norm_real,
      Complex.norm_real, Complex.norm_intCast, norm_neg, Complex.norm_ofNat, hT2]
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos (by positivity : (0:ℝ) < 2 * π),
      abs_of_pos pi_pos]
    field_simp
  have hΦn : ∀ y, ‖Φ y‖ = 1 / |(n : ℝ)| := fun y => by
    rw [hΦdef]; simp only; rw [norm_mul, hen, hc0, mul_one]
  set h : ℝ := 2 * π / m with hhdef
  have hmpos : (0 : ℝ) < m := Nat.cast_pos.mpr hm
  have hhpos : 0 ≤ h := by positivity
  set x : ℕ → ℝ := fun i => -π + i * h with hxdef
  have hx0 : x 0 = -π := by simp [hxdef]
  have hxm : x m = π := by
    simp only [hxdef, hhdef]; field_simp; ring
  have hxmono : Monotone x := by
    intro i j hij
    simp only [hxdef]
    have : (i : ℝ) ≤ j := Nat.cast_le.mpr hij
    nlinarith
  have hxmem : ∀ i ≤ m, x i ∈ Icc (-π) π := fun i hi =>
    ⟨hx0 ▸ hxmono (Nat.zero_le i), hxm ▸ hxmono hi⟩
  have hxsucc : ∀ i, |x (i + 1) - x i| = h := fun i => by
    simp only [hxdef]; push_cast
    rw [show -π + ((i : ℝ) + 1) * h - (-π + i * h) = h by ring, abs_of_nonneg hhpos]
  have hgint : ∀ a b, a ∈ Icc (-π) π → b ∈ Icc (-π) π →
      IntervalIntegrable g MeasureTheory.volume a b :=
    fun a b ha hb => hbv.intervalIntegrable (uIcc_subset_Icc ha hb)
  have hegint : ∀ a b, a ∈ Icc (-π) π → b ∈ Icc (-π) π →
      IntervalIntegrable (fun y => e y * g y) MeasureTheory.volume a b :=
    fun a b ha hb => (hgint a b ha hb).continuousOn_mul hec.continuousOn
  have hsplit : ∫ y in (-π)..π, e y * g y =
      ∑ i ∈ Finset.range m, ∫ y in (x i)..(x (i + 1)), e y * g y := by
    rw [intervalIntegral.sum_integral_adjacent_intervals, hx0, hxm]
    intro k hk; exact hegint _ _ (hxmem k hk.le) (hxmem (k + 1) hk)
  have hpiece : ∀ i ∈ Finset.range m, ∫ y in (x i)..(x (i + 1)), e y * g y =
      g (x (i + 1)) * (Φ (x (i + 1)) - Φ (x i)) +
        ∫ y in (x i)..(x (i + 1)), e y * (g y - g (x (i + 1))) := by
    intro i hi
    have hi' := Finset.mem_range.1 hi
    have hΦint : ∫ y in (x i)..(x (i + 1)), e y = Φ (x (i + 1)) - Φ (x i) :=
      intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hΦ y)
        (hec.intervalIntegrable _ _)
    have : ∫ y in (x i)..(x (i + 1)), e y * (g y - g (x (i + 1))) =
        (∫ y in (x i)..(x (i + 1)), e y * g y) - g (x (i + 1)) * ∫ y in (x i)..(x (i + 1)), e y := by
      rw [← intervalIntegral.integral_const_mul, ← intervalIntegral.integral_sub
        (hegint _ _ (hxmem i hi'.le) (hxmem (i + 1) hi')) ((hec.intervalIntegrable _ _).const_mul _)]
      congr 1; ext y; ring
    rw [this, hΦint]; ring
  have habel : ∑ i ∈ Finset.range m, g (x (i + 1)) * (Φ (x (i + 1)) - Φ (x i)) =
      ∑ i ∈ Finset.range m, (g (x i) - g (x (i + 1))) * Φ (x i) := by
    have htel := Finset.sum_range_sub (fun i => g (x i) * Φ (x i)) m
    have hend : g (x m) * Φ (x m) = g (x 0) * Φ (x 0) := by
      rw [hxm, hx0, per_pt_eq g hper]
      simp only [hΦdef, he]
      rw [fourier_pi_eq n]
    rw [hend, sub_self] at htel
    rw [← sub_eq_zero, ← Finset.sum_sub_distrib, ← htel]
    apply Finset.sum_congr rfl; intro i _; ring
  have hVi_ne : ∀ i < m, eVariationOn g (Icc (x i) (x (i + 1))) ≠ ⊤ := fun i hi =>
    ne_top_of_le_ne_top hbv (eVariationOn.mono _
      (Icc_subset_Icc (hxmem i hi.le).1 (hxmem (i + 1) hi).2))
  have herr : ∀ i ∈ Finset.range m,
      ‖∫ y in (x i)..(x (i + 1)), e y * (g y - g (x (i + 1)))‖ ≤
        (eVariationOn g (Icc (x i) (x (i + 1)))).toReal * h := by
    intro i hi
    have hi' := Finset.mem_range.1 hi
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := x i) (b := x (i + 1))
      (C := (eVariationOn g (Icc (x i) (x (i + 1)))).toReal)
      (f := fun y => e y * (g y - g (x (i + 1)))) ?_
    · rwa [hxsucc i] at this
    intro y hy
    rw [uIoc_of_le (hxmono (Nat.le_succ i))] at hy
    rw [norm_mul, hen, one_mul, ← dist_eq_norm]
    have := eVariationOn.edist_le g (s := Icc (x i) (x (i + 1))) ⟨hy.1.le, hy.2⟩
      ⟨hxmono (Nat.le_succ i), le_rfl⟩
    rw [edist_dist] at this
    exact (ENNReal.ofReal_le_iff_le_toReal (hVi_ne i hi')).1 this
  have hsumV : ∑ i ∈ Finset.range m, (eVariationOn g (Icc (x i) (x (i + 1)))).toReal ≤ V := by
    rw [← ENNReal.toReal_sum (fun i hi => hVi_ne i (Finset.mem_range.1 hi)),
      variation_sum_Icc g x hxmono m, hx0, hxm]
  have hjumps : ∑ i ∈ Finset.range m, ‖g (x i) - g (x (i + 1))‖ ≤ V := by
    have := eVariationOn.sum_le_of_monotoneOn_Iic (f := g) (s := Icc (-π) π) (n := m) (u := x)
      (hxmono.monotoneOn _) (fun i hi => hxmem i hi)
    have h2 : ENNReal.ofReal (∑ i ∈ Finset.range m, ‖g (x i) - g (x (i + 1))‖) =
        ∑ i ∈ Finset.range m, edist (g (x (i + 1))) (g (x i)) := by
      rw [ENNReal.ofReal_sum_of_nonneg (fun i _ => norm_nonneg _)]
      congr 1; ext i; rw [edist_dist, dist_eq_norm, norm_sub_rev]
    rw [← h2] at this
    exact (ENNReal.ofReal_le_iff_le_toReal hbv).1 this
  change ‖∫ y in (-π)..π, e y * g y‖ ≤ V / |(n : ℝ)| + h * V
  rw [hsplit, Finset.sum_congr rfl hpiece, Finset.sum_add_distrib, habel]
  refine (norm_add_le _ _).trans (add_le_add ?_ ?_)
  · refine (norm_sum_le _ _).trans ?_
    calc ∑ i ∈ Finset.range m, ‖(g (x i) - g (x (i + 1))) * Φ (x i)‖
        = (∑ i ∈ Finset.range m, ‖g (x i) - g (x (i + 1))‖) * (1 / |(n : ℝ)|) := by
          rw [Finset.sum_mul]; apply Finset.sum_congr rfl; intro i _; rw [norm_mul, hΦn]
      _ ≤ V * (1 / |(n : ℝ)|) := mul_le_mul_of_nonneg_right hjumps (by positivity)
      _ = V / |(n : ℝ)| := by ring
  · refine (norm_sum_le _ _).trans ?_
    refine (Finset.sum_le_sum herr).trans ?_
    rw [← Finset.sum_mul, mul_comm]
    exact mul_le_mul_of_nonneg_left hsumV hhpos

#print axioms norm_integral_le_of_bv_aux

lemma coeff_bv_bound (g : ℝ → ℂ) (hper : Periodic g (2 * π))
    (hbv : BoundedVariationOn g (Icc (-π) π)) (n : ℤ) (hn : n ≠ 0) :
    ‖fourierCoeffOn (neg_lt_self pi_pos) g n‖ ≤
      (eVariationOn g (Icc (-π) π)).toReal / (2 * π * |(n : ℝ)|) := by
  set V := (eVariationOn g (Icc (-π) π)).toReal with hV
  have hnpos : 0 < |(n : ℝ)| := abs_pos.mpr (Int.cast_ne_zero.mpr hn)
  have hI : ‖∫ y in (-π)..π, fourier (-n) (y : AddCircle (π - -π)) * g y‖ ≤ V / |(n : ℝ)| := by
    have ht : Filter.Tendsto (fun m : ℕ => V / |(n : ℝ)| + (2 * π / m) * V) Filter.atTop
        (nhds (V / |(n : ℝ)| + 0 * V)) :=
      tendsto_const_nhds.add ((tendsto_const_div_atTop_nhds_zero_nat (2 * π)).mul_const V)
    rw [zero_mul, add_zero] at ht
    refine ge_of_tendsto ht ?_
    rw [Filter.eventually_atTop]
    exact ⟨1, fun m hm => norm_integral_le_of_bv_aux g hper hbv n hn m hm⟩
  rw [fourierCoeffOn_eq_integral, norm_smul]
  simp only [smul_eq_mul]
  have hT2 : π - -π = 2 * π := by ring
  have hnorm : ‖(1 / (π - -π) : ℝ)‖ = 1 / (2 * π) := by
    rw [hT2, Real.norm_eq_abs, abs_of_pos (by positivity : (0:ℝ) < 1 / (2 * π))]
  rw [hnorm]
  calc 1 / (2 * π) * ‖∫ y in (-π)..π, fourier (-n) (y : AddCircle (π - -π)) * g y‖
      ≤ 1 / (2 * π) * (V / |(n : ℝ)|) := mul_le_mul_of_nonneg_left hI (by positivity)
    _ = V / (2 * π * |(n : ℝ)|) := by field_simp

#print axioms coeff_bv_bound

lemma Icc_succ_sum (g : ℤ → ℂ) (M : ℕ) :
    ∑ m ∈ Finset.Icc (-((M + 1 : ℕ) : ℤ)) ((M + 1 : ℕ) : ℤ), g m =
      g ((M : ℤ) + 1) + g (-((M : ℤ) + 1)) + ∑ m ∈ Finset.Icc (-(M : ℤ)) M, g m := by
  have hset : Finset.Icc (-((M + 1 : ℕ) : ℤ)) ((M + 1 : ℕ) : ℤ) =
      insert ((M : ℤ) + 1) (insert (-((M : ℤ) + 1)) (Finset.Icc (-(M : ℤ)) M)) := by
    ext z; simp only [Finset.mem_Icc, Finset.mem_insert]; push_cast; omega
  rw [hset, Finset.sum_insert, Finset.sum_insert, add_assoc]
  · simp only [Finset.mem_Icc]; omega
  · simp only [Finset.mem_insert, Finset.mem_Icc]; omega

#print axioms Icc_succ_sum

lemma pow_aux (M : ℝ) (hM : 0 ≤ M) (k : ℕ) : M ^ k * (M + 1 + k) ≤ (M + 1) ^ (k + 1) := by
  induction k with
  | zero => simp
  | succ k ih =>
    push_cast
    have h1 : 0 ≤ M ^ k := pow_nonneg hM k
    have hk0 : (0 : ℝ) ≤ k := k.cast_nonneg
    calc M ^ (k + 1) * (M + 1 + (k + 1)) = M ^ k * (M * (M + 2 + k)) := by ring
      _ ≤ M ^ k * ((M + 1) * (M + 1 + k)) :=
          mul_le_mul_of_nonneg_left (by nlinarith) h1
      _ = (M + 1) * (M ^ k * (M + 1 + k)) := by ring
      _ ≤ (M + 1) * (M + 1) ^ (k + 1) := mul_le_mul_of_nonneg_left ih (by linarith)
      _ = (M + 1) ^ (k + 1 + 1) := by ring

#print axioms pow_aux

lemma tail_aux (M : ℝ) (hM : 0 < M) (k : ℕ) (hk : 1 ≤ k) :
    1 / (M + 1) ^ (k + 1) ≤ 1 / (k * M ^ k) - 1 / (k * (M + 1) ^ k) := by
  have hkpos : (0 : ℝ) < k := by exact_mod_cast hk
  have key := pow_aux M hM.le k
  have hM1 : 0 < M + 1 := by linarith
  rw [← sub_nonneg]
  have : 1 / (k * M ^ k) - 1 / (k * (M + 1) ^ k) - 1 / (M + 1) ^ (k + 1) =
      ((M + 1) ^ (k + 1) - M ^ k * (M + 1 + k)) / (k * M ^ k * (M + 1) ^ (k + 1)) := by
    field_simp; ring
  rw [this]
  apply div_nonneg (by linarith) (by positivity)

#print axioms tail_aux

/-- **Decay of coefficients and smoothness.** Let `f` be a wave on the phase circle
(periodic with period `2π`), with derivatives `D 0 = f, D 1, …, D k`. Suppose
`D 0, …, D (k - 1)` are continuous and periodic (the wave is `C^(k-1)` round the loop;
for `k = 0` there is no condition), each `D j` with `j < k` has derivative `D (j + 1)`
except at countably many points (the jumps), and the `k`-th derivative `D k` is periodic
with finite travel (total variation) `V` over one cycle. Then for every harmonic `n ≠ 0`,
`|f̂(n)| ≤ V / (2π |n|^(k+1))`, where `f̂(n) = (1/2π) ∫_{-π}^{π} f(x) e^{-inx} dx`. -/
theorem fourierCoeff_decay_of_smoothness (k : ℕ) (f : ℝ → ℂ) (D : ℕ → ℝ → ℂ) (s : Set ℝ)
    (hD0 : D 0 = f)
    (hper : ∀ j ≤ k, Periodic (D j) (2 * π))
    (hcont : ∀ j < k, Continuous (D j))
    (hs : s.Countable)
    (hderiv : ∀ j < k, ∀ x ∈ Ioo (-π) π, x ∉ s → HasDerivAt (D j) (D (j + 1) x) x)
    (hbv : BoundedVariationOn (D k) (Icc (-π) π))
    (n : ℤ) (hn : n ≠ 0) :
    ‖fourierCoeffOn (neg_lt_self pi_pos) f n‖ ≤
      (eVariationOn (D k) (Icc (-π) π)).toReal / (2 * π * |(n : ℝ)| ^ (k + 1)) := by
  have hstep : ∀ j ≤ k, fourierCoeffOn (neg_lt_self pi_pos) (D j) n =
      (Complex.I * n) ^ j * fourierCoeffOn (neg_lt_self pi_pos) f n := by
    intro j hj
    induction j with
    | zero => simp [hD0]
    | succ j ih =>
      have hjk : j < k := hj
      have hint : IntervalIntegrable (D (j + 1)) MeasureTheory.volume (-π) π := by
        rcases lt_or_eq_of_le hj with h | h
        · exact (hcont (j + 1) h).intervalIntegrable _ _
        · rw [h]; exact hbv.intervalIntegrable (uIcc_of_le (neg_le_self pi_pos.le)).le
      rw [coeff_deriv_aux (D j) (D (j + 1)) s (hper j hjk.le) (hcont j hjk) hs
        (hderiv j hjk) hint n, ih hjk.le, pow_succ]
      ring
  have hb := coeff_bv_bound (D k) (hper k le_rfl) hbv n hn
  rw [hstep k le_rfl, norm_mul, norm_pow, norm_mul, Complex.norm_I, one_mul,
    Complex.norm_intCast] at hb
  have hnpos : 0 < |(n : ℝ)| := abs_pos.mpr (Int.cast_ne_zero.mpr hn)
  rw [le_div_iff₀ (by positivity)] at hb
  rw [le_div_iff₀ (by positivity)]
  calc ‖fourierCoeffOn (neg_lt_self pi_pos) f n‖ * (2 * π * |(n : ℝ)| ^ (k + 1))
      = |(n : ℝ)| ^ k * ‖fourierCoeffOn (neg_lt_self pi_pos) f n‖ * (2 * π * |(n : ℝ)|) := by
        ring
    _ ≤ _ := hb

/-- **One derivative, one factor of `n` (Step 1).** If a wave `f` is continuous round the
loop and has slope `f'` (integrable over a cycle) except at countably many points, then the
slope's coefficients are `i n` times the wave's: `(f')^(n) = i n f̂(n)`. -/
theorem fourierCoeff_deriv_eq_I_mul (f f' : ℝ → ℂ) (s : Set ℝ)
    (hper : Periodic f (2 * π)) (hcont : Continuous f) (hs : s.Countable)
    (hderiv : ∀ x ∈ Ioo (-π) π, x ∉ s → HasDerivAt f (f' x) x)
    (hint : IntervalIntegrable f' MeasureTheory.volume (-π) π) (n : ℤ) :
    fourierCoeffOn (neg_lt_self pi_pos) f' n = Complex.I * n * fourierCoeffOn (neg_lt_self pi_pos) f n := by
  exact coeff_deriv_aux f f' s hper hcont hs hderiv hint n

/-- **How many terms you need (Step 4).** Under the same hypotheses with `k ≥ 1`, the series
cut after harmonic `N ≥ 1`, `S_N f(x) = ∑_{|m| ≤ N} f̂(m) e^{imx}`, is within
`V / (π k N^k)` of the wave at every phase `x`. So `N ≥ (V / (π k ε))^(1/k)` harmonics
reach accuracy `ε` everywhere. -/
theorem uniform_error_le_of_smoothness (k : ℕ) (hk : 1 ≤ k) (f : ℝ → ℂ) (D : ℕ → ℝ → ℂ)
    (s : Set ℝ)
    (hD0 : D 0 = f)
    (hper : ∀ j ≤ k, Periodic (D j) (2 * π))
    (hcont : ∀ j < k, Continuous (D j))
    (hs : s.Countable)
    (hderiv : ∀ j < k, ∀ x ∈ Ioo (-π) π, x ∉ s → HasDerivAt (D j) (D (j + 1) x) x)
    (hbv : BoundedVariationOn (D k) (Icc (-π) π))
    (N : ℕ) (hN : 0 < N) (x : ℝ) :
    ‖f x - ∑ m ∈ Finset.Icc (-(N : ℤ)) N,
        fourierCoeffOn (neg_lt_self pi_pos) f m * Complex.exp (m * x * Complex.I)‖ ≤
      (eVariationOn (D k) (Icc (-π) π)).toReal / (π * k * (N : ℝ) ^ k) := by
  have hT2 : π - -π = 2 * π := by ring
  have hTpos : 0 < π - -π := by rw [hT2]; positivity
  have hT : Fact (0 < π - -π) := ⟨hTpos⟩
  set V := (eVariationOn (D k) (Icc (-π) π)).toReal with hV
  have hVnn : 0 ≤ V := ENNReal.toReal_nonneg
  set c : ℤ → ℂ := fun m => fourierCoeffOn (neg_lt_self pi_pos) f m with hc
  have hcb : ∀ m : ℤ, m ≠ 0 → ‖c m‖ ≤ V / (2 * π * |(m : ℝ)| ^ (k + 1)) := fun m hm =>
    fourierCoeff_decay_of_smoothness k f D s hD0 hper hcont hs hderiv hbv m hm
  have hfc : Continuous f := hD0 ▸ hcont 0 hk
  have hfper : Periodic f (2 * π) := hD0 ▸ hper 0 (Nat.zero_le _)
  have hfper' : Periodic f (π - -π) := by rw [hT2]; exact hfper
  let F : C(AddCircle (π - -π), ℂ) := ⟨AddCircle.liftIoc (π - -π) (-π) f,
    AddCircle.liftIoc_continuous
      (by rw [show -π + (π - -π) = π by ring]; exact (per_pt_eq f hfper).symm)
      hfc.continuousOn⟩
  have hFc : ∀ m, fourierCoeff F m = c m := fun m => rfl
  have hFx : ∀ y : ℝ, F (y : AddCircle (π - -π)) = f y := by
    intro y
    change f (toIocMod hT.out (-π) y) = f y
    rw [← self_sub_toIocDiv_zsmul]; exact hfper'.sub_zsmul_eq _
  have hsum_c : Summable c := by
    refine Summable.of_norm_bounded_eventually
      (g := fun m : ℤ => V / (2 * π) * |1 / (m : ℝ) ^ (k + 1)|)
      ((summable_one_div_int_pow.mpr (by omega)).abs.mul_left _) ?_
    filter_upwards [(Set.finite_singleton (0 : ℤ)).compl_mem_cofinite] with m hm
    have hm' : m ≠ 0 := hm
    refine (hcb m hm').trans (le_of_eq ?_)
    rw [abs_div, abs_one, abs_pow]
    ring
  have hser := has_pointwise_sum_fourier_series_of_summable (f := F)
    (by exact hsum_c) (x : AddCircle (π - -π))
  rw [hFx] at hser
  set a : ℤ → ℂ := fun m => c m * Complex.exp (m * x * Complex.I) with ha
  have hser' : HasSum a (f x) := by
    convert hser using 1
    ext m
    rw [hFc, smul_eq_mul, fourier_coe_apply]
    simp only [ha]
    congr 2
    push_cast
    have hπ : (π : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr pi_pos.ne'
    field_simp
    ring
  have han : ∀ m, ‖a m‖ = ‖c m‖ := by
    intro m; simp only [ha]; rw [norm_mul]
    have : (m : ℂ) * x * Complex.I = ((m * x : ℝ) : ℂ) * Complex.I := by push_cast; ring
    rw [this, Complex.norm_exp_ofReal_mul_I, mul_one]
  set S : ℕ → ℂ := fun M => ∑ m ∈ Finset.Icc (-(M : ℤ)) M, a m with hSdef
  have hS : Filter.Tendsto S Filter.atTop (nhds (f x)) :=
    hser'.comp (Finset.tendsto_Icc_neg (R := ℤ))
  have hkpos : (0 : ℝ) < k := by exact_mod_cast hk
  have hbound : ∀ M ≥ N, ‖S M - S N‖ ≤
      V / π * (1 / (k * (N : ℝ) ^ k) - 1 / (k * (M : ℝ) ^ k)) := by
    intro M hM
    induction M, hM using Nat.le_induction with
    | base => simp
    | succ M hNM ih =>
      have hMpos : (0 : ℝ) < M := Nat.cast_pos.mpr (lt_of_lt_of_le hN hNM)
      have hS1 : S (M + 1) - S N = a ((M : ℤ) + 1) + a (-((M : ℤ) + 1)) + (S M - S N) := by
        simp only [hSdef]; rw [Icc_succ_sum]; ring
      rw [hS1]
      have hM1 : |(((M : ℤ) + 1 : ℤ) : ℝ)| = (M : ℝ) + 1 := by
        push_cast; exact abs_of_pos (by positivity)
      have h1 : ‖a ((M : ℤ) + 1)‖ ≤ V / (2 * π * ((M : ℝ) + 1) ^ (k + 1)) := by
        rw [han, ← hM1]; exact hcb _ (by omega)
      have h2 : ‖a (-((M : ℤ) + 1))‖ ≤ V / (2 * π * ((M : ℝ) + 1) ^ (k + 1)) := by
        rw [han, ← hM1]
        have := hcb (-((M : ℤ) + 1)) (by omega)
        rwa [Int.cast_neg, abs_neg] at this
      have ht := tail_aux M hMpos k hk
      calc ‖a ((M : ℤ) + 1) + a (-((M : ℤ) + 1)) + (S M - S N)‖
          ≤ ‖a ((M : ℤ) + 1)‖ + ‖a (-((M : ℤ) + 1))‖ + ‖S M - S N‖ := norm_add₃_le
        _ ≤ V / (2 * π * ((M : ℝ) + 1) ^ (k + 1)) + V / (2 * π * ((M : ℝ) + 1) ^ (k + 1)) +
              V / π * (1 / (k * (N : ℝ) ^ k) - 1 / (k * (M : ℝ) ^ k)) := by gcongr
        _ ≤ V / π * (1 / (k * (N : ℝ) ^ k) - 1 / (k * ((M + 1 : ℕ) : ℝ) ^ k)) := by
          push_cast
          have : V / (2 * π * ((M : ℝ) + 1) ^ (k + 1)) + V / (2 * π * ((M : ℝ) + 1) ^ (k + 1)) =
              V / π * (1 / ((M : ℝ) + 1) ^ (k + 1)) := by
            field_simp; ring
          rw [this, ← mul_add]
          apply mul_le_mul_of_nonneg_left _ (by positivity)
          linarith
  have hlim : Filter.Tendsto (fun M => ‖S M - S N‖) Filter.atTop (nhds ‖f x - S N‖) :=
    (hS.sub_const _).norm
  have hfin : ‖f x - S N‖ ≤ V / π * (1 / (k * (N : ℝ) ^ k)) := by
    refine le_of_tendsto hlim (Filter.eventually_atTop.2 ⟨N, fun M hM => (hbound M hM).trans ?_⟩)
    apply mul_le_mul_of_nonneg_left _ (by positivity)
    have : 0 ≤ 1 / (k * (M : ℝ) ^ k) := by positivity
    linarith
  change ‖f x - S N‖ ≤ V / (π * k * (N : ℝ) ^ k)
  convert hfin using 1
  field_simp

/-! The card's whole-number worked examples. -/

-- The triangle wave needs harmonics up to 41; the top one sounds at 41 × 220 Hz = 9,020 Hz.
example : 41 * 220 = 9020 := by norm_num

-- Only odd harmonics are nonzero, so harmonics 1 to 41 give 21 nonzero tones.
example : ((Finset.range 42).filter Odd).card = 21 := by decide

-- The parabola wave needs harmonics up to 5; the top one sounds at 5 × 220 Hz = 1,100 Hz.
example : 5 * 220 = 1100 := by norm_num

-- The square wave needs 4,053 harmonics for 0.01 V root-mean-square: top at 891,660 Hz.
example : 4053 * 220 = 891660 := by norm_num

#print axioms fourierCoeff_decay_of_smoothness
#print axioms fourierCoeff_deriv_eq_I_mul
#print axioms uniform_error_le_of_smoothness
