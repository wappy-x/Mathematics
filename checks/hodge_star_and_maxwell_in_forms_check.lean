-- Hodge star: with the field two-form F built from E and B, the two lines dF = 0 and d⋆F = μ₀ c 𝒥 hold exactly when Maxwell's four vector equations hold.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Calculus.FDeriv.Const
import Mathlib.Tactic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Nat.Choose.Basic

open Matrix

namespace HodgeMaxwell

/-- An event in spacetime: coordinate 0 is the time t (s); 1, 2, 3 are x, y, z (m). -/
abbrev Spacetime := Fin 4 → ℝ

/-- The partial derivative `∂f/∂xᵏ` at the event `p`, from Mathlib's `fderiv`. -/
noncomputable def pd (k : Fin 4) (f : Spacetime → ℝ) (p : Spacetime) : ℝ :=
  fderiv ℝ f p (Pi.single k 1)

theorem pd_neg (k : Fin 4) (f : Spacetime → ℝ) (p : Spacetime) :
    pd k (fun q => -f q) p = -pd k f p := by
  simp [pd, fderiv_fun_neg]

theorem pd_zero (k : Fin 4) (p : Spacetime) : pd k (fun _ => (0 : ℝ)) p = 0 := by
  simp [pd]

theorem pd_const_mul (k : Fin 4) (a : ℝ) (f : Spacetime → ℝ) (p : Spacetime) :
    pd k (fun q => a * f q) p = a * pd k f p := by
  have h : (fun q => a * f q) = a • f := by ext q; simp
  simp [pd, h, fderiv_const_smul_field]

theorem pd_div_const (k : Fin 4) (a : ℝ) (f : Spacetime → ℝ) (p : Spacetime) :
    pd k (fun q => f q / a) p = pd k f p / a := by
  simpa [div_eq_inv_mul] using pd_const_mul k a⁻¹ f p

theorem antisym_entry {M : Matrix (Fin 4) (Fin 4) ℝ} (h : Mᵀ = -M) (i j : Fin 4) :
    M j i = -M i j := by
  simpa using congrFun (congrFun h i) j

theorem antisym_diag {M : Matrix (Fin 4) (Fin 4) ℝ} (h : Mᵀ = -M) (i : Fin 4) :
    M i i = 0 := by
  have := antisym_entry h i i
  linarith

#print axioms pd_neg
#print axioms pd_zero
#print axioms pd_const_mul
#print axioms pd_div_const
#print axioms antisym_entry
#print axioms antisym_diag

/-! ### Two-forms at one event

A two-form at one event is stored by its values `ω a b` on pairs of coordinate directions
`(e_a, e_b)`: a 4 × 4 table that changes sign when flipped (`ωᵀ = -ω`), so
`ω = ∑_{a<b} ω a b dxᵃ ∧ dxᵇ`. -/

/-- The field two-form `F = (E_x dx + E_y dy + E_z dz) ∧ dt + B_x dy∧dz + B_y dz∧dx + B_z dx∧dy`
at one event. -/
def fieldForm (E B : Fin 3 → ℝ) : Matrix (Fin 4) (Fin 4) ℝ :=
  !![0, -E 0, -E 1, -E 2;
     E 0, 0, B 2, -B 1;
     E 1, -B 2, 0, B 0;
     E 2, B 1, -B 0, 0]

/-- The Hodge star of the Minkowski metric `-c² dt² + dx² + dy² + dz²` with orientation
`(t, x, y, z)`, as the card's table: `⋆(dx∧dt) = (1/c) dy∧dz`, ..., `⋆(dy∧dz) = -c dx∧dt`, ...
So `⋆F` is `F` with `E` replaced by `-c B` and `B` by `E / c`. -/
noncomputable def minkStar (c : ℝ) (ω : Matrix (Fin 4) (Fin 4) ℝ) : Matrix (Fin 4) (Fin 4) ℝ :=
  !![0, c * ω 2 3, c * ω 3 1, c * ω 1 2;
     -(c * ω 2 3), 0, ω 3 0 / c, -(ω 2 0 / c);
     -(c * ω 3 1), -(ω 3 0 / c), 0, ω 1 0 / c;
     -(c * ω 1 2), ω 2 0 / c, -(ω 1 0 / c), 0]

/-- The diagonal of the inverse Minkowski metric: `-1/c²` for t, and 1 for x, y, z. -/
noncomputable def invMetric (c : ℝ) : Fin 4 → ℝ := ![-1 / c ^ 2, 1, 1, 1]

