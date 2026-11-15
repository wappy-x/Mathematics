-- States: every state on a unital C-star algebra builds, by the GNS construction, a Hilbert space with a representation by left multiplication and a unit vector Ω that gives back every expectation as ⟨Ω, π(A)Ω⟩.
import Mathlib.Analysis.CStarAlgebra.Classes
import Mathlib.Analysis.CStarAlgebra.GelfandNaimarkSegal
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Algebra.Star.StarAlgHom
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open scoped ComplexOrder InnerProductSpace Kronecker
open Matrix

universe u

/-- Helper: a functional that is never negative on squares is never negative on any
nonnegative member, for any star order on the algebra. -/
theorem gns_helper_nonneg {A : Type u} [CStarAlgebra A] [PartialOrder A] [StarOrderedRing A]
    (ω : A →ₗ[ℂ] ℂ) (hpos : ∀ a : A, 0 ≤ ω (star a * a)) (x : A) (hx : 0 ≤ x) : 0 ≤ ω x := by
  rw [StarOrderedRing.nonneg_iff] at hx
  induction hx using AddSubmonoid.closure_induction with
  | mem y hy => obtain ⟨s, rfl⟩ := hy; exact hpos s
  | zero => simp
  | add y z _ _ hy hz => rw [map_add]; exact add_nonneg hy hz

#print axioms gns_helper_nonneg

/-- **The GNS construction.** Let `A` be a C-star algebra with identity, and let `ω` be a state
on it: linear, never negative on squares (`0 ≤ ω(A*A)`), and worth 1 on the identity. Then there
is a Hilbert space `H`, a map `B ↦ [B]` from the algebra into `H` whose vectors are dense, and a
representation `π` (a map into bounded operators on `H` that keeps sums, products, scalars, stars
and the identity) such that the overlap of two members is the state, `⟨[B], [C]⟩ = ω(B*C)`;
each member acts by multiplying on the left, `π(A)[B] = [AB]`; and the identity's vector
`Ω = [1]` is a unit vector giving back every expectation, `ω(A) = ⟨Ω, π(A)Ω⟩`. -/
theorem gns_construction {A : Type u} [CStarAlgebra A]
    (ω : A →ₗ[ℂ] ℂ) (hpos : ∀ a : A, 0 ≤ ω (star a * a)) (hone : ω 1 = 1) :
    ∃ (H : Type u) (_ : NormedAddCommGroup H) (_ : InnerProductSpace ℂ H) (_ : CompleteSpace H)
      (π : A →⋆ₐ[ℂ] (H →L[ℂ] H)) (vec : A →ₗ[ℂ] H),
      DenseRange vec ∧
      (∀ b c : A, ⟪vec b, vec c⟫_ℂ = ω (star b * c)) ∧
      (∀ a b : A, π a (vec b) = vec (a * b)) ∧
      ‖vec 1‖ = 1 ∧
      ∀ a : A, ω a = ⟪vec 1, π a (vec 1)⟫_ℂ := by
  let _ : PartialOrder A := CStarAlgebra.spectralOrder A
  have : StarOrderedRing A := CStarAlgebra.spectralOrderedRing A
  let f : A →ₚ[ℂ] ℂ := PositiveLinearMap.mk₀ ω (gns_helper_nonneg ω hpos)
  have hf : ∀ x, f x = ω x := fun _ => rfl
  let vec : A →ₗ[ℂ] f.GNS :=
    ((UniformSpace.Completion.toComplL : f.PreGNS →L[ℂ] f.GNS) : f.PreGNS →ₗ[ℂ] f.GNS) ∘ₗ
      f.toPreGNS.toLinearMap
  have hvec : ∀ b, vec b = ((f.toPreGNS b : f.PreGNS) : f.GNS) := fun _ => rfl
  have hinner : ∀ b c : A, ⟪vec b, vec c⟫_ℂ = ω (star b * c) := by
    intro b c
    rw [hvec, hvec, UniformSpace.Completion.inner_coe, PositiveLinearMap.preGNS_inner_def]
    rfl
  have hpi : ∀ a b : A, f.gnsStarAlgHom a (vec b) = vec (a * b) := by
    intro a b
    rw [hvec, hvec]
    simp [PositiveLinearMap.gnsStarAlgHom_apply]
  refine ⟨f.GNS, inferInstance, inferInstance, inferInstance, f.gnsStarAlgHom, vec, ?_, hinner,
    hpi, ?_, ?_⟩
  · exact UniformSpace.Completion.denseRange_coe.comp f.toPreGNS.surjective.denseRange
      (UniformSpace.Completion.continuous_coe _)
  · have h1 : ‖vec 1‖ ^ 2 = 1 := by
      rw [@norm_sq_eq_re_inner ℂ, hinner, star_one, one_mul, hone, RCLike.one_re]
    nlinarith [norm_nonneg (vec 1)]
  · intro a
    rw [hpi, mul_one, hinner, star_one, one_mul]

