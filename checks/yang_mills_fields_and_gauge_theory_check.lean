-- Yang-Mills: on the one-site wrapped box with a compact SU(N) connection, the energy's first change is −(1/g²) Σ_ν ⟨Σ_μ [A_μ, F_μν], δA_ν⟩, so the energy stands still exactly when the field equations hold, and a gauge change leaves Wilson's plaquette cost unchanged.
import Mathlib.Algebra.Lie.OfAssociative
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic.Module
import Mathlib.Analysis.Complex.Basic
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Tactic.NormNum

open Matrix
open scoped Matrix

namespace YangMills

variable {N d : ℕ}

/-- The card's su(N): N by N complex matrices `X` with `X* = −X` (skew-Hermitian) and trace 0,
the turn rates of the compact group SU(N). -/
def InSU (X : Matrix (Fin N) (Fin N) ℂ) : Prop :=
  X ∈ skewAdjoint (Matrix (Fin N) (Fin N) ℂ) ∧ trace X = 0

/-- The card's pairing `⟨X, Y⟩ = −2 tr(X Y)` (its real part; for su(N) it is already real). -/
noncomputable def pairing (X Y : Matrix (Fin N) (Fin N) ℂ) : ℝ :=
  (-2 * trace (X * Y)).re

/-- The card's squared size `|X|² = −2 tr(X X)`. -/
noncomputable def sqSize (X : Matrix (Fin N) (Fin N) ℂ) : ℝ :=
  pairing X X

/-- Curvature of a constant connection on the one-site wrapped box: nothing varies across the
square, so `F_μν = ∂_μ A_ν − ∂_ν A_μ + [A_μ, A_ν] = [A_μ, A_ν]`. -/
def curv (A : Fin d → Matrix (Fin N) (Fin N) ℂ) (μ ν : Fin d) : Matrix (Fin N) (Fin N) ℂ :=
  ⁅A μ, A ν⁆

/-- The Yang-Mills energy density of a constant connection in `d` directions:
`YM = (1 / (2 g²)) Σ_{μ<ν} |F_μν|²`, with `g2` standing for the coupling squared `g²`. -/
noncomputable def ymEnergy (g2 : ℝ) (A : Fin d → Matrix (Fin N) (Fin N) ℂ) : ℝ :=
  1 / (2 * g2) * ∑ μ : Fin d, ∑ ν : Fin d, if μ < ν then sqSize (curv A μ ν) else 0

/-- The field-equation expression `Σ_μ D_μ F_μν`; for a constant connection
`D_μ F_μν = ∂_μ F_μν + [A_μ, F_μν] = [A_μ, F_μν]`. -/
def fieldEq (A : Fin d → Matrix (Fin N) (Fin N) ℂ) (ν : Fin d) : Matrix (Fin N) (Fin N) ℂ :=
  ∑ μ : Fin d, ⁅A μ, curv A μ ν⁆

/-- The plaquette on one site: walk along x, along y, back along x, back along y,
`U_p = U_x U_y U_x⁻¹ U_y⁻¹`. -/
def plaquette (Ux Uy : specialUnitaryGroup (Fin N) ℂ) : specialUnitaryGroup (Fin N) ℂ :=
  Ux * Uy * Ux⁻¹ * Uy⁻¹

/-- Wilson's cost of one square, `β (1 − Re tr U_p / N)`. -/
noncomputable def wilsonCost (β : ℝ) (Up : specialUnitaryGroup (Fin N) ℂ) : ℝ :=
  β * (1 - (trace (Up : Matrix (Fin N) (Fin N) ℂ)).re / N)

lemma pairing_add_left (X Y Z : Matrix (Fin N) (Fin N) ℂ) :
    pairing (X + Y) Z = pairing X Z + pairing Y Z := by
  simp [pairing, Matrix.add_mul, trace_add, mul_add]

lemma pairing_add_right (X Y Z : Matrix (Fin N) (Fin N) ℂ) :
    pairing X (Y + Z) = pairing X Y + pairing X Z := by
  simp [pairing, trace_add, mul_add]

