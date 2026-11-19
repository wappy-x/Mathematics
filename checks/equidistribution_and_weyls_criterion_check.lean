-- Equidistribution: a sequence's fractional parts spread evenly over the stretch from 0 to 1 exactly when every nonzero spin's arrow average tends to 0, and the multiples of a number spread evenly exactly when it is irrational, with each arrow sum capped by 1/(2‖hα‖).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Algebra.Order.Round
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Nat.Sqrt
import Mathlib.Data.Nat.Log
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds

open Filter Topology

/-- A sequence `x₁, x₂, …` is equidistributed modulo 1 when, for every interval from `a` to `b`
inside the stretch from 0 to 1, the share of the first `N` points whose fractional part `{x_n}`
lands in `[a, b)` tends to the interval's length `b − a`. -/
def EquidistributedModOne (x : ℕ → ℝ) : Prop :=
  ∀ a b : ℝ, 0 ≤ a → a ≤ b → b ≤ 1 →
    Tendsto (fun N : ℕ =>
      (((Finset.Icc 1 N).filter (fun n => a ≤ Int.fract (x n) ∧ Int.fract (x n) < b)).card : ℝ) / N)
      atTop (𝓝 (b - a))

lemma weyl_geom_Icc (z : ℂ) (N : ℕ) :
    (z - 1) * ∑ n ∈ Finset.Icc 1 N, z ^ n = z ^ (N + 1) - z := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih]; ring

#print axioms weyl_geom_Icc

lemma weyl_norm_exp_sub_one (t : ℝ) :
    ‖Complex.exp (2 * Real.pi * Complex.I * (t : ℂ)) - 1‖ = 2 * |Real.sin (Real.pi * t)| := by
  have := Complex.norm_exp_I_mul_ofReal_sub_one (2 * Real.pi * t)
  have e1 : Complex.I * ((2 * Real.pi * t : ℝ) : ℂ) = 2 * Real.pi * Complex.I * (t : ℂ) := by
    push_cast; ring
  rw [e1] at this
  rw [this, norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, abs_two]
  congr 2; ring_nf

#print axioms weyl_norm_exp_sub_one

lemma weyl_two_abs_le_abs_sin (θ : ℝ) :
    2 * |θ - round θ| ≤ |Real.sin (Real.pi * θ)| := by
  set y := θ - round θ with hy
  have hy2 : |y| ≤ 1 / 2 := abs_sub_round θ
  have hs : Real.sin (Real.pi * θ) = (-1) ^ (round θ) * Real.sin (Real.pi * y) := by
    rw [← Real.sin_add_int_mul_pi]; congr 1; rw [hy]; ring
  have habs : |Real.sin (Real.pi * θ)| = |Real.sin (Real.pi * y)| := by
    rw [hs, abs_mul, abs_zpow, abs_neg, abs_one, one_zpow, one_mul]
  rw [habs]
  have key : ∀ u : ℝ, 0 ≤ u → u ≤ 1 / 2 → 2 * u ≤ Real.sin (Real.pi * u) := by
    intro u hu0 hu1
    have := Real.mul_le_sin (x := Real.pi * u) (by positivity) (by nlinarith [Real.pi_pos])
    have hp := Real.pi_pos
    calc 2 * u = 2 / Real.pi * (Real.pi * u) := by field_simp
      _ ≤ _ := this
  rcases le_total 0 y with h0 | h0
  · rw [abs_of_nonneg h0]
    have := key y h0 (by rwa [abs_of_nonneg h0] at hy2)
    exact this.trans (le_abs_self _)
  · rw [abs_of_nonpos h0]
    have := key (-y) (by linarith) (by rwa [abs_of_nonpos h0] at hy2)
    simp only [mul_neg, Real.sin_neg] at this
    linarith [neg_le_abs (Real.sin (Real.pi * y))]

#print axioms weyl_two_abs_le_abs_sin

