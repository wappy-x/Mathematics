-- Spectral sequences in outline: once Serre's theorem gives the page, the page arithmetic alone forces the loop space of the 3-sphere and K(Z, 2) to have Z in every even degree and 0 in every odd degree, and gives a circle bundle over the 2-sphere the group Z/c in degree 2.
import Mathlib.Data.ZMod.QuotientGroup
import Mathlib.Algebra.Ring.Basic

/-! Serre's theorem, the path fibrations and the cell structures are stated on the card, not
proved; Mathlib has no Serre spectral sequence and no Eilenberg–MacLane spaces. What is stated
here is the page arithmetic the card proves from them, with each page entry an abelian group and
each differential a group homomorphism. -/

/-- The path fibration `ΩS³ → PS³ → S³`. Let `H q` stand for the unknown cohomology group
`H^q(ΩS³)`. The page has two columns: column 0 holds `H q` at row `q`, and column 3 holds
`H^3(S³; H q) ≅ H q` at row `q`. The only differential that can act is
`d₃ : E₃^{0, q+2} → E₃^{3, q}`, written `d₃ q : H (q + 2) →+ H q`.
The total space `PS³` shrinks to a point, so the last page is `ℤ` at (0, 0) and zero elsewhere:
`H 0 ≅ ℤ`; the entry (0, 1) has no differential in or out, so `H 1 = 0`; every `d₃` is one for
one (nothing survives in column 0 above row 1) and onto (nothing survives in column 3).
Then the loop space has `ℤ` in every even degree and `0` in every odd degree. -/
theorem loop_space_of_three_sphere_cohomology
    (H : ℕ → Type) [∀ q, AddCommGroup (H q)]
    (d₃ : ∀ q, H (q + 2) →+ H q)
    (h_zero : Nonempty (H 0 ≃+ ℤ))
    (h_one : Subsingleton (H 1))
    (h_out : ∀ q, Function.Injective (d₃ q))
    (h_hit : ∀ q, Function.Surjective (d₃ q)) :
    ∀ n : ℕ, Nonempty (H (2 * n) ≃+ ℤ) ∧ Subsingleton (H (2 * n + 1)) := by
  intro n
  induction n with
  | zero => exact ⟨h_zero, h_one⟩
  | succ n ih =>
    obtain ⟨⟨e⟩, hs⟩ := ih
    refine ⟨⟨(AddEquiv.ofBijective (d₃ (2 * n)) ⟨h_out _, h_hit _⟩).trans e⟩, ?_⟩
    exact (h_out (2 * n + 1)).subsingleton

/-- The path fibration `S¹ → P K(ℤ,2) → K(ℤ,2)`, read the other way: the fibre
`ΩK(ℤ,2) ≃ K(ℤ,1) = S¹` is known and the base is the unknown. Let `A p` stand for
`H^p(K(ℤ,2))`. The page has two rows, `q = 0` and `q = 1`, each holding `A p` at column `p`.
The only differential is `d₂ : E₂^{p,1} → E₂^{p+2,0}`, written `d₂ p : A p →+ A (p + 2)`.
The total space shrinks to a point, so: `A 0 ≅ ℤ`; the entry (1, 0) is hit by nothing, so
`A 1 = 0`; every `d₂` is one for one and onto. Then `K(ℤ,2)` has `ℤ` in every even degree and
`0` in every odd degree. -/
theorem eilenberg_maclane_K_Z_two_cohomology
    (A : ℕ → Type) [∀ p, AddCommGroup (A p)]
    (d₂ : ∀ p, A p →+ A (p + 2))
    (h_zero : Nonempty (A 0 ≃+ ℤ))
    (h_one : Subsingleton (A 1))
    (h_out : ∀ p, Function.Injective (d₂ p))
    (h_hit : ∀ p, Function.Surjective (d₂ p)) :
    ∀ n : ℕ, Nonempty (A (2 * n) ≃+ ℤ) ∧ Subsingleton (A (2 * n + 1)) := by
  intro n
  induction n with
  | zero => exact ⟨h_zero, h_one⟩
  | succ n ih =>
    obtain ⟨⟨e⟩, hs⟩ := ih
    refine ⟨⟨(AddEquiv.ofBijective (d₂ (2 * n)) ⟨h_out _, h_hit _⟩).symm.trans e⟩, ?_⟩
    exact ⟨fun x y => (h_hit (2 * n + 1)).forall₂.2 (fun a b => by
      rw [Subsingleton.elim a b]) x y⟩

