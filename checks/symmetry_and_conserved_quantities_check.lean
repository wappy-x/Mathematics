-- Symmetry and conservation: a Lagrangian unchanged by a smooth move of its coordinates keeps the momentum along that move constant (Noether), a Lagrangian with no clock in it keeps the energy constant, and for spin one-half S_z commutes with the field's Hamiltonian while S_x does not.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Pi
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Comp

open Filter Topology Complex

noncomputable section

/-- A continuous linear functional on `Fin n → ℝ` is the sum of its values on the basis. -/
theorem clm_sum_basis_mul {n : ℕ} (f : (Fin n → ℝ) →L[ℝ] ℝ) (w : Fin n → ℝ) :
    ∑ i, f (Pi.single i 1) * w i = f w := by
  conv_rhs => rw [← Finset.univ_sum_single w]
  rw [map_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  have : (Pi.single i (w i) : Fin n → ℝ) = w i • Pi.single i (1 : ℝ) := by
    rw [← Pi.single_smul']; simp
  rw [this, map_smul, smul_eq_mul, mul_comm]

/-- The derivative of a function of a pair splits into its two partial derivatives. -/
theorem fderiv_prod_split {E F : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [NormedAddCommGroup F] [NormedSpace ℝ F] (f : E × F → ℝ) (x : E) (v : F)
    (hf : DifferentiableAt ℝ f (x, v)) (a : E) (b : F) :
    fderiv ℝ f (x, v) (a, b)
      = fderiv ℝ (fun y => f (y, v)) x a + fderiv ℝ (fun w => f (x, w)) v b := by
  have h1 : HasFDerivAt (fun y => f (y, v))
      ((fderiv ℝ f (x, v)).comp (ContinuousLinearMap.inl ℝ E F)) x :=
    hf.hasFDerivAt.comp x (hasFDerivAt_prodMk_left x v)
  have h2 : HasFDerivAt (fun w => f (x, w))
      ((fderiv ℝ f (x, v)).comp (ContinuousLinearMap.inr ℝ E F)) v :=
    hf.hasFDerivAt.comp v (hasFDerivAt_prodMk_right x v)
  rw [h1.fderiv, h2.fderiv]
  simp only [ContinuousLinearMap.coe_comp, Function.comp_apply,
    ContinuousLinearMap.inl_apply, ContinuousLinearMap.inr_apply]
  rw [← map_add]; simp

/-- Noether's theorem (The formula, Step 2). Take a system with `n` coordinates and a Lagrangian
`L q q' t`, smooth (differentiable) in position and velocity together. Take a smooth direction
field `η` and suppose the move `q ↦ q + ε η(q)` (so `q' ↦ q' + ε η'`, with `η' = Dη(q) q'`) leaves
`L` unchanged for every small `ε`. Let `q(t)` be a motion obeying Lagrange's equation: the
momentum `p_i = ∂L/∂q_i'` changes at the rate `∂L/∂q_i`. Then `Q = ∑ p_i η_i` is the same at every
time `t` as at time `0`. -/
theorem noether_symmetry_gives_conserved_quantity {n : ℕ}
    (L : (Fin n → ℝ) → (Fin n → ℝ) → ℝ → ℝ)
    (hL : ∀ t, Differentiable ℝ (fun z : (Fin n → ℝ) × (Fin n → ℝ) => L z.1 z.2 t))
    (η : (Fin n → ℝ) → (Fin n → ℝ)) (hη : Differentiable ℝ η)
    (hsym : ∀ x v t, ∀ᶠ ε in 𝓝 (0 : ℝ),
      L (x + ε • η x) (v + ε • fderiv ℝ η x v) t = L x v t)
    (q : ℝ → Fin n → ℝ) (hq : Differentiable ℝ q)
    (hlagrange : ∀ i t, HasDerivAt
      (fun s => fderiv ℝ (fun v => L (q s) v s) (deriv q s) (Pi.single i 1))
      (fderiv ℝ (fun x => L x (deriv q t) t) (q t) (Pi.single i 1)) t) :
    ∀ t : ℝ,
      ∑ i, fderiv ℝ (fun v => L (q t) v t) (deriv q t) (Pi.single i 1) * η (q t) i
        = ∑ i, fderiv ℝ (fun v => L (q 0) v 0) (deriv q 0) (Pi.single i 1) * η (q 0) i := by
  intro t
  have key : ∀ s, HasDerivAt
      (fun s => ∑ i, fderiv ℝ (fun v => L (q s) v s) (deriv q s) (Pi.single i 1) * η (q s) i)
      0 s := by
    intro s
    have hηq : HasDerivAt (fun s => η (q s)) (fderiv ℝ η (q s) (deriv q s)) s :=
      (hη (q s)).hasFDerivAt.comp_hasDerivAt s (hq s).hasDerivAt
    have hsum := HasDerivAt.fun_sum (u := Finset.univ) (x := s)
      (fun i _ => (hlagrange i s).mul (hasDerivAt_pi.1 hηq i))
    convert hsum using 1
    rw [Finset.sum_add_distrib, clm_sum_basis_mul, clm_sum_basis_mul]
    -- symmetry along the move
    set x := q s
    set v := deriv q s
    have hdiff : DifferentiableAt ℝ (fun z : (Fin n → ℝ) × (Fin n → ℝ) => L z.1 z.2 s) (x, v) :=
      (hL s) _
    have hcurve : HasDerivAt (fun ε : ℝ => (x + ε • η x, v + ε • fderiv ℝ η x v))
        ((1 : ℝ) • η x, (1 : ℝ) • fderiv ℝ η x v) 0 :=
      (((hasDerivAt_id (0 : ℝ)).smul_const (η x)).const_add x).prodMk
        (((hasDerivAt_id (0 : ℝ)).smul_const (fderiv ℝ η x v)).const_add v)
    have hd0 : HasFDerivAt (fun z : (Fin n → ℝ) × (Fin n → ℝ) => L z.1 z.2 s)
        (fderiv ℝ (fun z : (Fin n → ℝ) × (Fin n → ℝ) => L z.1 z.2 s) (x, v))
        (x + (0 : ℝ) • η x, v + (0 : ℝ) • fderiv ℝ η x v) := by
      simpa using hdiff.hasFDerivAt
    have hg := hd0.comp_hasDerivAt (0 : ℝ) hcurve
    have hg0 : HasDerivAt (fun ε : ℝ =>
        (fun z : (Fin n → ℝ) × (Fin n → ℝ) => L z.1 z.2 s)
          (x + ε • η x, v + ε • fderiv ℝ η x v)) 0 0 := by
      refine (hasDerivAt_const (0 : ℝ) (L x v s)).congr_of_eventuallyEq ?_
      filter_upwards [hsym x v s] with ε hε
      simpa using hε
    have huniq := hg.unique hg0
    rw [fderiv_prod_split _ x v hdiff] at huniq
    simpa using huniq.symm
  exact is_const_of_deriv_eq_zero (fun s => (key s).differentiableAt)
    (fun s => (key s).deriv) t 0

/-- Steady rules keep energy (Step 3). Take a system with `n` coordinates and a Lagrangian
`L q q' t`, differentiable in position, velocity and time together, that does not change with the
clock (`∂L/∂t = 0`). Let `q(t)` be a motion with a differentiable velocity that obeys Lagrange's
equation: the momentum `p_i = ∂L/∂q_i'` changes at the rate `∂L/∂q_i`. Then the energy
`E = ∑ p_i q_i' - L` is the same at every time `t` as at time `0`. -/
theorem energy_conserved_when_lagrangian_is_steady {n : ℕ}
    (L : (Fin n → ℝ) → (Fin n → ℝ) → ℝ → ℝ)
    (hL : Differentiable ℝ
      (fun z : (Fin n → ℝ) × (Fin n → ℝ) × ℝ => L z.1 z.2.1 z.2.2))
    (hsteady : ∀ x v t, deriv (fun s => L x v s) t = 0)
    (q : ℝ → Fin n → ℝ) (hq : Differentiable ℝ q) (hq' : Differentiable ℝ (deriv q))
    (hlagrange : ∀ i t, HasDerivAt
      (fun s => fderiv ℝ (fun v => L (q s) v s) (deriv q s) (Pi.single i 1))
      (fderiv ℝ (fun x => L x (deriv q t) t) (q t) (Pi.single i 1)) t) :
    ∀ t : ℝ,
      (∑ i, fderiv ℝ (fun v => L (q t) v t) (deriv q t) (Pi.single i 1) * deriv q t i)
          - L (q t) (deriv q t) t
        = (∑ i, fderiv ℝ (fun v => L (q 0) v 0) (deriv q 0) (Pi.single i 1) * deriv q 0 i)
          - L (q 0) (deriv q 0) 0 := by
  intro t
  have key : ∀ s, HasDerivAt
      (fun s => (∑ i, fderiv ℝ (fun v => L (q s) v s) (deriv q s) (Pi.single i 1) * deriv q s i)
          - L (q s) (deriv q s) s) 0 s := by
    intro s
    have hq's : HasDerivAt (deriv q) (deriv (deriv q) s) s := (hq' s).hasDerivAt
    have hsum := HasDerivAt.fun_sum (u := Finset.univ) (x := s)
      (fun i _ => (hlagrange i s).mul (hasDerivAt_pi.1 hq's i))
    have hcurve : HasDerivAt (fun r : ℝ => (q r, (deriv q r, r)))
        (deriv q s, (deriv (deriv q) s, 1)) s :=
      (hq s).hasDerivAt.prodMk (hq's.prodMk (hasDerivAt_id s))
    have hLc := (hL _).hasFDerivAt.comp_hasDerivAt s hcurve
    have hE := hsum.sub hLc
    convert hE using 1
    all_goals try (funext r; rfl)
    rw [Finset.sum_add_distrib, clm_sum_basis_mul, clm_sum_basis_mul]
    set x := q s
    set v := deriv q s
    have hdiff : DifferentiableAt ℝ
        (fun z : (Fin n → ℝ) × (Fin n → ℝ) × ℝ => L z.1 z.2.1 z.2.2) (x, (v, s)) := hL _
    have hdiff2 : DifferentiableAt ℝ
        (fun w : (Fin n → ℝ) × ℝ => L x w.1 w.2) (v, s) :=
      hdiff.comp (v, s) (differentiableAt_const x |>.prodMk differentiableAt_id)
    rw [fderiv_prod_split _ x (v, s) hdiff]
    simp only []
    rw [fderiv_prod_split (fun w : (Fin n → ℝ) × ℝ => L x w.1 w.2) v s hdiff2]
    simp only []
    have ht : fderiv ℝ (fun r => L x v r) s 1 = 0 := by
      rw [← deriv]; exact hsteady x v s
    rw [ht]; ring
  exact is_const_of_deriv_eq_zero (fun s => (key s).differentiableAt)
    (fun s => (key s).deriv) t 0

/-- Spin one-half in a field along `z` (Step 5), in units where `ħ = 1`. With the spin matrices
`S_x = ½ [[0,1],[1,0]]`, `S_y = ½ [[0,-i],[i,0]]`, `S_z = ½ [[1,0],[0,-1]]`:
`[S_x, S_y] = i S_z`; and for every sweep rate `ω` and Hamiltonian `H = ω S_z`,
`[S_z, H] = 0` (so `S_z` is kept) while `[S_x, H] = -i ω S_y` (so `S_x` moves). -/
theorem spin_half_commutators_with_field_along_z (ω : ℝ) :
    let Sx : Matrix (Fin 2) (Fin 2) ℂ := !![0, 1 / 2; 1 / 2, 0]
    let Sy : Matrix (Fin 2) (Fin 2) ℂ := !![0, -I / 2; I / 2, 0]
    let Sz : Matrix (Fin 2) (Fin 2) ℂ := !![1 / 2, 0; 0, -1 / 2]
    let H : Matrix (Fin 2) (Fin 2) ℂ := (ω : ℂ) • Sz
    Sx * Sy - Sy * Sx = I • Sz ∧
      Sz * H - H * Sz = 0 ∧
      Sx * H - H * Sx = (-(I * ω)) • Sy := by
  intro Sx Sy Sz H
  refine ⟨?_, ?_, ?_⟩ <;>
  · ext i j
    fin_cases i <;> fin_cases j <;>
      simp [Sx, Sy, Sz, H] <;> ring_nf <;> simp [Complex.ext_iff] <;> ring

end

/-! Worked numbers from the card. -/

-- The spin starts 60 degrees from the field: its average component along the field is
-- ½ × cos 60° = 1/4 ħ (the card's 0.2500 ħ).
example : (1 / 2 : ℝ) * Real.cos (Real.pi / 3) = 1 / 4 := by
  rw [Real.cos_pi_div_three]; norm_num

#print axioms clm_sum_basis_mul
#print axioms fderiv_prod_split
#print axioms noether_symmetry_gives_conserved_quantity
#print axioms energy_conserved_when_lagrangian_is_steady
#print axioms spin_half_commutators_with_field_along_z
