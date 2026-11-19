-- Group action and homogeneous space: a transitive group's cosets of a stabiliser match the space's points one for one, and the globe is SO(3) with the polar spins divided out.
import Mathlib.GroupTheory.GroupAction.Quotient
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Arg

open Matrix

/-- The spin `Z(α)` of the globe by angle `α` about the polar (`z`) axis. -/
noncomputable def spinZ (α : ℝ) : Matrix (Fin 3) (Fin 3) ℝ :=
  !![Real.cos α, -Real.sin α, 0; Real.sin α, Real.cos α, 0; 0, 0, 1]

/-- The North Pole `n = (0, 0, 1)`. -/
def northPole : Fin 3 → ℝ := ![0, 0, 1]

lemma exists_angle_of_sq_add_sq (a b : ℝ) (h : a ^ 2 + b ^ 2 = 1) :
    ∃ α : ℝ, Real.cos α = a ∧ Real.sin α = b := by
  set z : ℂ := ⟨a, b⟩ with hzdef
  have hn : ‖z‖ = 1 := by
    rw [Complex.norm_def, Complex.normSq_mk, ← sq, ← sq, h, Real.sqrt_one]
  have hz : z ≠ 0 := by
    intro h0; rw [h0, norm_zero] at hn; exact zero_ne_one hn
  exact ⟨Complex.arg z, by rw [Complex.cos_arg hz, hn, div_one],
    by rw [Complex.sin_arg, hn, div_one]⟩

lemma spinZ_mulVec_northPole (α : ℝ) : spinZ α *ᵥ northPole = northPole := by
  ext i; fin_cases i <;> simp [spinZ, northPole, mulVec, dotProduct, Fin.sum_univ_three]

lemma mem_SO3_mk (A : Matrix (Fin 3) (Fin 3) ℝ) (ho : A * Aᵀ = 1) (hd : A.det = 1) :
    A ∈ specialOrthogonalGroup (Fin 3) ℝ :=
  ⟨(mem_orthogonalGroup_iff (Fin 3) ℝ).mpr ho, hd⟩

#print axioms exists_angle_of_sq_add_sq
#print axioms spinZ_mulVec_northPole
#print axioms mem_SO3_mk

/-- If a group `G` can carry any point of `M` to any other (the action is transitive, so `M` is
a homogeneous space of `G`), and `H` is the stabiliser of a base point `p`, then the cosets `gH`
match the points of `M` one for one, by the rule `gH ↦ g • p`: `G / H ↔ M`. -/
theorem quotient_by_stabilizer_equiv_homogeneous_space
    {G M : Type*} [Group G] [MulAction G M] [MulAction.IsPretransitive G M] (p : M) :
    ∃ e : G ⧸ MulAction.stabilizer G p ≃ M,
      ∀ g : G, e (g : G ⧸ MulAction.stabilizer G p) = g • p := by
  refine ⟨Equiv.ofBijective (MulAction.ofQuotientStabilizer G p)
    ⟨MulAction.injective_ofQuotientStabilizer G p, fun m => ?_⟩, fun g => ?_⟩
  · obtain ⟨g, hg⟩ := MulAction.exists_smul_eq G p m
    exact ⟨(g : G ⧸ MulAction.stabilizer G p), by rw [MulAction.ofQuotientStabilizer_mk, hg]⟩
  · exact MulAction.ofQuotientStabilizer_mk G p g

