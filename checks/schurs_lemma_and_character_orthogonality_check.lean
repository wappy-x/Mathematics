-- Schur's lemma and orthogonality: a map that respects the moves between two irreducible complex representations of a finite group is zero or invertible (and a multiple of the identity from a piece to itself), so irreducible characters are orthonormal and the inner product of characters counts copies of each piece.
import Mathlib.RepresentationTheory.Character
import Mathlib.RepresentationTheory.Irreducible
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Algebra.DirectSum.Module
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.Data.Matrix.Mul
import Mathlib.Order.Interval.Finset.Defs
import Mathlib.Data.Int.Interval

open Representation DihedralGroup

namespace SchursLemmaAndCharacterOrthogonality

variable {G V W : Type*} [Group G] [Fintype G]
  [AddCommGroup V] [Module ℂ V] [FiniteDimensional ℂ V]
  [AddCommGroup W] [Module ℂ W] [FiniteDimensional ℂ W]

/-- The character of a direct sum is the sum of the characters. -/
lemma char_directSum {ι : Type*} [Fintype ι] [DecidableEq ι] {U : ι → Type*}
    [∀ i, AddCommGroup (U i)] [∀ i, Module ℂ (U i)] [∀ i, FiniteDimensional ℂ (U i)]
    (τ : ∀ i, Representation ℂ G (U i)) (g : G) :
    (Representation.directSum τ).character g = ∑ i, (τ i).character g := by
  have h : (Representation.directSum τ) g = ∑ i, (DirectSum.lof ℂ ι U i) ∘ₗ (τ i g) ∘ₗ
      (DirectSum.component ℂ ι U i) := by
    ext x j
    simp [DirectSum.component]
    rw [Finset.sum_eq_single x]
    · simp only [DirectSum.lof_eq_of]
      erw [DFinsupp.lapply_apply, DirectSum.of_eq_same]
    · intro b _ hb
      simp only [DirectSum.lof_eq_of]
      erw [DFinsupp.lapply_apply, DirectSum.of_eq_of_ne _ _ _ hb]
      simp
    · simp
  rw [character, h, map_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [LinearMap.trace_comp_comm', LinearMap.comp_assoc]
  have hc : DirectSum.component ℂ ι U i ∘ₗ DirectSum.lof ℂ ι U i = LinearMap.id := by
    ext y; simp
  rw [hc, LinearMap.comp_id]
  rfl

#print axioms char_directSum

/-- **Schur's lemma.** For a finite group acting by complex matrices on `V` and `W`, both
irreducible, a map `T` from `V` to `W` with `T ρ_V(g) = ρ_W(g) T` for every move `g` is zero or
invertible; and a map `S` from `V` to itself that respects the moves is a plain number `λ` times
the identity. -/
theorem schurs_lemma (ρ : Representation ℂ G V) (σ : Representation ℂ G W)
    [ρ.IsIrreducible] [σ.IsIrreducible]
    (T : V →ₗ[ℂ] W) (hT : ∀ g : G, T ∘ₗ ρ g = σ g ∘ₗ T) :
    (T = 0 ∨ Function.Bijective T) ∧
      ∀ S : V →ₗ[ℂ] V, (∀ g : G, S ∘ₗ ρ g = ρ g ∘ₗ S) →
        ∃ c : ℂ, S = c • LinearMap.id := by
  refine ⟨?_, fun S hS => ?_⟩
  · let f : IntertwiningMap ρ σ := ⟨T, hT⟩
    rcases IsIrreducible.bijective_or_eq_zero f with h | h
    · exact Or.inr h
    · left
      have := congrArg IntertwiningMap.toLinearMap h
      exact this
  · let f : IntertwiningMap ρ ρ := ⟨S, hS⟩
    obtain ⟨c, hc⟩ := (IsIrreducible.algebraMap_intertwiningMap_bijective_of_isAlgClosed
      (ρ := ρ)).2 f
    refine ⟨c, ?_⟩
    ext v
    have := congrArg (fun F : IntertwiningMap ρ ρ => F v) hc
    exact this.symm

open scoped Classical in
/-- **Orthogonality of characters.** For two irreducible complex representations of a finite
group, the average over all moves of `χ_V(g) χ_W(g⁻¹)` is 1 when they are the same piece (an
isomorphism respecting the moves joins them) and 0 when they are different pieces:
`⟨χ_i, χ_j⟩ = δ_ij`. -/
theorem character_orthogonality (ρ : Representation ℂ G V) (σ : Representation ℂ G W)
    [ρ.IsIrreducible] [σ.IsIrreducible] :
    (Fintype.card G : ℂ)⁻¹ * ∑ g : G, ρ.character g * σ.character g⁻¹ =
      if Nonempty (ρ.Equiv σ) then 1 else 0 := by
  have : Invertible (Nat.card G : ℂ) := invertibleOfNonzero (by simp)
  rw [Fintype.card_eq_nat_card, char_orthonormal]
  have : Nonempty (σ.Equiv ρ) ↔ Nonempty (ρ.Equiv σ) :=
    ⟨fun ⟨e⟩ => ⟨e.symm⟩, fun ⟨e⟩ => ⟨e.symm⟩⟩
  simp [this]

open scoped Classical in
/-- **Decomposition by inner products.** If a complex representation `V` of a finite group splits
(respecting the moves) as a direct sum of irreducible pieces `U i`, then for any irreducible
representation `W` the inner product `⟨χ_V, χ_W⟩` is the number of pieces `U i` that are copies
of `W`: `m_W = ⟨χ_V, χ_W⟩`. -/
theorem inner_product_counts_copies {ι : Type*} [Fintype ι] [DecidableEq ι] {U : ι → Type*}
    [∀ i, AddCommGroup (U i)] [∀ i, Module ℂ (U i)] [∀ i, FiniteDimensional ℂ (U i)]
    (τ : ∀ i, Representation ℂ G (U i)) [∀ i, (τ i).IsIrreducible]
    (ρ : Representation ℂ G V) (e : ρ.Equiv (Representation.directSum τ))
    (σ : Representation ℂ G W) [σ.IsIrreducible] :
    (Fintype.card G : ℂ)⁻¹ * ∑ g : G, ρ.character g * σ.character g⁻¹ =
      ((Finset.univ.filter fun i => Nonempty ((τ i).Equiv σ)).card : ℂ) := by
  rw [char_iso e]
  simp_rw [char_directSum, Finset.sum_mul]
  rw [Finset.sum_comm, Finset.mul_sum]
  simp_rw [character_orthogonality]
  rw [Finset.sum_boole]

/-! ### The card's worked numbers on the square tile

The tile group is `DihedralGroup 4`: `r k` is the turn by `k` quarter turns and `sr k` a flip.
The corners are numbered 0 to 3 round the tile, as `ZMod 4`. -/

/-- Where the move `g` sends corner `i`. -/
def cornerMove : DihedralGroup 4 → ZMod 4 → ZMod 4
  | r k, i => i + k
  | sr k, i => k - i

/-- The corner character: the trace of a corner shuffle, which counts the corners left in place. -/
def cornerChar (g : DihedralGroup 4) : ℤ :=
  ((Finset.univ.filter fun i : ZMod 4 => cornerMove g i = i).card : ℤ)

/-- The corner character on the five classes (identity, half turn, quarter turns, diagonal flips,
edge flips) is 4, 0, 0, 2, 0. -/
example : cornerChar (r 0) = 4 ∧ cornerChar (r 2) = 0 ∧ cornerChar (r 1) = 0 ∧
    cornerChar (r 3) = 0 ∧ cornerChar (sr 0) = 2 ∧ cornerChar (sr 2) = 2 ∧
    cornerChar (sr 1) = 0 ∧ cornerChar (sr 3) = 0 := by decide

/-- The floor plane's moves as 2 by 2 matrices: the quarter turn `[[0, -1], [1, 0]]` to the power
`k`, and that times the flip `[[1, 0], [0, -1]]`. -/
def floorMat : DihedralGroup 4 → Matrix (Fin 2) (Fin 2) ℤ
  | r k => !![0, -1; 1, 0] ^ k.val
  | sr k => !![0, -1; 1, 0] ^ k.val * !![1, 0; 0, -1]

/-- The floor character, the trace of each floor matrix. -/
def floorChar (g : DihedralGroup 4) : ℤ := (floorMat g).trace

/-- The inner product over the 8 moves is the sum of `χ(g) ψ(g⁻¹)`, divided by 8.
Corner against trivial: 8/8 = 1. -/
example : ∑ g : DihedralGroup 4, cornerChar g * 1 = 8 := by decide

/-- Corner against the floor character (2, -2, 0, 0, 0): 8/8 = 1. -/
example : ∑ g : DihedralGroup 4, cornerChar g * floorChar g⁻¹ = 8 := by decide

/-- Corner against itself: 24/8 = 3, the sum of squared counts 1 + 1 + 1. -/
example : ∑ g : DihedralGroup 4, cornerChar g * cornerChar g⁻¹ = 24 := by decide

/-- By classes with class sizes 1, 1, 2, 2, 2: against trivial, diagonal sign, floor, flip sign
and edge sign the corner character (4, 0, 0, 2, 0) gives 1, 1, 1, 0, 0. -/
example :
    ((1 * 4 * 1 + 1 * 0 * 1 + 2 * 0 * 1 + 2 * 2 * 1 + 2 * 0 * 1 : ℤ) : ℚ) / 8 = 1 ∧
    ((1 * 4 * 1 + 1 * 0 * 1 + 2 * 0 * (-1) + 2 * 2 * 1 + 2 * 0 * (-1) : ℤ) : ℚ) / 8 = 1 ∧
    ((1 * 4 * 2 + 1 * 0 * (-2) + 2 * 0 * 0 + 2 * 2 * 0 + 2 * 0 * 0 : ℤ) : ℚ) / 8 = 1 ∧
    ((1 * 4 * 1 + 1 * 0 * 1 + 2 * 0 * 1 + 2 * 2 * (-1) + 2 * 0 * (-1) : ℤ) : ℚ) / 8 = 0 ∧
    ((1 * 4 * 1 + 1 * 0 * 1 + 2 * 0 * (-1) + 2 * 2 * (-1) + 2 * 0 * 1 : ℤ) : ℚ) / 8 = 0 ∧
    ((1 * 4 * 4 + 1 * 0 * 0 + 2 * 0 * 0 + 2 * 2 * 2 + 2 * 0 * 0 : ℤ) : ℚ) / 8 = 3 := by
  norm_num

/-- Step 4 on the floor: averaging `[[3, 1], [4, 1]]` over the 8 moves gives `[[2, 0], [0, 2]]`,
trace 4 divided by dimension 2 times the identity (the sum is 8 times that). -/
example : ∑ g : DihedralGroup 4, floorMat g * !![3, 1; 4, 1] * floorMat g⁻¹ = !![16, 0; 0, 16] := by
  decide

/-- Step 2 on the floor: of the 625 matrices with entries from -2 to 2, exactly 5 commute with all
8 floor moves. -/
example : ((Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2 ×ˢ
    Finset.Icc (-2 : ℤ) 2).filter fun x : ℤ × ℤ × ℤ × ℤ =>
      ∀ g : DihedralGroup 4, !![x.1, x.2.1; x.2.2.1, x.2.2.2] * floorMat g =
        floorMat g * !![x.1, x.2.1; x.2.2.1, x.2.2.2]).card = 5 := by
  decide

#print axioms schurs_lemma
#print axioms character_orthogonality
#print axioms inner_product_counts_copies

end SchursLemmaAndCharacterOrthogonality