lemma weyl_sum_mul_irrational_le_aux (α : ℝ) (hα : Irrational α) (h : ℤ) (hh : h ≠ 0) (N : ℕ) :
    ‖∑ n ∈ Finset.Icc 1 N,
        Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * ((n : ℝ) * α) : ℝ) : ℂ))‖ =
        |Real.sin (Real.pi * N * (h * α))| / |Real.sin (Real.pi * (h * α))| ∧
      |Real.sin (Real.pi * N * (h * α))| / |Real.sin (Real.pi * (h * α))| ≤
        1 / |Real.sin (Real.pi * (h * α))| ∧
      1 / |Real.sin (Real.pi * (h * α))| ≤ 1 / (2 * |h * α - round (h * α)|) := by
  set θ : ℝ := h * α with hθ
  have hirr : Irrational θ := hα.intCast_mul hh
  have hsin : Real.sin (Real.pi * θ) ≠ 0 := by
    intro h0
    rw [Real.sin_eq_zero_iff] at h0
    obtain ⟨n, hn⟩ := h0
    exact hirr.ne_int n (by
      have hp := Real.pi_pos.ne'
      apply mul_left_cancel₀ hp; linarith [hn])
  have hsinpos : 0 < |Real.sin (Real.pi * θ)| := abs_pos.mpr hsin
  set z : ℂ := Complex.exp (2 * Real.pi * Complex.I * (θ : ℂ)) with hz
  have hterm : ∀ n : ℕ, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * ((n : ℝ) * α) : ℝ) : ℂ))
      = z ^ n := by
    intro n
    rw [hz, ← Complex.exp_nat_mul]; congr 1; rw [hθ]; push_cast; ring
  have hz1 : ‖z - 1‖ = 2 * |Real.sin (Real.pi * θ)| := weyl_norm_exp_sub_one θ
  have hzN : ‖z ^ N - 1‖ = 2 * |Real.sin (Real.pi * N * θ)| := by
    rw [hz, ← Complex.exp_nat_mul]
    have := weyl_norm_exp_sub_one (N * θ)
    rw [show (N : ℂ) * (2 * Real.pi * Complex.I * (θ : ℂ)) =
      2 * Real.pi * Complex.I * (((N * θ : ℝ)) : ℂ) by push_cast; ring, this]
    congr 2; ring_nf
  have hznorm : ‖z‖ = 1 := by
    rw [hz, show 2 * Real.pi * Complex.I * (θ : ℂ) = ((2 * Real.pi * θ : ℝ) : ℂ) * Complex.I by
      push_cast; ring]
    exact Complex.norm_exp_ofReal_mul_I _
  have hz1ne : ‖z - 1‖ ≠ 0 := by rw [hz1]; positivity
  refine ⟨?_, ?_, ?_⟩
  · simp_rw [hterm]
    have hg := weyl_geom_Icc z N
    have : ∑ n ∈ Finset.Icc 1 N, z ^ n = (z ^ (N + 1) - z) / (z - 1) := by
      rw [← hg, mul_div_cancel_left₀]
      intro h0; apply hz1ne; rw [h0, norm_zero]
    rw [this, norm_div, show z ^ (N + 1) - z = z * (z ^ N - 1) by ring, norm_mul, hznorm, one_mul,
      hzN, hz1]
    field_simp
  · exact div_le_div_of_nonneg_right (Real.abs_sin_le_one _) (abs_nonneg _)
  · have hpos : 0 < 2 * |θ - round θ| := by
      have : θ - round θ ≠ 0 := sub_ne_zero.mpr (hirr.ne_int _)
      positivity
    exact one_div_le_one_div_of_le hpos (weyl_two_abs_le_abs_sin θ)

#print axioms weyl_sum_mul_irrational_le_aux

lemma weyl_exp_sub_le (a b : ℝ) :
    ‖Complex.exp (2 * Real.pi * Complex.I * (a : ℂ)) -
      Complex.exp (2 * Real.pi * Complex.I * (b : ℂ))‖ ≤ 2 * Real.pi * |a - b| := by
  have e : Complex.exp (2 * Real.pi * Complex.I * (a : ℂ)) -
      Complex.exp (2 * Real.pi * Complex.I * (b : ℂ)) =
      Complex.exp (((2 * Real.pi * b : ℝ) : ℂ) * Complex.I) *
        (Complex.exp (Complex.I * ((2 * Real.pi * (a - b) : ℝ) : ℂ)) - 1) := by
    rw [mul_sub, mul_one, ← Complex.exp_add]; congr 2 <;> push_cast <;> ring
  rw [e, norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul]
  refine (Real.norm_exp_I_mul_ofReal_sub_one_le).trans_eq ?_
  rw [Real.norm_eq_abs, abs_mul, abs_of_pos (by positivity : (0:ℝ) < 2 * Real.pi)]

#print axioms weyl_exp_sub_le

lemma weyl_exp_int_mul_fract (h : ℤ) (x : ℝ) :
    Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * x : ℝ) : ℂ)) =
      Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * Int.fract x : ℝ) : ℂ)) := by
  have hx : x = Int.fract x + (⌊x⌋ : ℝ) := by rw [Int.fract]; ring
  conv_lhs => rw [hx]
  have : 2 * Real.pi * Complex.I * (((h : ℝ) * (Int.fract x + (⌊x⌋ : ℝ)) : ℝ) : ℂ) =
      2 * Real.pi * Complex.I * (((h : ℝ) * Int.fract x : ℝ) : ℂ) +
        ((h * ⌊x⌋ : ℤ) : ℂ) * (2 * Real.pi * Complex.I) := by push_cast; ring
  rw [this, Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one]

#print axioms weyl_exp_int_mul_fract

lemma weyl_root_sum (h : ℤ) (hh : h ≠ 0) (M : ℕ) (hM : (|h| : ℝ) < M) :
    ∑ k ∈ Finset.range M,
      Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * ((k : ℝ) / M) : ℝ) : ℂ)) = 0 := by
  have hM0 : (0 : ℝ) < M := lt_of_le_of_lt (abs_nonneg _) hM
  have hM0' : (M : ℂ) ≠ 0 := by exact_mod_cast hM0.ne'
  set ω := Complex.exp (2 * Real.pi * Complex.I * h / M) with hω
  have hterm : ∀ k : ℕ, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * ((k : ℝ) / M) : ℝ) : ℂ))
      = ω ^ k := by
    intro k; rw [hω, ← Complex.exp_nat_mul]; congr 1; push_cast; field_simp
  simp_rw [hterm]
  have hω1 : ω ≠ 1 := by
    intro h1
    rw [hω, Complex.exp_eq_one_iff] at h1
    obtain ⟨n, hn⟩ := h1
    have hne : (2 * Real.pi * Complex.I : ℂ) ≠ 0 := by
      simp [Real.pi_ne_zero, Complex.I_ne_zero]
    have h2 : (h : ℂ) = n * M := by
      field_simp at hn
      linear_combination hn
    have h3 : (h : ℝ) = n * M := by exact_mod_cast h2
    have h4 : n ≠ 0 := by rintro rfl; simp at h3; exact hh (by exact_mod_cast h3)
    have : (M : ℝ) ≤ |(h : ℝ)| := by
      rw [h3, abs_mul, abs_of_pos hM0]
      have : (1 : ℝ) ≤ |(n : ℝ)| := by
        rw [← Int.cast_abs]; exact_mod_cast Int.one_le_abs h4
      nlinarith
    rw [← Int.cast_abs] at this hM
    linarith
  have hωM : ω ^ M = 1 := by
    rw [hω, ← Complex.exp_nat_mul, Complex.exp_eq_one_iff]
    exact ⟨h, by field_simp⟩
  rw [geom_sum_eq hω1, hωM, sub_self, zero_div]

