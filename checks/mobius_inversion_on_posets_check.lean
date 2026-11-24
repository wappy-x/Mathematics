-- Mobius inversion on an order: on any order where everything below each member is finite, totals over everything below can be undone with the Mobius function, which is a sign on subsets and number theory's Mobius function on divisors.
import Mathlib.Combinatorics.Enumerative.IncidenceAlgebra
import Mathlib.Data.Finset.Interval
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Sum

open Finset IncidenceAlgebra

/-- Swap the order of a double sum over `z ≤ x ≤ y`. -/
theorem iic_iic_sum_swap {𝕜 α : Type*} [AddCommMonoid 𝕜] [PartialOrder α] [LocallyFiniteOrder α]
    [LocallyFiniteOrderBot α] (F : α → α → 𝕜) (y : α) :
    ∑ x ∈ Iic y, ∑ z ∈ Iic x, F z x = ∑ z ∈ Iic y, ∑ x ∈ Icc z y, F z x := by
  apply Finset.sum_comm'
  intro x z
  simp only [mem_Iic, mem_Icc]
  constructor
  · rintro ⟨hxy, hzx⟩; exact ⟨⟨hzx, hxy⟩, hzx.trans hxy⟩
  · rintro ⟨⟨hzx, hxy⟩, -⟩; exact ⟨hxy, hzx⟩

