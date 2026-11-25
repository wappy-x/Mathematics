-- Lie's theorems: SO(3) and SU(2) share one bracket table, yet no map from rotations to SU(2) can send each yaw turn exp(θ Lz) to the spin-1/2 turn exp(θ X3), the members of SU(2) lying over the rotation I are exactly I and -I, and the slope-√2 line on the torus is one-to-one and dense but not closed.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Algebra.Lie.OfAssociative
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Data.Real.Sqrt
import Mathlib.Topology.Instances.AddCircle.DenseSubgroup
import Mathlib.Analysis.SpecialFunctions.Exponential

open Matrix

namespace LiesTheorems

/-- The unit roll rate `Lx` in so(3), a 3 by 3 skew matrix. -/
def Lx : Matrix (Fin 3) (Fin 3) ℝ := !![0, 0, 0; 0, 0, -1; 0, 1, 0]

/-- The unit pitch rate `Ly` in so(3). -/
def Ly : Matrix (Fin 3) (Fin 3) ℝ := !![0, 0, 1; 0, 0, 0; -1, 0, 0]

/-- The unit yaw rate `Lz` in so(3). -/
def Lz : Matrix (Fin 3) (Fin 3) ℝ := !![0, -1, 0; 1, 0, 0; 0, 0, 0]

/-- The rate `X1` in su(2): `-i/2` times the first Pauli matrix. -/
noncomputable def X1 : Matrix (Fin 2) (Fin 2) ℂ := !![0, -Complex.I / 2; -Complex.I / 2, 0]

/-- The rate `X2` in su(2): `-i/2` times the second Pauli matrix. -/
noncomputable def X2 : Matrix (Fin 2) (Fin 2) ℂ := !![0, -1 / 2; 1 / 2, 0]

/-- The rate `X3` in su(2): `-i/2` times the third Pauli matrix, `diag(-i/2, i/2)`. -/
noncomputable def X3 : Matrix (Fin 2) (Fin 2) ℂ := !![-Complex.I / 2, 0; 0, Complex.I / 2]

/-- The line of slope `√2` on the torus of the gimbal's two motor angles, each counted in
turns (modulo one): at time `t` motor 1 is at `t` and motor 2 at `√2 t`. -/
noncomputable def torusLine (t : ℝ) : AddCircle (1 : ℝ) × AddCircle (1 : ℝ) :=
  ((t : AddCircle (1 : ℝ)), ((Real.sqrt 2 * t : ℝ) : AddCircle (1 : ℝ)))

/-! ### Helper lemmas -/

theorem X3_smul_eq_diagonal (z : ℂ) :
    z • X3 = diagonal ![-(z * Complex.I / 2), z * Complex.I / 2] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [X3] <;> ring

theorem exp_smul_X3 (z : ℂ) :
    NormedSpace.exp (z • X3) =
      diagonal ![Complex.exp (-(z * Complex.I / 2)), Complex.exp (z * Complex.I / 2)] := by
  rw [X3_smul_eq_diagonal, Matrix.exp_diagonal]
  congr 1
  ext i; fin_cases i <;> simp [← Complex.exp_eq_exp_ℂ]

theorem exp_two_pi_X3 : NormedSpace.exp (((2 * Real.pi : ℝ) : ℂ) • X3) = -1 := by
  rw [exp_smul_X3]
  have h1 : Complex.exp (-(((2 * Real.pi : ℝ) : ℂ) * Complex.I / 2)) = -1 := by
    have : -(((2 * Real.pi : ℝ) : ℂ) * Complex.I / 2) = -(Real.pi * Complex.I) := by
      push_cast; ring
    rw [this, Complex.exp_neg, Complex.exp_pi_mul_I]; norm_num
  have h2 : Complex.exp (((2 * Real.pi : ℝ) : ℂ) * Complex.I / 2) = -1 := by
    have : (((2 * Real.pi : ℝ) : ℂ) * Complex.I / 2) = (Real.pi * Complex.I) := by
      push_cast; ring
    rw [this, Complex.exp_pi_mul_I]
  rw [h1, h2]
  ext i j; fin_cases i <;> fin_cases j <;> simp

