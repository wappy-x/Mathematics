-- Domain decomposition: each alternating Schwarz sweep on two overlapping pieces of [0, 1] multiplies the error by (a/b)((1 - b)/(1 - a)), which is below 1 exactly when the pieces overlap, and the additive Schwarz preconditioner of a symmetric positive definite matrix is symmetric positive definite.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic

open Matrix Set

/-- The restriction `R_s`: the 0-1 matrix that picks out the unknowns of the piece `s`.
Its transpose puts a piece's values back in their places, with zeros elsewhere. -/
def restriction {n : Type*} [DecidableEq n] (s : Finset n) : Matrix s n ℝ :=
  (1 : Matrix n n ℝ).submatrix (fun j : s => (j : n)) id

lemma restriction_mul_mul_transpose {n : Type*} [Fintype n] [DecidableEq n] (s : Finset n)
    (A : Matrix n n ℝ) :
    restriction s * A * (restriction s)ᵀ = A.submatrix (fun j : s => (j : n)) (fun j : s => (j : n)) := by
  have h1 := one_submatrix_mul (α := ℝ) (fun j : s => (j : n)) (Equiv.refl n) A
  have h2 := mul_submatrix_one (α := ℝ) (Equiv.refl n) (fun j : s => (j : n))
    (A.submatrix (fun j : s => (j : n)) id)
  simp only [Equiv.coe_refl, Equiv.refl_symm, Function.id_comp] at h1 h2
  rw [restriction, transpose_submatrix, transpose_one, h1, h2, submatrix_submatrix]
  rfl

lemma restriction_mulVec_apply {n : Type*} [Fintype n] [DecidableEq n] (s : Finset n)
    (x : n → ℝ) (i : s) : (restriction s *ᵥ x) i = x i := by
  show ((1 : Matrix n n ℝ) *ᵥ x) (i : n) = x i
  rw [one_mulVec]

#print axioms restriction_mul_mul_transpose
#print axioms restriction_mulVec_apply

/-- The 1-D alternating Schwarz sweep for `-u'' = 0` on `[0, 1]`, pieces `[0, b]` and `[a, 1]`
with `0 < a < b < 1`. The error of each piece solve is a straight line that is zero at the true
end of its piece. Piece 1 starts from the edge error `e₀` at `x = b`; piece 2 starts from piece 1's
error at `x = a`. Then the new error at `b` is `ρ e₀` with `ρ = (a/b)((1 - b)/(1 - a))`, and the
largest error on `[0, 1]` after the sweep (piece 1's line on `[0, a]`, piece 2's on `[a, 1]`)
is `(a/b)|e₀|`. So each later sweep multiplies the largest error by the same `ρ`. -/
theorem alternating_schwarz_sweep_factor (a b : ℝ) (ha : 0 < a) (hab : a < b) (hb : b < 1)
    (e₀ : ℝ) (e₁ e₂ : ℝ → ℝ)
    (h₁ : ∃ m c : ℝ, ∀ x, e₁ x = m * x + c) (h₁0 : e₁ 0 = 0) (h₁b : e₁ b = e₀)
    (h₂ : ∃ m c : ℝ, ∀ x, e₂ x = m * x + c) (h₂a : e₂ a = e₁ a) (h₂1 : e₂ 1 = 0) :
    e₂ b = a / b * ((1 - b) / (1 - a)) * e₀ ∧
      IsGreatest ((fun x => |if x ≤ a then e₁ x else e₂ x|) '' Icc 0 1) (a / b * |e₀|) := by
  obtain ⟨m₁, c₁, hm₁⟩ := h₁
  obtain ⟨m₂, c₂, hm₂⟩ := h₂
  have hb0 : 0 < b := ha.trans hab
  have ha1 : 0 < 1 - a := by linarith
  have hbne : b ≠ 0 := hb0.ne'
  have hane : 1 - a ≠ 0 := ha1.ne'
  rw [hm₁] at h₁0 h₁b h₂a
  rw [hm₂] at h₂a h₂1
  have hc₁ : c₁ = 0 := by simpa using h₁0
  subst hc₁
  have hm₁e : m₁ = e₀ / b := by field_simp; linarith
  have hc₂ : c₂ = -m₂ := by linarith
  subst hc₂
  have hm₂e : m₂ = -(e₀ * a / b / (1 - a)) := by
    rw [hm₁e] at h₂a
    field_simp
    field_simp at h₂a
    linarith
  have he₁ : ∀ x, e₁ x = e₀ * x / b := fun x => by rw [hm₁, hm₁e]; ring
  have he₂ : ∀ x, e₂ x = e₀ * a / b * (1 - x) / (1 - a) := fun x => by
    rw [hm₂, hm₂e]; field_simp; ring
  refine ⟨?_, ?_, ?_⟩
  · rw [he₂]; field_simp
  · refine ⟨a, ⟨ha.le, by linarith⟩, ?_⟩
    simp only [le_refl, ite_true, he₁]
    rw [abs_div, abs_mul, abs_of_pos ha, abs_of_pos hb0]; ring
  · rintro y ⟨x, ⟨hx0, hx1⟩, rfl⟩
    dsimp only
    split_ifs with hxa
    · rw [he₁, abs_div, abs_mul, abs_of_nonneg hx0, abs_of_pos hb0]
      rw [div_mul_eq_mul_div, div_le_div_iff_of_pos_right hb0, mul_comm a]
      exact mul_le_mul_of_nonneg_left hxa (abs_nonneg _)
    · rw [not_le] at hxa
      rw [he₂, abs_div, abs_mul, abs_div, abs_mul, abs_of_pos ha, abs_of_pos hb0,
        abs_of_nonneg (by linarith : (0:ℝ) ≤ 1 - x), abs_of_pos ha1]
      rw [div_le_iff₀ ha1]
      have : |e₀| * a / b * (1 - x) ≤ |e₀| * a / b * (1 - a) :=
        mul_le_mul_of_nonneg_left (by linarith) (by positivity)
      calc |e₀| * a / b * (1 - x) ≤ |e₀| * a / b * (1 - a) := this
        _ = a / b * |e₀| * (1 - a) := by ring