/-- A circle bundle over `S²` with Euler number `c`: its two-row page has `ℤ` at (0, 0), (0, 1),
(2, 0) and (2, 1), and the one differential `d₂ : E₂^{0,1} → E₂^{2,0}` multiplies by `c`.
The last page keeps the cokernel at (2, 0), which is `ℤ/c`, so `H²` of the total space is
`ℤ/c`; it keeps the kernel at (0, 1), which is zero exactly when `c ≠ 0`, so `H¹` of the total
space is `0` unless `c = 0`. -/
theorem circle_bundle_page_differential (c : ℤ) :
    Nonempty (ℤ ⧸ (AddMonoidHom.mulLeft c).range ≃+ ZMod c.natAbs) ∧
      ((AddMonoidHom.mulLeft c).ker = ⊥ ↔ c ≠ 0) := by
  have hr : (AddMonoidHom.mulLeft c).range = AddSubgroup.zmultiples c := by
    ext x
    simp only [AddMonoidHom.mem_range, AddMonoidHom.coe_mulLeft, AddSubgroup.mem_zmultiples_iff,
      zsmul_eq_mul]
    constructor
    · rintro ⟨y, rfl⟩; exact ⟨y, mul_comm _ _⟩
    · rintro ⟨y, rfl⟩; exact ⟨y, mul_comm _ _⟩
  refine ⟨⟨(QuotientAddGroup.quotientAddEquivOfEq hr).trans (Int.quotientZMultiplesEquivZMod c)⟩, ?_⟩
  rw [AddMonoidHom.ker_eq_bot_iff]
  constructor
  · intro h hc
    subst hc
    have := @h 0 1 (by simp)
    exact zero_ne_one this
  · intro hc a b hab
    exact mul_left_cancel₀ hc hab

/-! The card's whole-number examples. -/

/-- All lists of ranks 0, 1 or 2 of length `n`. -/
def rankLists : ℕ → List (List ℕ)
  | 0 => [[]]
  | n + 1 => (rankLists n).flatMap fun l => [0 :: l, 1 :: l, 2 :: l]

/-- Columns 0 and 3 of the path fibration page, both holding the rank list `s` in rows 0 to 8,
with `d₃` jumping 3 columns right and 2 rows down: every nonzero entry but (0, 0) dies, either
going out one for one or being hit; a partner past row 8 is not tested, as on the card. -/
def emptiedByD3 (s : List ℕ) : Bool :=
  (List.range 9).all fun q =>
    (q == 0 || s.getD q 0 == 0 || (q ≥ 2 && decide (s.getD q 0 ≤ s.getD (q - 2) 0))) &&
    (s.getD q 0 == 0 || q + 2 > 8 || decide (s.getD q 0 ≤ s.getD (q + 2) 0))

-- The exhaustive search: of the 3 ^ 8 = 6561 rank lists for degrees 1 to 8, exactly one survives.
example : (rankLists 8).length = 6561 := by decide +kernel
example : ((rankLists 8).map (1 :: ·)).filter emptiedByD3 = [[1, 0, 1, 0, 1, 0, 1, 0, 1]] := by
  decide +kernel

-- Stopping at page 2 for the loop space: the point PS³ would get ranks 1, 0, 1, 1, 1, 1, 1, 1, 1.
example : (List.range 9).map (fun k => (if k % 2 = 0 then 1 else 0) +
    (if 3 ≤ k ∧ (k - 3) % 2 = 0 then 1 else 0)) = [1, 0, 1, 1, 1, 1, 1, 1, 1] := by decide

-- Circle bundles over S²: the Euler characteristic is 0 on page 2 (ranks 1, 1, 1, 1) and on the
-- last page (ranks 1, 0, 0, 1 for c ≠ 0), and equals χ(S²) · χ(S¹) = 2 · 0.
example : (1 : ℤ) - 1 + 1 - 1 = 0 ∧ (1 : ℤ) - 0 + 0 - 1 = 0 ∧ (1 - 0 + 1 : ℤ) * (1 - 1) = 0 := by
  norm_num

#print axioms loop_space_of_three_sphere_cohomology
#print axioms eilenberg_maclane_K_Z_two_cohomology
#print axioms circle_bundle_page_differential