lemma pairing_smul_left (t : ℝ) (X Y : Matrix (Fin N) (Fin N) ℂ) :
    pairing ((t : ℂ) • X) Y = t * pairing X Y := by
  simp only [pairing, Matrix.smul_mul, trace_smul, smul_eq_mul]
  rw [show (-2 * ((t : ℂ) * trace (X * Y))) = (t : ℂ) * (-2 * trace (X * Y)) by ring,
    Complex.re_ofReal_mul]

lemma pairing_comm (X Y : Matrix (Fin N) (Fin N) ℂ) : pairing X Y = pairing Y X := by
  simp only [pairing, trace_mul_comm X Y]

lemma pairing_smul_right (t : ℝ) (X Y : Matrix (Fin N) (Fin N) ℂ) :
    pairing X ((t : ℂ) • Y) = t * pairing X Y := by
  rw [pairing_comm, pairing_smul_left, pairing_comm]

lemma pairing_neg_neg (X Y : Matrix (Fin N) (Fin N) ℂ) : pairing (-X) (-Y) = pairing X Y := by
  simp [pairing]

lemma pairing_sum_left {ι : Type*} (s : Finset ι) (X : ι → Matrix (Fin N) (Fin N) ℂ)
    (Y : Matrix (Fin N) (Fin N) ℂ) : pairing (∑ i ∈ s, X i) Y = ∑ i ∈ s, pairing (X i) Y := by
  simp [pairing, Finset.sum_mul, trace_sum, Finset.mul_sum, Complex.re_sum]

lemma pairing_lie (F A D : Matrix (Fin N) (Fin N) ℂ) :
    pairing F ⁅A, D⁆ = -pairing ⁅A, F⁆ D := by
  simp only [pairing, Ring.lie_def, Matrix.mul_sub, Matrix.sub_mul, trace_sub]
  rw [show trace (F * (D * A)) = trace (A * F * D) by
    rw [← Matrix.mul_assoc, trace_mul_cycle]]
  rw [show trace (F * (A * D)) = trace (F * A * D) by rw [Matrix.mul_assoc]]
  simp only [mul_sub, Complex.sub_re]
  ring

lemma mlie_skew (X Y : Matrix (Fin N) (Fin N) ℂ) : -⁅Y, X⁆ = ⁅X, Y⁆ := by
  simp only [Ring.lie_def, neg_sub]

lemma curv_line (A δA : Fin d → Matrix (Fin N) (Fin N) ℂ) (t : ℝ) (μ ν : Fin d) :
    curv (fun μ => A μ + (t : ℂ) • δA μ) μ ν = curv A μ ν
      + (t : ℂ) • (⁅δA μ, A ν⁆ + ⁅A μ, δA ν⁆) + ((t ^ 2 : ℝ) : ℂ) • ⁅δA μ, δA ν⁆ := by
  simp only [curv, Ring.lie_def, Matrix.add_mul, Matrix.mul_add, Matrix.smul_mul,
    Matrix.mul_smul]
  push_cast
  module

lemma sqSize_quad (F G H : Matrix (Fin N) (Fin N) ℂ) (t : ℝ) :
    sqSize (F + (t : ℂ) • G + ((t ^ 2 : ℝ) : ℂ) • H) =
      pairing F F + t * (2 * pairing F G) + t ^ 2 * (pairing G G + 2 * pairing F H)
        + t ^ 3 * (2 * pairing G H) + t ^ 4 * pairing H H := by
  simp only [sqSize, pairing_add_left, pairing_add_right, pairing_smul_left, pairing_smul_right]
  rw [pairing_comm G F, pairing_comm H F, pairing_comm H G]
  ring

lemma quartic_hasDerivAt (a b c e f : ℝ) :
    HasDerivAt (fun t : ℝ => a + t * b + t ^ 2 * c + t ^ 3 * e + t ^ 4 * f) b 0 := by
  have h1 := (hasDerivAt_id (0 : ℝ)).mul_const b
  have h2 := (hasDerivAt_pow 2 (0 : ℝ)).mul_const c
  have h3 := (hasDerivAt_pow 3 (0 : ℝ)).mul_const e
  have h4 := (hasDerivAt_pow 4 (0 : ℝ)).mul_const f
  have := ((((h1.const_add a).add h2).add h3).add h4)
  convert this using 1
  · funext t
    simp only [Pi.add_apply, id]
  · simp

