-- The z-transform: a linear constant-coefficient difference equation settles exactly when every root of its characteristic polynomial (every pole) lies inside the unit circle, with Jury's test for quadratics and the transform of a geometric sequence.
import Mathlib.Algebra.LinearRecurrence
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Normed.Algebra.GelfandFormula
import Mathlib.Analysis.Normed.Operator.Banach
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Mathlib.Topology.Algebra.Module.FiniteDimension

open Filter Topology Polynomial

lemma LinearRecurrence.tupleSucc_shift (E : LinearRecurrence ℂ) {u : ℕ → ℂ}
    (hu : E.IsSolution u) (n : ℕ) :
    E.tupleSucc (fun i : Fin E.order => u (n + i)) = fun i : Fin E.order => u (n + 1 + i) := by
  funext i
  simp only [LinearRecurrence.tupleSucc, LinearMap.coe_mk, AddHom.coe_mk]
  split_ifs with h
  · congr 1
    omega
  · have hi : (i : ℕ) + 1 = E.order := by omega
    rw [← hu n]
    congr 1
    omega

lemma LinearRecurrence.tendsto_zero_of_roots (E : LinearRecurrence ℂ)
    (hE : ∀ p : ℂ, E.charPoly.IsRoot p → ‖p‖ < 1) (u : ℕ → ℂ) (hu : E.IsSolution u) :
    Tendsto u atTop (𝓝 0) := by
  rcases Nat.eq_zero_or_pos E.order with hd | hd
  · have hz : u = 0 := by
      funext n
      have : IsEmpty (Fin E.order) := by rw [hd]; infer_instance
      have h := hu n
      simp only [Finset.univ_eq_empty, Finset.sum_empty] at h
      rw [hd, Nat.add_zero] at h
      simpa using h
    rw [hz]
    exact tendsto_const_nhds
  have : Nonempty (Fin E.order) := ⟨⟨0, hd⟩⟩
  let T : (Fin E.order → ℂ) →L[ℂ] (Fin E.order → ℂ) :=
    LinearMap.toContinuousLinearMap E.tupleSucc
  have hT : ∀ x, T x = E.tupleSucc x := fun x => rfl
  have hspec : ∀ μ ∈ spectrum ℂ T, ‖μ‖₊ < 1 := by
    intro μ hμ
    rw [ContinuousLinearMap.spectrum_eq] at hμ
    have hev : Module.End.HasEigenvalue (E.tupleSucc : Module.End ℂ (Fin E.order → ℂ)) μ :=
      Module.End.hasEigenvalue_iff_mem_spectrum.mpr hμ
    obtain ⟨v, hv⟩ := hev.exists_hasEigenvector
    have hv0 : v ≠ 0 := hv.2
    have hTv : E.tupleSucc v = μ • v := hv.apply_eq_smul
    set w := E.mkSol v with hwdef
    have hw : E.IsSolution w := E.is_sol_mkSol v
    have hstate : ∀ n, (fun i : Fin E.order => w (n + i)) = μ ^ n • v := by
      intro n
      induction n with
      | zero =>
        funext i
        simp [w, E.mkSol_eq_init]
      | succ n ih =>
        rw [← E.tupleSucc_shift hw n, ih, map_smul, hTv, smul_smul, pow_succ]
    have hwn : ∀ n, w n = μ ^ n * v ⟨0, hd⟩ := by
      intro n
      have := congrFun (hstate n) ⟨0, hd⟩
      simpa using this
    have hv00 : v ⟨0, hd⟩ ≠ 0 := by
      intro h0
      apply hv0
      funext i
      rw [← E.mkSol_eq_init v i]
      show w i = 0
      rw [hwn, h0, mul_zero]
    have hgeom : E.IsSolution fun n => μ ^ n := by
      have hm := E.solSpace.smul_mem (v ⟨0, hd⟩)⁻¹ hw
      have heq : (v ⟨0, hd⟩)⁻¹ • w = fun n => μ ^ n := by
        funext n
        simp only [Pi.smul_apply, smul_eq_mul, hwn]
        field_simp
      rw [heq] at hm
      exact hm
    have := hE μ ((E.geom_sol_iff_root_charPoly μ).mp hgeom)
    rwa [← NNReal.coe_lt_coe, coe_nnnorm, NNReal.coe_one]
  have hrad : spectralRadius ℂ T < 1 := by
    have := spectrum.spectralRadius_lt_of_forall_lt T hspec
    simpa using this
  have hg : gelfandRadius T < 1 := by
    rw [spectrum.spectralRadius_eq_gelfandRadius, ENNReal.ofReal_lt_one] at hrad
    exact hrad
  have hg0 := gelfandRadius_nonneg T
  obtain ⟨C, hC, hCb⟩ :=
    norm_pow_le_mul_pow_of_gelfandRadius_lt T (r := (gelfandRadius T + 1) / 2) (by linarith)
  set s0 : Fin E.order → ℂ := fun i => u (0 + i)
  have hpow : ∀ n, (T ^ n) s0 = fun i : Fin E.order => u (n + i) := by
    intro n
    induction n with
    | zero => rfl
    | succ n ih =>
      rw [pow_succ']
      show T ((T ^ n) s0) = _
      rw [ih, hT]
      exact E.tupleSucc_shift hu n
  have hbound : ∀ n, ‖u n‖ ≤ C * ((gelfandRadius T + 1) / 2) ^ n * ‖s0‖ := by
    intro n
    have h1 : u n = ((T ^ n) s0) ⟨0, hd⟩ := by rw [hpow]; simp
    rw [h1]
    calc ‖((T ^ n) s0) ⟨0, hd⟩‖ ≤ ‖(T ^ n) s0‖ := norm_le_pi_norm _ _
      _ ≤ ‖T ^ n‖ * ‖s0‖ := (T ^ n).le_opNorm s0
      _ ≤ C * ((gelfandRadius T + 1) / 2) ^ n * ‖s0‖ :=
        mul_le_mul_of_nonneg_right (hCb n) (norm_nonneg _)
  refine squeeze_zero_norm hbound ?_
  have h0 : Tendsto (fun n : ℕ => ((gelfandRadius T + 1) / 2) ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one (by linarith) (by linarith)
  simpa using (h0.const_mul C).mul_const ‖s0‖

#print axioms LinearRecurrence.tupleSucc_shift
#print axioms LinearRecurrence.tendsto_zero_of_roots

/-- The card's stability theorem: a linear, time-invariant difference equation
`u (n + d) = ∑ i, c i * u (n + i)` settles (every one of its natural motions, every
solution, dies away to 0) exactly when every pole, that is every root `p` of its
characteristic polynomial `z ^ d - ∑ i, c i * z ^ i`, lies strictly inside the unit
circle, `‖p‖ < 1`. -/
theorem settles_iff_poles_inside_unit_circle (E : LinearRecurrence ℂ) :
    (∀ u : ℕ → ℂ, E.IsSolution u → Tendsto u atTop (𝓝 0)) ↔
      ∀ p : ℂ, E.charPoly.IsRoot p → ‖p‖ < 1 := by
  constructor
  · intro h p hp
    have := h _ ((E.geom_sol_iff_root_charPoly p).mpr hp)
    exact tendsto_pow_atTop_nhds_zero_iff_norm_lt_one.mp this
  · exact E.tendsto_zero_of_roots

/-- Jury's test, second-order case: both roots of `z ^ 2 + c₁ z + c₀` with real
coefficients lie inside the unit circle exactly when `|c₀| < 1`, `1 + c₁ + c₀ > 0`
and `1 - c₁ + c₀ > 0`. -/
theorem jury_test_quadratic (c₁ c₀ : ℝ) :
    (∀ z : ℂ, z ^ 2 + (c₁ : ℂ) * z + (c₀ : ℂ) = 0 → ‖z‖ < 1) ↔
      |c₀| < 1 ∧ 1 + c₁ + c₀ > 0 ∧ 1 - c₁ + c₀ > 0 := by
  constructor
  · intro h
    rcases le_or_gt 0 (c₁ ^ 2 - 4 * c₀) with hD | hD
    · set s := Real.sqrt (c₁ ^ 2 - 4 * c₀) with hsdef
      have hs : s ^ 2 = c₁ ^ 2 - 4 * c₀ := Real.sq_sqrt hD
      have hs0 : 0 ≤ s := Real.sqrt_nonneg _
      have hroot : ∀ r : ℝ, r ^ 2 + c₁ * r + c₀ = 0 → |r| < 1 := by
        intro r hr
        have := h (r : ℂ) (by exact_mod_cast hr)
        simpa [Complex.norm_real] using this
      have h1 := hroot ((-c₁ + s) / 2) (by linear_combination (1 / 4 : ℝ) * hs)
      have h2 := hroot ((-c₁ - s) / 2) (by linear_combination (1 / 4 : ℝ) * hs)
      rw [abs_lt] at h1 h2
      obtain ⟨a1, b1⟩ := h1
      obtain ⟨a2, b2⟩ := h2
      have hc0 : c₀ = ((-c₁ + s) / 2) * ((-c₁ - s) / 2) := by linear_combination (1 / 4 : ℝ) * hs
      refine ⟨abs_lt.mpr ⟨?_, ?_⟩, ?_, ?_⟩
      · rw [hc0]
        nlinarith [mul_pos (by linarith : (0:ℝ) < 1 + (-c₁ + s) / 2) (by linarith : (0:ℝ) < 1 + (-c₁ - s) / 2),
          mul_pos (by linarith : (0:ℝ) < 1 - (-c₁ + s) / 2) (by linarith : (0:ℝ) < 1 - (-c₁ - s) / 2)]
      · rw [hc0]
        nlinarith [mul_pos (by linarith : (0:ℝ) < 1 + (-c₁ + s) / 2) (by linarith : (0:ℝ) < 1 - (-c₁ - s) / 2),
          mul_pos (by linarith : (0:ℝ) < 1 - (-c₁ + s) / 2) (by linarith : (0:ℝ) < 1 + (-c₁ - s) / 2)]
      · rw [hc0]
        nlinarith [mul_pos (by linarith : (0:ℝ) < 1 - (-c₁ + s) / 2) (by linarith : (0:ℝ) < 1 - (-c₁ - s) / 2)]
      · rw [hc0]
        nlinarith [mul_pos (by linarith : (0:ℝ) < 1 + (-c₁ + s) / 2) (by linarith : (0:ℝ) < 1 + (-c₁ - s) / 2)]
    · set s := Real.sqrt (4 * c₀ - c₁ ^ 2) with hsdef
      have hs : s ^ 2 = 4 * c₀ - c₁ ^ 2 := Real.sq_sqrt (by linarith)
      have hz := h ⟨-c₁ / 2, s / 2⟩ (by
        apply Complex.ext <;> simp [pow_two] <;>
          first
          | linear_combination (1 / 4 : ℝ) * hs
          | linear_combination (-1 / 4 : ℝ) * hs
          | ring)
      have hn : Complex.normSq ⟨-c₁ / 2, s / 2⟩ < 1 := by
        rw [Complex.normSq_eq_norm_sq]
        nlinarith [norm_nonneg (⟨-c₁ / 2, s / 2⟩ : ℂ)]
      rw [Complex.normSq_mk] at hn
      have hc0 : c₀ < 1 := by nlinarith
      have hc0' : 0 < c₀ := by nlinarith [sq_nonneg c₁]
      refine ⟨abs_lt.mpr ⟨by linarith, hc0⟩, ?_, ?_⟩
      · nlinarith [sq_nonneg (1 - c₀), sq_nonneg (c₁ + 1 + c₀)]
      · nlinarith [sq_nonneg (1 - c₀), sq_nonneg (c₁ - 1 - c₀)]
  · rintro ⟨h0, h1, h2⟩ z hz
    rw [abs_lt] at h0
    obtain ⟨h0a, h0b⟩ := h0
    by_contra hn
    have hn' : 1 ≤ ‖z‖ := not_lt.mp hn
    have hre := congrArg Complex.re hz
    have him := congrArg Complex.im hz
    simp [pow_two] at hre him
    have hnorm : 1 ≤ z.re * z.re + z.im * z.im := by
      have := Complex.normSq_eq_norm_sq z
      rw [Complex.normSq_apply] at this
      nlinarith
    by_cases hy : z.im = 0
    · rw [hy] at hre hnorm
      set x := z.re
      rcases le_or_gt 1 x with hx | hx
      · nlinarith
      · have hx' : x ≤ -1 := by nlinarith
        nlinarith
    · have hc : c₁ = -2 * z.re := by
        have : z.im * (2 * z.re + c₁) = 0 := by linear_combination him
        rcases mul_eq_zero.mp this with h | h
        · exact absurd h hy
        · linarith
      rw [hc] at hre
      nlinarith

/-- The transform of the geometric sequence `p ^ n`: the sum `∑ p ^ n z ^ (-n)`
converges to `z / (z - p)` whenever `|z| > |p|` (outside the circle of radius `|p|`). -/
theorem z_transform_geometric (p z : ℂ) (h : ‖p‖ < ‖z‖) :
    HasSum (fun n : ℕ => p ^ n * z ^ (-(n : ℤ))) (z / (z - p)) := by
  have hz : z ≠ 0 := by
    intro h0
    rw [h0, norm_zero] at h
    exact absurd h (not_lt.mpr (norm_nonneg p))
  have hzp : z - p ≠ 0 := by
    intro h0
    rw [sub_eq_zero] at h0
    rw [h0] at h
    exact lt_irrefl _ h
  have hq : ‖p / z‖ < 1 := by
    rw [norm_div, div_lt_one (norm_pos_iff.mpr hz)]
    exact h
  have hs := hasSum_geometric_of_norm_lt_one hq
  have hf : (fun n : ℕ => p ^ n * z ^ (-(n : ℤ))) = fun n : ℕ => (p / z) ^ n := by
    funext n
    rw [zpow_neg, zpow_natCast, div_pow, div_eq_mul_inv]
  have hv : z / (z - p) = (1 - p / z)⁻¹ := by
    field_simp
  rw [hf, hv]
  exact hs

/-! The card's worked numbers, by hand (T = 1/10 s, C = 5/2 J/°C, R = 20 °C/W,
K = 25/2 W/°C, r = 5 °C). -/

-- tip memory a = 1 - T / (R C) = 0.998
example : (1 : ℝ) - (1 / 10) / (20 * (5 / 2)) = 499 / 500 := by norm_num
-- tip warming b = T / C = 0.04
example : ((1 : ℝ) / 10) / (5 / 2) = 1 / 25 := by norm_num
-- loop constant b K = 0.5
example : (1 / 25 : ℝ) * (25 / 2) = 1 / 2 := by norm_num
-- first tick y[1] = b K r = 2.5
example : (1 / 25 : ℝ) * (25 / 2) * 5 = 5 / 2 := by norm_num
-- second tick y[2] = 0.998 × 2.5 + 0.5 × (5 - 0) = 4.995
example : (499 / 500 : ℝ) * (5 / 2) + 1 / 2 * (5 - 0) = 999 / 200 := by norm_num
-- third tick y[3] = 0.998 × 4.995 + 0.5 × (5 - 2.5) = 6.23501, the peak
example : (499 / 500 : ℝ) * (999 / 200) + 1 / 2 * (5 - 5 / 2) = 623501 / 100000 := by norm_num
-- fourth tick y[4] = 0.998 × 6.23501 + 0.5 × (5 - 4.995) ≈ 6.22504, below the peak
example : (499 / 500 : ℝ) * (623501 / 100000) + 1 / 2 * (5 - 999 / 200) = 311251999 / 50000000 ∧
    (311251999 / 50000000 : ℝ) < 623501 / 100000 := by norm_num
-- final value H(1) r = 0.5 / (1 - 0.998 + 0.5) × 5 = 1250/251 ≈ 4.98008
example : (1 / 2 : ℝ) / (1 - 499 / 500 + 1 / 2) * 5 = 1250 / 251 := by norm_num
-- stability limit: b K = 1, so K = 1 / 0.04 = 25 W/°C; gain margin 25 / 12.5 = 2
example : (1 : ℝ) / (1 / 25) = 25 ∧ (25 : ℝ) / (25 / 2) = 2 := by norm_num
-- Jury's three inequalities hold at the design gain: z ^ 2 - 0.998 z + 0.5
example : |(1 / 2 : ℝ)| < 1 ∧ 1 + (-(499 / 500 : ℝ)) + 1 / 2 > 0 ∧
    1 - (-(499 / 500 : ℝ)) + 1 / 2 > 0 := by norm_num [abs_of_pos]
-- transform of the step response at z = 2: 2.5 × 4 / ((2 - 1)(4 - 1.996 + 0.5)) = 1250/313
example : (5 / 2 : ℝ) * 4 / ((2 - 1) * (4 - 499 / 500 * 2 + 1 / 2)) = 1250 / 313 := by norm_num

#print axioms settles_iff_poles_inside_unit_circle
#print axioms jury_test_quadratic
#print axioms z_transform_geometric