#print axioms weyl_root_sum

lemma weyl_forward (x : ℕ → ℝ) (hx : EquidistributedModOne x) (h : ℤ) (hh : h ≠ 0) :
    Tendsto (fun N : ℕ => (N : ℂ)⁻¹ *
      ∑ n ∈ Finset.Icc 1 N, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * x n : ℝ) : ℂ)))
      atTop (𝓝 0) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hpi := Real.pi_pos
  have hh' : (0 : ℝ) < |(h : ℝ)| := by positivity
  obtain ⟨M, hMgt⟩ := exists_nat_gt (max |(h : ℝ)| (4 * Real.pi * |(h : ℝ)| / ε))
  have hMh : (|h| : ℝ) < M := by exact lt_of_le_of_lt (le_max_left _ _) hMgt
  have hM0 : (0 : ℝ) < M := lt_of_le_of_lt (abs_nonneg _) (lt_of_le_of_lt (le_max_left _ _) hMgt)
  have hMε : 2 * Real.pi * |(h : ℝ)| / M < ε / 2 := by
    have := lt_of_le_of_lt (le_max_right _ _) hMgt
    rw [div_lt_iff₀ hM0]
    rw [div_lt_iff₀ hε] at this
    nlinarith
  set E : ℝ → ℂ := fun t => Complex.exp (2 * Real.pi * Complex.I * (t : ℂ)) with hE
  set bin : ℕ → ℕ := fun n => ⌊(M : ℝ) * Int.fract (x n)⌋₊ with hbin
  have hbin_lt : ∀ n, bin n < M := by
    intro n
    have := Int.fract_lt_one (x n)
    have h0 := Int.fract_nonneg (x n)
    rw [hbin]; dsimp only
    rw [Nat.floor_lt (by positivity)]
    nlinarith
  have hbin_iff : ∀ n k, bin n = k ↔
      ((k : ℝ) / M ≤ Int.fract (x n) ∧ Int.fract (x n) < ((k : ℝ) + 1) / M) := by
    intro n k
    rw [hbin]; dsimp only
    rw [Nat.floor_eq_iff (by have := Int.fract_nonneg (x n); positivity), div_le_iff₀ hM0,
      lt_div_iff₀ hM0]
    constructor <;> rintro ⟨h1, h2⟩ <;> constructor <;> linarith
  -- the step-function sums tend to zero
  have hT : Tendsto (fun N : ℕ => ∑ k ∈ Finset.range M,
      E ((h : ℝ) * ((k : ℝ) / M)) *
        ((((((Finset.Icc 1 N).filter (fun n => (k : ℝ) / M ≤ Int.fract (x n) ∧
          Int.fract (x n) < ((k : ℝ) + 1) / M)).card : ℝ) / N : ℝ)) : ℂ)) atTop
      (𝓝 (∑ k ∈ Finset.range M, E ((h : ℝ) * ((k : ℝ) / M)) * (((1 / M : ℝ)) : ℂ))) := by
    apply tendsto_finsetSum
    intro k hk
    apply Tendsto.const_mul
    apply (Complex.continuous_ofReal.tendsto _).comp
    have hk' : (k : ℝ) + 1 ≤ M := by
      have := Finset.mem_range.mp hk; exact_mod_cast this
    have := hx ((k : ℝ) / M) (((k : ℝ) + 1) / M) (by positivity)
      (div_le_div_of_nonneg_right (by linarith) hM0.le) (by rwa [div_le_one hM0])
    convert this using 2
    field_simp; ring
  rw [← Finset.sum_mul, weyl_root_sum h hh M hMh, zero_mul] at hT
  rw [Metric.tendsto_atTop] at hT
  obtain ⟨N0, hN0⟩ := hT (ε / 2) (by positivity)
  refine ⟨max N0 1, fun N hN => ?_⟩
  have hN1 : 1 ≤ N := le_trans (le_max_right _ _) hN
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN1
  have hT' := hN0 N (le_trans (le_max_left _ _) hN)
  rw [dist_zero_right] at hT' ⊢
  -- rewrite the step sum as a sum over n
  have hstep : ∑ k ∈ Finset.range M,
      E ((h : ℝ) * ((k : ℝ) / M)) *
        ((((((Finset.Icc 1 N).filter (fun n => (k : ℝ) / M ≤ Int.fract (x n) ∧
          Int.fract (x n) < ((k : ℝ) + 1) / M)).card : ℝ) / N : ℝ)) : ℂ) =
      (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * ((bin n : ℝ) / M)) := by
    conv_rhs => rw [← Finset.sum_fiberwise_of_maps_to (g := bin) (t := Finset.range M)
      (fun n _ => Finset.mem_range.mpr (hbin_lt n)), Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro k hk
    have hfil : (Finset.Icc 1 N).filter (fun n => bin n = k) =
        (Finset.Icc 1 N).filter (fun n => (k : ℝ) / M ≤ Int.fract (x n) ∧
          Int.fract (x n) < ((k : ℝ) + 1) / M) := Finset.filter_congr (fun n _ => hbin_iff n k)
    rw [Finset.sum_congr rfl (fun n hn => by rw [(Finset.mem_filter.mp hn).2] :
      ∀ n ∈ (Finset.Icc 1 N).filter (fun n => bin n = k),
        E ((h : ℝ) * ((bin n : ℝ) / M)) = E ((h : ℝ) * ((k : ℝ) / M))), Finset.sum_const, hfil,
      nsmul_eq_mul]
    push_cast; ring
  rw [hstep] at hT'
  have herr : ‖(N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * x n) -
      (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * ((bin n : ℝ) / M))‖ ≤
      2 * Real.pi * |(h : ℝ)| / M := by
    rw [← mul_sub, ← Finset.sum_sub_distrib, norm_mul, norm_inv, Complex.norm_natCast]
    rw [inv_mul_le_iff₀ hNpos]
    refine (norm_sum_le _ _).trans ?_
    have hcard : ((Finset.Icc 1 N).card : ℝ) = N := by simp
    calc ∑ n ∈ Finset.Icc 1 N, ‖E ((h : ℝ) * x n) - E ((h : ℝ) * ((bin n : ℝ) / M))‖
        ≤ ∑ n ∈ Finset.Icc 1 N, 2 * Real.pi * |(h : ℝ)| / M := by
          apply Finset.sum_le_sum
          intro n _
          rw [hE]; dsimp only
          rw [weyl_exp_int_mul_fract h (x n)]
          refine (weyl_exp_sub_le _ _).trans ?_
          have hb := (hbin_iff n (bin n)).mp rfl
          have hd : |Int.fract (x n) - (bin n : ℝ) / M| ≤ 1 / M := by
            rw [abs_le]; constructor
            · have := hb.1; have : (0:ℝ) < 1 / M := by positivity
              linarith
            · have := hb.2; rw [add_div] at this; linarith
          rw [← mul_sub, abs_mul]
          calc 2 * Real.pi * (|(h : ℝ)| * |Int.fract (x n) - (bin n : ℝ) / M|)
              ≤ 2 * Real.pi * (|(h : ℝ)| * (1 / M)) := by gcongr
            _ = 2 * Real.pi * |(h : ℝ)| / M := by ring
      _ = N * (2 * Real.pi * |(h : ℝ)| / M) := by rw [Finset.sum_const, nsmul_eq_mul, hcard]
  calc ‖(N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * x n)‖
      ≤ ‖(N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * x n) -
      (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * ((bin n : ℝ) / M))‖ +
        ‖(N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, E ((h : ℝ) * ((bin n : ℝ) / M))‖ := norm_le_norm_sub_add _ _
    _ < ε / 2 + ε / 2 := by linarith
    _ = ε := by ring

#print axioms weyl_forward

lemma weyl_coe_fract (t : ℝ) :
    ((t : ℝ) : AddCircle (1 : ℝ)) = ((Int.fract t : ℝ) : AddCircle (1 : ℝ)) := by
  have h0 : ((⌊t⌋ : ℝ) : AddCircle (1 : ℝ)) = 0 := (AddCircle.coe_eq_zero_iff 1).2 ⟨⌊t⌋, by simp⟩
  rw [Int.fract, AddCircle.coe_sub, h0, sub_zero]

#print axioms weyl_coe_fract

lemma weyl_span (x : ℕ → ℝ)
    (hW : ∀ h : ℤ, h ≠ 0 →
        Tendsto (fun N : ℕ => (N : ℂ)⁻¹ *
          ∑ n ∈ Finset.Icc 1 N, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * x n : ℝ) : ℂ)))
          atTop (𝓝 0))
    (F : C(AddCircle (1 : ℝ), ℂ)) (hF : F ∈ Submodule.span ℂ (Set.range (@fourier 1))) :
    Tendsto (fun N : ℕ => (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, F ((x n : ℝ) : AddCircle (1 : ℝ)))
      atTop (𝓝 (∫ t in (0 : ℝ)..1, F ((t : ℝ) : AddCircle (1 : ℝ)))) := by
  have hcont : ∀ G : C(AddCircle (1 : ℝ), ℂ),
      Continuous (fun t : ℝ => G ((t : ℝ) : AddCircle (1 : ℝ))) :=
    fun G => G.continuous.comp (AddCircle.continuous_mk' 1)
  induction hF using Submodule.span_induction with
  | mem G hG =>
    obtain ⟨m, rfl⟩ := hG
    by_cases hm : m = 0
    · subst hm
      simp only [fourier_zero, Finset.sum_const, Nat.card_Icc, add_tsub_cancel_right, nsmul_eq_mul,
        mul_one, intervalIntegral.integral_const, sub_zero, one_smul]
      apply tendsto_const_nhds.congr'
      filter_upwards [eventually_ge_atTop 1] with N hN
      have : (N : ℂ) ≠ 0 := by exact_mod_cast (show N ≠ 0 by omega)
      field_simp
    · have hfun : ∀ t : ℝ, fourier m ((t : ℝ) : AddCircle (1 : ℝ)) =
          Complex.exp (2 * Real.pi * Complex.I * (((m : ℝ) * t : ℝ) : ℂ)) := by
        intro t; rw [fourier_coe_apply]; push_cast; ring_nf
      have hint : ∫ t in (0 : ℝ)..1, fourier m ((t : ℝ) : AddCircle (1 : ℝ)) = 0 := by
        simp_rw [hfun]
        have hc : (2 * Real.pi * Complex.I * m : ℂ) ≠ 0 := by
          simp [Real.pi_ne_zero, Complex.I_ne_zero, hm]
        have := integral_exp_mul_complex (a := 0) (b := 1) hc
        have e1 : ∀ t : ℝ, Complex.exp (2 * Real.pi * Complex.I * (((m : ℝ) * t : ℝ) : ℂ)) =
            Complex.exp (2 * Real.pi * Complex.I * m * t) := by intro t; push_cast; ring_nf
        simp_rw [e1, this]
        have e2 : Complex.exp (2 * Real.pi * Complex.I * m * ((1 : ℝ) : ℂ)) = 1 := by
          rw [← Complex.exp_int_mul_two_pi_mul_I m]; push_cast; ring_nf
        rw [e2]; simp
      rw [hint]
      simp_rw [hfun]
      exact hW m hm
  | zero => simp
  | add F G _ _ hF hG =>
    have := hF.add hG
    rw [← intervalIntegral.integral_add ((hcont F).intervalIntegrable _ _)
      ((hcont G).intervalIntegrable _ _)] at this
    convert this using 1
    · ext N; simp [Finset.sum_add_distrib, mul_add]
  | smul c F _ hF =>
    have := hF.const_mul c
    rw [← intervalIntegral.integral_const_mul] at this
    convert this using 1
    · ext N; simp [Finset.mul_sum]; apply Finset.sum_congr rfl; intro n _; ring

#print axioms weyl_span

lemma weyl_all_continuous (x : ℕ → ℝ)
    (hW : ∀ h : ℤ, h ≠ 0 →
        Tendsto (fun N : ℕ => (N : ℂ)⁻¹ *
          ∑ n ∈ Finset.Icc 1 N, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * x n : ℝ) : ℂ)))
          atTop (𝓝 0))
    (F : C(AddCircle (1 : ℝ), ℂ)) :
    Tendsto (fun N : ℕ => (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, F ((x n : ℝ) : AddCircle (1 : ℝ)))
      atTop (𝓝 (∫ t in (0 : ℝ)..1, F ((t : ℝ) : AddCircle (1 : ℝ)))) := by
  have hcont : ∀ G : C(AddCircle (1 : ℝ), ℂ),
      Continuous (fun t : ℝ => G ((t : ℝ) : AddCircle (1 : ℝ))) :=
    fun G => G.continuous.comp (AddCircle.continuous_mk' 1)
  have hmem : F ∈ (Submodule.span ℂ (Set.range (@fourier 1))).topologicalClosure := by
    rw [span_fourier_closure_eq_top]; trivial
  rw [← SetLike.mem_coe, Submodule.topologicalClosure_coe, Metric.mem_closure_iff] at hmem
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨P, hP, hFP⟩ := hmem (ε / 3) (by positivity)
  have hpt : ∀ y, ‖F y - P y‖ ≤ dist F P := by
    intro y; rw [← dist_eq_norm]; exact ContinuousMap.dist_apply_le_dist y
  obtain ⟨N0, hN0⟩ := Metric.tendsto_atTop.mp (weyl_span x hW P hP) (ε / 3) (by positivity)
  refine ⟨max N0 1, fun N hN => ?_⟩
  have hN1 : 1 ≤ N := le_trans (le_max_right _ _) hN
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN1
  have h2 := hN0 N (le_trans (le_max_left _ _) hN)
  rw [dist_eq_norm] at h2 ⊢
  have h1 : ‖(N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, F ((x n : ℝ) : AddCircle (1 : ℝ)) -
      (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, P ((x n : ℝ) : AddCircle (1 : ℝ))‖ ≤ dist F P := by
    rw [← mul_sub, ← Finset.sum_sub_distrib, norm_mul, norm_inv, Complex.norm_natCast,
      inv_mul_le_iff₀ hNpos]
    refine (norm_sum_le _ _).trans ?_
    refine (Finset.sum_le_sum (fun n _ => hpt _)).trans ?_
    simp
  have h3 : ‖(∫ t in (0 : ℝ)..1, P ((t : ℝ) : AddCircle (1 : ℝ))) -
      ∫ t in (0 : ℝ)..1, F ((t : ℝ) : AddCircle (1 : ℝ))‖ ≤ dist F P := by
    rw [← intervalIntegral.integral_sub ((hcont P).intervalIntegrable _ _)
      ((hcont F).intervalIntegrable _ _)]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := 1)
      (C := dist F P) (f := fun t : ℝ => P ((t : ℝ) : AddCircle (1 : ℝ)) -
        F ((t : ℝ) : AddCircle (1 : ℝ))) (fun t _ => by rw [norm_sub_rev]; exact hpt _)
    simpa using this
  calc _ = ‖((N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, F ((x n : ℝ) : AddCircle (1 : ℝ)) -
      (N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, P ((x n : ℝ) : AddCircle (1 : ℝ))) +
      ((N : ℂ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, P ((x n : ℝ) : AddCircle (1 : ℝ)) -
        ∫ t in (0 : ℝ)..1, P ((t : ℝ) : AddCircle (1 : ℝ))) +
      ((∫ t in (0 : ℝ)..1, P ((t : ℝ) : AddCircle (1 : ℝ))) -
        ∫ t in (0 : ℝ)..1, F ((t : ℝ) : AddCircle (1 : ℝ)))‖ := by congr 1; ring
    _ ≤ _ := norm_add₃_le
    _ < ε := by linarith

#print axioms weyl_all_continuous

lemma weyl_lower (x : ℕ → ℝ)
    (hW : ∀ h : ℤ, h ≠ 0 →
        Tendsto (fun N : ℕ => (N : ℂ)⁻¹ *
          ∑ n ∈ Finset.Icc 1 N, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * x n : ℝ) : ℂ)))
          atTop (𝓝 0))
    (a b : ℝ) (ha : 0 ≤ a) (hb : b ≤ 1) (ε : ℝ) (hε : 0 < ε) :
    ∀ᶠ N : ℕ in atTop, b - a - ε <
      (((Finset.Icc 1 N).filter (fun n => a ≤ Int.fract (x n) ∧ Int.fract (x n) < b)).card : ℝ) / N := by
  by_cases hsmall : b - a < ε
  · refine Eventually.of_forall (fun N => ?_)
    have : (0 : ℝ) ≤ (((Finset.Icc 1 N).filter
      (fun n => a ≤ Int.fract (x n) ∧ Int.fract (x n) < b)).card : ℝ) / N := by positivity
    linarith
  replace hsmall := not_lt.mp hsmall
  set δ := ε / 4 with hδ
  have hδ0 : 0 < δ := by positivity
  set T : ℝ → ℝ := fun t => max 0 (min 1 (min ((t - a) / δ) ((b - t) / δ))) with hT
  have hTc : Continuous T := by rw [hT]; fun_prop
  have hT0 : T 0 = 0 := by
    rw [hT]; dsimp only
    apply max_eq_left
    have : (0 - a) / δ ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) hδ0.le
    exact (min_le_right _ _).trans ((min_le_left _ _).trans this)
  have hT1 : T 1 = 0 := by
    rw [hT]; dsimp only
    apply max_eq_left
    have : (b - 1) / δ ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) hδ0.le
    exact (min_le_right _ _).trans ((min_le_right _ _).trans this)
  have hTle : ∀ t, T t ≤ if a ≤ t ∧ t < b then 1 else 0 := by
    intro t
    split_ifs with hc
    · rw [hT]; dsimp only; exact max_le zero_le_one (min_le_left _ _)
    · rw [hT]; dsimp only
      apply le_of_eq; apply max_eq_left
      rcases not_and_or.mp hc with h1 | h1
      · have : (t - a) / δ ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) hδ0.le
        exact (min_le_right _ _).trans ((min_le_left _ _).trans this)
      · have : (b - t) / δ ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) hδ0.le
        exact (min_le_right _ _).trans ((min_le_right _ _).trans this)
  -- the continuous function on the circle
  set F : C(AddCircle (1 : ℝ), ℂ) :=
    ⟨AddCircle.liftIco 1 0 (fun t => (T t : ℂ)),
      AddCircle.liftIco_continuous (by simp [hT0, hT1])
        (Complex.continuous_ofReal.comp hTc).continuousOn⟩ with hF
  have hFapp : ∀ t : ℝ, F ((t : ℝ) : AddCircle (1 : ℝ)) = (T (Int.fract t) : ℂ) := by
    intro t
    rw [hF, ContinuousMap.coe_mk, weyl_coe_fract t, AddCircle.liftIco_coe_apply]
    exact ⟨Int.fract_nonneg t, by rw [zero_add]; exact Int.fract_lt_one t⟩
  have hlim := weyl_all_continuous x hW F
  simp_rw [hFapp] at hlim
  have hint : ∫ t in (0 : ℝ)..1, (T (Int.fract t) : ℂ) = ((∫ t in (0 : ℝ)..1, T t : ℝ) : ℂ) := by
    rw [← intervalIntegral.integral_ofReal]
    apply intervalIntegral.integral_congr
    intro t ht
    rw [Set.uIcc_of_le zero_le_one] at ht
    dsimp only
    rcases eq_or_lt_of_le ht.2 with h1 | h1
    · rw [h1, Int.fract_one, hT0, hT1]
    · rw [Int.fract_eq_self.mpr ⟨ht.1, h1⟩]
  rw [hint] at hlim
  have hlimR : Tendsto (fun N : ℕ => (N : ℝ)⁻¹ * ∑ n ∈ Finset.Icc 1 N, T (Int.fract (x n)))
      atTop (𝓝 (∫ t in (0 : ℝ)..1, T t)) := by
    have := (Complex.continuous_re.tendsto _).comp hlim
    convert this using 2; simp
  have hintge : b - a - 2 * δ ≤ ∫ t in (0 : ℝ)..1, T t := by
    have h1 : ∫ t in (a + δ)..(b - δ), T t = b - a - 2 * δ := by
      rw [intervalIntegral.integral_congr (g := fun _ => (1 : ℝ))]
      · simp; ring
      · intro t ht
        rw [Set.uIcc_of_le (by linarith)] at ht
        rw [hT]; dsimp only
        have e1 : 1 ≤ (t - a) / δ := by rw [le_div_iff₀ hδ0]; linarith [ht.1]
        have e2 : 1 ≤ (b - t) / δ := by rw [le_div_iff₀ hδ0]; linarith [ht.2]
        rw [min_eq_left (le_min e1 e2), max_eq_right zero_le_one]
    rw [← h1]
    apply intervalIntegral.integral_mono_interval (by linarith) (by linarith) (by linarith)
    · exact Eventually.of_forall (fun t => le_max_left _ _)
    · exact hTc.intervalIntegrable _ _
  filter_upwards [(tendsto_order.1 hlimR).1 (b - a - ε) (by linarith)] with N hN
  refine lt_of_lt_of_le hN ?_
  rw [div_eq_inv_mul, Finset.natCast_card_filter]
  apply mul_le_mul_of_nonneg_left _ (by positivity)
  exact Finset.sum_le_sum (fun n _ => hTle _)