lemma sum_lt_two (T : Fin d → Fin d → ℝ) (hs : ∀ μ ν, T ν μ = T μ ν) (hd : ∀ μ, T μ μ = 0) :
    2 * ∑ μ, ∑ ν, (if μ < ν then T μ ν else 0) = ∑ μ, ∑ ν, T μ ν := by
  have hsplit : ∀ μ ν, T μ ν = (if μ < ν then T μ ν else 0) + (if ν < μ then T ν μ else 0) := by
    intro μ ν
    rcases lt_trichotomy μ ν with h | h | h
    · simp [h, not_lt_of_gt h]
    · subst h; simp [hd]
    · simp [h, not_lt_of_gt h, hs]
  have : ∑ μ, ∑ ν, T μ ν = ∑ μ, ∑ ν, (if μ < ν then T μ ν else 0)
      + ∑ μ, ∑ ν, (if ν < μ then T ν μ else 0) := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun μ _ => ?_
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun ν _ => hsplit μ ν
  rw [this, Finset.sum_comm (f := fun μ ν => if ν < μ then T ν μ else 0)]
  ring

lemma lie_skew_mem {X Y : Matrix (Fin N) (Fin N) ℂ}
    (hX : X ∈ skewAdjoint (Matrix (Fin N) (Fin N) ℂ))
    (hY : Y ∈ skewAdjoint (Matrix (Fin N) (Fin N) ℂ)) : InSU ⁅X, Y⁆ := by
  rw [skewAdjoint.mem_iff] at hX hY
  refine ⟨?_, ?_⟩
  · rw [skewAdjoint.mem_iff, Ring.lie_def, star_sub, star_mul, star_mul, hX, hY]
    simp only [neg_mul_neg]
    abel
  · rw [Ring.lie_def, trace_sub, trace_mul_comm, sub_self]

lemma fieldEq_mem (A : Fin d → Matrix (Fin N) (Fin N) ℂ) (hA : ∀ μ, InSU (A μ)) (ν : Fin d) :
    InSU (fieldEq A ν) := by
  refine ⟨?_, ?_⟩
  · exact AddSubgroup.sum_mem _ fun μ _ =>
      (lie_skew_mem (hA μ).1 (lie_skew_mem (hA μ).1 (hA ν).1).1).1
  · rw [fieldEq, trace_sum]
    exact Finset.sum_eq_zero fun μ _ =>
      (lie_skew_mem (hA μ).1 (lie_skew_mem (hA μ).1 (hA ν).1).1).2

lemma pairing_self_eq (X : Matrix (Fin N) (Fin N) ℂ)
    (hX : X ∈ skewAdjoint (Matrix (Fin N) (Fin N) ℂ)) :
    pairing X X = 2 * ∑ i, ∑ j, Complex.normSq (X i j) := by
  rw [skewAdjoint.mem_iff] at hX
  have hX' : ∀ i j, X j i = -(starRingEnd ℂ) (X i j) := by
    intro i j
    have h1 : star (X j i) = -X i j := by simpa using congr_fun (congr_fun hX i) j
    have h2 := congrArg star h1
    simpa using h2
  have ht : trace (X * X) = -((∑ i, ∑ j, Complex.normSq (X i j) : ℝ) : ℂ) := by
    push_cast
    simp only [trace, diag, Matrix.mul_apply, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [hX' i j, mul_neg, Complex.mul_conj]
  rw [pairing, ht, show (-2 : ℂ) * -((∑ i, ∑ j, Complex.normSq (X i j) : ℝ) : ℂ)
    = ((2 * ∑ i, ∑ j, Complex.normSq (X i j) : ℝ) : ℂ) by push_cast; ring, Complex.ofReal_re]

lemma pairing_self_nonneg (X : Matrix (Fin N) (Fin N) ℂ)
    (hX : X ∈ skewAdjoint (Matrix (Fin N) (Fin N) ℂ)) : 0 ≤ pairing X X := by
  rw [pairing_self_eq X hX]
  exact mul_nonneg (by norm_num)
    (Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ => Complex.normSq_nonneg _)

lemma eq_zero_of_pairing_self (X : Matrix (Fin N) (Fin N) ℂ)
    (hX : X ∈ skewAdjoint (Matrix (Fin N) (Fin N) ℂ)) (h0 : pairing X X = 0) : X = 0 := by
  rw [pairing_self_eq X hX] at h0
  have h1 : ∑ i, ∑ j, Complex.normSq (X i j) = 0 := by linarith
  ext i j
  have h2 := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ =>
    Finset.sum_nonneg fun j _ => Complex.normSq_nonneg (X i j))).1 h1 i (Finset.mem_univ _)
  have h3 := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ =>
    Complex.normSq_nonneg (X i j))).1 h2 j (Finset.mem_univ _)
  simpa using h3

