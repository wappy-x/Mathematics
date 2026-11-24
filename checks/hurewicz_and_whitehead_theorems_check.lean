-- Hurewicz and Whitehead: on the figure eight the Hurewicz map, sending a loop word to its exponent sums, is onto with kernel the commutator subgroup, so H_1 = Z^2 is the abelianised fundamental group; it forgets the order of ab and ba; and the dunce hat's fundamental group is trivial.
import Mathlib.GroupTheory.FreeGroup.Reduce
import Mathlib.GroupTheory.PresentedGroup
import Mathlib.GroupTheory.Commutator.Basic
import Mathlib.Algebra.Group.Pi.Lemmas
import Mathlib.GroupTheory.Abelianization.Defs
import Mathlib.Tactic.FinCases

open FreeGroup

/-- The Hurewicz map `h : π₁ → H₁` of the figure eight `S¹ ∨ S¹`. Its fundamental group is the
free group on the two loops `a = of 0` and `b = of 1`, its first homology is `ℤ²`, and `h` sends
a loop word to its exponent sums: the number of `a` minus the number of `A = a⁻¹`, and the same
for `b`. The group `ℤ²` is written multiplicatively, so its zero is `1`. -/
def exponentSum : FreeGroup (Fin 2) →* Multiplicative (Fin 2 → ℤ) :=
  FreeGroup.lift fun i => Multiplicative.ofAdd (Pi.single i 1)

/-- A homomorphism back from `ℤ²` to the abelianised free group on two letters. -/
def expSumInv : Multiplicative (Fin 2 → ℤ) →* Abelianization (FreeGroup (Fin 2)) where
  toFun x := Abelianization.of (of 0) ^ (Multiplicative.toAdd x 0) *
    Abelianization.of (of 1) ^ (Multiplicative.toAdd x 1)
  map_one' := by simp
  map_mul' x y := by
    simp only [toAdd_mul, Pi.add_apply, zpow_add]
    exact mul_mul_mul_comm _ _ _ _

/-- Going to `ℤ²` and back is the abelianisation map. -/
theorem expSumInv_comp : expSumInv.comp exponentSum = Abelianization.of := by
  apply FreeGroup.ext_hom
  intro i
  fin_cases i <;> simp [expSumInv, exponentSum]

/-- **Hurewicz for n = 1, on the figure eight.** The Hurewicz map from loops to first homology
is onto, and the loops it sends to zero are exactly the commutator subgroup `[π₁, π₁]`, the
subgroup built from commutators `α β α⁻¹ β⁻¹`. So `H₁ = ℤ²` is `π₁` with every pair of loops
allowed to commute: `H₁ ≅ π₁ᵃᵇ`. -/
theorem figure_eight_h1_is_abelianised_pi1 :
    Function.Surjective exponentSum ∧ exponentSum.ker = commutator (FreeGroup (Fin 2)) := by
  constructor
  · intro x
    refine ⟨of 0 ^ (Multiplicative.toAdd x 0) * of 1 ^ (Multiplicative.toAdd x 1), ?_⟩
    apply Multiplicative.toAdd.injective
    funext i
    fin_cases i <;> simp [exponentSum]
  · apply le_antisymm
    · intro g hg
      rw [← Abelianization.ker_of, MonoidHom.mem_ker, ← expSumInv_comp, MonoidHom.comp_apply,
        MonoidHom.mem_ker.mp hg, _root_.map_one]
    · exact Abelianization.commutator_le_ker exponentSum

/-- **Homology forgets order.** On the figure eight, `ab` and `ba` are different loops, but the
Hurewicz map sends both to the same class `(1, 1)`: once round each circle. -/
theorem ab_ne_ba_same_homology_class :
    of (0 : Fin 2) * of 1 ≠ of 1 * of 0 ∧
    exponentSum (of 0 * of 1) = Multiplicative.ofAdd (fun _ => (1 : ℤ)) ∧
    exponentSum (of 1 * of 0) = Multiplicative.ofAdd (fun _ => (1 : ℤ)) := by
  refine ⟨by decide, ?_, ?_⟩ <;>
  · apply Multiplicative.toAdd.injective
    funext i
    fin_cases i <;> simp [exponentSum]

/-- **The dunce hat's loops all shrink.** The dunce hat has one point, one edge `a` and one
2-cell with rim word `a a a⁻¹`, so its fundamental group is `⟨a | a a a⁻¹⟩`. That word reduces
to `a`, the relation says `a = 1`, and every element of the group is trivial. -/
theorem dunce_hat_pi1_trivial :
    ∀ g : PresentedGroup ({of () * of () * (of ())⁻¹} : Set (FreeGroup Unit)), g = 1 := by
  intro g
  have hof : (PresentedGroup.of () : PresentedGroup
      ({of () * of () * (of ())⁻¹} : Set (FreeGroup Unit))) = 1 := by
    have h := PresentedGroup.mk_eq_mk_of_mul_inv_mem
      (rels := ({of () * of () * (of ())⁻¹} : Set (FreeGroup Unit)))
      (x := of () * of ()) (y := of ()) rfl
    rw [_root_.map_mul] at h
    exact mul_eq_right.mp h
  have := PresentedGroup.generated_by _ ⊥ (fun _ => by rw [hof]; exact one_mem _) g
  exact (Subgroup.mem_bot).mp this

/-- The four letters `a, A, b, B` as Mathlib's free-group letters: `(i, true)` is a generator,
`(i, false)` its inverse. -/
def letters : List (Fin 2 × Bool) := [(0, true), (0, false), (1, true), (1, false)]

/-- All reduced words of length `k`: no letter stands next to its own inverse. -/
def reducedWords (k : ℕ) : List (List (Fin 2 × Bool)) :=
  (List.replicate k letters).sections.filter fun L => FreeGroup.reduce L = L

-- There are 4, 12, 36 and 108 reduced words of length 1, 2, 3 and 4.
example : (List.range 4).map (fun k => (reducedWords (k + 1)).length) = [4, 12, 36, 108] := by
  decide

-- Of the 108 reduced words of length 4, exactly 8 have both exponent sums zero.
example : ((reducedWords 4).filter fun L => exponentSum (FreeGroup.mk L) = 1).length = 8 := by
  decide

#print axioms expSumInv
#print axioms expSumInv_comp
#print axioms figure_eight_h1_is_abelianised_pi1
#print axioms ab_ne_ba_same_homology_class
#print axioms dunce_hat_pi1_trivial