/-- **What positivity gives for free.** For a rule `ω` on a C-star algebra with identity that is
linear and never negative on squares: stars become conjugates, `ω(A*) = conj ω(A)`; the
Cauchy-Schwarz inequality `|ω(B*C)|² ≤ ω(B*B) ω(C*C)` holds; and a member of length 0 stays of
length 0 after multiplying on the left, because `ω((AB)*(AB)) ≤ ‖A‖² ω(B*B)`. -/
theorem positive_functional_conj_cauchy_schwarz_left_ideal {A : Type u} [CStarAlgebra A]
    (ω : A →ₗ[ℂ] ℂ) (hpos : ∀ a : A, 0 ≤ ω (star a * a)) :
    (∀ a : A, ω (star a) = star (ω a)) ∧
    (∀ b c : A, ((‖ω (star b * c)‖ ^ 2 : ℝ) : ℂ) ≤ ω (star b * b) * ω (star c * c)) ∧
    (∀ a b : A, ω (star (a * b) * (a * b)) ≤ ((‖a‖ ^ 2 : ℝ) : ℂ) * ω (star b * b)) := by
  let _ : PartialOrder A := CStarAlgebra.spectralOrder A
  have : StarOrderedRing A := CStarAlgebra.spectralOrderedRing A
  let f : A →ₚ[ℂ] ℂ := PositiveLinearMap.mk₀ ω (gns_helper_nonneg ω hpos)
  have hf : ∀ x, f x = ω x := fun _ => rfl
  refine ⟨fun a => ?_, fun b c => ?_, fun a b => ?_⟩
  · rw [← hf, ← hf, map_star]
  · have h := PositiveLinearMap.norm_map_star_mul_sq_le f b c
    simp only [hf] at h
    rw [Complex.eq_coe_norm_of_nonneg (hpos b), Complex.eq_coe_norm_of_nonneg (hpos c),
      ← Complex.ofReal_mul, Complex.real_le_real]
    exact h
  · have hle : star (a * b) * (a * b) ≤ (‖a‖ ^ 2 : ℝ) • (star b * b) := by
      have := CStarAlgebra.star_left_conjugate_le_norm_smul b (star a * a)
      rw [CStarRing.norm_star_mul_self, ← sq] at this
      simpa [star_mul, mul_assoc] using this
    have := OrderHomClass.mono f hle
    rw [← Complex.coe_smul, map_smul, smul_eq_mul] at this
    exact this