lemma first_variation_aux (g2 : ℝ) (hg : 0 < g2) (A δA : Fin d → Matrix (Fin N) (Fin N) ℂ) :
    HasDerivAt (fun t : ℝ => ymEnergy g2 (fun μ => A μ + (t : ℂ) • δA μ))
      (-(1 / g2) * ∑ ν : Fin d, pairing (fieldEq A ν) (δA ν)) 0 := by
  have hg' : g2 ≠ 0 := hg.ne'
  set G : Fin d → Fin d → Matrix (Fin N) (Fin N) ℂ :=
    fun μ ν => ⁅δA μ, A ν⁆ + ⁅A μ, δA ν⁆ with hGdef
  set T : Fin d → Fin d → ℝ := fun μ ν => pairing (curv A μ ν) (G μ ν) with hTdef
  have h : ∀ μ ν, HasDerivAt (fun t : ℝ =>
      if μ < ν then sqSize (curv (fun μ => A μ + (t : ℂ) • δA μ) μ ν) else 0)
      (2 * (if μ < ν then T μ ν else 0)) 0 := by
    intro μ ν
    split_ifs
    · simp_rw [curv_line, sqSize_quad]
      exact quartic_hasDerivAt _ _ _ _ _
    · rw [mul_zero]; exact hasDerivAt_const _ _
  have hs := (HasDerivAt.sum (u := Finset.univ) fun μ _ =>
    HasDerivAt.sum (u := Finset.univ) fun ν _ => h μ ν).const_mul (1 / (2 * g2))
  have hcurv_skew : ∀ μ ν, curv A ν μ = -curv A μ ν := by
    intro μ ν; simp only [curv, mlie_skew]
  have hsym : ∀ μ ν, T ν μ = T μ ν := by
    intro μ ν
    simp only [hTdef, hGdef, hcurv_skew μ ν]
    rw [← pairing_neg_neg]
    congr 1
    · simp
    · rw [← mlie_skew (A μ) (δA ν), ← mlie_skew (δA μ) (A ν)]; abel
  have hdiag : ∀ μ, T μ μ = 0 := by
    intro μ; simp [hTdef, curv, pairing, Ring.lie_def]
  have hTsum : ∑ μ, ∑ ν, T μ ν = -2 * ∑ ν, pairing (fieldEq A ν) (δA ν) := by
    have e1 : ∑ μ, ∑ ν, T μ ν = ∑ μ, ∑ ν, pairing (curv A μ ν) ⁅δA μ, A ν⁆
        + ∑ μ, ∑ ν, pairing (curv A μ ν) ⁅A μ, δA ν⁆ := by
      simp only [hTdef, hGdef, pairing_add_right, Finset.sum_add_distrib]
    have e2 : ∑ μ, ∑ ν, pairing (curv A μ ν) ⁅δA μ, A ν⁆
        = ∑ μ, ∑ ν, pairing (curv A μ ν) ⁅A μ, δA ν⁆ := by
      rw [Finset.sum_comm]
      refine Finset.sum_congr rfl fun μ _ => Finset.sum_congr rfl fun ν _ => ?_
      rw [hcurv_skew, ← pairing_neg_neg, neg_neg, mlie_skew]
    have e3 : ∑ μ, ∑ ν, pairing (curv A μ ν) ⁅A μ, δA ν⁆
        = -∑ ν, pairing (fieldEq A ν) (δA ν) := by
      rw [Finset.sum_comm, ← Finset.sum_neg_distrib]
      refine Finset.sum_congr rfl fun ν _ => ?_
      rw [fieldEq, pairing_sum_left, ← Finset.sum_neg_distrib]
      exact Finset.sum_congr rfl fun μ _ => pairing_lie _ _ _
    rw [e1, e2, e3]; ring
  have hlt := sum_lt_two T hsym hdiag
  convert hs using 1
  · funext t
    simp only [ymEnergy, Finset.sum_apply]
  · simp only [← Finset.mul_sum]
    rw [hlt, hTsum]
    field_simp