/-- The two factors `a/b` and `(1 - b)/(1 - a)`, for inner ends `a` and `b` strictly inside
`(0, 1)`, are each below 1 exactly when `a < b`, that is when the pieces overlap; so is their
product `ρ`, which is always positive. -/
theorem schwarz_factor_lt_one_iff_overlap (a b : ℝ) (ha0 : 0 < a) (ha1 : a < 1)
    (hb0 : 0 < b) (hb1 : b < 1) :
    0 < a / b * ((1 - b) / (1 - a)) ∧
      (a / b < 1 ↔ a < b) ∧ ((1 - b) / (1 - a) < 1 ↔ a < b) ∧
      (a / b * ((1 - b) / (1 - a)) < 1 ↔ a < b) := by
  have h1a : 0 < 1 - a := by linarith
  have h1b : 0 < 1 - b := by linarith
  refine ⟨by positivity, by rw [div_lt_one hb0], by rw [div_lt_one h1a]; constructor <;> intro h <;> linarith, ?_⟩
  rw [div_mul_div_comm, div_lt_one (by positivity)]
  constructor
  · intro h; nlinarith
  · intro h; nlinarith

/-- Additive Schwarz preconditioner: if `A` is symmetric positive definite and the pieces cover
every unknown, then each piece matrix `A_i = R_i A R_iᵀ` is positive definite (so solvable), and
`M⁻¹ = R₀ᵀ A₀⁻¹ R₀ + ∑ R_iᵀ A_i⁻¹ R_i`, with `A₀ = R₀ A R₀ᵀ` for any coarse restriction `R₀`,
is symmetric positive definite, as conjugate gradient needs. -/
theorem additive_schwarz_preconditioner_posDef
    {n ι m : Type*} [Fintype n] [DecidableEq n] [Fintype ι] [Fintype m] [DecidableEq m]
    (A : Matrix n n ℝ) (hA : A.PosDef)
    (S : ι → Finset n) (hcover : ∀ k, ∃ i, k ∈ S i) (R₀ : Matrix m n ℝ) :
    (∀ i, (restriction (S i) * A * (restriction (S i))ᵀ).PosDef) ∧
      (R₀ᵀ * (R₀ * A * R₀ᵀ)⁻¹ * R₀ +
        ∑ i, (restriction (S i))ᵀ * (restriction (S i) * A * (restriction (S i))ᵀ)⁻¹ *
          restriction (S i)).PosDef := by
  have hloc : ∀ i, (restriction (S i) * A * (restriction (S i))ᵀ).PosDef := fun i => by
    rw [restriction_mul_mul_transpose]
    exact hA.submatrix Subtype.val_injective
  refine ⟨hloc, ?_⟩
  have hcoarse : (R₀ᵀ * (R₀ * A * R₀ᵀ)⁻¹ * R₀).PosSemidef := by
    have h1 : (R₀ * A * R₀ᵀ).PosSemidef := by
      simpa [conjTranspose_eq_transpose_of_trivial] using
        hA.posSemidef.mul_mul_conjTranspose_same R₀
    simpa [conjTranspose_eq_transpose_of_trivial] using
      h1.inv.conjTranspose_mul_mul_same R₀
  have hterm : ∀ i, ((restriction (S i))ᵀ * (restriction (S i) * A * (restriction (S i))ᵀ)⁻¹ *
          restriction (S i)).PosSemidef := fun i => by
    simpa [conjTranspose_eq_transpose_of_trivial] using
      (hloc i).inv.posSemidef.conjTranspose_mul_mul_same (restriction (S i))
  refine PosDef.posSemidef_add hcoarse ?_
  have hsum := posSemidef_sum Finset.univ (fun i _ => hterm i)
  refine PosDef.of_dotProduct_mulVec_pos hsum.isHermitian fun x hx => ?_
  obtain ⟨k, hk⟩ : ∃ k, x k ≠ 0 := by
    by_contra h; simp only [not_exists, not_not] at h; exact hx (funext h)
  obtain ⟨i, hi⟩ := hcover k
  rw [sum_mulVec, dotProduct_sum]
  have hnn : ∀ j ∈ Finset.univ, 0 ≤ star x ⬝ᵥ (((restriction (S j))ᵀ *
      (restriction (S j) * A * (restriction (S j))ᵀ)⁻¹ * restriction (S j)) *ᵥ x) :=
    fun j _ => (hterm j).dotProduct_mulVec_nonneg x
  refine lt_of_lt_of_le ?_ (Finset.single_le_sum hnn (Finset.mem_univ i))
  have hRx : restriction (S i) *ᵥ x ≠ 0 := by
    intro h
    apply hk
    have := congrFun h ⟨k, hi⟩
    rwa [restriction_mulVec_apply] at this
  have := (hloc i).inv.dotProduct_mulVec_pos hRx
  convert this using 1
  simp only [star_trivial, ← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose]

