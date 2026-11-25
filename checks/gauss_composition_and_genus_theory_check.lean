-- Composition and genus: two binary quadratic forms of the same discriminant compose into a third whose values include every product of their values, every value of a primitive form prime to an odd prime q dividing D has the same Legendre symbol modulo q, and an odd prime other than 5 is x^2 + 5y^2 exactly when it is 1 or 9 mod 20 and 2x^2 + 2xy + 3y^2 exactly when it is 3 or 7 mod 20.
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Ring
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.IntervalCases

/-! Mathlib has class groups of number fields but no theory of binary quadratic forms, so the
match of form classes with ideal classes and Gauss's count of genera are not stated here.
This file states the parts of the card that can be stated exactly with whole numbers:

* Dirichlet composition (the card's Steps 3 and 4): forms `(a₁, b₁, c₁)` and `(a₂, b₂, c₂)` of
  one discriminant `D`, with `gcd(a₁, a₂, (b₁ + b₂)/2) = 1`, have a composite `(a₁a₂, B, C)` of
  discriminant `D`, with `B ≡ b₁ (mod 2a₁)` and `B ≡ b₂ (mod 2a₂)`, and two bilinear
  expressions `X`, `Y` in `x, y, z, w` that turn the product of the two forms into the composite.
* The genus character (the card's Step 5): for a primitive form and an odd prime `q` dividing
  `D`, all values prime to `q` have the same Legendre symbol modulo `q`.
* The rule for `x² + 5y²` modulo 20 (the card's Step 6), with both classes of discriminant −20. -/

theorem united_forms_identity (a₁ a₂ b₁ b₂ c₁ c₂ B C P Q : ℤ) (h1 : b₁ = B - 2 * a₁ * P)
    (h2 : b₂ = B - 2 * a₂ * Q) (h3 : c₁ = a₂ * C + a₁ * P ^ 2 - B * P)
    (h4 : c₂ = a₁ * C + a₂ * Q ^ 2 - B * Q) (x y z w : ℤ) :
    (a₁ * x ^ 2 + b₁ * x * y + c₁ * y ^ 2) * (a₂ * z ^ 2 + b₂ * z * w + c₂ * w ^ 2) =
      a₁ * a₂ * (1 * x * z + (-Q) * x * w + (-P) * y * z + (P * Q - C) * y * w) ^ 2 +
      B * (1 * x * z + (-Q) * x * w + (-P) * y * z + (P * Q - C) * y * w) *
        (0 * x * z + a₁ * x * w + a₂ * y * z + (B - a₁ * P - a₂ * Q) * y * w) +
      C * (0 * x * z + a₁ * x * w + a₂ * y * z + (B - a₁ * P - a₂ * Q) * y * w) ^ 2 := by
  subst h1 h2 h3 h4
  ring

theorem genus_value_eq_first (a b c : ℤ) (q : ℕ) [Fact q.Prime] (hq : q ≠ 2)
    (ha : ¬ (q : ℤ) ∣ a) (hqD : (q : ℤ) ∣ b ^ 2 - 4 * a * c) (x y : ℤ)
    (hm : ¬ (q : ℤ) ∣ a * x ^ 2 + b * x * y + c * y ^ 2) :
    legendreSym q (a * x ^ 2 + b * x * y + c * y ^ 2) = legendreSym q a := by
  set m := a * x ^ 2 + b * x * y + c * y ^ 2 with hmdef
  have h2 : ((2 : ℤ) : ZMod q) ≠ 0 := by
    intro h
    rw [ZMod.intCast_zmod_eq_zero_iff_dvd] at h
    have h' : q ∣ 2 := by exact_mod_cast h
    exact hq ((Nat.prime_dvd_prime_iff_eq Fact.out Nat.prime_two).mp h')
  have ha' : ((a : ℤ) : ZMod q) ≠ 0 := by rwa [Ne, ZMod.intCast_zmod_eq_zero_iff_dvd]
  have hm' : ((m : ℤ) : ZMod q) ≠ 0 := by rwa [Ne, ZMod.intCast_zmod_eq_zero_iff_dvd]
  have hcast : (((2 : ℤ) ^ 2 * a * m : ℤ) : ZMod q) = (((2 * a * x + b * y) ^ 2 : ℤ) : ZMod q) := by
    rw [ZMod.intCast_eq_intCast_iff_dvd_sub]
    obtain ⟨k, hk⟩ := hqD
    exact ⟨k * y ^ 2, by rw [hmdef]; linear_combination y ^ 2 * hk⟩
  have hne : (((2 * a * x + b * y : ℤ)) : ZMod q) ≠ 0 := by
    intro h0
    have h1 : (((2 : ℤ) ^ 2 * a * m : ℤ) : ZMod q) = 0 := by
      rw [hcast, Int.cast_pow, h0, zero_pow two_ne_zero]
    have h3 : ((2 : ℤ) : ZMod q) ^ 2 * (a : ZMod q) * (m : ZMod q) ≠ 0 :=
      mul_ne_zero (mul_ne_zero (pow_ne_zero 2 h2) ha') hm'
    exact h3 (by exact_mod_cast h1)
  have hL : legendreSym q ((2 : ℤ) ^ 2 * a * m) = legendreSym q ((2 * a * x + b * y) ^ 2) := by
    simp only [legendreSym]; rw [hcast]
  rw [legendreSym.sq_one' q hne, legendreSym.mul, legendreSym.mul, legendreSym.sq_one' q h2] at hL
  rcases legendreSym.eq_one_or_neg_one q ha' with h | h <;>
    rcases legendreSym.eq_one_or_neg_one q hm' with h' | h' <;>
    rw [h, h'] at hL ⊢ <;> norm_num at hL

theorem zmod20_principal_values : ∀ s r : ZMod 20,
    (s ^ 2 + 5 * r ^ 2).val % 2 = 0 ∨ (s ^ 2 + 5 * r ^ 2).val % 5 = 0 ∨
      (s ^ 2 + 5 * r ^ 2).val = 1 ∨ (s ^ 2 + 5 * r ^ 2).val = 9 := by
  decide

theorem zmod20_other_values : ∀ s r : ZMod 20,
    (2 * s ^ 2 + 2 * s * r + 3 * r ^ 2).val % 2 = 0 ∨ (2 * s ^ 2 + 2 * s * r + 3 * r ^ 2).val % 5 = 0 ∨
      (2 * s ^ 2 + 2 * s * r + 3 * r ^ 2).val = 3 ∨ (2 * s ^ 2 + 2 * s * r + 3 * r ^ 2).val = 7 := by
  decide

theorem principal_mod_twenty (p : ℕ) (hp : p.Prime) (h2 : p ≠ 2) (h5 : p ≠ 5) (x y : ℤ)
    (h : (p : ℤ) = x ^ 2 + 5 * y ^ 2) : p % 20 = 1 ∨ p % 20 = 9 := by
  have hc : (p : ZMod 20) = (x : ZMod 20) ^ 2 + 5 * (y : ZMod 20) ^ 2 := by
    have := congrArg (fun z : ℤ => (z : ZMod 20)) h
    push_cast at this
    exact this
  rcases zmod20_principal_values (x : ZMod 20) (y : ZMod 20) with h' | h' | h' | h' <;>
    rw [← hc, ZMod.val_natCast] at h'
  · have hd : 2 ∣ p := by omega
    rcases hp.eq_one_or_self_of_dvd 2 hd with h0 | h0 <;> omega
  · have hd : 5 ∣ p := by omega
    rcases hp.eq_one_or_self_of_dvd 5 hd with h0 | h0 <;> omega
  · omega
  · omega

theorem other_mod_twenty (p : ℕ) (hp : p.Prime) (h2 : p ≠ 2) (h5 : p ≠ 5) (x y : ℤ)
    (h : (p : ℤ) = 2 * x ^ 2 + 2 * x * y + 3 * y ^ 2) : p % 20 = 3 ∨ p % 20 = 7 := by
  have hc : (p : ZMod 20) = 2 * (x : ZMod 20) ^ 2 + 2 * (x : ZMod 20) * (y : ZMod 20) +
      3 * (y : ZMod 20) ^ 2 := by
    have := congrArg (fun z : ℤ => (z : ZMod 20)) h
    push_cast at this
    exact this
  rcases zmod20_other_values (x : ZMod 20) (y : ZMod 20) with h' | h' | h' | h' <;>
    rw [← hc, ZMod.val_natCast] at h'
  · have hd : 2 ∣ p := by omega
    rcases hp.eq_one_or_self_of_dvd 2 hd with h0 | h0 <;> omega
  · have hd : 5 ∣ p := by omega
    rcases hp.eq_one_or_self_of_dvd 5 hd with h0 | h0 <;> omega
  · omega
  · omega

/-- Reduction of forms of discriminant -20: every number represented by a positive definite
form of discriminant -20 is represented by `x² + 5y²` or by `2x² + 2xy + 3y²`. -/
theorem reduce_disc_neg_twenty (n : ℤ) : ∀ (k : ℕ) (a b c : ℤ), a.toNat ≤ k → 0 < a →
    b ^ 2 - 4 * a * c = -20 → (∃ x y : ℤ, n = a * x ^ 2 + b * x * y + c * y ^ 2) →
    (∃ x y : ℤ, n = x ^ 2 + 5 * y ^ 2) ∨ (∃ x y : ℤ, n = 2 * x ^ 2 + 2 * x * y + 3 * y ^ 2) := by
  intro k
  induction k with
  | zero => intro a b c hk ha; omega
  | succ k ih =>
    intro a b c hk ha hdisc ⟨x, y, hn⟩
    -- shift the middle number into [-a, a)
    obtain ⟨s, hs⟩ : ∃ s, s = (b + a) / (2 * a) := ⟨_, rfl⟩
    have hmod := Int.emod_add_mul_ediv (b + a) (2 * a)
    have hr0 := Int.emod_nonneg (b + a) (show 2 * a ≠ 0 by omega)
    have hr1 := Int.emod_lt_of_pos (b + a) (show 0 < 2 * a by omega)
    rw [← hs] at hmod
    obtain ⟨b', hb'⟩ : ∃ b', b' = b - 2 * a * s := ⟨_, rfl⟩
    obtain ⟨c', hc'⟩ : ∃ c', c' = a * s ^ 2 - b * s + c := ⟨_, rfl⟩
    obtain ⟨X, hX⟩ : ∃ X, X = x + s * y := ⟨_, rfl⟩
    have hlo : -a ≤ b' := by
      have : b' = (b + a) % (2 * a) - a := by rw [hb']; linear_combination -hmod
      omega
    have hhi : b' < a := by
      have : b' = (b + a) % (2 * a) - a := by rw [hb']; linear_combination -hmod
      omega
    have hdisc' : b' ^ 2 - 4 * a * c' = -20 := by
      rw [hb', hc']; linear_combination hdisc
    have hn' : n = a * X ^ 2 + b' * X * y + c' * y ^ 2 := by
      rw [hb', hc', hX, hn]; ring
    have hcpos : 0 < c' := by nlinarith
    by_cases hca : c' < a
    · exact ih c' (-b') a (by omega) hcpos (by linear_combination hdisc')
        ⟨y, -X, by rw [hn']; ring⟩
    · have hca' : a ≤ c' := by omega
      have ha2 : a ≤ 2 := by nlinarith
      have hcases : (a = 1 ∧ b' = 0 ∧ c' = 5) ∨ (a = 2 ∧ b' = -2 ∧ c' = 3) := by
        interval_cases a <;> interval_cases b' <;> norm_num at hdisc' ⊢ <;> omega
      rcases hcases with ⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩
      · exact Or.inl ⟨X, y, by rw [hn']; ring⟩
      · exact Or.inr ⟨-X, y, by rw [hn']; ring⟩

theorem exists_sq_add_five_dvd (p : ℕ) [Fact p.Prime]
    (h : p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9) : ∃ k : ℤ, (p : ℤ) ∣ k ^ 2 + 5 := by
  have : Fact (Nat.Prime 5) := ⟨by norm_num⟩
  have hp2 : p ≠ 2 := by omega
  have hrec : legendreSym p 5 = legendreSym 5 p :=
    legendreSym.quadratic_reciprocity_one_mod_four (by norm_num) hp2
  have hmod5 : legendreSym 5 p = legendreSym 5 ((p % 5 : ℕ) : ℤ) := by
    rw [legendreSym.mod 5 (p : ℤ)]
    push_cast
    rfl
  have hL : legendreSym p (-5) = 1 := by
    rw [legendreSym.at_neg hp2, hrec, hmod5, ZMod.χ₄_nat_eq_if_mod_four]
    rcases h with h | h | h | h
    · rw [show p % 5 = 1 by omega]
      simp only [show p % 2 = 1 by omega, show p % 4 = 1 by omega]
      norm_num
    · rw [show p % 5 = 3 by omega]
      simp only [show p % 2 = 1 by omega, show p % 4 = 3 by omega]
      norm_num
    · rw [show p % 5 = 2 by omega]
      simp only [show p % 2 = 1 by omega, show p % 4 = 3 by omega]
      norm_num
    · rw [show p % 5 = 4 by omega]
      simp only [show p % 2 = 1 by omega, show p % 4 = 1 by omega]
      norm_num
  have h0 : ((-5 : ℤ) : ZMod p) ≠ 0 := by
    intro h0
    rw [← legendreSym.eq_zero_iff] at h0
    rw [h0] at hL
    exact zero_ne_one hL
  obtain ⟨r, hr⟩ := (legendreSym.eq_one_iff p h0).mp hL
  refine ⟨(r.val : ℤ), ?_⟩
  rw [← ZMod.intCast_zmod_eq_zero_iff_dvd]
  push_cast
  rw [ZMod.natCast_zmod_val, sq, ← hr]
  ring

#print axioms united_forms_identity
#print axioms genus_value_eq_first
#print axioms zmod20_principal_values
#print axioms zmod20_other_values
#print axioms principal_mod_twenty
#print axioms other_mod_twenty
#print axioms reduce_disc_neg_twenty
#print axioms exists_sq_add_five_dvd

/-- **Dirichlet composition.** Two forms `a₁x² + b₁xy + c₁y²` and `a₂z² + b₂zw + c₂w²` with
positive first numbers and the same discriminant `D = b² − 4ac`, whose first numbers and half the
sum of the middle numbers share no factor, have a composite `a₁a₂X² + BXY + CY²`: its middle
number `B` is `b₁` modulo `2a₁` and `b₂` modulo `2a₂`, its discriminant is `D`, and there are
`X` and `Y`, each a whole-number combination of `xz, xw, yz, yw`, that make the product of the
two forms equal the composite for every `x, y, z, w`. -/
theorem dirichlet_composition (a₁ b₁ c₁ a₂ b₂ c₂ : ℤ) (ha₁ : 0 < a₁) (ha₂ : 0 < a₂)
    (hD : b₁ ^ 2 - 4 * a₁ * c₁ = b₂ ^ 2 - 4 * a₂ * c₂)
    (hcop : Int.gcd (Int.gcd a₁ a₂) ((b₁ + b₂) / 2) = 1) :
    ∃ B C : ℤ, B ≡ b₁ [ZMOD 2 * a₁] ∧ B ≡ b₂ [ZMOD 2 * a₂] ∧
      B ^ 2 - 4 * (a₁ * a₂) * C = b₁ ^ 2 - 4 * a₁ * c₁ ∧
      ∃ p₁ p₂ p₃ p₄ r₁ r₂ r₃ r₄ : ℤ, ∀ x y z w : ℤ,
        (a₁ * x ^ 2 + b₁ * x * y + c₁ * y ^ 2) * (a₂ * z ^ 2 + b₂ * z * w + c₂ * w ^ 2) =
          a₁ * a₂ * (p₁ * x * z + p₂ * x * w + p₃ * y * z + p₄ * y * w) ^ 2 +
          B * (p₁ * x * z + p₂ * x * w + p₃ * y * z + p₄ * y * w) *
            (r₁ * x * z + r₂ * x * w + r₃ * y * z + r₄ * y * w) +
          C * (r₁ * x * z + r₂ * x * w + r₃ * y * z + r₄ * y * w) ^ 2 := by
  have hpar : (2 : ℤ) ∣ b₁ + b₂ := by
    rcases Int.even_or_odd b₁ with ⟨k, hk⟩ | ⟨k, hk⟩ <;>
      rcases Int.even_or_odd b₂ with ⟨m, hm⟩ | ⟨m, hm⟩
    · exact ⟨k + m, by omega⟩
    · exfalso; subst hk hm
      have h4 : (4 : ℤ) ∣ 1 :=
        ⟨k ^ 2 - a₁ * c₁ - m ^ 2 - m + a₂ * c₂, by linear_combination (-1 : ℤ) * hD⟩
      norm_num at h4
    · exfalso; subst hk hm
      have h4 : (4 : ℤ) ∣ 1 :=
        ⟨m ^ 2 - a₂ * c₂ - k ^ 2 - k + a₁ * c₁, by linear_combination hD⟩
      norm_num at h4
    · exact ⟨k + m + 1, by omega⟩
  obtain ⟨β, hβ⟩ := hpar
  have hβ' : (b₁ + b₂) / 2 = β := by omega
  rw [hβ'] at hcop
  obtain ⟨t, rfl⟩ : ∃ t, b₁ = β - t := ⟨β - b₁, by ring⟩
  obtain rfl : b₂ = β + t := by omega
  -- Bezout: a₁ u + a₂ v + β w = 1
  have hg := Int.gcd_eq_gcd_ab a₁ a₂
  have hg2 := Int.gcd_eq_gcd_ab (Int.gcd a₁ a₂ : ℤ) β
  rw [hcop] at hg2
  set u := Int.gcdA a₁ a₂ * Int.gcdA (Int.gcd a₁ a₂ : ℤ) β
  set v := Int.gcdB a₁ a₂ * Int.gcdA (Int.gcd a₁ a₂ : ℤ) β
  set w := Int.gcdB (Int.gcd a₁ a₂ : ℤ) β
  have hbez : a₁ * u + a₂ * v + β * w = 1 := by
    simp only [u, v, w]; push_cast at hg2
    linear_combination (-Int.gcdA (Int.gcd a₁ a₂ : ℤ) β) * hg - hg2
  have hc : a₁ * c₁ - a₂ * c₂ + β * t = 0 := by
    have h4 : 4 * (a₁ * c₁ - a₂ * c₂ + β * t) = 4 * 0 := by linear_combination (-1 : ℤ) * hD
    exact mul_left_cancel₀ (by norm_num) h4
  have hQ : a₂ * (-v * t - w * c₂) = a₁ * (u * t - w * c₁) - t := by
    linear_combination (-t) * hbez + w * hc
  have hN : (β - t) * (u * t - w * c₁) + a₁ * (u * t - w * c₁) ^ 2 + c₁ =
      a₂ * ((u * t - w * c₁) * (-v * t - w * c₂) + u * c₂ + v * c₁) := by
    linear_combination (-(u * t - w * c₁)) * hQ - c₁ * hbez + u * hc
  have hM : (β + t) * (-v * t - w * c₂) + a₂ * (-v * t - w * c₂) ^ 2 + c₂ =
      a₁ * ((u * t - w * c₁) * (-v * t - w * c₂) + u * c₂ + v * c₁) := by
    linear_combination (-v * t - w * c₂) * hQ - c₂ * hbez - v * hc
  refine ⟨β - t + 2 * a₁ * (u * t - w * c₁),
    (u * t - w * c₁) * (-v * t - w * c₂) + u * c₂ + v * c₁, ?_, ?_, ?_,
    1, -(-v * t - w * c₂), -(u * t - w * c₁), (u * t - w * c₁) * (-v * t - w * c₂) - ((u * t - w * c₁) * (-v * t - w * c₂) + u * c₂ + v * c₁),
    0, a₁, a₂, (β - t + 2 * a₁ * (u * t - w * c₁)) - a₁ * (u * t - w * c₁) - a₂ * (-v * t - w * c₂),
    united_forms_identity _ _ _ _ _ _ _ _ _ _ ?_ ?_ ?_ ?_⟩
  · rw [Int.modEq_iff_dvd]; exact ⟨-(u * t - w * c₁), by ring⟩
  · rw [Int.modEq_iff_dvd]; exact ⟨-(-v * t - w * c₂), by linear_combination 2 * hQ⟩
  · linear_combination 4 * a₁ * hN
  · ring
  · linear_combination 2 * hQ
  · linear_combination hN
  · linear_combination hM - 2 * (-v * t - w * c₂) * hQ

/-- **Genus characters.** Let `ax² + bxy + cy²` be a primitive form (`a, b, c` share no factor)
and `q` an odd prime dividing its discriminant `b² − 4ac`. Then any two values of the form that
`q` does not divide have the same Legendre symbol modulo `q`: the sign `(m/q)` is fixed by the
form. -/
theorem genus_character_constant (a b c : ℤ) (q : ℕ) [Fact q.Prime] (hq : q ≠ 2)
    (hprim : Int.gcd (Int.gcd a b) c = 1) (hqD : (q : ℤ) ∣ b ^ 2 - 4 * a * c)
    (x y x' y' : ℤ) (hm : ¬ (q : ℤ) ∣ a * x ^ 2 + b * x * y + c * y ^ 2)
    (hm' : ¬ (q : ℤ) ∣ a * x' ^ 2 + b * x' * y' + c * y' ^ 2) :
    legendreSym q (a * x ^ 2 + b * x * y + c * y ^ 2) =
      legendreSym q (a * x' ^ 2 + b * x' * y' + c * y' ^ 2) := by
  by_cases ha : (q : ℤ) ∣ a
  · have hc : ¬ (q : ℤ) ∣ c := by
      intro hc
      have hqp : Prime (q : ℤ) := Nat.prime_iff_prime_int.mp Fact.out
      have hb2 : (q : ℤ) ∣ b ^ 2 := by
        have : (q : ℤ) ∣ b ^ 2 - 4 * a * c + 4 * a * c := dvd_add hqD (dvd_mul_of_dvd_right hc _)
        simpa using this
      have hb : (q : ℤ) ∣ b := hqp.dvd_of_dvd_pow hb2
      have h1 : (q : ℤ) ∣ ((Int.gcd (Int.gcd a b) c : ℕ) : ℤ) :=
        Int.dvd_coe_gcd (Int.dvd_coe_gcd ha hb) hc
      rw [hprim] at h1
      have h1' : q ∣ 1 := by exact_mod_cast h1
      exact (Fact.out : q.Prime).one_lt.ne' (Nat.dvd_one.mp h1')
    have hqD' : (q : ℤ) ∣ b ^ 2 - 4 * c * a := by rwa [mul_assoc, mul_comm c a, ← mul_assoc]
    have e : ∀ s r : ℤ, a * s ^ 2 + b * s * r + c * r ^ 2 = c * r ^ 2 + b * r * s + a * s ^ 2 :=
      fun s r => by ring
    rw [e] at hm hm' ⊢
    rw [e, genus_value_eq_first c b a q hq hc hqD' y x hm,
      genus_value_eq_first c b a q hq hc hqD' y' x' hm']
  · rw [genus_value_eq_first a b c q hq ha hqD x y hm,
      genus_value_eq_first a b c q hq ha hqD x' y' hm']

/-- **The rule for `x² + 5y²`.** A prime `p` other than 2 and 5 is `x² + 5y²` exactly when it
leaves remainder 1 or 9 on division by 20, and is `2x² + 2xy + 3y²` exactly when it leaves
remainder 3 or 7. -/
theorem prime_x_sq_add_five_y_sq_iff (p : ℕ) (hp : p.Prime) (h2 : p ≠ 2) (h5 : p ≠ 5) :
    ((∃ x y : ℤ, (p : ℤ) = x ^ 2 + 5 * y ^ 2) ↔ p % 20 = 1 ∨ p % 20 = 9) ∧
    ((∃ x y : ℤ, (p : ℤ) = 2 * x ^ 2 + 2 * x * y + 3 * y ^ 2) ↔ p % 20 = 3 ∨ p % 20 = 7) := by
  have := Fact.mk hp
  have key : (p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9) →
      (∃ x y : ℤ, (p : ℤ) = x ^ 2 + 5 * y ^ 2) ∨
        (∃ x y : ℤ, (p : ℤ) = 2 * x ^ 2 + 2 * x * y + 3 * y ^ 2) := by
    intro h
    obtain ⟨k, m, hm⟩ := exists_sq_add_five_dvd p h
    have hp0 : (0 : ℤ) < p := by exact_mod_cast hp.pos
    exact reduce_disc_neg_twenty (p : ℤ) (p : ℤ).toNat (p : ℤ) (2 * k) m le_rfl hp0
      (by linear_combination 4 * hm) ⟨1, 0, by ring⟩
  refine ⟨⟨fun ⟨x, y, h⟩ => principal_mod_twenty p hp h2 h5 x y h, fun h => ?_⟩,
    ⟨fun ⟨x, y, h⟩ => other_mod_twenty p hp h2 h5 x y h, fun h => ?_⟩⟩
  · rcases key (by omega) with h' | ⟨x, y, h'⟩
    · exact h'
    · have := other_mod_twenty p hp h2 h5 x y h'
      omega
  · rcases key (by omega) with ⟨x, y, h'⟩ | h'
    · have := principal_mod_twenty p hp h2 h5 x y h'
      omega
    · exact h'

-- Worked numbers from the card.
-- The forms (2, 2, 3), the united forms (2, 10, 15) and (3, 10, 10), and the composite (6, 10, 5)
-- all have discriminant -20.
example : (2 : ℤ) ^ 2 - 4 * 2 * 3 = -20 ∧ (10 : ℤ) ^ 2 - 4 * 2 * 15 = -20 ∧
    (10 : ℤ) ^ 2 - 4 * 3 * 10 = -20 ∧ (10 : ℤ) ^ 2 - 4 * 6 * 5 = -20 := by norm_num
-- The coprime condition for (2, 2, 3) with itself fails, gcd(2, 2, 2) = 2; after moving the second
-- form to (3, -2, 2) it holds, gcd(2, 3, 0) = 1.
example : Int.gcd (Int.gcd 2 2) 2 = 2 ∧ Int.gcd (Int.gcd 2 3) 0 = 1 := by norm_num
-- B = 10: 10 is 2 mod 4, -2 mod 6, and 10^2 is -20 mod 24; then C = (100 + 20)/24 = 5.
example : (10 : ℤ) ≡ 2 [ZMOD 4] ∧ (10 : ℤ) ≡ -2 [ZMOD 6] ∧ (10 : ℤ) ^ 2 ≡ -20 [ZMOD 24] ∧
    ((100 : ℤ) + 20) / 24 = 5 := by decide
-- 3 = f(0, 1) and 7 = f(1, 1) for f = 2x^2 + 2xy + 3y^2, and 3 × 7 = (-1)^2 + 5 × 2^2 = 21.
example : (2 * 0 ^ 2 + 2 * 0 * 1 + 3 * 1 ^ 2 : ℤ) = 3 ∧ (2 * 1 ^ 2 + 2 * 1 * 1 + 3 * 1 ^ 2 : ℤ) = 7 ∧
    (3 * 7 : ℤ) = (-1) ^ 2 + 5 * 2 ^ 2 := by norm_num
-- 29 = 3^2 + 5 × 2^2, and 29 leaves 9 on division by 20.
example : (29 : ℤ) = 3 ^ 2 + 5 * 2 ^ 2 ∧ 29 % 20 = 9 := by norm_num
instance : Fact (Nat.Prime 5) := ⟨by norm_num⟩
instance : Fact (Nat.Prime 7) := ⟨by norm_num⟩
-- The genus characters at -20: (1/5) = +1 and (2/5) = -1.
example : legendreSym 5 1 = 1 ∧ legendreSym 5 2 = -1 := by norm_num
-- At -56: 23 = 3^2 + 14 × 1^2 and 79 = 2 × 6^2 + 7 × 1^2 both leave 23 on division by 56,
-- and both have (m/7) = +1.
example : (23 : ℤ) = 3 ^ 2 + 14 * 1 ^ 2 ∧ (79 : ℤ) = 2 * 6 ^ 2 + 7 * 1 ^ 2 ∧
    79 % 56 = 23 ∧ 23 % 56 = 23 := by norm_num
example : legendreSym 7 23 = 1 ∧ legendreSym 7 79 = 1 := by norm_num
-- 79 is not x^2 + 14y^2 (x^2 ≤ 79 forces x ≤ 8, and 14y^2 ≤ 79 forces y ≤ 2).
example : ∀ x < 9, ∀ y < 3, x ^ 2 + 14 * y ^ 2 ≠ 79 := by decide

#print axioms dirichlet_composition
#print axioms genus_character_constant
#print axioms prime_x_sq_add_five_y_sq_iff
