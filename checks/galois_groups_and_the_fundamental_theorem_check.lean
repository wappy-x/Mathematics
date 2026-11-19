-- The Galois correspondence: in a finite, normal, separable extension, fixed fields and fixing subgroups undo each other, reverse inclusion, and a subgroup's fixed field has degree equal to its index.
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.NumberTheory.Zsqrtd.GaussianInt

open IntermediateField

variable {K L : Type*} [Field K] [Field L] [Algebra K L]

/-- The fundamental theorem of Galois theory. Let `L/K` be finite, normal and separable (a Galois
extension) with group `G = Gal(L/K)`. Then the subgroup fixing the fixed field of `H` is `H`
again; the fixed field of the subgroup fixing a middle field `E` is `E` again; a larger subgroup
fixes a smaller field; and the fixed field `L^H` has degree `[L^H : K] = [G : H]` over `K`. -/
theorem galois_correspondence [FiniteDimensional K L] [Normal K L] [Algebra.IsSeparable K L] :
    (∀ H : Subgroup Gal(L/K), fixingSubgroup (fixedField H) = H) ∧
    (∀ E : IntermediateField K L, fixedField (fixingSubgroup E) = E) ∧
    (∀ H₁ H₂ : Subgroup Gal(L/K), H₁ ≤ H₂ ↔ fixedField H₂ ≤ fixedField H₁) ∧
    (∀ H : Subgroup Gal(L/K), Module.finrank K (fixedField H) = H.index) := by
  have : IsGalois K L := isGalois_iff.mpr ⟨inferInstance, inferInstance⟩
  refine ⟨fun H => fixingSubgroup_fixedField H, fun E => IsGalois.fixedField_fixingSubgroup E,
    fun H₁ H₂ => ?_, fun H => ?_⟩
  · constructor
    · exact fun h => fixedField_le h
    · intro h
      rw [← fixingSubgroup_fixedField H₁, ← fixingSubgroup_fixedField H₂]
      exact fixingSubgroup_le h
  · rw [IntermediateField.finrank_eq_fixingSubgroup_index, fixingSubgroup_fixedField]

/-- Artin's count (Step 2 of the card): for any subgroup `H` of the symmetries of a finite
extension `L/K`, the degree of `L` over the fixed field `L^H` is exactly `|H|`. -/
theorem finrank_over_fixedField_eq_card [FiniteDimensional K L] (H : Subgroup Gal(L/K)) :
    Module.finrank (fixedField H) L = Nat.card H := by
  exact finrank_fixedField_eq_card H

/-- Normal subgroups match normal fields (Step 4 of the card): in a finite, normal, separable
extension `L/K`, a subgroup `H` is normal exactly when its fixed field `L^H` is normal over `K`,
and then the symmetries of `L^H` over `K` form the quotient group `G/H`. -/
theorem normal_subgroup_iff_normal_fixedField [FiniteDimensional K L] [Normal K L]
    [Algebra.IsSeparable K L] (H : Subgroup Gal(L/K)) :
    (H.Normal ↔ Normal K (fixedField H)) ∧
    ∀ [H.Normal], Nonempty (Gal(L/K) ⧸ H ≃* Gal(fixedField H/K)) := by
  have : IsGalois K L := isGalois_iff.mpr ⟨inferInstance, inferInstance⟩
  refine ⟨⟨fun h => ?_, fun h => ?_⟩, fun {_} => ⟨IsGalois.normalAutEquivQuotient H⟩⟩
  · exact (IsGalois.of_fixedField_normal_subgroup H).to_normal
  · have : IsGalois K (fixedField H) :=
      isGalois_iff.mpr ⟨Algebra.isSeparable_tower_bot_of_isSeparable K (fixedField H) L, h⟩
    have := IsGalois.fixingSubgroup_normal_of_isGalois (fixedField H)
    rwa [fixingSubgroup_fixedField] at this

/-! Worked numbers for `x^4 - 2`. Its group is `D_4`, the square's 8 symmetries. In Mathlib's
`DihedralGroup 4`, `σ` (the quarter turn) is `r 1` and `τ` (complex conjugation) is `sr 0`. -/

open DihedralGroup

-- The group has 8 members, matching the degree 4 × 2 = 8.
example : Fintype.card (DihedralGroup 4) = 8 ∧ 4 * 2 = 8 := by decide

-- Order matters: τσ = σ³τ, not στ.
example : (sr 0 * r 1 : DihedralGroup 4) = r 3 * sr 0 ∧ (sr 0 * r 1 : DihedralGroup 4) ≠ r 1 * sr 0 := by
  decide

-- The symmetries fixing √2 = α²: σ sends α² to -α², while τ, σ², σ²τ fix it; with 1 they are
-- {1, τ, σ², σ²τ}, a subgroup of 4, whose fixed field has degree 8 / 4 = 2.
example : ({1, sr 0, r 2, r 2 * sr 0} : Finset (DihedralGroup 4)).card = 4 ∧ 8 / 4 = 2 := by
  decide

-- The size law on the card's table: subgroups of order 1, 2, 4, 8 fix fields of degree 8, 4, 2, 1.
example : [8 / 1, 8 / 2, 8 / 4, 8 / 8] = [8, 4, 2, 1] := by decide

-- ((1 + i)α)^4 = (1 + i)^4 · 2 = -4 · 2 = -8, so (1 + i)α is a root of x^4 + 8.
example : ((⟨1, 1⟩ : GaussianInt) ^ 4 = -4) ∧ (-4 : ℤ) * 2 = -8 := by decide

-- The subgroups of D_4, found by checking all 256 subsets: 10 of them, 6 normal.
example : ((Finset.univ : Finset (DihedralGroup 4)).powerset.filter
    (fun S => (1 : DihedralGroup 4) ∈ S ∧ ∀ a ∈ S, ∀ b ∈ S, a * b ∈ S)).card = 10 := by
  decide

example : ((Finset.univ : Finset (DihedralGroup 4)).powerset.filter
    (fun S => (1 : DihedralGroup 4) ∈ S ∧ (∀ a ∈ S, ∀ b ∈ S, a * b ∈ S) ∧
      ∀ g : DihedralGroup 4, ∀ h ∈ S, g * h * g⁻¹ ∈ S)).card = 6 := by
  decide

#print axioms galois_correspondence
#print axioms finrank_over_fixedField_eq_card
#print axioms normal_subgroup_iff_normal_fixedField