-- The card's pieces [0, 0.6] and [0.4, 1]: ρ = (0.4/0.6)(0.4/0.6) = 4/9.
example : ((2 / 5 : ℚ) / (3 / 5)) * ((1 - 3 / 5) / (1 - 2 / 5)) = 4 / 9 := by norm_num

-- Overlap 0.02, pieces [0, 0.51] and [0.49, 1]: ρ = 2401/2601.
example : ((49 / 100 : ℚ) / (51 / 100)) * ((1 - 51 / 100) / (1 - 49 / 100)) = 2401 / 2601 := by
  norm_num

-- No overlap, a = b = 0.5: the factor is 1.
example : ((1 / 2 : ℚ) / (1 / 2)) * ((1 - 1 / 2) / (1 - 1 / 2)) = 1 := by norm_num

-- Worked numbers by hand: u(0.6) = 1/3 after sweep 1, u(0.4) = 2/9 and u(0.6) = 13/27
-- after sweep 2; largest errors 2/5 then 8/45, ratio 4/9.
example : (3 / 5 - 2 / 5 : ℚ) / (1 - 2 / 5) = 1 / 3 := by norm_num
example : (2 / 5 : ℚ) / (3 / 5) * (1 / 3) = 2 / 9 := by norm_num
example : (2 / 9 : ℚ) + (1 / 5) / (3 / 5) * (1 - 2 / 9) = 13 / 27 := by norm_num
example : ((2 / 5 : ℚ) - 2 / 9) / (2 / 5 - 0) = 4 / 9 := by norm_num

-- Schur complement on the grid of step 1/100, cut at x = 0.5:
-- S = 2 - 49/50 - 49/50 = 1/25, g = 1/50, u(0.5) = g/S = 1/2.
example : (2 : ℚ) - 49 / 50 - 49 / 50 = 1 / 25 := by norm_num
example : ((1 / 50 : ℚ)) / (1 / 25) = 1 / 2 := by norm_num

#print axioms alternating_schwarz_sweep_factor
#print axioms schwarz_factor_lt_one_iff_overlap
#print axioms additive_schwarz_preconditioner_posDef