/-- The inner product of two-forms from the inverse metric,
`⟨α, β⟩ = ∑_{a<b} g^aa g^bb α_ab β_ab`. -/
noncomputable def minkInner (c : ℝ) (α β : Matrix (Fin 4) (Fin 4) ℝ) : ℝ :=
  (1 / 2) * ∑ a, ∑ b, invMetric c a * invMetric c b * α a b * β a b

/-- The coefficient of `dt∧dx∧dy∧dz` in the four-form `α ∧ β` of two two-forms. -/
def wedgeTop (α β : Matrix (Fin 4) (Fin 4) ℝ) : ℝ :=
  α 0 1 * β 2 3 - α 0 2 * β 1 3 + α 0 3 * β 1 2 + α 1 2 * β 0 3 - α 1 3 * β 0 2 + α 2 3 * β 0 1

/-! ### Fields on spacetime -/

/-- The exterior derivative of a two-form field, evaluated on `(e_i, e_j, e_k)`:
`(dF)_ijk = ∂_i F_jk + ∂_j F_ki + ∂_k F_ij`. -/
noncomputable def extD (F : Spacetime → Matrix (Fin 4) (Fin 4) ℝ) (p : Spacetime) (i j k : Fin 4) : ℝ :=
  pd i (fun q => F q j k) p + pd j (fun q => F q k i) p + pd k (fun q => F q i j) p

/-- The value of `dxᵃ ∧ dxᵇ ∧ dxᵈ` on `(e_i, e_j, e_k)`: the determinant of the 3 × 3 table
of matches. -/
noncomputable def wedge3 (a b d i j k : Fin 4) : ℝ :=
  Matrix.det (Matrix.of fun r s => if ![a, b, d] r = ![i, j, k] s then (1 : ℝ) else 0)

/-- The current three-form `𝒥 = ρ dx∧dy∧dz - (J_x dy∧dz + J_y dz∧dx + J_z dx∧dy) ∧ dt`
at one event, evaluated on `(e_i, e_j, e_k)`. -/
noncomputable def currentForm (ρ : ℝ) (J : Fin 3 → ℝ) (i j k : Fin 4) : ℝ :=
  ρ * wedge3 1 2 3 i j k
    - (J 0 * wedge3 2 3 0 i j k + J 1 * wedge3 3 1 0 i j k + J 2 * wedge3 1 2 0 i j k)

/-- The divergence of a space vector field, taken at an event. -/
noncomputable def divergence (V : Spacetime → Fin 3 → ℝ) (p : Spacetime) : ℝ :=
  pd 1 (fun q => V q 0) p + pd 2 (fun q => V q 1) p + pd 3 (fun q => V q 2) p

/-- The curl of a space vector field, taken at an event. -/
noncomputable def curl (V : Spacetime → Fin 3 → ℝ) (p : Spacetime) : Fin 3 → ℝ :=
  ![pd 2 (fun q => V q 2) p - pd 3 (fun q => V q 1) p,
    pd 3 (fun q => V q 0) p - pd 1 (fun q => V q 2) p,
    pd 1 (fun q => V q 1) p - pd 2 (fun q => V q 0) p]

/-- The time derivative of a space vector field, taken at an event. -/
noncomputable def timeDeriv (V : Spacetime → Fin 3 → ℝ) (p : Spacetime) : Fin 3 → ℝ :=
  fun i => pd 0 (fun q => V q i) p

theorem dF_zero_of (E B : Spacetime → Fin 3 → ℝ) (p : Spacetime)
    (hd : divergence B p = 0) (hf : curl E p + timeDeriv B p = 0) (i j k : Fin 4) :
    extD (fun q => fieldForm (E q) (B q)) p i j k = 0 := by
  have hf0 := congrFun hf 0
  have hf1 := congrFun hf 1
  have hf2 := congrFun hf 2
  simp [divergence, curl, timeDeriv] at hd hf0 hf1 hf2
  fin_cases i <;> fin_cases j <;> fin_cases k <;>
    simp [extD, fieldForm, pd_neg, pd_zero] <;> linarith

