-- Direct sums and quotient spaces: blurring a subspace U of a finite-dimensional space V leaves a quotient of dimension dim V - dim U, a linear map's domain blurred by its kernel is a copy of its image, and a sum with zero overlap splits every vector in exactly one way.
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Isomorphisms
import Mathlib.Data.ZMod.Basic

open Module

/-- Blurring a subspace to a point removes exactly its dimensions: for a subspace `U` of a
finite-dimensional vector space `V`, the quotient `V / U` has dimension `dim V - dim U`. -/
theorem finrank_quotient_eq_finrank_sub_finrank {K V : Type*} [Field K] [AddCommGroup V]
    [Module K V] [FiniteDimensional K V] (U : Submodule K V) :
    finrank K (V ⧸ U) = finrank K V - finrank K U := by
  have := Submodule.finrank_quotient_add_finrank U
  omega

/-- The first isomorphism theorem: for a linear map `T : V → W`, blurring away its kernel leaves
a copy of its image. The match sends the coset `x + ker T` to `T x`, and keeps adding and
scaling. -/
theorem quotient_ker_equiv_image {K V W : Type*} [Field K] [AddCommGroup V] [Module K V]
    [AddCommGroup W] [Module K W] (T : V →ₗ[K] W) :
    ∃ e : (V ⧸ LinearMap.ker T) ≃ₗ[K] LinearMap.range T,
      ∀ x : V, (e (Submodule.Quotient.mk x) : W) = T x := by
  exact ⟨T.quotKerEquivRange, fun x => by rw [LinearMap.quotKerEquivRange_apply_mk]⟩

/-- A direct sum is a unique split: `U + W = V` and `U ∩ W = {0}` exactly when every vector
breaks into one piece from `U` plus one piece from `W` in exactly one way. -/
theorem direct_sum_iff_unique_split {K V : Type*} [Field K] [AddCommGroup V] [Module K V]
    (U W : Submodule K V) :
    (U ⊔ W = ⊤ ∧ U ⊓ W = ⊥) ↔ ∀ v : V, ∃! p : U × W, (p.1 : V) + (p.2 : V) = v := by
  constructor
  · rintro ⟨hsup, hinf⟩ v
    have hv : v ∈ U ⊔ W := by rw [hsup]; exact Submodule.mem_top
    obtain ⟨y, hy, z, hz, hyz⟩ := Submodule.mem_sup.mp hv
    refine ⟨(⟨y, hy⟩, ⟨z, hz⟩), hyz, ?_⟩
    rintro ⟨⟨a, ha⟩, ⟨b, hb⟩⟩ hab
    simp only at hab
    have hU : a - y ∈ U := U.sub_mem ha hy
    have hW : a - y ∈ W := by
      have : a - y = z - b := by rw [← hyz] at hab; rw [sub_eq_sub_iff_add_eq_add, hab, add_comm]
      rw [this]; exact W.sub_mem hz hb
    have h0 : a - y ∈ U ⊓ W := ⟨hU, hW⟩
    rw [hinf, Submodule.mem_bot, sub_eq_zero] at h0
    subst h0
    have hb' : b = z := by
      have := hab.trans hyz.symm
      exact add_left_cancel this
    subst hb'
    rfl
  · intro h
    refine ⟨?_, ?_⟩
    · rw [eq_top_iff]
      intro v _
      obtain ⟨p, hp, _⟩ := h v
      rw [← hp]
      exact Submodule.add_mem_sup p.1.2 p.2.2
    · rw [eq_bot_iff]
      intro x hx
      obtain ⟨hxU, hxW⟩ := Submodule.mem_inf.mp hx
      obtain ⟨p, _, hu⟩ := h x
      have e1 := hu (⟨x, hxU⟩, 0) (by simp)
      have e2 := hu (0, ⟨x, hxW⟩) (by simp)
      have := e1.trans e2.symm
      have := congrArg (fun q : U × W => (q.1 : V)) this
      simpa using this

/-- The bill of a basket (loaves, milks, dozens of eggs) at the prices $3, $2, $4. -/
def bill (x : ℤ × ℤ × ℤ) : ℤ := 3 * x.1 + 2 * x.2.1 + 4 * x.2.2

-- (2, 3, 1) and (4, 0, 1) both cost $16; their difference (2, -3, 0) costs $0.
example : bill (2, 3, 1) = 16 ∧ bill (4, 0, 1) = 16 := by decide
example : (4, 0, 1) - (2, 3, 1) = ((2, -3, 0) : ℤ × ℤ × ℤ) ∧ bill (2, -3, 0) = 0 := by decide
-- The $0 plane is spanned by (2, -3, 0) and (0, 2, -1).
example : bill (0, 2, -1) = 0 := by decide
-- The split of (2, 3, 1): the $0 basket (2, -5, 1) plus 8 milks; (2, -5, 1) = 1 * (2, -3, 0) - 1 * (0, 2, -1).
example : ((2, -5, 1) : ℤ × ℤ × ℤ) + (0, 8, 0) = (2, 3, 1) ∧ bill (2, -5, 1) = 0 ∧
    ((2, -3, 0) : ℤ × ℤ × ℤ) - (0, 2, -1) = (2, -5, 1) := by decide
-- Cosets add: (2, 3, 1) + (4, 0, 1) = (6, 3, 2) costs $32, and 3 * (2, 3, 1) costs $48.
example : ((2, 3, 1) : ℤ × ℤ × ℤ) + (4, 0, 1) = (6, 3, 2) ∧ bill (6, 3, 2) = 32 ∧
    bill (6, 9, 3) = 48 := by decide
-- The no-eggs plane against U: 2 + 2 - 1 = 3; the quotient: 3 - 2 = 1.
example : 2 + 2 - 1 = 3 ∧ 3 - 2 = 1 := by decide
-- On the 7-hour clock: 343 baskets, 49 cost $0, and 343 / 49 = 7 cosets.
example : Fintype.card (ZMod 7 × ZMod 7 × ZMod 7) = 343 := by norm_num
set_option maxRecDepth 20000 in
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7 × ZMod 7)).filter
    (fun v => 3 * v.1 + 2 * v.2.1 + 4 * v.2.2 = 0)).card = 49 := by decide
example : 343 / 49 = 7 := by decide
-- A box of 0 to 4 of each item: 125 baskets, but only 35 different bills.
set_option maxRecDepth 20000 in
example : ((Finset.range 5 ×ˢ Finset.range 5 ×ˢ Finset.range 5).image
    (fun v : ℕ × ℕ × ℕ => 3 * v.1 + 2 * v.2.1 + 4 * v.2.2)).card = 35 := by decide

#print axioms finrank_quotient_eq_finrank_sub_finrank
#print axioms quotient_ker_equiv_image
#print axioms direct_sum_iff_unique_split