/-- The field equations are where the energy stands still. On the one-site wrapped box (a constant
connection, so no boundary terms), with the compact group SU(N), every component `A_μ` in su(N),
and coupling `g² > 0`: the first change of the Yang-Mills energy is zero for every small change
`δA` in su(N) exactly when the field equations `Σ_μ D_μ F_μν = 0` hold for each direction `ν`. -/
theorem yang_mills_stationary_iff_field_equations (g2 : ℝ) (hg : 0 < g2)
    (A : Fin d → Matrix (Fin N) (Fin N) ℂ) (hA : ∀ μ, InSU (A μ)) :
    (∀ δA : Fin d → Matrix (Fin N) (Fin N) ℂ, (∀ μ, InSU (δA μ)) →
        deriv (fun t : ℝ => ymEnergy g2 (fun μ => A μ + (t : ℂ) • δA μ)) 0 = 0) ↔
      ∀ ν, fieldEq A ν = 0 := by
  have hg' : g2 ≠ 0 := hg.ne'
  constructor
  · intro h
    have hE := fieldEq_mem A hA
    have h0 := h (fieldEq A) hE
    rw [(first_variation_aux g2 hg A (fieldEq A)).deriv] at h0
    have hsum : ∑ ν : Fin d, pairing (fieldEq A ν) (fieldEq A ν) = 0 := by
      rcases mul_eq_zero.1 h0 with h1 | h1
      · exfalso; simp at h1; exact hg' h1
      · exact h1
    intro ν
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun ν _ =>
      pairing_self_nonneg (fieldEq A ν) (hE ν).1)).1 hsum ν (Finset.mem_univ _)
    exact eq_zero_of_pairing_self _ (hE ν).1 this
  · intro h δA hδA
    rw [(first_variation_aux g2 hg A δA).deriv]
    simp [h, pairing]

/-- The first change of the energy. On the one-site wrapped box, pushing the connection to
`A + t δA` changes the Yang-Mills energy at the rate
`−(1/g²) Σ_ν ⟨Σ_μ D_μ F_μν, δA_ν⟩` at `t = 0`. -/
theorem yang_mills_first_variation (g2 : ℝ) (hg : 0 < g2)
    (A δA : Fin d → Matrix (Fin N) (Fin N) ℂ) (hA : ∀ μ, InSU (A μ))
    (hδA : ∀ μ, InSU (δA μ)) :
    HasDerivAt (fun t : ℝ => ymEnergy g2 (fun μ => A μ + (t : ℂ) • δA μ))
      (-(1 / g2) * ∑ ν : Fin d, pairing (fieldEq A ν) (δA ν)) 0 := by
  exact first_variation_aux g2 hg A δA

/-- Gauge changes leave the energy alone. On the one-site box a gauge change is one element `h`
of SU(N) at the site, turning each link `U` into `h U h⁻¹`; Wilson's cost of the plaquette
does not change. -/
theorem wilson_cost_gauge_invariant (β : ℝ) (h Ux Uy : specialUnitaryGroup (Fin N) ℂ) :
    wilsonCost β (plaquette (h * Ux * h⁻¹) (h * Uy * h⁻¹)) = wilsonCost β (plaquette Ux Uy) := by
  have hp : plaquette (h * Ux * h⁻¹) (h * Uy * h⁻¹) = h * plaquette Ux Uy * h⁻¹ := by
    simp only [plaquette]; group
  have ht : trace ((h * plaquette Ux Uy * h⁻¹ : specialUnitaryGroup (Fin N) ℂ) :
      Matrix (Fin N) (Fin N) ℂ) = trace ((plaquette Ux Uy : specialUnitaryGroup (Fin N) ℂ) :
      Matrix (Fin N) (Fin N) ℂ) := by
    rw [Submonoid.coe_mul, Submonoid.coe_mul, trace_mul_cycle, ← Submonoid.coe_mul,
      inv_mul_cancel, Submonoid.coe_one, Matrix.one_mul]
  rw [wilsonCost, wilsonCost, hp, ht]

