-- Yang-Mills existence and mass gap: in the card's Z2 lattice toy on a 2 by 2 box, the transfer matrix is positive definite for every coupling β > 0 (reflection positivity on the lattice), each link's 2 by 2 factor has eigenvalues 2 cosh β and 2 sinh β, and a ±1 plaquette weight splits as cosh β (1 + u U) with u = tanh β; the open Clay problem itself is not stated.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Arsinh

open Real Matrix

/-- A slice configuration of the 2 by 2 periodic box: each of its 8 spatial links carries a
value, `false` for +1 and `true` for −1. -/
abbrev Slice := Fin 8 → Bool

/-- The ±1 value a link carries. -/
def spin (b : Bool) : ℝ := if b then -1 else 1

/-- The card's link number: site `(x, y)`, direction `d` (0 along x, 1 along y). -/
def lid (x y d : Fin 2) : Fin 8 := ⟨2 * (x.val + 2 * y.val) + d.val, by omega⟩

/-- The plaquette at site `(x, y)`: the product of the four links round that unit square
(the box is periodic, so `x + 1` wraps round in `Fin 2`). -/
def plaq (s : Slice) (x y : Fin 2) : ℝ :=
  spin (s (lid x y 0)) * spin (s (lid (x + 1) y 1)) * spin (s (lid x (y + 1) 0)) *
    spin (s (lid x y 1))

/-- `P(s)`: the sum of the slice's four plaquettes. -/
def plaqSum (s : Slice) : ℝ := ∑ x : Fin 2, ∑ y : Fin 2, plaq s x y

/-- The card's transfer matrix on the 256 slice configurations, with every timelike link +1:
`T(s, s') = e^(β P(s)/2) · ∏ₗ e^(β sₗ s'ₗ) · e^(β P(s')/2)`. -/
noncomputable def transfer (β : ℝ) : Matrix Slice Slice ℝ :=
  Matrix.of fun s t =>
    Real.exp (β / 2 * plaqSum s) * (∏ l : Fin 8, Real.exp (β * spin (s l) * spin (t l))) *
      Real.exp (β / 2 * plaqSum t)