#print axioms weyl_lower

lemma weyl_partition (x : ℕ → ℝ) (a b : ℝ) (hab : a ≤ b) (N : ℕ) :
    (((Finset.Icc 1 N).filter (fun n => 0 ≤ Int.fract (x n) ∧ Int.fract (x n) < a)).card : ℝ) +
      (((Finset.Icc 1 N).filter (fun n => a ≤ Int.fract (x n) ∧ Int.fract (x n) < b)).card : ℝ) +
      (((Finset.Icc 1 N).filter (fun n => b ≤ Int.fract (x n) ∧ Int.fract (x n) < 1)).card : ℝ) =
      N := by
  simp only [Finset.natCast_card_filter, ← Finset.sum_add_distrib]
  rw [Finset.sum_congr rfl (g := fun _ => (1 : ℝ))]
  · simp
  intro n _
  have h0 := Int.fract_nonneg (x n)
  have hl := Int.fract_lt_one (x n)
  rcases lt_or_ge (Int.fract (x n)) a with h1 | h1
  · rw [ite_eq_left ⟨h0, h1⟩, ite_eq_right (fun h => by linarith [h.1]), ite_eq_right (fun h => by linarith [h.1])]
    norm_num
  · rcases lt_or_ge (Int.fract (x n)) b with h2 | h2
    · rw [ite_eq_right (fun h => by linarith [h.2]), ite_eq_left ⟨h1, h2⟩, ite_eq_right (fun h => by linarith [h.1])]
      norm_num
    · rw [ite_eq_right (fun h => by linarith [h.2]), ite_eq_right (fun h => by linarith [h.2]), ite_eq_left ⟨h2, hl⟩]
      norm_num