/-- On subsets between `S` and a strictly larger `T`, the signs `(-1)^(|U| - |S|)` sum to zero. -/
theorem sum_Icc_sign_subsets {α : Type*} [DecidableEq α] {S T : Finset α} (h : S ⊆ T)
    (hne : S ≠ T) : ∑ U ∈ Icc S T, (-1 : ℤ) ^ (U.card - S.card) = 0 := by
  rw [Finset.Icc_eq_image_powerset h, Finset.sum_image]
  · have hcard : ∀ V ∈ (T \ S).powerset, (-1 : ℤ) ^ ((S ∪ V).card - S.card) = (-1) ^ V.card := by
      intro V hV
      have hd : Disjoint S V :=
        Finset.disjoint_of_subset_right (Finset.mem_powerset.1 hV) Finset.disjoint_sdiff
      rw [Finset.card_union_of_disjoint hd, Nat.add_sub_cancel_left]
    rw [Finset.sum_congr rfl hcard]
    apply Finset.sum_powerset_neg_one_pow_card_of_nonempty
    rw [Finset.sdiff_nonempty]
    intro hTS
    exact hne (Finset.Subset.antisymm h hTS)
  · intro V hV W hW hVW
    have hV' := Finset.mem_powerset.1 (Finset.mem_coe.1 hV)
    have hW' := Finset.mem_powerset.1 (Finset.mem_coe.1 hW)
    simp only at hVW
    ext a
    constructor
    · intro ha
      have : a ∈ S ∪ W := hVW ▸ Finset.mem_union_right S ha
      rcases Finset.mem_union.1 this with hS | hW2
      · exact absurd hS (Finset.mem_sdiff.1 (hV' ha)).2
      · exact hW2
    · intro ha
      have : a ∈ S ∪ V := hVW.symm ▸ Finset.mem_union_right S ha
      rcases Finset.mem_union.1 this with hS | hV2
      · exact absurd hS (Finset.mem_sdiff.1 (hW' ha)).2
      · exact hV2

/-- Mobius inversion on an order. In a partial order where everything below each member is
finite, the totals `g y` are the sums of the unknowns `f x` over every `x ≤ y` (the member itself
included) exactly when each unknown `f y` is the sum over every `x ≤ y` of `μ(x, y) * g x`, where
`μ` is the Mobius function of the order (`IncidenceAlgebra.mu`, built by the card's recursion
`μ(x, x) = 1`, `μ(x, y) = -∑_{x ≤ z < y} μ(x, z)`). Finite sets below each member also make every
interval finite, so `LocallyFiniteOrder` adds nothing beyond `LocallyFiniteOrderBot`. -/
theorem mobius_inversion_on_order {𝕜 α : Type*} [Ring 𝕜] [PartialOrder α] [LocallyFiniteOrder α]
    [LocallyFiniteOrderBot α] [DecidableEq α] (f g : α → 𝕜) :
    (∀ y, g y = ∑ x ∈ Iic y, f x) ↔ (∀ y, f y = ∑ x ∈ Iic y, mu 𝕜 x y * g x) := by
  constructor
  · intro h y
    calc f y = ∑ z ∈ Iic y, (if z = y then (1 : 𝕜) else 0) * f z := by
          rw [Finset.sum_congr rfl (fun z _ => ite_mul _ _ _ _)]
          simp
      _ = ∑ z ∈ Iic y, (∑ x ∈ Icc z y, mu 𝕜 x y) * f z := by
          refine Finset.sum_congr rfl (fun z _ => ?_)
          rw [sum_Icc_mu_left]
      _ = ∑ z ∈ Iic y, ∑ x ∈ Icc z y, mu 𝕜 x y * f z := by
          simp_rw [Finset.sum_mul]
      _ = ∑ x ∈ Iic y, ∑ z ∈ Iic x, mu 𝕜 x y * f z :=
          (iic_iic_sum_swap (fun z x => mu 𝕜 x y * f z) y).symm
      _ = ∑ x ∈ Iic y, mu 𝕜 x y * g x := by
          refine Finset.sum_congr rfl (fun x _ => ?_)
          rw [h x, Finset.mul_sum]
  · intro h y
    calc g y = ∑ z ∈ Iic y, (if z = y then (1 : 𝕜) else 0) * g z := by
          rw [Finset.sum_congr rfl (fun z _ => ite_mul _ _ _ _)]
          simp
      _ = ∑ z ∈ Iic y, (∑ x ∈ Icc z y, mu 𝕜 z x) * g z := by
          refine Finset.sum_congr rfl (fun z _ => ?_)
          rw [sum_Icc_mu_right]
      _ = ∑ z ∈ Iic y, ∑ x ∈ Icc z y, mu 𝕜 z x * g z := by
          simp_rw [Finset.sum_mul]
      _ = ∑ x ∈ Iic y, ∑ z ∈ Iic x, mu 𝕜 z x * g z :=
          (iic_iic_sum_swap (fun z x => mu 𝕜 z x * g z) y).symm
      _ = ∑ x ∈ Iic y, f x := by
          refine Finset.sum_congr rfl (fun x _ => ?_)
          rw [h x]

/-- On the subsets of a set ordered by inclusion, the Mobius function is a sign:
`μ(S, T) = (-1)^(|T| - |S|)` whenever `S ⊆ T`. -/
theorem mu_subsets_eq_sign {α : Type*} [DecidableEq α] {S T : Finset α} (h : S ⊆ T) :
    mu ℤ S T = (-1) ^ (T.card - S.card) := by
  induction T using Finset.strongInduction with
  | H T ih =>
    by_cases hST : S = T
    · subst hST; simp
    · have hsum := sum_Icc_sign_subsets h hST
      rw [Finset.Icc_eq_cons_Ico h, Finset.sum_cons] at hsum
      rw [mu_eq_neg_sum_Ico_of_ne hST]
      have hIco : ∑ U ∈ Ico S T, mu ℤ S U = ∑ U ∈ Ico S T, (-1 : ℤ) ^ (U.card - S.card) := by
        refine Finset.sum_congr rfl (fun U hU => ?_)
        rw [Finset.mem_Ico] at hU
        exact ih U hU.2 hU.1
      rw [hIco]
      linarith

/-- On divisors, the inversion uses number theory's Mobius function: for positive whole numbers,
`g n = ∑_{d ∣ n} f d` for every `n` exactly when `f n = ∑_{d ∣ n} μ(n / d) * g d` for every `n`. -/
theorem mobius_inversion_on_divisors (f g : ℕ → ℤ) :
    (∀ n > 0, g n = ∑ d ∈ n.divisors, f d) ↔
      (∀ n > 0, f n = ∑ d ∈ n.divisors, (ArithmeticFunction.moebius (n / d) : ℤ) * g d) := by
  have key := ArithmeticFunction.sum_eq_iff_sum_mul_moebius_eq (R := ℤ) (f := f) (g := g)
  have hswap : ∀ n : ℕ, ∑ x ∈ n.divisorsAntidiagonal, (ArithmeticFunction.moebius x.1 : ℤ) * g x.2 =
      ∑ d ∈ n.divisors, (ArithmeticFunction.moebius (n / d) : ℤ) * g d := fun n =>
    Nat.sum_divisorsAntidiagonal' (fun a b => (ArithmeticFunction.moebius a : ℤ) * g b)
  simp only [Int.cast_id, hswap] at key
  constructor
  · intro h n hn
    exact (key.1 (fun m hm => (h m hm).symm) n hn).symm
  · intro h n hn
    exact (key.2 (fun m hm => (h m hm).symm) n hn).symm

-- Six-bit strings that are not a shorter block repeated: 2^6 - 2^3 - 2^2 + 2^1 = 54.
example : (2 : ℤ) ^ 6 - 2 ^ 3 - 2 ^ 2 + 2 ^ 1 = 54 := by norm_num
-- The same count by brute force over all 64 strings: no shift by 1, 2 or 3 places leaves it unchanged.
example : (univ.filter (fun s : Fin 6 → Bool =>
    ∀ d ∈ ({1, 2, 3} : Finset (Fin 6)), ∃ i, s i ≠ s (i + d))).card = 54 := by decide
-- The same 54 from number theory's Mobius function on the divisors 1, 2, 3, 6 of 6:
-- mu(6 / d) is 1, -1, -1, 1, so the sum is 2 - 4 - 8 + 64.
open ArithmeticFunction in
example : ∑ d ∈ (6 : ℕ).divisors, (moebius (6 / d) : ℤ) * 2 ^ d = 54 := by
  rw [show (6 : ℕ).divisors = {1, 2, 3, 6} from by decide]
  have h2 : moebius 2 = -1 := moebius_apply_prime Nat.prime_two
  have h3 : moebius 3 = -1 := moebius_apply_prime Nat.prime_three
  have h6 : moebius 6 = 1 := by
    rw [show (6 : ℕ) = 2 * 3 from rfl, isMultiplicative_moebius.map_mul_of_coprime (by norm_num),
      h2, h3]; rfl
  simp [h2, h3, h6]
-- mu(1, 4) = 0 on divisors, since 2 squared divides 4.
example : ArithmeticFunction.moebius 4 = 0 :=
  ArithmeticFunction.moebius_eq_zero_of_not_squarefree (by decide)
-- Peeling from the bottom: f(6) = 64 - 2 - 2 - 6 = 54, and 54 strings make 54 / 6 = 9 necklaces.
example : 64 - 2 - 2 - 6 = 54 ∧ 54 / 6 = 9 := by decide
-- Length 12: 2^12 - 2^6 - 2^4 + 2^2 = 4020.
example : (2 : ℤ) ^ 12 - 2 ^ 6 - 2 ^ 4 + 2 ^ 2 = 4020 := by norm_num
-- On the subsets of {1, 2, 3, 4}, the signs (-1)^|T| are +1 for 8 subsets and -1 for 8.
example : ((range 4).powerset.filter (fun T => Even T.card)).card = 8 ∧
    ((range 4).powerset.filter (fun T => ¬ Even T.card)).card = 8 := by decide
-- The hotel: 100 - 120 + 45 - 5 = 20 guests with no extra.
example : (100 : ℤ) - 120 + 45 - 5 = 20 := by norm_num

#print axioms iic_iic_sum_swap
#print axioms sum_Icc_sign_subsets
#print axioms mobius_inversion_on_order
#print axioms mu_subsets_eq_sign
#print axioms mobius_inversion_on_divisors
