-- Gauss sums: for every odd prime p the quadratic Gauss sum is exactly √p when p ≡ 1 mod 4 and i√p when p ≡ 3 mod 4, it equals the sum of ζ_p^(x²), and every non-trivial character mod p has a Gauss sum of size √p.
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.NumberTheory.DirichletCharacter.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.GaussSum
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.Analysis.SpecialFunctions.Gaussian.PoissonSummation
import Mathlib.NumberTheory.ModularForms.JacobiTheta.TwoVariable
import Mathlib.Analysis.SpecialFunctions.Pow.Continuity

open Complex Finset

section GaussSumHelpers
open Real Filter Topology

lemma gs_tail_bound (s : ℝ) (hs : 0 < s) (g : ℤ → ℂ)
    (hg : ∀ k : ℤ, ‖g k‖ ≤ rexp (-π * s * (k : ℝ) ^ 2)) :
    ‖∑' k, g k - g 0‖ ≤ 2 * (rexp (-π * s) / (1 - rexp (-π * s))) := by
  set q := rexp (-π * s) with hqdef
  have hq0 : 0 ≤ q := (Real.exp_pos _).le
  have hq1 : q < 1 := by
    rw [hqdef, ← Real.exp_zero]
    exact Real.exp_lt_exp.mpr (by nlinarith [Real.pi_pos])
  have hb : ∀ n : ℕ, rexp (-π * s * ((n : ℝ) + 1) ^ 2) ≤ q ^ (n + 1) := by
    intro n
    rw [hqdef, ← Real.exp_nat_mul]
    apply Real.exp_le_exp.mpr
    push_cast
    have h1 : ((n : ℝ) + 1) ≤ ((n : ℝ) + 1) ^ 2 := by nlinarith
    have h2 : 0 < π * s := mul_pos Real.pi_pos hs
    nlinarith
  have hgeo : HasSum (fun n : ℕ => q ^ (n + 1)) (q / (1 - q)) := by
    have := (hasSum_geometric_of_lt_one hq0 hq1).mul_left q
    simpa [pow_succ', div_eq_mul_inv] using this
  have h1 : ∀ n : ℕ, ‖g ((n : ℤ) + 1)‖ ≤ q ^ (n + 1) := fun n => by
    have := hg ((n : ℤ) + 1); push_cast at this; exact this.trans (hb n)
  have h2 : ∀ n : ℕ, ‖g (-((n : ℤ) + 1))‖ ≤ q ^ (n + 1) := fun n => by
    have := hg (-((n : ℤ) + 1)); push_cast at this; rw [neg_sq] at this; exact this.trans (hb n)
  have s1 : Summable (fun n : ℕ => g ((n : ℤ) + 1)) := Summable.of_norm_bounded hgeo.summable h1
  have s2 : Summable (fun n : ℕ => g (-((n : ℤ) + 1))) := Summable.of_norm_bounded hgeo.summable h2
  have s0 : Summable (fun n : ℕ => g n) := (summable_nat_add_iff 1).mp (by simpa using s1)
  rw [tsum_of_nat_of_neg_add_one s0 s2, s0.tsum_eq_zero_add]
  have e1 : ∑' n : ℕ, g ((n + 1 : ℕ) : ℤ) = ∑' n : ℕ, g ((n : ℤ) + 1) := by
    congr 1
  rw [e1]
  have : g ((0 : ℕ) : ℤ) + ∑' n : ℕ, g ((n : ℤ) + 1) + ∑' n : ℕ, g (-((n : ℤ) + 1)) - g 0
      = ∑' n : ℕ, g ((n : ℤ) + 1) + ∑' n : ℕ, g (-((n : ℤ) + 1)) := by simp only [Nat.cast_zero]; ring
  rw [this]
  refine (norm_add_le _ _).trans ?_
  have := tsum_of_norm_bounded hgeo h1
  have := tsum_of_norm_bounded hgeo h2
  linarith

#print axioms gs_tail_bound

lemma gs_bound_tendsto (c : ℝ) (hc : 0 < c) :
    Tendsto (fun t : ℝ => 2 * (rexp (-π * (t⁻¹ * c)) / (1 - rexp (-π * (t⁻¹ * c)))))
      (𝓝[>] 0) (𝓝 0) := by
  have hs : Tendsto (fun t : ℝ => t⁻¹ * c) (𝓝[>] 0) atTop :=
    tendsto_inv_nhdsGT_zero.atTop_mul_const hc
  have hq : Tendsto (fun t : ℝ => rexp (-π * (t⁻¹ * c))) (𝓝[>] 0) (𝓝 0) :=
    Real.tendsto_exp_atBot.comp (hs.const_mul_atTop_of_neg (by linarith [Real.pi_pos]))
  have := ((hq.div (tendsto_const_nhds.sub hq) (by norm_num : (1:ℝ) - 0 ≠ 0)).const_mul 2)
  simpa using this

#print axioms gs_bound_tendsto

lemma gs_theta_tendsto (c : ℝ) (hc : 0 < c) (φ : ℝ → ℤ → ℝ) (hφ0 : ∀ t, φ t 0 = 0) :
    Tendsto (fun t : ℝ => ∑' k : ℤ, cexp (↑(-π * (t⁻¹ * c) * (k : ℝ) ^ 2) + ↑(φ t k) * I))
      (𝓝[>] 0) (𝓝 1) := by
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero' (Eventually.of_forall fun t => norm_nonneg _) ?_ (gs_bound_tendsto c hc)
  filter_upwards [self_mem_nhdsWithin] with t ht
  have ht : 0 < t := ht
  have h := gs_tail_bound (t⁻¹ * c) (by positivity)
    (fun k : ℤ => cexp (↑(-π * (t⁻¹ * c) * (k : ℝ) ^ 2) + ↑(φ t k) * I)) (fun k => by
      rw [Complex.norm_exp]
      simp only [add_re, ofReal_re, mul_re, ofReal_im, I_re, I_im]
      apply le_of_eq; congr 1; ring)
  simpa [hφ0] using h

#print axioms gs_theta_tendsto

lemma gs_summable (a : ℂ) (ha : 0 < a.re) : Summable (fun n : ℤ => cexp (-π * a * n ^ 2)) := by
  have := (summable_jacobiTheta₂_term_iff 0 (I * a)).mpr (by simpa using ha)
  convert this using 2 with n
  simp only [jacobiTheta₂_term]
  congr 1
  ring_nf; rw [I_sq]; ring

#print axioms gs_summable

lemma gs_tsum_split (f : ℤ → ℂ) (hf : Summable f) (M : ℕ) [NeZero M] :
    ∑' n, f n = ∑ r ∈ range M, ∑' m : ℤ, f (m * M + r) := by
  let e : Fin M × ℤ ≃ ℤ := (Equiv.prodComm _ _).trans (Int.divModEquiv M).symm
  have hs : Summable (f ∘ e) := e.summable_iff.mpr hf
  rw [← e.tsum_eq]
  change ∑' c, (f ∘ e) c = _
  rw [Summable.tsum_prod' hs (fun r => hs.prod_factor r), tsum_fintype]
  rw [← Fin.sum_univ_eq_sum_range (fun r => ∑' m : ℤ, f (m * M + r))]
  rfl

#print axioms gs_tsum_split

lemma gs_cpow_half_ofReal_mul (t : ℝ) (ht : 0 < t) (w : ℂ) (hw : w ≠ 0) :
    ((t : ℂ) * w) ^ (1 / 2 : ℂ) = (Real.sqrt t : ℂ) * w ^ (1 / 2 : ℂ) := by
  have ht' : (t : ℂ) ≠ 0 := by exact_mod_cast ht.ne'
  rw [Complex.cpow_def_of_ne_zero (mul_ne_zero ht' hw), Complex.log_ofReal_mul ht hw,
    Complex.cpow_def_of_ne_zero hw, add_mul, Complex.exp_add, Real.sqrt_eq_rpow,
    Complex.ofReal_cpow ht.le, Complex.cpow_def_of_ne_zero ht', ← Complex.ofReal_log ht.le]
  push_cast
  ring_nf

#print axioms gs_cpow_half_ofReal_mul

lemma gs_sideA (N : ℕ) [NeZero N] (t : ℝ) (ht : 0 < t) :
    ((Real.sqrt t * N : ℝ) : ℂ) * ∑' n : ℤ, cexp (-π * ((t : ℂ) - 2 * I / N) * n ^ 2)
      = ∑ r ∈ range N, cexp (2 * π * I * ((r : ℂ) ^ 2) / N) *
        ∑' k : ℤ, cexp (↑(-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2) +
          ↑(2 * π * r * k / N) * I) := by
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  have hNr : (N : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  have ht' : (t : ℂ) ≠ 0 := by exact_mod_cast ht.ne'
  have hre : 0 < ((t : ℂ) - 2 * I / N).re := by
    have : ((t : ℂ) - 2 * I / N) = (t : ℂ) + ((-2 / (N : ℝ) : ℝ) : ℂ) * I := by
      push_cast; ring
    rw [this]; simpa using ht
  rw [gs_tsum_split _ (gs_summable _ hre) N, Finset.mul_sum]
  refine Finset.sum_congr rfl (fun r _ => ?_)
  have hterm : ∀ m : ℤ, cexp (-π * ((t : ℂ) - 2 * I / N) * (((m * N + r : ℤ)) : ℂ) ^ 2)
      = cexp (2 * π * I * ((r : ℂ) ^ 2) / N) * cexp (-π * t * r ^ 2) *
        cexp (-π * ((t : ℂ) * N ^ 2) * m ^ 2 + 2 * π * (-(t * N * r : ℂ)) * m) := by
    intro m
    rw [← Complex.exp_add, ← Complex.exp_add]
    have : -π * ((t : ℂ) - 2 * I / N) * (((m * N + r : ℤ)) : ℂ) ^ 2
        = (2 * π * I * ((r : ℂ) ^ 2) / N + -π * t * r ^ 2 +
          (-π * ((t : ℂ) * N ^ 2) * m ^ 2 + 2 * π * (-(t * N * r : ℂ)) * m)) +
          ((m ^ 2 * N + 2 * m * r : ℤ) : ℂ) * (2 * π * I) := by
      push_cast; field_simp; ring
    rw [this, Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one]
  simp_rw [hterm]
  have hre2 : 0 < ((t : ℂ) * N ^ 2).re := by
    have : ((t : ℂ) * N ^ 2) = ((t * N ^ 2 : ℝ) : ℂ) := by push_cast; ring
    rw [this, ofReal_re]; positivity
  rw [tsum_mul_left, Complex.tsum_exp_neg_quadratic hre2]
  have hsq : ((t : ℂ) * N ^ 2) ^ (1 / 2 : ℂ) = ((Real.sqrt t * N : ℝ) : ℂ) := by
    rw [gs_cpow_half_ofReal_mul t ht _ (pow_ne_zero 2 hN), one_div,
      Complex.sq_cpow_two_inv (by simp [Nat.pos_of_ne_zero (NeZero.ne N)])]
    push_cast; ring
  rw [hsq]
  have hsqne : ((Real.sqrt t * N : ℝ) : ℂ) ≠ 0 := by
    have : 0 < Real.sqrt t * N := mul_pos (Real.sqrt_pos.mpr ht)
      (Nat.cast_pos.mpr (Nat.pos_of_ne_zero (NeZero.ne N)))
    exact_mod_cast this.ne'
  have hS : cexp (-π * (t : ℂ) * (r : ℂ) ^ 2) *
      ∑' n : ℤ, cexp (-π / ((t : ℂ) * (N : ℂ) ^ 2) * ((n : ℂ) + I * -((t : ℂ) * N * r)) ^ 2)
      = ∑' k : ℤ, cexp (↑(-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2) +
          ↑(2 * π * r * k / N) * I) := by
    rw [← tsum_mul_left]
    congr 1; ext k
    rw [← Complex.exp_add]
    congr 1
    push_cast
    field_simp
    ring_nf
    rw [I_sq]
    ring
  rw [← hS]
  field_simp

#print axioms gs_sideA

lemma gs_I3 : I ^ 3 = -I := by rw [pow_succ, I_sq]; ring

#print axioms gs_I3

lemma gs_cpow_ne_zero (z s : ℂ) (hz : z ≠ 0) : z ^ s ≠ 0 := by
  rw [Complex.cpow_def_of_ne_zero hz]; exact Complex.exp_ne_zero _

#print axioms gs_cpow_ne_zero

lemma gs_sideB (N : ℕ) [NeZero N] (t : ℝ) (ht : 0 < t) :
    ((Real.sqrt t * N : ℝ) : ℂ) * ∑' n : ℤ, cexp (-π * ((t : ℂ) - 2 * I / N) * n ^ 2)
      = N / (((t : ℂ) - 2 * I / N) ^ (1 / 2 : ℂ) *
          (2 * (N : ℂ) ^ 2 / (2 + I * N * t)) ^ (1 / 2 : ℂ)) *
        ∑ e ∈ range 2, cexp (-π * I * N * (e : ℂ) ^ 2 / 2) *
          ∑' k : ℤ, cexp (↑(-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2) +
            ((-π * (k : ℝ) ^ 2 / (2 * N) + π * e * k : ℝ) : ℂ) * I) := by
  set a : ℂ := (t : ℂ) - 2 * I / N with ha_def
  set w : ℂ := 2 * (N : ℂ) ^ 2 / (2 + I * N * t) with hw_def
  set D : ℂ := (t : ℂ) * w with hD_def
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  have hNr : (N : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  have ht' : (t : ℂ) ≠ 0 := by exact_mod_cast ht.ne'
  have hden : (2 + I * N * t : ℂ) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have hw0 : w ≠ 0 := div_ne_zero (mul_ne_zero two_ne_zero (pow_ne_zero 2 hN)) hden
  have hD0 : D ≠ 0 := mul_ne_zero ht' hw0
  have ha_eq : a = (t : ℂ) + ((-2 / (N : ℝ) : ℝ) : ℂ) * I := by
    rw [ha_def]; push_cast; ring
  have hre : 0 < a.re := by rw [ha_eq]; simpa using ht
  have ha0 : a ≠ 0 := by
    intro h; rw [h] at hre; simp at hre
  have hkey : 1 / a = I * N / 2 + D / 4 := by
    have e1 : a = ((t : ℂ) * N - 2 * I) / N := by rw [ha_def]; field_simp
    have h0 : (t : ℂ) * N - 2 * I ≠ 0 := by
      intro h; rw [h, zero_div] at e1; exact ha0 e1
    rw [e1, hD_def, hw_def]
    generalize hz : (2 + I * N * t : ℂ) = z at *
    field_simp
    rw [← hz]
    ring_nf
    simp only [I_sq, gs_I3]
    ring
  have hDinv : 1 / D = ((t⁻¹ * ((N : ℝ) ^ 2)⁻¹ : ℝ) : ℂ) + I / (2 * N) := by
    rw [hD_def, hw_def]; push_cast; field_simp
  have hDre : 0 < D.re := by
    have h1 : 0 < (1 / D).re := by
      rw [hDinv]; simp only [add_re, ofReal_re, div_re, I_re, I_im]; simp; positivity
    have : D = (1 / D)⁻¹ := by field_simp
    rw [this, inv_re]; exact div_pos h1 (normSq_pos.mpr (by simpa using hD0))
  rw [Complex.tsum_exp_neg_mul_int_sq hre]
  have hsum : Summable (fun n : ℤ => cexp (-π / a * (n : ℂ) ^ 2)) := by
    have hre' : 0 < (a⁻¹).re := by rw [inv_re]; exact div_pos hre (normSq_pos.mpr ha0)
    exact (gs_summable a⁻¹ hre').congr (fun n => by rw [div_eq_mul_inv])
  rw [gs_tsum_split _ hsum 2]
  have hterm : ∀ e ∈ range 2, ∑' m : ℤ, cexp (-π / a * (((m * (2 : ℕ) + e : ℤ)) : ℂ) ^ 2)
      = cexp (-π * I * N * (e : ℂ) ^ 2 / 2) * (1 / D ^ (1 / 2 : ℂ) *
        ∑' k : ℤ, cexp (↑(-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2) +
            ((-π * (k : ℝ) ^ 2 / (2 * N) + π * e * k : ℝ) : ℂ) * I)) := by
    intro e _
    have h1 : ∀ m : ℤ, cexp (-π / a * (((m * (2 : ℕ) + e : ℤ)) : ℂ) ^ 2)
        = cexp (-π * I * N * (e : ℂ) ^ 2 / 2) * cexp (-π * D * (e : ℂ) ^ 2 / 4) *
          cexp (-π * D * m ^ 2 + 2 * π * (-(D * e / 2)) * m) := by
      intro m
      rw [← Complex.exp_add, ← Complex.exp_add]
      have : -π / a * (((m * (2 : ℕ) + e : ℤ)) : ℂ) ^ 2
          = (-π * I * N * (e : ℂ) ^ 2 / 2 + -π * D * (e : ℂ) ^ 2 / 4 +
            (-π * D * m ^ 2 + 2 * π * (-(D * e / 2)) * m)) +
            ((-((N : ℤ) * m ^ 2 + N * m * e)) : ℤ) * (2 * π * I) := by
        rw [div_eq_mul_one_div (-π : ℂ) a, hkey]; push_cast; ring
      rw [this, Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one]
    simp_rw [h1]
    rw [tsum_mul_left, Complex.tsum_exp_neg_quadratic hDre, mul_assoc]
    congr 1
    rw [mul_left_comm]
    congr 1
    rw [← tsum_mul_left]
    congr 1; ext k
    rw [← Complex.exp_add]
    congr 1
    have h2 : -π * D * (e : ℂ) ^ 2 / 4 + -π / D * ((k : ℂ) + I * -(D * e / 2)) ^ 2
        = -π * (1 / D) * (k : ℂ) ^ 2 + π * I * e * k := by
      field_simp
      ring_nf
      rw [I_sq]
      ring
    rw [h2, hDinv]
    push_cast
    ring
  rw [Finset.sum_congr rfl hterm]
  simp_rw [mul_left_comm (cexp _) (1 / D ^ (1 / 2 : ℂ))]
  rw [← Finset.mul_sum, hD_def, gs_cpow_half_ofReal_mul t ht w hw0]
  have h3 : ((Real.sqrt t : ℝ) : ℂ) ≠ 0 := by
    exact_mod_cast (Real.sqrt_pos.mpr ht).ne'
  have h4 := gs_cpow_ne_zero a (1 / 2) ha0
  have h5 := gs_cpow_ne_zero w (1 / 2) hw0
  push_cast
  field_simp

#print axioms gs_sideB

lemma gs_eval (N : ℕ) [NeZero N] :
    ∑ r ∈ range N, cexp (2 * π * I * ((r : ℂ) ^ 2) / N)
      = N / ((-2 * I / N) ^ (1 / 2 : ℂ) * ((N : ℂ) ^ 2) ^ (1 / 2 : ℂ)) *
        ∑ e ∈ range 2, cexp (-π * I * N * (e : ℂ) ^ 2 / 2) := by
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  have hNr : (0 : ℝ) < N := Nat.cast_pos.mpr (Nat.pos_of_ne_zero (NeZero.ne N))
  have hc : (0 : ℝ) < ((N : ℝ) ^ 2)⁻¹ := by positivity
  have hA : Tendsto (fun t : ℝ => ∑ r ∈ range N, cexp (2 * π * I * ((r : ℂ) ^ 2) / N) *
        ∑' k : ℤ, cexp (((-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2 : ℝ) : ℂ) +
          ((2 * π * r * k / N : ℝ) : ℂ) * I)) (𝓝[>] 0)
        (𝓝 (∑ r ∈ range N, cexp (2 * π * I * ((r : ℂ) ^ 2) / N) * 1)) := by
    apply tendsto_finsetSum
    intro r _
    exact tendsto_const_nhds.mul
      (gs_theta_tendsto _ hc (fun t k => 2 * π * r * k / N) (by intro t; simp))
  have h0 : Tendsto (fun t : ℝ => (t : ℂ)) (𝓝[>] 0) (𝓝 0) := by
    have := (continuous_ofReal.tendsto (0 : ℝ)).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simpa using this
  have ha : Tendsto (fun t : ℝ => ((t : ℂ) - 2 * I / N) ^ (1 / 2 : ℂ)) (𝓝[>] 0)
      (𝓝 ((-2 * I / N) ^ (1 / 2 : ℂ))) := by
    have h1 : Tendsto (fun t : ℝ => ((t : ℂ) - 2 * I / N)) (𝓝[>] 0) (𝓝 (-2 * I / N)) := by
      have := h0.sub (tendsto_const_nhds (x := 2 * I / N))
      convert this using 2; ring
    refine ((continuousAt_cpow_const ?_).tendsto).comp h1
    rw [mem_slitPlane_iff]; right
    have : (-2 * I / N : ℂ) = ((-2 / (N : ℝ) : ℝ) : ℂ) * I := by push_cast; ring
    rw [this]; simp [hNr.ne']
  have hw : Tendsto (fun t : ℝ => (2 * (N : ℂ) ^ 2 / (2 + I * N * t)) ^ (1 / 2 : ℂ)) (𝓝[>] 0)
      (𝓝 (((N : ℂ) ^ 2) ^ (1 / 2 : ℂ))) := by
    have h1 : Tendsto (fun t : ℝ => (2 * (N : ℂ) ^ 2 / (2 + I * N * t))) (𝓝[>] 0)
        (𝓝 ((N : ℂ) ^ 2)) := by
      have := (tendsto_const_nhds (x := 2 * (N : ℂ) ^ 2)).div
        (tendsto_const_nhds.add (tendsto_const_nhds.mul h0)) (by simp : (2 : ℂ) + I * N * 0 ≠ 0)
      convert this using 2; simp
    refine ((continuousAt_cpow_const ?_).tendsto).comp h1
    rw [mem_slitPlane_iff]; left
    have : ((N : ℂ) ^ 2) = (((N : ℝ) ^ 2 : ℝ) : ℂ) := by push_cast; ring
    rw [this, ofReal_re]; positivity
  have hB : Tendsto (fun t : ℝ => N / (((t : ℂ) - 2 * I / N) ^ (1 / 2 : ℂ) *
          (2 * (N : ℂ) ^ 2 / (2 + I * N * t)) ^ (1 / 2 : ℂ)) *
        ∑ e ∈ range 2, cexp (-π * I * N * (e : ℂ) ^ 2 / 2) *
          ∑' k : ℤ, cexp (((-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2 : ℝ) : ℂ) +
            ((-π * (k : ℝ) ^ 2 / (2 * N) + π * e * k : ℝ) : ℂ) * I)) (𝓝[>] 0)
        (𝓝 (N / ((-2 * I / N) ^ (1 / 2 : ℂ) * ((N : ℂ) ^ 2) ^ (1 / 2 : ℂ)) *
          ∑ e ∈ range 2, cexp (-π * I * N * (e : ℂ) ^ 2 / 2) * 1)) := by
    have hne : (-2 * I / N) ^ (1 / 2 : ℂ) * ((N : ℂ) ^ 2) ^ (1 / 2 : ℂ) ≠ 0 :=
      mul_ne_zero (gs_cpow_ne_zero _ _ (by simp [hN])) (gs_cpow_ne_zero _ _ (pow_ne_zero 2 hN))
    refine (tendsto_const_nhds.div (ha.mul hw) hne).mul (tendsto_finsetSum _ fun e _ => ?_)
    exact tendsto_const_nhds.mul
      (gs_theta_tendsto _ hc (fun t k => -π * (k : ℝ) ^ 2 / (2 * N) + π * e * k)
        (by intro t; simp))
  have hEq2 : ∀ᶠ t in 𝓝[>] (0 : ℝ), (∑ r ∈ range N, cexp (2 * π * I * ((r : ℂ) ^ 2) / N) *
        ∑' k : ℤ, cexp (((-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2 : ℝ) : ℂ) +
          ((2 * π * r * k / N : ℝ) : ℂ) * I)) = N / (((t : ℂ) - 2 * I / N) ^ (1 / 2 : ℂ) *
          (2 * (N : ℂ) ^ 2 / (2 + I * N * t)) ^ (1 / 2 : ℂ)) *
        ∑ e ∈ range 2, cexp (-π * I * N * (e : ℂ) ^ 2 / 2) *
          ∑' k : ℤ, cexp (((-π * (t⁻¹ * ((N : ℝ) ^ 2)⁻¹) * (k : ℝ) ^ 2 : ℝ) : ℂ) +
            ((-π * (k : ℝ) ^ 2 / (2 * N) + π * e * k : ℝ) : ℂ) * I) := by
    filter_upwards [self_mem_nhdsWithin] with t ht
    rw [← gs_sideA N t ht, ← gs_sideB N t ht]
  have := tendsto_nhds_unique (hA.congr' hEq2) hB
  simpa using this

#print axioms gs_eval

lemma gs_eval_odd (N : ℕ) (hN : N % 2 = 1) :
    ∑ r ∈ range N, cexp (2 * π * I * ((r : ℂ) ^ 2) / N)
      = if N % 4 = 1 then (Real.sqrt N : ℂ) else I * Real.sqrt N := by
  have hpos : 0 < N := by omega
  have : NeZero N := ⟨by omega⟩
  have hNr : (0 : ℝ) < N := Nat.cast_pos.mpr hpos
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (by omega)
  have hs : (0 : ℝ) < Real.sqrt N := Real.sqrt_pos.mpr hNr
  have hs' : ((Real.sqrt N : ℝ) : ℂ) ≠ 0 := by exact_mod_cast hs.ne'
  have hss : ((Real.sqrt N : ℝ) : ℂ) ^ 2 = N := by
    rw [← ofReal_pow, Real.sq_sqrt hNr.le]; push_cast; rfl
  have h1 : (-2 * I / N) ^ (1 / 2 : ℂ) = (1 - I) / (Real.sqrt N : ℂ) := by
    have hx : 0 < ((1 - I) / (Real.sqrt N : ℂ)).re := by
      have : (1 - I) / (Real.sqrt N : ℂ) = (((Real.sqrt N)⁻¹ : ℝ) : ℂ) + ((-(Real.sqrt N)⁻¹ : ℝ) : ℂ) * I := by
        push_cast; field_simp; ring
      rw [this]; simp; positivity
    have : (-2 * I / N : ℂ) = ((1 - I) / (Real.sqrt N : ℂ)) ^ 2 := by
      rw [div_pow, hss]; ring_nf; rw [I_sq]; ring
    rw [this, one_div, Complex.sq_cpow_two_inv hx]
  have h2 : ((N : ℂ) ^ 2) ^ (1 / 2 : ℂ) = N := by
    rw [one_div, Complex.sq_cpow_two_inv (by simp [hpos])]
  rw [gs_eval N, h1, h2, Finset.sum_range_succ, Finset.sum_range_one]
  set m := N / 4 with hm
  have h1I : (1 : ℂ) - I ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have hfac : (N : ℂ) / ((1 - I) / (Real.sqrt N : ℂ) * N) = (Real.sqrt N : ℂ) / (1 - I) := by
    field_simp
  rw [hfac]
  simp only [Nat.cast_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
    zero_div, Complex.exp_zero]
  have h4 : N % 4 = 1 ∨ N % 4 = 3 := by omega
  rcases h4 with h | h
  · simp only [h, ↓reduceIte]
    have he : cexp (-π * I * N * ((1 : ℕ) : ℂ) ^ 2 / 2) = -I := by
      have hN' : (N : ℂ) = 4 * (m : ℂ) + 1 := by
        have : N = 4 * m + 1 := by omega
        exact_mod_cast this
      have : -π * I * N * ((1 : ℕ) : ℂ) ^ 2 / 2 = -π / 2 * I + ((-(m : ℤ) : ℤ) : ℂ) * (2 * π * I) := by
        rw [hN']; push_cast; ring
      rw [this, Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one, exp_neg_pi_div_two_mul_I]
    rw [he]
    field_simp
    ring
  · have hn : ¬ N % 4 = 1 := by omega
    simp only [hn, ↓reduceIte]
    have he : cexp (-π * I * N * ((1 : ℕ) : ℂ) ^ 2 / 2) = I := by
      have hN' : (N : ℂ) = 4 * (m : ℂ) + 3 := by
        have : N = 4 * m + 3 := by omega
        exact_mod_cast this
      have : -π * I * N * ((1 : ℕ) : ℂ) ^ 2 / 2 = π / 2 * I + ((-(m : ℤ) - 1 : ℤ) : ℂ) * (2 * π * I) := by
        rw [hN']; push_cast; ring
      rw [this, Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one, exp_pi_div_two_mul_I]
    rw [he]
    field_simp
    ring_nf
    simp only [I_sq]
    ring

#print axioms gs_eval_odd

end GaussSumHelpers

lemma gs_sum_range_eq_sum_zmod (p : ℕ) [NeZero p] {M : Type*} [AddCommMonoid M]
    (f : ZMod p → M) : ∑ a ∈ range p, f (a : ZMod p) = ∑ a : ZMod p, f a := by
  refine Finset.sum_bij' (fun a _ => (a : ZMod p)) (fun b _ => b.val) (by simp)
    (fun b _ => by simpa using ZMod.val_lt b) (fun a ha => ?_) (fun b _ => by simp) (fun _ _ => rfl)
  simpa using ZMod.val_cast_of_lt (Finset.mem_range.mp ha)

#print axioms gs_sum_range_eq_sum_zmod

lemma gs_exp_eq_stdAddChar (p : ℕ) [NeZero p] (a : ℕ) :
    exp (2 * Real.pi * I * a / p) = ZMod.stdAddChar (a : ZMod p) := by
  have := ZMod.stdAddChar_coe (N := p) (a : ℤ)
  simpa using this.symm

#print axioms gs_exp_eq_stdAddChar

/-- The quadratic Gauss sum mod `p`: the `p`-th roots of unity `ζ_p ^ a = e^(2πia/p)`,
`a = 0, …, p - 1`, each weighted by the Legendre symbol `(a/p)`, and added. -/
noncomputable def quadGaussSum (p : ℕ) [Fact p.Prime] : ℂ :=
  ∑ a ∈ range p, (legendreSym p a : ℂ) * exp (2 * Real.pi * I * a / p)

lemma gs_sum_exp_sq_eq (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    ∑ x ∈ range p, exp (2 * Real.pi * I * ((x : ℂ) ^ 2) / p) = quadGaussSum p := by
  set ψ : AddChar (ZMod p) ℂ := ZMod.stdAddChar
  have hL : ∑ x ∈ range p, exp (2 * Real.pi * I * ((x : ℂ) ^ 2) / p)
      = ∑ y : ZMod p, ψ (y ^ 2) := by
    rw [← gs_sum_range_eq_sum_zmod p (fun y => ψ (y ^ 2))]
    refine Finset.sum_congr rfl (fun x _ => ?_)
    have := gs_exp_eq_stdAddChar p (x ^ 2)
    push_cast at this
    exact this
  have hR : quadGaussSum p = ∑ y : ZMod p, quadraticChar (ZMod p) y * ψ y := by
    unfold quadGaussSum
    rw [← gs_sum_range_eq_sum_zmod p (fun y => (quadraticChar (ZMod p) y : ℂ) * ψ y)]
    refine Finset.sum_congr rfl (fun x _ => ?_)
    rw [gs_exp_eq_stdAddChar p x, legendreSym, Int.cast_natCast]
  rw [hL, hR]
  classical
  have hfib : ∑ y : ZMod p, ψ (y ^ 2)
      = ∑ b : ZMod p, ∑ y ∈ univ.filter (fun y : ZMod p => y ^ 2 = b), ψ (y ^ 2) :=
    (Finset.sum_fiberwise univ (fun y : ZMod p => y ^ 2) _).symm
  rw [hfib]
  have hcard : ∀ b : ZMod p, ∑ y ∈ univ.filter (fun y : ZMod p => y ^ 2 = b), ψ (y ^ 2)
      = (quadraticChar (ZMod p) b + 1 : ℤ) * ψ b := by
    intro b
    rw [Finset.sum_congr rfl (fun y hy => by rw [(Finset.mem_filter.mp hy).2]), Finset.sum_const,
      nsmul_eq_mul]
    congr 1
    have h := quadraticChar_card_sqrts ((ZMod.ringChar_zmod_n p).substr hp) b
    rw [Set.toFinset_ofPred] at h
    exact_mod_cast h
  simp_rw [hcard]
  push_cast
  simp_rw [add_mul, one_mul, Finset.sum_add_distrib]
  have hne : ψ ≠ 1 := by
    have := ZMod.isPrimitive_stdAddChar p (a := 1) one_ne_zero
    rwa [AddChar.mulShift_one] at this
  rw [AddChar.sum_eq_zero_of_ne_one hne, add_zero]

#print axioms gs_sum_exp_sq_eq

/-- The card's main claim: for an odd prime `p`, the quadratic Gauss sum is exactly `√p`
when `p` leaves remainder 1 on division by 4, and `i√p` when it leaves remainder 3. -/
theorem quadGaussSum_eq_sqrt_or_I_sqrt (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    quadGaussSum p = if p % 4 = 1 then (Real.sqrt p : ℂ) else I * Real.sqrt p := by
  have hodd : p % 2 = 1 := Nat.odd_iff.mp ((Fact.out : p.Prime).odd_of_ne_two hp)
  rw [← gs_sum_exp_sq_eq p hp]
  exact gs_eval_odd p hodd

/-- The two forms of `g` agree: for an odd prime `p`, adding `ζ_p ^ (x²)` over every
`x = 0, …, p - 1`, `x = 0` included, gives the Legendre-weighted sum. -/
theorem sum_exp_sq_eq_quadGaussSum (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    ∑ x ∈ range p, exp (2 * Real.pi * I * ((x : ℂ) ^ 2) / p) = quadGaussSum p := by
  exact gs_sum_exp_sq_eq p hp

/-- For a prime `p`, every non-trivial Dirichlet character `χ` mod `p` has a Gauss sum
`g(χ) = Σ χ(a) ζ_p ^ a` of size exactly `√p`. -/
theorem norm_gaussSum_of_ne_one (p : ℕ) [Fact p.Prime] (χ : DirichletCharacter ℂ p)
    (hχ : χ ≠ 1) :
    ‖∑ a ∈ range p, χ (a : ZMod p) * exp (2 * Real.pi * I * a / p)‖ = Real.sqrt p := by
  have hg : ∑ a ∈ range p, χ (a : ZMod p) * exp (2 * Real.pi * I * a / p)
      = gaussSum χ ZMod.stdAddChar := by
    rw [gaussSum, ← gs_sum_range_eq_sum_zmod p (fun a => χ a * ZMod.stdAddChar a)]
    refine Finset.sum_congr rfl (fun x _ => ?_)
    rw [gs_exp_eq_stdAddChar p x]
  rw [hg]
  have h1 := gaussSum_mul_gaussSum_eq_card hχ (ZMod.isPrimitive_stdAddChar p)
  rw [← star_gaussSum_eq, ZMod.card] at h1
  have h2 : ‖gaussSum χ ZMod.stdAddChar‖ ^ 2 = p := by
    have := Complex.mul_conj (gaussSum χ ZMod.stdAddChar)
    rw [← starRingEnd_apply] at h1
    rw [h1, Complex.normSq_eq_norm_sq] at this
    exact_mod_cast this.symm
  rw [← h2, Real.sqrt_sq (norm_nonneg _)]

-- The squares mod 7: x² mod 7 for x = 0, …, 6 is 0, 1, 4, 2, 2, 4, 1, so the squares are 0, 1, 2, 4.
example : (List.range 7).map (fun x => x ^ 2 % 7) = [0, 1, 4, 2, 2, 4, 1] := by decide
example : (range 7).image (fun x => x ^ 2 % 7) = {0, 1, 2, 4} := by decide

-- Euler's criterion mod 7, a = 1, …, 6: a³ mod 7 is 1, 1, 6, 1, 6, 6, so the symbols are + + - + - -.
example : (List.range' 1 6).map (fun a => a ^ 3 % 7) = [1, 1, 6, 1, 6, 6] := by decide

section seven
local instance : Fact (Nat.Prime 7) := ⟨by norm_num⟩

-- The Legendre symbols mod 7 for a = 1, …, 6, and (-1/7) = -1, so g² = -7.
example : legendreSym 7 1 = 1 ∧ legendreSym 7 2 = 1 ∧ legendreSym 7 3 = -1 ∧
    legendreSym 7 4 = 1 ∧ legendreSym 7 5 = -1 ∧ legendreSym 7 6 = -1 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> norm_num
example : legendreSym 7 (-1) * 7 = -7 := by norm_num

end seven

-- 7 leaves 3 on division by 4, so g = i√7; and the determinant's direction is i^21 = i.
example : 7 % 4 = 3 := by norm_num
example : 7 * (7 - 1) / 2 = 21 ∧ 21 % 4 = 1 := by norm_num

-- Schur's eigenvalue counts for p = 7, (m₁, m₂, m₃, m₄) = (2, 2, 2, 1): they total 7,
-- (m₁ + m₂) - (m₃ + m₄) = 1, and (m₁ - m₂)² + (m₃ - m₄)² = 1.
example : (2 + 2 + 2 + 1 : ℤ) = 7 ∧ ((2 + 2) - (2 + 1) : ℤ) = 1 ∧
    ((2 - 2) ^ 2 + (2 - 1) ^ 2 : ℤ) = 1 := by norm_num

-- 14 odd primes below 50.
example : ((range 50).filter (fun n => n.Prime ∧ n ≠ 2)).card = 14 := by decide

#print axioms quadGaussSum_eq_sqrt_or_I_sqrt
#print axioms sum_exp_sq_eq_quadGaussSum
#print axioms norm_gaussSum_of_ne_one
