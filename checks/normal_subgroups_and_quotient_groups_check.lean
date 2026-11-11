-- Normal subgroups and quotient groups: in any group, the piles (cosets) of a subgroup multiply by multiplying their names exactly when the subgroup is normal, collapsing a group by a map's kernel leaves a copy of the map's image, and the integers collapsed by the multiples of n are Z mod n.
import Mathlib.GroupTheory.QuotientGroup.Basic
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.Data.ZMod.QuotientGroup
import Mathlib.Algebra.Group.Pointwise.Set.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum

open Pointwise DihedralGroup

/-- A subgroup can be collapsed exactly when it looks the same from every position. For a
subgroup `N` of any group `G` (no finiteness needed): `N` is normal (Mathlib's `Subgroup.Normal`)
exactly when the card's test passes, `g N g⁻¹ = N` for every `g`; and that happens exactly when
piles combine by combining names, `(gN)(kN) = (gk)N`, with no answer depending on which member
named a pile: whenever `gN = g'N` and `kN = k'N`, also `(gk)N = (g'k')N`. -/
theorem collapse_works_iff_normal {G : Type*} [Group G] (N : Subgroup G) :
    (N.Normal ↔ ∀ g : G, (fun h => g * h * g⁻¹) '' (N : Set G) = (N : Set G)) ∧
    (N.Normal ↔ ∀ g g' k k' : G, g • (N : Set G) = g' • (N : Set G) →
      k • (N : Set G) = k' • (N : Set G) → (g * k) • (N : Set G) = (g' * k') • (N : Set G)) := by
  have hconj : N.Normal ↔ ∀ g : G, (fun h => g * h * g⁻¹) '' (N : Set G) = (N : Set G) := by
    constructor
    · intro hn g
      ext x
      constructor
      · rintro ⟨h, hh, rfl⟩
        exact hn.conj_mem h hh g
      · intro hx
        refine ⟨g⁻¹ * x * g, ?_, ?_⟩
        · simpa using hn.conj_mem x hx g⁻¹
        · simp [mul_assoc]
    · intro h
      refine ⟨fun n hn g => ?_⟩
      have h1 : g * n * g⁻¹ ∈ (fun h => g * h * g⁻¹) '' (N : Set G) := ⟨n, hn, rfl⟩
      rw [h g] at h1
      exact h1
  have hcos : N.Normal ↔ ∀ g g' k k' : G, g • (N : Set G) = g' • (N : Set G) →
      k • (N : Set G) = k' • (N : Set G) → (g * k) • (N : Set G) = (g' * k') • (N : Set G) := by
    constructor
    · intro hn g g' k k' h1 h2
      rw [leftCoset_eq_iff] at h1 h2 ⊢
      have h3 := hn.conj_mem _ h1 k⁻¹
      have h4 := N.mul_mem (by simpa [mul_assoc] using h3) h2
      simpa [mul_assoc] using h4
    · intro h
      refine ⟨fun n hn g => ?_⟩
      have e1 : g • (N : Set G) = (g * n) • (N : Set G) := by
        rw [leftCoset_eq_iff]; simpa using hn
      have := h g (g * n) g⁻¹ g⁻¹ e1 rfl
      rw [leftCoset_eq_iff] at this
      simpa [mul_assoc] using this
  exact ⟨hconj, hcos⟩

/-- The first isomorphism theorem: collapse a group by what a homomorphism `φ` forgets (its
kernel) and a copy of its image is left. The pile `g ker φ` is labelled by the value `φ g`,
and this labelling is an isomorphism from `G / ker φ` onto the image of `φ`. -/
theorem first_isomorphism_theorem {G H : Type*} [Group G] [Group H] (φ : G →* H) :
    ∃ e : G ⧸ φ.ker ≃* φ.range, ∀ g : G, (e (g : G ⧸ φ.ker) : H) = φ g := by
  refine ⟨QuotientGroup.quotientKerEquivRange φ, fun g => ?_⟩
  rfl

/-- Z mod n is the model: collapsing the integers by the subgroup of multiples of `n` gives
`ZMod n`, the pile of an integer `a` being sent to `a` read mod `n`, with addition kept. -/
theorem integers_mod_multiples_is_zmod (n : ℕ) :
    ∃ e : (ℤ ⧸ AddSubgroup.zmultiples (n : ℤ)) ≃+ ZMod n,
      ∀ a : ℤ, e (a : ℤ ⧸ AddSubgroup.zmultiples (n : ℤ)) = (a : ZMod n) := by
  exact ⟨Int.quotientZMultiplesNatEquivZMod n, fun a => rfl⟩

-- The clock: 15 and -9 land on the same mark, 3, and pile 7 plus pile 8 is pile 3.
example : (15 : ZMod 12) = 3 ∧ (-9 : ZMod 12) = 3 ∧ (15 : ZMod 12) = -9 := by decide
example : (7 : ZMod 12) + 8 = 3 := by decide
-- The integers from -24 to 35, sorted by remainder after 12, fall into 12 piles.
example : ((Finset.Icc (-24 : ℤ) 35).image (fun x => x % 12)).card = 12 := by decide +kernel

-- The square tile: 8 moves, `r i` the turns and `sr i` the flips.
example : Fintype.card (DihedralGroup 4) = 8 := by decide
-- All 32 conjugates of the 4 turns are turns: the turns are normal.
example : ∀ g : DihedralGroup 4, ∀ i : ZMod 4, ∃ j : ZMod 4, g * r i * g⁻¹ = r j := by decide
-- The flip subgroup {do nothing, sr 0}: the half turn leaves the flip alone, the quarter turn
-- carries it to a different flip, outside the subgroup.
example : r 2 * sr 0 * (r 2)⁻¹ = (sr 0 : DihedralGroup 4) := by decide
example : r 1 * sr 0 * (r 1)⁻¹ = (sr 2 : DihedralGroup 4) ∧
    (sr 2 : DihedralGroup 4) ≠ 1 ∧ (sr 2 : DihedralGroup 4) ≠ sr 0 := by decide
-- One pile, two names ("do nothing" and the flip), each times a quarter turn: two different piles.
example : ({r 1 * 1, r 1 * sr 0} : Finset (DihedralGroup 4)) = {r 1, sr 3} ∧
    ({sr 0 * r 1 * 1, sr 0 * r 1 * sr 0} : Finset (DihedralGroup 4)) = {r 3, sr 1} ∧
    ({r 1, sr 3} : Finset (DihedralGroup 4)) ≠ {r 3, sr 1} := by decide

-- The 24-hour clock to the 12-hour clock: 13:00 reads 1, the kernel is {0, 12}, 24 / 2 = 12.
example : (((13 : ZMod 24).val : ℕ) : ZMod 12) = 1 := by decide
example : Finset.univ.filter (fun x : ZMod 24 => ((x.val : ℕ) : ZMod 12) = 0) = {0, 12} := by
  decide
example : (24 : ℕ) / 2 = 12 := by norm_num

#print axioms collapse_works_iff_normal
#print axioms first_isomorphism_theorem
#print axioms integers_mod_multiples_is_zmod