#print axioms weyl_partition

/-- Weyl's criterion: a sequence is equidistributed modulo 1 if and only if, for every whole
number `h ≠ 0`, the average of the spun arrows `e(h x_n) = exp(2πi h x_n)` over the first `N`
points tends to 0 as `N` grows. -/
theorem weyl_criterion (x : ℕ → ℝ) :
    EquidistributedModOne x ↔
      ∀ h : ℤ, h ≠ 0 →
        Tendsto (fun N : ℕ => (N : ℂ)⁻¹ *
          ∑ n ∈ Finset.Icc 1 N, Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * x n : ℝ) : ℂ)))
          atTop (𝓝 0) := by
  constructor
  · intro hx h hh
    exact weyl_forward x hx h hh
  · intro hW a b ha hab hb
    rw [tendsto_order]
    constructor
    · intro c hc
      exact (weyl_lower x hW a b ha hb (b - a - c) (by linarith)).mono (fun N hN => by linarith)
    · intro c hc
      have hε : 0 < (c - (b - a)) / 2 := by linarith
      filter_upwards [weyl_lower x hW 0 a le_rfl (by linarith) _ hε,
        weyl_lower x hW b 1 (by linarith) le_rfl _ hε, eventually_ge_atTop 1] with N h1 h2 hN
      have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
      have hpart := weyl_partition x a b hab N
      have hsum : (((Finset.Icc 1 N).filter
            (fun n => 0 ≤ Int.fract (x n) ∧ Int.fract (x n) < a)).card : ℝ) / N +
          (((Finset.Icc 1 N).filter
            (fun n => a ≤ Int.fract (x n) ∧ Int.fract (x n) < b)).card : ℝ) / N +
          (((Finset.Icc 1 N).filter
            (fun n => b ≤ Int.fract (x n) ∧ Int.fract (x n) < 1)).card : ℝ) / N = 1 := by
        rw [← add_div, ← add_div, hpart, div_self hNpos.ne']
      linarith

/-- Multiples of one step: the points `α, 2α, 3α, …` are equidistributed modulo 1 exactly when
`α` is irrational. A rational step `m/q` fails, since at spin `h = q` every arrow is 1. -/
theorem equidistributed_mul_iff_irrational (α : ℝ) :
    EquidistributedModOne (fun n => (n : ℝ) * α) ↔ Irrational α := by
  constructor
  · intro hE
    by_contra hirr
    obtain ⟨r, hr⟩ := not_not.mp hirr
    have hden : ((r.den : ℤ)) ≠ 0 := by exact_mod_cast r.den_nz
    have hlim := (weyl_criterion _).mp hE (r.den : ℤ) hden
    have hterm : ∀ n : ℕ, Complex.exp (2 * Real.pi * Complex.I *
        (((((r.den : ℤ) : ℝ)) * ((n : ℝ) * α) : ℝ) : ℂ)) = 1 := by
      intro n
      rw [← hr]
      have e : (((r.den : ℤ) : ℝ)) * ((n : ℝ) * (r : ℝ)) = (((n : ℤ) * r.num : ℤ) : ℝ) := by
        have hd : (r.den : ℝ) ≠ 0 := by exact_mod_cast r.den_nz
        rw [Rat.cast_def]; push_cast; field_simp
      rw [e, ← Complex.exp_int_mul_two_pi_mul_I ((n : ℤ) * r.num)]
      congr 1; push_cast; ring
    simp only [hterm, Finset.sum_const, Nat.card_Icc, add_tsub_cancel_right, nsmul_eq_mul,
      mul_one] at hlim
    have hone : Tendsto (fun N : ℕ => (N : ℂ)⁻¹ * (N : ℂ)) atTop (𝓝 1) := by
      apply tendsto_const_nhds.congr'
      filter_upwards [eventually_ge_atTop 1] with N hN
      have : (N : ℂ) ≠ 0 := by exact_mod_cast (show N ≠ 0 by omega)
      field_simp
    exact one_ne_zero (tendsto_nhds_unique hone hlim)
  · intro hα
    apply (weyl_criterion _).mpr
    intro h hh
    set C := 1 / |Real.sin (Real.pi * (h * α))| with hC
    have hbound : ∀ N : ℕ, ‖∑ n ∈ Finset.Icc 1 N,
        Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * ((n : ℝ) * α) : ℝ) : ℂ))‖ ≤ C := by
      intro N
      obtain ⟨heq, hle, -⟩ := weyl_sum_mul_irrational_le_aux α hα h hh N
      rw [heq]; exact hle
    apply squeeze_zero_norm (a := fun N : ℕ => C / N)
    · intro N
      rw [norm_mul, norm_inv, Complex.norm_natCast, div_eq_inv_mul]
      exact mul_le_mul_of_nonneg_left (hbound N) (by positivity)
    · exact tendsto_const_div_atTop_nhds_zero_nat C