/-- The turns in `SO(3)` that keep the North Pole still are exactly the spins `Z(α)` about the
polar axis: the stabiliser of the pole is the circle group `SO(2)`. -/
theorem stabilizer_of_north_pole_eq_spins (g : Matrix (Fin 3) (Fin 3) ℝ)
    (hg : g ∈ specialOrthogonalGroup (Fin 3) ℝ) :
    g *ᵥ northPole = northPole ↔ ∃ α : ℝ, g = spinZ α := by
  constructor
  · intro h
    obtain ⟨ho, hd⟩ := hg
    have ho' : g * gᵀ = 1 := (mem_orthogonalGroup_iff (Fin 3) ℝ).mp ho
    have e : ∀ i j, (g * gᵀ) i j = (1 : Matrix (Fin 3) (Fin 3) ℝ) i j := fun i j => by rw [ho']
    have hv : ∀ i, (g *ᵥ northPole) i = northPole i := fun i => by rw [h]
    have e00 := e 0 0
    have e11 := e 1 1
    have e01 := e 0 1
    have e22 := e 2 2
    have v0 := hv 0
    have v1 := hv 1
    have v2 := hv 2
    have hd' : g.det = 1 := hd
    rw [Matrix.det_fin_three] at hd'
    simp [Matrix.mul_apply, Fin.sum_univ_three, mulVec, dotProduct, northPole] at e00 e11 e01 e22 v0 v1 v2
    simp only [v0, v1, v2] at hd' e00 e11 e01 e22
    have h20 : g 2 0 = 0 := by nlinarith [sq_nonneg (g 2 0), sq_nonneg (g 2 1)]
    have h21 : g 2 1 = 0 := by nlinarith [sq_nonneg (g 2 0), sq_nonneg (g 2 1)]
    have hd2 : g 0 0 * g 1 1 - g 0 1 * g 1 0 = 1 := by linear_combination hd'
    have hsq : (g 1 1 - g 0 0) ^ 2 + (g 1 0 + g 0 1) ^ 2 = 0 := by
      linear_combination e00 + e11 - 2 * hd2
    have h1 : (g 1 1 - g 0 0) ^ 2 = 0 := by
      nlinarith [sq_nonneg (g 1 1 - g 0 0), sq_nonneg (g 1 0 + g 0 1)]
    have h2 : (g 1 0 + g 0 1) ^ 2 = 0 := by
      nlinarith [sq_nonneg (g 1 1 - g 0 0), sq_nonneg (g 1 0 + g 0 1)]
    have ha : g 1 1 = g 0 0 := sub_eq_zero.mp (pow_eq_zero_iff two_ne_zero |>.mp h1)
    have hb : g 0 1 = -g 1 0 := by
      have := pow_eq_zero_iff two_ne_zero |>.mp h2
      linarith
    obtain ⟨α, hc, hs⟩ := exists_angle_of_sq_add_sq (g 0 0) (g 1 0)
      (by rw [hb] at e00; linear_combination e00)
    refine ⟨α, ?_⟩
    ext i j
    fin_cases i <;> fin_cases j <;> simp [spinZ, hc, hs, ha, hb, v0, v1, v2, h20, h21]
  · rintro ⟨α, rfl⟩
    exact spinZ_mulVec_northPole α

/-- The globe is the rotation group divided by the polar spins, `SO(3)/SO(2) ↔ S²`, by
`gH ↦ g • n`: every turn sends the North Pole to a point of the unit sphere, every point of the
unit sphere is reached by some turn, and two turns send the pole to the same point exactly when
the second is the first followed on the right by a spin, `g' = g Z(α)`. -/
theorem sphere_eq_rotations_mod_polar_spins :
    (∀ g ∈ specialOrthogonalGroup (Fin 3) ℝ, (g *ᵥ northPole) ⬝ᵥ (g *ᵥ northPole) = 1) ∧
    (∀ v : Fin 3 → ℝ, v ⬝ᵥ v = 1 →
      ∃ g ∈ specialOrthogonalGroup (Fin 3) ℝ, g *ᵥ northPole = v) ∧
    (∀ g ∈ specialOrthogonalGroup (Fin 3) ℝ, ∀ g' ∈ specialOrthogonalGroup (Fin 3) ℝ,
      g *ᵥ northPole = g' *ᵥ northPole ↔ ∃ α : ℝ, g' = g * spinZ α) := by
  refine ⟨?_, ?_, ?_⟩
  · intro g hg
    have ho' : gᵀ * g = 1 := (mem_orthogonalGroup_iff' (Fin 3) ℝ).mp hg.1
    have e22 : (gᵀ * g) 2 2 = (1 : Matrix (Fin 3) (Fin 3) ℝ) 2 2 := by rw [ho']
    simp [Matrix.mul_apply, Fin.sum_univ_three, mulVec, dotProduct, northPole] at e22 ⊢
    linear_combination e22
  · intro v hv
    simp [dotProduct, Fin.sum_univ_three] at hv
    by_cases hz : v 2 = -1
    · have hx : v 0 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1)]
      have hy : v 1 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1)]
      refine ⟨!![1, 0, 0; 0, -1, 0; 0, 0, -1], mem_SO3_mk _ ?_ ?_, ?_⟩
      · ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_three]
      · simp [Matrix.det_fin_three]
      · ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_three, northPole, hx, hy, hz]
    · have hw : 1 + v 2 ≠ 0 := by intro h; apply hz; linarith
      set x := v 0
      set y := v 1
      set z := v 2
      refine ⟨!![1 - x ^ 2 / (1 + z), -(x * y) / (1 + z), x;
                 -(x * y) / (1 + z), 1 - y ^ 2 / (1 + z), y;
                 -x, -y, z], mem_SO3_mk _ ?_ ?_, ?_⟩
      · ext i j; fin_cases i <;> fin_cases j <;>
          simp [Matrix.mul_apply, Fin.sum_univ_three] <;> field_simp
        · linear_combination x ^ 2 * hv
        · linear_combination x * y * hv
        · linear_combination x * hv
        · linear_combination x * y * hv
        · linear_combination y ^ 2 * hv
        · linear_combination y * hv
        · linear_combination x * hv
        · linear_combination y * hv
        · linear_combination hv
      · simp [Matrix.det_fin_three]; field_simp; linear_combination (1 + z) * hv
      · ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_three, northPole, x, y, z]
  · intro g hg g' hg'
    have hgo : g * gᵀ = 1 := (mem_orthogonalGroup_iff (Fin 3) ℝ).mp hg.1
    have hgo' : gᵀ * g = 1 := (mem_orthogonalGroup_iff' (Fin 3) ℝ).mp hg.1
    have hg'o : g' * g'ᵀ = 1 := (mem_orthogonalGroup_iff (Fin 3) ℝ).mp hg'.1
    have hgd : g.det = 1 := hg.2
    have hg'd : g'.det = 1 := hg'.2
    have hk : gᵀ * g' ∈ specialOrthogonalGroup (Fin 3) ℝ := by
      refine mem_SO3_mk _ ?_ ?_
      · rw [Matrix.transpose_mul, Matrix.transpose_transpose, Matrix.mul_assoc,
          ← Matrix.mul_assoc g', hg'o, Matrix.one_mul, hgo']
      · rw [Matrix.det_mul, Matrix.det_transpose, hgd, hg'd, one_mul]
    constructor
    · intro h
      have hkn : (gᵀ * g') *ᵥ northPole = northPole := by
        rw [← Matrix.mulVec_mulVec, ← h, Matrix.mulVec_mulVec, hgo', Matrix.one_mulVec]
      obtain ⟨α, hα⟩ := (stabilizer_of_north_pole_eq_spins _ hk).mp hkn
      refine ⟨α, ?_⟩
      rw [← hα, ← Matrix.mul_assoc, hgo, Matrix.one_mul]
    · rintro ⟨α, rfl⟩
      rw [← Matrix.mulVec_mulVec, spinZ_mulVec_northPole]

-- The globe's dimension: three turning directions minus the one spin that leaves a point still.
example : 3 - 1 = 2 := by decide

-- The cube's 24 turns: orbit times stabiliser is 24 for a face centre, a corner,
-- an edge midpoint and a general point.
example : 6 * 4 = 24 ∧ 8 * 3 = 24 ∧ 12 * 2 = 24 ∧ 24 * 1 = 24 := by decide

-- The 3 special orbits hold 6 + 8 + 12 = 26 points.
example : 6 + 8 + 12 = 26 := by decide

-- Turn-and-fixed-point pairs counted two ways: by points 46, by turns 23 x 2 = 46.
example : 6 * (4 - 1) + 8 * (3 - 1) + 12 * (2 - 1) = 46 ∧ (24 - 1) * 2 = 46 := by decide

#print axioms quotient_by_stabilizer_equiv_homogeneous_space
#print axioms stabilizer_of_north_pole_eq_spins
#print axioms sphere_eq_rotations_mod_polar_spins