/-- **No vector in ℂ² gives a coin that can land either way.** For a coin with chance of heads
`p` strictly between 0 and 1 (the fair coin is `p = 1/2`), the state
`ω(A) = p a₁₁ + (1 − p) a₂₂` on 2 × 2 complex matrices is not a vector state: no vector `ψ` in
ℂ² has `ψ* A ψ = ω(A)` for every matrix `A`. So the GNS construction needs a bigger space. -/
theorem coin_state_not_vector_state (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) :
    ¬ ∃ ψ : Fin 2 → ℂ, ∀ M : Matrix (Fin 2) (Fin 2) ℂ,
      star ψ ⬝ᵥ (M *ᵥ ψ) = (p : ℂ) * M 0 0 + (1 - (p : ℂ)) * M 1 1 := by
  rintro ⟨ψ, hψ⟩
  have h01 := hψ !![0, 1; 0, 0]
  have h00 := hψ !![1, 0; 0, 0]
  have h11 := hψ !![0, 0; 0, 1]
  simp [dotProduct, Matrix.mulVec, Fin.sum_univ_two] at h01 h00 h11
  rcases h01 with h | h
  · rw [h] at h00
    simp at h00
    exact absurd h00.symm (by exact_mod_cast hp0.ne')
  · rw [h] at h11
    simp at h11
    have : (1 : ℂ) - p ≠ 0 := by
      rw [sub_ne_zero]; exact_mod_cast hp1.ne'
    exact this h11.symm

/-! ### The card's worked numbers, exactly -/

/-- The coin state with chance of heads `p`, on 2 × 2 matrices: `p a₁₁ + (1 − p) a₂₂`. -/
abbrev coin {R : Type*} [Ring R] (p : R) (M : Matrix (Fin 2) (Fin 2) R) : R :=
  p * M 0 0 + (1 - p) * M 1 1

-- The bet X = [[10, 0], [0, −6]] on the fair coin: expected payout £2, mean square 68,
-- standard deviation 8, since 68 − 2² = 8².
example : coin (1/2 : ℚ) !![10, 0; 0, -6] = 2 ∧
    coin (1/2 : ℚ) ((!![10, 0; 0, -6])ᵀ * !![10, 0; 0, -6]) = 68 ∧ (68 : ℚ) - 2 ^ 2 = 8 ^ 2 := by
  refine ⟨?_, ?_, ?_⟩ <;> norm_num [coin, Matrix.mul_apply, Fin.sum_univ_two]

-- The fair coin on the identity and on the swap S: ω(1) = 1, ω(S) = 0.
example : coin (1/2 : ℚ) 1 = 1 ∧ coin (1/2 : ℚ) !![0, 1; 1, 0] = 0 := by
  constructor <;> norm_num [coin]

-- Test matrices Y = [[1, 2], [i, 3]], Z = [[0, i], [2, −1]] on the fair coin:
-- ω(Y*Y) = 15/2, ω(Z*Z) = 3, ω(Y*Z) = −3/2, and |−3/2|² = 9/4 ≤ 15/2 × 3 = 45/2.
example : coin (1/2 : ℂ) ((!![1, 2; Complex.I, 3])ᴴ * !![1, 2; Complex.I, 3]) = 15/2 ∧
    coin (1/2 : ℂ) ((!![0, Complex.I; 2, -1])ᴴ * !![0, Complex.I; 2, -1]) = 3 ∧
    coin (1/2 : ℂ) ((!![1, 2; Complex.I, 3])ᴴ * !![0, Complex.I; 2, -1]) = -3/2 ∧
    ((-3/2 : ℚ)) ^ 2 ≤ 15/2 * 3 := by
  refine ⟨?_, ?_, ?_, by norm_num⟩ <;>
    simp [coin, Matrix.mul_apply, Fin.sum_univ_two, Matrix.conjTranspose_apply] <;>
    apply Complex.ext <;> simp <;> norm_num

-- What breaks: the rule 1.5 a₁₁ − 0.5 a₂₂ is worth 1 on the identity but gives E₂₂*E₂₂ = E₂₂
-- the squared length −1/2.
example : (3/2 : ℚ) * (1 : Matrix (Fin 2) (Fin 2) ℚ) 0 0 - 1/2 * (1 : Matrix (Fin 2) (Fin 2) ℚ) 1 1 = 1 ∧
    (3/2 : ℚ) * ((!![0, 0; 0, 1])ᵀ * !![0, 0; 0, 1] : Matrix (Fin 2) (Fin 2) ℚ) 0 0
      - 1/2 * ((!![0, 0; 0, 1])ᵀ * !![0, 0; 0, 1] : Matrix (Fin 2) (Fin 2) ℚ) 1 1 = -1/2 := by
  constructor <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> norm_num

-- The two-headed coin, p = 1: E₁₂ has length 0, but multiplying on the right by E₂₁ gives
-- E₁₂E₂₁ = E₁₁, of squared length 1.
example : coin (1 : ℚ) ((!![0, 1; 0, 0])ᵀ * !![0, 1; 0, 0]) = 0 ∧
    coin (1 : ℚ) ((!![0, 1; 0, 0] * !![0, 0; 1, 0])ᵀ * (!![0, 1; 0, 0] * !![0, 0; 1, 0])) = 1 := by
  constructor <;> simp [coin, Matrix.mul_apply, Fin.sum_univ_two]

-- One vector in ℚ² for the fair coin fails: e₁* E₁₁ e₁ = 1, but ω(E₁₁) = 1/2.
example : (![1, 0] : Fin 2 → ℚ) ⬝ᵥ (!![1, 0; 0, 0] *ᵥ ![1, 0]) = 1 ∧
    coin (1/2 : ℚ) !![1, 0; 0, 0] = 1/2 := by
  constructor <;> simp [coin, dotProduct, Matrix.mulVec, Fin.sum_univ_two]

-- The Bell pair: with v = e₁₁ + e₂₂ = √2 Ω and π(A) = A ⊗ 1, the expectation
-- ⟨Ω, π(X)Ω⟩ = ½ v·(X ⊗ 1)v is the £2, and the swap gives ½ v·(S ⊗ 1)v = 0.
example : (1/2 : ℚ) * ((fun ij : Fin 2 × Fin 2 => if ij.1 = ij.2 then (1 : ℚ) else 0) ⬝ᵥ
      ((!![10, 0; 0, -6] ⊗ₖ (1 : Matrix (Fin 2) (Fin 2) ℚ)) *ᵥ
        (fun ij : Fin 2 × Fin 2 => if ij.1 = ij.2 then (1 : ℚ) else 0))) = 2 ∧
    (1/2 : ℚ) * ((fun ij : Fin 2 × Fin 2 => if ij.1 = ij.2 then (1 : ℚ) else 0) ⬝ᵥ
      ((!![0, 1; 1, 0] ⊗ₖ (1 : Matrix (Fin 2) (Fin 2) ℚ)) *ᵥ
        (fun ij : Fin 2 × Fin 2 => if ij.1 = ij.2 then (1 : ℚ) else 0))) = 0 := by
  constructor <;>
    simp [dotProduct, Matrix.mulVec, Fintype.sum_prod_type, Fin.sum_univ_two,
      Matrix.kroneckerMap_apply, Matrix.one_apply] <;> norm_num

-- The one-third event: among the 2^N patterns of N flips, those below 1/3 number
-- (2^N + 2)/3, for N = 2, 4 and 8.
example : 3 * ((List.range (2 ^ 2)).countP (fun m => 3 * m < 2 ^ 2)) = 2 ^ 2 + 2 ∧
    3 * ((List.range (2 ^ 4)).countP (fun m => 3 * m < 2 ^ 4)) = 2 ^ 4 + 2 ∧
    3 * ((List.range (2 ^ 8)).countP (fun m => 3 * m < 2 ^ 8)) = 2 ^ 8 + 2 := by
  decide +kernel

#print axioms gns_construction
#print axioms positive_functional_conj_cauchy_schwarz_left_ideal
#print axioms coin_state_not_vector_state
