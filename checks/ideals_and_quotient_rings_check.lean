-- Ideals and quotient rings: the kernel of every ring map passes the two-part ideal test and collapsing by it leaves the image, every ideal of the whole numbers is the multiples of some n, and collapsing the whole numbers by the multiples of n gives Z mod n.
import Mathlib.RingTheory.Ideal.Quotient.Operations
import Mathlib.RingTheory.PrincipalIdealDomain
import Mathlib.Data.ZMod.QuotientRing
import Mathlib.Data.Int.Interval
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Tactic.Ring

/-- Kernels are ideals, and collapsing by the kernel leaves the image. Take any ring map
φ from a ring R to a ring S (multiplication order may matter). Everything φ sends to 0 passes
the ideal test: it is closed under subtraction, and a member times anything in R, on either
side, stays inside. And R collapsed by that kernel is the image of φ under new names:
R / ker φ ≅ im φ (the first isomorphism theorem). -/
theorem kernel_is_ideal_and_quotient_by_kernel_is_image
    {R S : Type*} [Ring R] [Ring S] (φ : R →+* S) :
    ((∀ a ∈ RingHom.ker φ, ∀ b ∈ RingHom.ker φ, a - b ∈ RingHom.ker φ) ∧
      (∀ a ∈ RingHom.ker φ, ∀ r : R, r * a ∈ RingHom.ker φ ∧ a * r ∈ RingHom.ker φ)) ∧
    Nonempty ((R ⧸ RingHom.ker φ) ≃+* φ.range) := by
  refine ⟨⟨?_, ?_⟩, ⟨RingHom.quotientKerEquivRange φ⟩⟩
  · intro a ha b hb
    rw [RingHom.mem_ker] at ha hb ⊢
    rw [map_sub, ha, hb, sub_zero]
  · intro a ha r
    simp only [RingHom.mem_ker] at ha ⊢
    simp [ha]

/-- The multiples of n are the model: every ideal of the whole numbers Z is the set of
multiples of some n (its smallest positive member, or 0). -/
theorem every_ideal_of_int_is_the_multiples_of_some_n (I : Ideal ℤ) :
    ∃ n : ℕ, I = Ideal.span {(n : ℤ)} := by
  obtain ⟨g, hg⟩ := (IsPrincipalIdealRing.principal I).principal
  refine ⟨g.natAbs, ?_⟩
  rw [hg]
  simp


/-- Clock arithmetic is this construction: collapsing the whole numbers by the multiples of n
gives Z mod n, for every n. -/
theorem int_collapsed_by_multiples_of_n_is_zmod_n (n : ℕ) :
    Nonempty ((ℤ ⧸ Ideal.span {(n : ℤ)}) ≃+* ZMod n) := by
  exact ⟨Int.quotientSpanNatEquivZMod n⟩

-- The invoice: 47 crates at $23 come to $1,081.
example : 47 * 23 = 1081 := by norm_num
-- Casting out nines: 47 leaves 2, 23 leaves 5, 2 × 5 = 10 leaves 1, and 1,081 leaves 1.
example : 47 % 9 = 2 ∧ 23 % 9 = 5 ∧ 2 * 5 = 10 ∧ 10 % 9 = 1 ∧ 1081 % 9 = 1 := by decide
-- The same check as arithmetic of classes in Z mod 9.
example : (47 : ZMod 9) * 23 = 1081 ∧ (2 : ZMod 9) * 5 = 1 ∧ (1081 : ZMod 9) = 1 := by decide
-- Other names, same class: 56 × 32 = 1,792, class 1.
example : 56 * 32 = 1792 ∧ 1792 % 9 = 1 := by decide
-- All 121 pairs of names shifted by multiples of 9 (i, j from -5 to 5) land in class 1.
example : ∀ i ∈ Finset.Icc (-5 : ℤ) 5, ∀ j ∈ Finset.Icc (-5 : ℤ) 5,
    ((47 + 9 * i) * (23 + 9 * j)) % 9 = 1 := by decide
-- A passed check is not proof: the wrong total 1,090 is class 1 too.
example : (1090 : ZMod 9) = 1081 := by decide
-- The kernel of casting out nines, from 0 to 40, is 0, 9, 18, 27, 36.
example : (Finset.range 41).filter (fun k => k % 9 = 0) = {0, 9, 18, 27, 36} := by decide
-- On the 12-hour clock, {0, 3, 6, 9} passes both halves of the ideal test.
example : ∀ a ∈ ({0, 3, 6, 9} : Finset (ZMod 12)), ∀ b ∈ ({0, 3, 6, 9} : Finset (ZMod 12)),
    a - b ∈ ({0, 3, 6, 9} : Finset (ZMod 12)) ∧
    ∀ r : ZMod 12, r * a ∈ ({0, 3, 6, 9} : Finset (ZMod 12)) := by decide
-- {0, 4, 6, 8} absorbs every product, yet 4 + 6 = 10 lies outside it.
example : (∀ a ∈ ({0, 4, 6, 8} : Finset (ZMod 12)), ∀ r : ZMod 12,
    r * a ∈ ({0, 4, 6, 8} : Finset (ZMod 12))) ∧
    (4 : ZMod 12) + 6 = 10 ∧ (10 : ZMod 12) ∉ ({0, 4, 6, 8} : Finset (ZMod 12)) := by decide
-- Collapsing by x^2 + 1: (2 + 3x)(4 + x) = 8 + 14x + 3x^2, which differs from 5 + 14x
-- by 3 times x^2 + 1, so its class is 5 + 14x.
open Polynomial in
example : ((2 + 3 * X) * (4 + X) : ℤ[X]) = 8 + 14 * X + 3 * X ^ 2 ∧
    ((2 + 3 * X) * (4 + X) : ℤ[X]) = (5 + 14 * X) + 3 * (X ^ 2 + 1) := by
  constructor <;> ring
-- Z mod 9 has zero divisors: 3 × 3 = 0 with 3 not zero.
example : (3 : ZMod 9) * 3 = 0 ∧ (3 : ZMod 9) ≠ 0 := by decide
-- 6 of the 8 nonzero classes of Z mod 9 have a reciprocal; all 6 of Z mod 7 do.
example : ((Finset.univ : Finset (ZMod 9)).filter (fun a => a ≠ 0 ∧ ∃ b, a * b = 1)).card = 6 ∧
    ((Finset.univ : Finset (ZMod 7)).filter (fun a => a ≠ 0 ∧ ∃ b, a * b = 1)).card = 6 := by
  decide

#print axioms kernel_is_ideal_and_quotient_by_kernel_is_image
#print axioms every_ideal_of_int_is_the_multiples_of_some_n
#print axioms int_collapsed_by_multiples_of_n_is_zmod_n