/-- The cap on the arrow sum for multiples of an irrational `α`: for every whole number `h ≠ 0`
and every `N`, the sum `S_N(h) = Σ_{n ≤ N} e(h n α)` has size
`|sin(π N h α)| / |sin(π h α)|`, which is at most `1 / |sin(π h α)|`, which is at most
`1 / (2‖hα‖)`, where `‖hα‖` is the distance from `hα` to the nearest whole number.
The cap does not depend on `N`. -/
theorem weyl_sum_mul_irrational_le (α : ℝ) (hα : Irrational α) (h : ℤ) (hh : h ≠ 0) (N : ℕ) :
    ‖∑ n ∈ Finset.Icc 1 N,
        Complex.exp (2 * Real.pi * Complex.I * (((h : ℝ) * ((n : ℝ) * α) : ℝ) : ℂ))‖ =
        |Real.sin (Real.pi * N * (h * α))| / |Real.sin (Real.pi * (h * α))| ∧
      |Real.sin (Real.pi * N * (h * α))| / |Real.sin (Real.pi * (h * α))| ≤
        1 / |Real.sin (Real.pi * (h * α))| ∧
      1 / |Real.sin (Real.pi * (h * α))| ≤ 1 / (2 * |h * α - round (h * α)|) := by
  exact weyl_sum_mul_irrational_le_aux α hα h hh N