theorem exp_four_pi_X3 : NormedSpace.exp (((4 * Real.pi : ℝ) : ℂ) • X3) = 1 := by
  rw [exp_smul_X3]
  have h1 : Complex.exp (-(((4 * Real.pi : ℝ) : ℂ) * Complex.I / 2)) = 1 := by
    have : -(((4 * Real.pi : ℝ) : ℂ) * Complex.I / 2) = ((-1 : ℤ) : ℂ) * (2 * Real.pi * Complex.I) := by
      push_cast; ring
    rw [this, Complex.exp_int_mul_two_pi_mul_I]
  have h2 : Complex.exp (((4 * Real.pi : ℝ) : ℂ) * Complex.I / 2) = 1 := by
    have : (((4 * Real.pi : ℝ) : ℂ) * Complex.I / 2) = ((1 : ℤ) : ℂ) * (2 * Real.pi * Complex.I) := by
      push_cast; ring
    rw [this, Complex.exp_int_mul_two_pi_mul_I]
  rw [h1, h2]
  ext i j; fin_cases i <;> fin_cases j <;> simp

noncomputable def P : Matrix (Fin 3) (Fin 3) ℂ := !![1, 1, 0; -Complex.I, Complex.I, 0; 0, 0, 1]
noncomputable def Q : Matrix (Fin 3) (Fin 3) ℂ :=
  !![1/2, Complex.I/2, 0; 1/2, -Complex.I/2, 0; 0, 0, 1]

theorem PQ : P * Q = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [P, Q, Matrix.mul_apply, Fin.sum_univ_three] <;> ring_nf <;> simp

theorem Lz_conj (t : ℝ) :
    (Complex.ofRealHom.mapMatrix (t • Lz) : Matrix (Fin 3) (Fin 3) ℂ) =
      P * diagonal ![t * Complex.I, -(t * Complex.I), 0] * P⁻¹ := by
  rw [Matrix.inv_eq_right_inv PQ]
  ext i j
  simp only [Matrix.mul_apply, Fin.sum_univ_three, Matrix.diagonal_apply]
  fin_cases i <;> fin_cases j <;> simp [P, Q, Lz] <;> ring_nf <;> simp