/-- One link's factor of `W`: `e^β` on the diagonal and `e^(−β)` off it. -/
noncomputable def linkMatrix (β : ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![Real.exp β, Real.exp (-β); Real.exp (-β), Real.exp β]


lemma spin_mul_self (a : Bool) : spin a * spin a = 1 := by cases a <;> norm_num [spin]

lemma exp_spin_mul (β : ℝ) (a b : Bool) :
    Real.exp (β * spin a * spin b) = Real.cosh β + Real.sinh β * (spin a * spin b) := by
  cases a <;> cases b <;> simp [spin, Real.cosh_eq, Real.sinh_eq] <;> ring

lemma quad_expand (c d : ℝ) (y : Slice → ℝ) :
    ∑ s, ∑ t, y s * y t * ∏ l, (c + d * (spin (s l) * spin (t l))) =
      ∑ A ∈ (Finset.univ : Finset (Fin 8)).powerset,
        ((∏ _l ∈ A, d) * ∏ _l ∈ Finset.univ \ A, c) * (∑ s, y s * ∏ l ∈ A, spin (s l)) ^ 2 := by
  have key : ∀ s t : Slice, ∏ l, (c + d * (spin (s l) * spin (t l))) =
      ∑ A ∈ (Finset.univ : Finset (Fin 8)).powerset,
        ((∏ _l ∈ A, d) * ∏ _l ∈ Finset.univ \ A, c) *
          ((∏ l ∈ A, spin (s l)) * ∏ l ∈ A, spin (t l)) := by
    intro s t
    rw [show (fun l => c + d * (spin (s l) * spin (t l))) =
      fun l => d * (spin (s l) * spin (t l)) + c from by ext; ring]
    rw [Finset.prod_add]
    refine Finset.sum_congr rfl fun A _ => ?_
    rw [Finset.prod_mul_distrib, Finset.prod_mul_distrib]; ring
  simp_rw [key, Finset.mul_sum, sq, Finset.sum_mul_sum, Finset.mul_sum]
  rw [Finset.sum_congr rfl fun s _ => Finset.sum_comm, Finset.sum_comm]
  refine Finset.sum_congr rfl fun A _ => Finset.sum_congr rfl fun s _ =>
    Finset.sum_congr rfl fun t _ => by ring

lemma prod_one_add_spin (s t : Slice) :
    ∏ l, ((1 : ℝ) + spin (s l) * spin (t l)) = if s = t then 256 else 0 := by
  split_ifs with h
  · subst h; simp [spin_mul_self]; norm_num
  · obtain ⟨l, hl⟩ : ∃ l, s l ≠ t l := by
      by_contra h'; push Not at h'; exact h (funext h')
    apply Finset.prod_eq_zero (Finset.mem_univ l)
    cases hs : s l <;> cases ht : t l <;> simp_all [spin]

/-- Reflection positivity on the lattice: for every coupling β > 0 the toy's transfer matrix
T is positive definite (symmetric, with every eigenvalue positive), so each level's energy
`a E_k = ln(λ₀ / λ_k)` is a real number. -/
theorem transfer_matrix_pos_def {β : ℝ} (hβ : 0 < β) : (transfer β).PosDef := by
  refine Matrix.PosDef.of_dotProduct_mulVec_pos ?_ ?_
  · refine Matrix.IsHermitian.ext fun s t => ?_
    simp only [transfer, Matrix.of_apply, star_trivial]
    rw [show (∏ l, Real.exp (β * spin (t l) * spin (s l))) =
      ∏ l, Real.exp (β * spin (s l) * spin (t l)) from
        Finset.prod_congr rfl fun l _ => by ring_nf]
    ring
  · intro x hx
    set y : Slice → ℝ := fun s => Real.exp (β / 2 * plaqSum s) * x s with hy
    have hQ : star x ⬝ᵥ (transfer β *ᵥ x) = ∑ s, ∑ t, y s * y t *
        ∏ l, (Real.cosh β + Real.sinh β * (spin (s l) * spin (t l))) := by
      simp only [star_trivial, dotProduct, mulVec, transfer, Matrix.of_apply, y, exp_spin_mul,
        Finset.mul_sum]
      exact Finset.sum_congr rfl fun s _ => Finset.sum_congr rfl fun t _ => by ring
    rw [hQ, quad_expand]
    have h1 := quad_expand 1 1 y
    simp only [one_mul, Finset.prod_const_one, prod_one_add_spin] at h1
    have hy0 : y ≠ 0 := by
      intro h0; apply hx; funext s
      have := congrFun h0 s
      simp only [y, Pi.zero_apply, mul_eq_zero] at this
      rcases this with h | h
      · exact absurd h (Real.exp_pos _).ne'
      · exact h
    obtain ⟨s0, hs0⟩ : ∃ s, y s ≠ 0 := by
      by_contra h'; push Not at h'; exact hy0 (funext h')
    have hpos : (0 : ℝ) < ∑ s, y s * y s * 256 := by
      apply Finset.sum_pos' (fun s _ => by nlinarith [mul_self_nonneg (y s)])
      exact ⟨s0, Finset.mem_univ _, by have := mul_self_pos.mpr hs0; linarith⟩
    have hpos2 : (0 : ℝ) <
        ∑ A ∈ (Finset.univ : Finset (Fin 8)).powerset, (∑ s, y s * ∏ l ∈ A, spin (s l)) ^ 2 := by
      rw [← h1]
      simp only [mul_ite, mul_zero, Finset.sum_ite_eq, Finset.mem_univ, ite_true]
      exact hpos
    obtain ⟨A, hA, hApos⟩ := Finset.exists_lt_of_sum_lt (f := fun _ => (0 : ℝ))
      (g := fun A => (∑ s, y s * ∏ l ∈ A, spin (s l)) ^ 2)
      (by rw [Finset.sum_const_zero]; exact hpos2)
    have hc := Real.cosh_pos β
    have hs := Real.sinh_pos_iff.mpr hβ
    apply Finset.sum_pos' (fun B _ => by positivity)
    exact ⟨A, hA, mul_pos (by positivity) hApos⟩

/-- Each link's factor of `W` has eigenvector (1, 1) with eigenvalue `2 cosh β` and eigenvector
(1, −1) with eigenvalue `2 sinh β`, and both eigenvalues are positive when β > 0. -/
theorem link_matrix_eigenvalues {β : ℝ} (hβ : 0 < β) :
    linkMatrix β *ᵥ ![1, 1] = (2 * Real.cosh β) • ![1, 1] ∧
    linkMatrix β *ᵥ ![1, -1] = (2 * Real.sinh β) • ![1, -1] ∧
    0 < 2 * Real.cosh β ∧ 0 < 2 * Real.sinh β := by
  refine ⟨?_, ?_, by positivity, by linarith [Real.sinh_pos_iff.mpr hβ]⟩
  · ext i; fin_cases i <;>
      simp [linkMatrix, mulVec, dotProduct, Fin.sum_univ_two, Real.cosh_eq] <;> ring
  · ext i; fin_cases i <;>
      simp [linkMatrix, mulVec, dotProduct, Fin.sum_univ_two, Real.sinh_eq] <;> ring

/-- The strong-coupling rewrite: because a plaquette `U` is +1 or −1, its weight
`e^(β U)` equals `cosh β · (1 + u U)` with `u = tanh β`. -/
theorem plaquette_weight_strong_coupling (β U : ℝ) (hU : U = 1 ∨ U = -1) :
    Real.exp (β * U) = Real.cosh β * (1 + Real.tanh β * U) := by
  have hc := Real.cosh_pos β
  rw [Real.tanh_eq_sinh_div_cosh]
  rcases hU with rfl | rfl
  · field_simp; exact (Real.cosh_add_sinh β).symm
  · field_simp; rw [← sub_eq_add_neg, Real.cosh_sub_sinh]

/-- The links touching site `(x, y)`: both x-links of row `y` and both y-links of column `x`. -/
def siteLinks (x y : Fin 2) : Finset (Fin 8) :=
  {lid x y 0, lid (x + 1) y 0, lid x y 1, lid x (y + 1) 1}

/-- The links flipped by one setting `g` of a layer of timelike links (a gauge change): a link
flips when an odd number of the sites it touches have `g` set. -/
def gaugePattern (g : Fin 2 → Fin 2 → Bool) : Slice := fun l =>
  decide ((Finset.univ.filter fun p : Fin 2 × Fin 2 => g p.1 p.2 ∧ l ∈ siteLinks p.1 p.2).card
    % 2 = 1)

-- One slice has 2^8 = 256 link configurations.
example : Fintype.card Slice = 256 := by simp
-- A layer's 16 settings give only 8 distinct gauge changes, each twice.
example : (Finset.univ.image gaugePattern).card = 8 := by decide +kernel
example : (16 : ℕ) = 2 * 8 := by norm_num
-- Grouping the 256 configurations by gauge changes leaves 32 gauge-invariant states.
example : (Finset.univ.image fun s : Slice =>
    Finset.univ.image fun g => fun l => xor (s l) (gaugePattern g l)).card = 32 := by
  decide +kernel
-- With every link +1, all four plaquettes are +1, so P = 4.
example : plaqSum (fun _ => false) = 4 := by
  norm_num [plaqSum, plaq, spin, Fin.sum_univ_two]

#print axioms spin_mul_self
#print axioms exp_spin_mul
#print axioms quad_expand
#print axioms prod_one_add_spin
#print axioms transfer_matrix_pos_def
#print axioms link_matrix_eigenvalues
#print axioms plaquette_weight_strong_coupling