/-! ## The card's whole-number worked examples -/

-- Multiples of 99/70, n = 1..1000: {99n/70} = (99n mod 70)/70, so the ten bins of width 0.1
-- hold 100, 99, 101, 100, 101, 99, 100, 99, 101, 100 points.
example : (List.range 10).map (fun b => ((Finset.Icc 1 1000).filter
    (fun n => 10 * (99 * n % 70) / 70 = b)).card) =
      [100, 99, 101, 100, 101, 99, 100, 99, 101, 100] := by
  decide +kernel

-- The narrow interval [0.001, 0.014) gets 0 of the first 1,000 multiples of 99/70.
example : ((Finset.Icc 1 1000).filter
    (fun n => 70 ≤ 1000 * (99 * n % 70) ∧ 1000 * (99 * n % 70) < 980)).card = 0 := by
  decide +kernel

-- At spin h = 70 each point n × 99/70 becomes 99n turns, a whole number, so every arrow is 1.
example (n : ℕ) : (70 : ℚ) * (n * (99 / 70)) = 99 * n := by ring

-- Multiples of √2, n = 1..1000, counted exactly: ⌊10{n√2}⌋ = ⌊√(200n²)⌋ − 10⌊√(2n²)⌋, and the
-- ten bins hold 100, 99, 101, 100, 101, 99, 100, 100, 101, 99 points.
example : (List.range 10).map (fun b => ((Finset.Icc 1 1000).filter
    (fun n => Nat.sqrt (200 * n ^ 2) - 10 * Nat.sqrt (2 * n ^ 2) = b)).card) =
      [100, 99, 101, 100, 101, 99, 100, 100, 101, 99] := by
  decide +kernel