set_option maxHeartbeats 2000000 in
theorem dStarF_of (c μ₀ ε₀ : ℝ) (hc0 : c ≠ 0) (hε : ε₀ ≠ 0) (hμ : μ₀ = 1 / (c ^ 2 * ε₀))
    (E B J : Spacetime → Fin 3 → ℝ) (ρ : Spacetime → ℝ) (p : Spacetime)
    (hg : divergence E p = ρ p / ε₀) (ha : curl B p = μ₀ • J p + (μ₀ * ε₀) • timeDeriv E p)
    (i j k : Fin 4) :
    extD (fun q => minkStar c (fieldForm (E q) (B q))) p i j k
      = μ₀ * c * currentForm (ρ p) (J p) i j k := by
  have ha0 := congrFun ha 0
  have ha1 := congrFun ha 1
  have ha2 := congrFun ha 2
  simp [divergence, curl, timeDeriv] at hg ha0 ha1 ha2
  subst hμ
  field_simp at hg ha0 ha1 ha2
  clear ha
  fin_cases i <;> fin_cases j <;> fin_cases k <;>
    simp [extD, fieldForm, minkStar, currentForm, wedge3, Matrix.det_fin_three, pd_neg,
      pd_zero, pd_const_mul, pd_div_const] <;> field_simp <;> linarith

#print axioms dF_zero_of
#print axioms dStarF_of

/-- **Maxwell's equations in two lines.** In flat spacetime with the Minkowski metric of
signature `(-, +, +, +)` and orientation `(t, x, y, z)`, in vacuum, write the electric field `E`
and magnetic field `B` as one two-form `F`. Then `dF = 0` and `d⋆F = μ₀ c 𝒥` hold exactly when
the four vector equations hold everywhere: no magnetic charge, Faraday's law, Gauss's law and
the Ampère–Maxwell law (with `μ₀ ε₀ = 1/c²`). -/
theorem maxwell_iff_dF_eq_zero_and_d_star_F_eq_current
    (c μ₀ ε₀ : ℝ) (hc : 0 < c) (hμε : μ₀ * ε₀ = 1 / c ^ 2)
    (E B J : Spacetime → Fin 3 → ℝ) (ρ : Spacetime → ℝ) :
    ((∀ p i j k, extD (fun q => fieldForm (E q) (B q)) p i j k = 0) ∧
      (∀ p i j k, extD (fun q => minkStar c (fieldForm (E q) (B q))) p i j k
        = μ₀ * c * currentForm (ρ p) (J p) i j k)) ↔
    ∀ p, divergence B p = 0 ∧
      curl E p + timeDeriv B p = 0 ∧
      divergence E p = ρ p / ε₀ ∧
      curl B p = μ₀ • J p + (μ₀ * ε₀) • timeDeriv E p := by
  have hc0 : c ≠ 0 := hc.ne'
  have hε : ε₀ ≠ 0 := by
    rintro rfl
    have : (1 : ℝ) / c ^ 2 ≠ 0 := by positivity
    simp at hμε
    exact this (by simpa using hμε.symm)
  have hμ : μ₀ = 1 / (c ^ 2 * ε₀) := by
    field_simp
    field_simp at hμε
    linarith
  constructor
  · rintro ⟨h1, h2⟩ p
    have a1 := h1 p 1 2 3
    have a2 := h1 p 0 2 3
    have a3 := h1 p 0 3 1
    have a4 := h1 p 0 1 2
    have b1 := h2 p 1 2 3
    have b2 := h2 p 0 2 3
    have b3 := h2 p 0 3 1
    have b4 := h2 p 0 1 2
    simp [extD, fieldForm, minkStar, currentForm, wedge3, Matrix.det_fin_three, pd_neg,
      pd_const_mul, pd_div_const] at a1 a2 a3 a4 b1 b2 b3 b4
    refine ⟨?_, ?_, ?_, ?_⟩
    · simp only [divergence]; linarith
    · ext i; fin_cases i <;> simp [curl, timeDeriv] <;> linarith
    · simp only [divergence]
      rw [hμ] at b1
      field_simp at b1 ⊢
      linarith
    · ext i; fin_cases i <;> simp [curl, timeDeriv] <;> rw [hμ] at * <;> field_simp at * <;> linarith
  · intro h
    refine ⟨fun p => ?_, fun p => ?_⟩
    · exact dF_zero_of E B p (h p).1 (h p).2.1
    · exact dStarF_of c μ₀ ε₀ hc0 hε hμ E B J ρ p (h p).2.2.1 (h p).2.2.2