theorem exp_two_pi_Lz : NormedSpace.exp ((2 * Real.pi) • Lz) = 1 := by
  have hc : Continuous (Complex.ofRealHom.mapMatrix : Matrix (Fin 3) (Fin 3) ℝ →+* _) :=
    continuous_id.matrix_map Complex.continuous_ofReal
  apply Matrix.map_injective Complex.ofReal_injective
  show Complex.ofRealHom.mapMatrix _ = Complex.ofRealHom.mapMatrix _
  have hm : ∀ x : Matrix (Fin 3) (Fin 3) ℝ, Complex.ofRealHom.mapMatrix (NormedSpace.exp x) =
      NormedSpace.exp (Complex.ofRealHom.mapMatrix x) := fun x => by
    open scoped Norms.Operator in
    exact NormedSpace.map_exp (Complex.ofRealHom.mapMatrix : Matrix (Fin 3) (Fin 3) ℝ →+* _) hc x
  rw [hm, Lz_conj, Matrix.exp_conj _ _ (IsUnit.of_mul_eq_one _ PQ),
    Matrix.exp_diagonal, map_one, Matrix.inv_eq_right_inv PQ]
  have : NormedSpace.exp (![((2 * Real.pi : ℝ) : ℂ) * Complex.I, -(((2 * Real.pi : ℝ) : ℂ) * Complex.I), 0]) = (1 : Fin 3 → ℂ) := by
    ext i; fin_cases i <;> simp [← Complex.exp_eq_exp_ℂ, Complex.exp_neg]
  rw [this, Matrix.diagonal_one', Matrix.mul_one, PQ]

theorem neg_one_mem_su2 : (-1 : Matrix (Fin 2) (Fin 2) ℂ) ∈ specialUnitaryGroup (Fin 2) ℂ := by
  rw [mem_specialUnitaryGroup_iff, mem_unitaryGroup_iff']
  refine ⟨by simp, ?_⟩
  simp [Matrix.det_neg]

theorem commute_of_conj_eq {U X : Matrix (Fin 2) (Fin 2) ℂ}
    (hU : U ∈ unitaryGroup (Fin 2) ℂ) (h : U * X * star U = X) : U * X = X * U := by
  rw [mem_unitaryGroup_iff'] at hU
  calc U * X = U * X * (star U * U) := by rw [hU, Matrix.mul_one]
    _ = (U * X * star U) * U := by simp only [Matrix.mul_assoc]
    _ = X * U := by rw [h]

theorem circle_coe_eq_iff {x y : ℝ} :
    ((x : AddCircle (1 : ℝ)) = y) ↔ ∃ n : ℤ, (n : ℝ) = x - y := by
  rw [← sub_eq_zero, ← AddCircle.coe_sub, AddCircle.coe_eq_zero_iff]
  simp

theorem sqrt_two_mul_int_ne_rat (n : ℤ) (q : ℚ) (hn : n ≠ 0) :
    Real.sqrt 2 * n ≠ q := by
  intro h
  apply irrational_sqrt_two
  refine ⟨q / n, ?_⟩
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  push_cast
  rw [← h]
  field_simp

/-- The spin-1/2 guess fails: there is no map at all (let alone a group map) from 3 by 3 real
matrices, and so none from SO(3), to 2 by 2 complex matrices that sends the yaw turn
`exp(θ Lz)` to the spin-1/2 turn `exp(θ X3)` for every angle `θ`. The full turn `θ = 2π`
gives the rotation `I` again, which the guess would have to send to both `I` and `-I`;
so the bracket-keeping map `Lz ↦ X3` has no group map behind it, because SO(3) is not
simply connected. -/
theorem no_map_from_rotations_to_su2_for_spin_half :
    ¬ ∃ Φ : Matrix (Fin 3) (Fin 3) ℝ → Matrix (Fin 2) (Fin 2) ℂ,
      ∀ θ : ℝ, Φ (NormedSpace.exp (θ • Lz)) = NormedSpace.exp ((θ : ℂ) • X3) := by
  rintro ⟨Φ, hΦ⟩
  have h0 := hΦ 0
  have h2 := hΦ (2 * Real.pi)
  simp only [zero_smul, Complex.ofReal_zero, NormedSpace.exp_zero] at h0
  rw [exp_two_pi_Lz, exp_two_pi_X3, h0] at h2
  have := congrFun (congrFun h2 0) 0
  norm_num at this

/-- The kernel of the double cover has two points: a member `U` of SU(2) lies over the
rotation `I` (conjugation by `U` fixes each of the rates `X1, X2, X3`) exactly when
`U = I` or `U = -I`. So `Γ = {I, -I}` and SO(3) is SU(2) with `U` and `-U` folded. -/
theorem su2_over_identity_rotation_eq_pm_one :
    {U : Matrix (Fin 2) (Fin 2) ℂ | U ∈ specialUnitaryGroup (Fin 2) ℂ ∧
        U * X1 * star U = X1 ∧ U * X2 * star U = X2 ∧ U * X3 * star U = X3} =
      {1, -1} := by
  ext U
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
  constructor
  · rintro ⟨hU, h1, -, h3⟩
    have hU' := hU
    rw [mem_specialUnitaryGroup_iff] at hU'
    obtain ⟨hu, hdet⟩ := hU'
    have c1 := commute_of_conj_eq hu h1
    have c3 := commute_of_conj_eq hu h3
    have e01 := congrFun (congrFun c3 0) 1
    have e10 := congrFun (congrFun c3 1) 0
    have f01 := congrFun (congrFun c1 0) 1
    simp [X1, X3, Matrix.mul_apply, Fin.sum_univ_two] at e01 e10 f01
    rw [Matrix.det_fin_two] at hdet
    have hb : U 0 1 = 0 := by
      have : U 0 1 * Complex.I = 0 := by linear_combination e01
      simpa [Complex.I_ne_zero] using this
    have hc : U 1 0 = 0 := by
      have : U 1 0 * Complex.I = 0 := by linear_combination -e10
      simpa [Complex.I_ne_zero] using this
    have hd : U 1 1 = U 0 0 := by
      have : (U 1 1 - U 0 0) * Complex.I = 0 := by linear_combination 2 * f01
      simpa [Complex.I_ne_zero, sub_eq_zero] using this
    rw [hb, hc, hd] at hdet
    have : (U 0 0 - 1) * (U 0 0 + 1) = 0 := by linear_combination hdet
    rcases mul_eq_zero.mp this with h | h
    · left
      ext i j; fin_cases i <;> fin_cases j <;> simp [hb, hc, hd] <;> linear_combination h
    · right
      ext i j; fin_cases i <;> fin_cases j <;> simp [hb, hc, hd] <;> linear_combination h
  · rintro (rfl | rfl)
    · exact ⟨one_mem _, by simp, by simp, by simp⟩
    · exact ⟨neg_one_mem_su2, by simp, by simp, by simp⟩

/-- The slope-`√2` line on the torus is a one-to-one copy of the real line that comes
back near every pair of motor angles (dense) but never closes up, and it is not a closed
subset of the torus, so it is not an embedded Lie subgroup. -/
theorem sqrt_two_torus_line_injective_dense_not_closed :
    Function.Injective torusLine ∧ Dense (Set.range torusLine) ∧
      ¬ IsClosed (Set.range torusLine) := by
  have hdense : Dense (Set.range torusLine) := by
    intro x
    obtain ⟨A, B⟩ := x
    obtain ⟨a, rfl⟩ := QuotientAddGroup.mk_surjective A
    let g : AddCircle (1 : ℝ) → AddCircle (1 : ℝ) × AddCircle (1 : ℝ) :=
      fun y => (((a : ℝ) : AddCircle (1 : ℝ)), ((Real.sqrt 2 * a : ℝ) : AddCircle (1 : ℝ)) + y)
    have hg : Continuous g := by fun_prop
    have hD : Dense (Set.range (· • ((Real.sqrt 2 : ℝ) : AddCircle (1 : ℝ)) : ℤ → AddCircle (1 : ℝ))) :=
      AddCircle.denseRange_zsmul_coe_iff (a := Real.sqrt 2) (p := 1) |>.mpr (by simpa using irrational_sqrt_two)
    have hsub : g '' Set.range (· • ((Real.sqrt 2 : ℝ) : AddCircle (1 : ℝ)) : ℤ → AddCircle (1 : ℝ))
        ⊆ Set.range torusLine := by
      rintro _ ⟨_, ⟨n, rfl⟩, rfl⟩
      refine ⟨a + n, ?_⟩
      simp only [torusLine, g, Prod.mk.injEq]
      constructor
      · exact circle_coe_eq_iff.mpr ⟨n, by ring⟩
      · rw [← AddCircle.coe_zsmul, ← AddCircle.coe_add, zsmul_eq_mul]
        congr 1; ring
    have hx : ((a : AddCircle (1 : ℝ)), B) ∈ Set.range g :=
      ⟨B - ((Real.sqrt 2 * a : ℝ) : AddCircle (1 : ℝ)), by simp [g]⟩
    exact closure_mono hsub (hg.range_subset_closure_image_dense hD hx)
  refine ⟨?_, hdense, ?_⟩
  · intro t s h
    simp only [torusLine, Prod.mk.injEq] at h
    obtain ⟨⟨n, hn⟩, ⟨m, hm⟩⟩ := And.intro (circle_coe_eq_iff.mp h.1) (circle_coe_eq_iff.mp h.2)
    by_cases h0 : n = 0
    · subst h0; simp at hn; linarith
    · exfalso
      apply sqrt_two_mul_int_ne_rat n m h0
      rw [hn]; push_cast; linarith
  · intro hcl
    have huniv : Set.range torusLine = Set.univ := by
      rw [← hcl.closure_eq, hdense.closure_eq]
    have hmem : ((0 : AddCircle (1 : ℝ)), (((1 / 2 : ℝ)) : AddCircle (1 : ℝ))) ∈ Set.range torusLine := by
      rw [huniv]; trivial
    obtain ⟨t, ht⟩ := hmem
    simp only [torusLine, Prod.mk.injEq] at ht
    obtain ⟨n, hn⟩ := circle_coe_eq_iff.mp (ht.1.trans (AddCircle.coe_zero (1 : ℝ)).symm)
    rw [sub_zero] at hn
    subst hn
    obtain ⟨m, hm⟩ := circle_coe_eq_iff.mp ht.2
    by_cases h0 : n = 0
    · subst h0
      have : (2 * m + 1 : ℝ) = 0 := by simp at hm; linarith
      have : (2 * m + 1 : ℤ) = 0 := by exact_mod_cast this
      omega
    · apply sqrt_two_mul_int_ne_rat n ((m : ℚ) + 1 / 2) h0
      push_cast; linarith

/-! ### The card's worked numbers -/

/-- `[X1, X2] = X3` and its cyclic turns in su(2). -/
example : ⁅X1, X2⁆ = X3 ∧ ⁅X2, X3⁆ = X1 ∧ ⁅X3, X1⁆ = X2 := by
  simp only [Ring.lie_def]
  refine ⟨?_, ?_, ?_⟩ <;> ext i j <;> fin_cases i <;> fin_cases j <;>
    simp [X1, X2, X3] <;> ring_nf <;> simp [Complex.I_sq] <;> ring

/-- `[Lx, Ly] = Lz` and its cyclic turns in so(3): the same bracket table. -/
example : ⁅Lx, Ly⁆ = Lz ∧ ⁅Ly, Lz⁆ = Lx ∧ ⁅Lz, Lx⁆ = Ly := by
  simp only [Ring.lie_def]
  refine ⟨?_, ?_, ?_⟩ <;> ext i j <;> fin_cases i <;> fin_cases j <;>
    simp [Lx, Ly, Lz]

/-- A full yaw turn, 360°, is `I` in SO(3). -/
example : NormedSpace.exp ((2 * Real.pi) • Lz) = 1 := exp_two_pi_Lz

/-- A full yaw turn, 360°, is `-I` in SU(2). -/
example : NormedSpace.exp (((2 * Real.pi : ℝ) : ℂ) • X3) = -1 := exp_two_pi_X3

/-- Two full yaw turns, 720°, are `I` in SU(2). -/
example : NormedSpace.exp (((4 * Real.pi : ℝ) : ℂ) • X3) = 1 := exp_four_pi_X3

/-- The record return times of the slope-`√2` line up to 1,000 turns follow the Pell rule:
each is twice the last plus the one before, and the next, 2378, passes 1,000. -/
example :
    let r : List ℕ := [1, 2, 5, 12, 29, 70, 169, 408, 985]
    (List.range 7).all (fun i => r[i + 2]! == 2 * r[i + 1]! + r[i]!) = true ∧
      2 * 985 + 408 = 2378 := by
  decide

/-- After 12 turns of motor 1, motor 2 at `12√2` turns falls just short of 17. -/
example : 16 < 12 * Real.sqrt 2 ∧ 12 * Real.sqrt 2 < 17 := by
  have h := Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num)
  have h0 := Real.sqrt_nonneg 2
  constructor <;> nlinarith

/-- The Pell identity behind the 12-turn miss `17 - 12√2`: `17² - 2·12² = 1`. -/
example : (17 : ℤ) ^ 2 - 2 * 12 ^ 2 = 1 := by norm_num

/-- Slope 3/2 closes exactly after 2 turns: `2 · 3/2 = 3`, a whole number. -/
example : (2 : ℚ) * (3 / 2) = 3 := by norm_num

#print axioms X3_smul_eq_diagonal
#print axioms exp_smul_X3
#print axioms exp_two_pi_X3
#print axioms exp_four_pi_X3
#print axioms PQ
#print axioms Lz_conj
#print axioms exp_two_pi_Lz
#print axioms neg_one_mem_su2
#print axioms commute_of_conj_eq
#print axioms circle_coe_eq_iff
#print axioms sqrt_two_mul_int_ne_rat
#print axioms no_map_from_rotations_to_su2_for_spin_half
#print axioms su2_over_identity_rotation_eq_pm_one
#print axioms sqrt_two_torus_line_injective_dense_not_closed

end LiesTheorems