-- The narrow interval [0.001, 0.014) gets 13 of the first 1,000 multiples of √2, its fair share:
-- {n√2} ∈ [0.001, 0.014) exactly when 1 ≤ ⌊1000{n√2}⌋ ≤ 13.
example : ((Finset.Icc 1 1000).filter (fun n =>
    1 ≤ Nat.sqrt (2000000 * n ^ 2) - 1000 * Nat.sqrt (2 * n ^ 2) ∧
      Nat.sqrt (2000000 * n ^ 2) - 1000 * Nat.sqrt (2 * n ^ 2) ≤ 13)).card = 13 := by
  decide +kernel

-- |2h² − m²| = 1 with m the whole number nearest h√2 happens, for h up to 1,000, exactly at
-- h = 1, 2, 5, 12, 29, 70, 169, 408, 985 (the Pell denominators, 99/70 among them).
example : (Finset.Icc 1 1000).filter (fun h =>
    Nat.sqrt (2 * h ^ 2) ^ 2 + 1 = 2 * h ^ 2 ∨ (Nat.sqrt (2 * h ^ 2) + 1) ^ 2 = 2 * h ^ 2 + 1) =
      {1, 2, 5, 12, 29, 70, 169, 408, 985} := by
  decide +kernel
example : 2 * 70 ^ 2 - 99 ^ 2 = (-1 : ℤ) := by norm_num

-- Leading digit 1: 111 of the numbers 1 to 999, and 1,111 of the numbers 1 to 1,999.
example : ((Finset.Icc 1 999).filter (fun n => n / 10 ^ Nat.log 10 n = 1)).card = 111 := by
  decide +kernel
example : ((Finset.Icc 1 1999).filter (fun n => n / 10 ^ Nat.log 10 n = 1)).card = 1111 := by
  decide +kernel

-- Powers 2ⁿ, n = 1..1000: 301 start with 1 and 45 start with 9.
example : ((Finset.Icc 1 1000).filter (fun n => 2 ^ n / 10 ^ Nat.log 10 (2 ^ n) = 1)).card = 301 := by
  decide +kernel
example : ((Finset.Icc 1 1000).filter (fun n => 2 ^ n / 10 ^ Nat.log 10 (2 ^ n) = 9)).card = 45 := by
  decide +kernel

#print axioms weyl_criterion
#print axioms equidistributed_mul_iff_irrational
#print axioms weyl_sum_mul_irrational_le