end YangMills

-- Worked numbers. An su(2) element f₁T₁ + f₂T₂ + f₃T₃ is the 3-vector f, the bracket is the
-- cross product and |f|² = f₁² + f₂² + f₃².

-- F_xy = [A_x, A_y] = [5T₁, 5T₂] = 25 T₃ per fm².
example : ![(5 : ℤ), 0, 0] ⨯₃ ![0, 5, 0] = ![0, 0, 25] := by
  norm_num [crossProduct, vecHead, vecTail]

-- |F_xy|² = 25² = 625 per fm⁴.
example : (0 : ℤ) ^ 2 + 0 ^ 2 + 25 ^ 2 = 625 := by norm_num

-- β = 2.4 = 12/5 gives g² = 2N/β = 4/(12/5) = 5/3, and the energy density 625/(2 g²) = 375/2 = 187.5 per fm⁴.
example : (4 : ℚ) / (12 / 5) = 5 / 3 := by norm_num
example : (625 : ℚ) / (2 * (5 / 3)) = 375 / 2 := by norm_num

-- Field equation, x-direction: [A_y, F_yx] = −[5T₂, 25T₃] = −125 T₁ per fm³, not zero.
example : -(![(0 : ℤ), 5, 0] ⨯₃ ![0, 0, 25]) = ![-125, 0, 0] := by
  norm_num [crossProduct, vecHead, vecTail]

-- Slope of the energy: 125 / g² = 125 / (5/3) = 75.
example : (125 : ℚ) / (5 / 3) = 75 := by norm_num

-- Try changing: A_y = (3, 4, 0) gives F_xy = (0, 0, 20) and energy 400 / (10/3) = 120 per fm⁴.
example : ![(5 : ℤ), 0, 0] ⨯₃ ![3, 4, 0] = ![0, 0, 20] := by
  norm_num [crossProduct, vecHead, vecTail]
example : (20 : ℚ) ^ 2 / (2 * (5 / 3)) = 120 := by norm_num

-- Commuting fields A_x = (0, 0, 5), A_y = (0, 0, 3): the bracket is zero, so the energy is 0.
example : ![(0 : ℤ), 0, 5] ⨯₃ ![0, 0, 3] = ![0, 0, 0] := by
  norm_num [crossProduct, vecHead, vecTail]

-- What breaks: in the non-compact SL(2, ℝ), X = diag(1, −1) has −2 tr(X X) = −4 < 0.
example : -2 * trace (!![(1 : ℤ), 0; 0, -1] * !![1, 0; 0, -1]) = -4 := by
  norm_num [trace, Fin.sum_univ_two]

-- What breaks: forgetting the 1/N and taking β = 1/g² = 3/5 instead of 2N/g² = 12/5 is a factor 2N = 4 too small.
example : (12 : ℚ) / 5 / (3 / 5) = 4 := by norm_num

open YangMills

#print axioms yang_mills_stationary_iff_field_equations
#print axioms yang_mills_first_variation
#print axioms wilson_cost_gauge_invariant
#print axioms pairing_add_left
#print axioms pairing_add_right
#print axioms pairing_smul_left
#print axioms pairing_comm
#print axioms pairing_smul_right
#print axioms pairing_neg_neg
#print axioms pairing_sum_left
#print axioms pairing_lie
#print axioms mlie_skew
#print axioms curv_line
#print axioms sqSize_quad
#print axioms quartic_hasDerivAt
#print axioms sum_lt_two
#print axioms lie_skew_mem
#print axioms fieldEq_mem
#print axioms pairing_self_eq
#print axioms pairing_self_nonneg
#print axioms eq_zero_of_pairing_self
#print axioms first_variation_aux