/-- **The rule fixes the star.** For two-forms, `⋆β` is the one two-form `σ` with
`α ∧ σ = ⟨α, β⟩ vol` for every two-form `α`, where `vol = c dt∧dx∧dy∧dz`. -/
theorem star_unique_by_rule (c : ℝ) (hc : 0 < c) (β σ : Matrix (Fin 4) (Fin 4) ℝ)
    (hβ : βᵀ = -β) (hσ : σᵀ = -σ) :
    (∀ α : Matrix (Fin 4) (Fin 4) ℝ, αᵀ = -α → wedgeTop α σ = c * minkInner c α β) ↔
      σ = minkStar c β := by
  have hc0 : c ≠ 0 := hc.ne'
  have eb := antisym_entry hβ
  have es := antisym_entry hσ
  constructor
  · intro h
    have key : ∀ a b : Fin 4, a ≠ b → wedgeTop (Matrix.of fun i j =>
        if i = a ∧ j = b then (1 : ℝ) else if i = b ∧ j = a then -1 else 0) σ =
        c * minkInner c (Matrix.of fun i j =>
          if i = a ∧ j = b then (1 : ℝ) else if i = b ∧ j = a then -1 else 0) β := by
      intro a b hab
      apply h
      ext i j
      simp only [Matrix.transpose_apply, Matrix.of_apply, Matrix.neg_apply]
      by_cases h1 : i = a <;> by_cases h2 : j = b <;> by_cases h3 : i = b <;>
        by_cases h4 : j = a <;> simp_all
    have k01 := key 0 1 (by decide)
    have k02 := key 0 2 (by decide)
    have k03 := key 0 3 (by decide)
    have k12 := key 1 2 (by decide)
    have k13 := key 1 3 (by decide)
    have k23 := key 2 3 (by decide)
    simp [wedgeTop, minkInner, invMetric, Fin.sum_univ_succ,
      eb 0 1, eb 0 2, eb 0 3, eb 1 2, eb 1 3, eb 2 3] at k01 k02 k03 k12 k13 k23
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [minkStar, es 0 1, es 0 2, es 0 3, es 1 2, es 1 3, es 2 3, antisym_diag hσ,
        eb 0 1, eb 0 2, eb 0 3, eb 1 3] <;>
      field_simp at * <;> linarith
  · rintro rfl α hα
    have ea := antisym_entry hα
    simp [wedgeTop, minkInner, invMetric, minkStar, Fin.sum_univ_succ, antisym_diag hα,
      antisym_diag hβ, ea 0 1, ea 0 2, ea 0 3, ea 1 2, ea 1 3, ea 2 3,
      eb 0 1, eb 0 2, eb 0 3, eb 1 2, eb 1 3, eb 2 3]
    field_simp
    ring

/-- **The star twice is minus one.** With the spacetime signature `(-, +, +, +)`,
`⋆⋆ω = -ω` for every two-form `ω`. -/
theorem star_star_eq_neg (c : ℝ) (hc : 0 < c) (ω : Matrix (Fin 4) (Fin 4) ℝ) (hω : ωᵀ = -ω) :
    minkStar c (minkStar c ω) = -ω := by
  have hc0 : c ≠ 0 := hc.ne'
  have e := antisym_entry hω
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [minkStar, e 0 1, e 0 2, e 0 3, e 1 2, e 1 3, e 2 3, antisym_diag hω, hc0] <;>
    field_simp

/-- Four dimensions have six coordinate planes: one slot for each of the six field numbers. -/
example : Nat.choose 4 2 = 6 := by decide

/-- A one-form has only four slots, too few for six numbers. -/
example : Nat.choose 4 1 = 4 := by decide

/-- A three-form has four components, so the two lines are 2 × 4 = 8 component equations. -/
example : 2 * Nat.choose 4 3 = 8 := by decide

/-- The mast's wave at a crest, `F = 0.1 dz∧dt - (0.1/c) dz∧dx`, has invariant
`c² ⟨F, F⟩ = c² B² - E² = 0`. -/
example : (299792458 : ℝ) ^ 2 *
    minkInner 299792458 (fieldForm ![0, 0, 1 / 10] ![0, -(1 / 10) / 299792458, 0])
      (fieldForm ![0, 0, 1 / 10] ![0, -(1 / 10) / 299792458, 0]) = 0 := by
  norm_num [minkInner, invMetric, fieldForm, Fin.sum_univ_succ]

/-- The star turns the vertical wave horizontal: `⋆F` has `E_y = 0.1` V/m and `B_z = 0.1/c`. -/
example : minkStar 299792458 (fieldForm ![0, 0, 1 / 10] ![0, -(1 / 10) / 299792458, 0]) =
    fieldForm ![0, 1 / 10, 0] ![0, 0, (1 / 10) / 299792458] := by
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [minkStar, fieldForm]

#print axioms maxwell_iff_dF_eq_zero_and_d_star_F_eq_current
#print axioms star_unique_by_rule
#print axioms star_star_eq_neg

end HodgeMaxwell
