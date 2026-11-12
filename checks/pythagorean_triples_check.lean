-- Pythagorean triples: three positive whole numbers form a triple exactly when they come from two seeds, bigger first, coprime and one odd one even, through the recipe (difference of squares, twice the product, sum of squares) scaled up by a whole number; the recipe always gives a triple for any seeds with the bigger first; and every triple has an even leg.
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.PythagoreanTriples

/-! Sides and seeds are whole numbers (`ℕ`). The seeds are `m` (the bigger) and `n` (the
smaller). The recipe's three sides are `m * m - n * n` (the odd leg), `2 * m * n` (the even leg)
and `m * m + n * n` (the long side). A triple is `a`, `b`, `c` with `a * a + b * b = c * c`,
where `a` and `b` are the legs, in either order. -/

theorem recipe_gives_triple_aux (m n : ℕ) (h : n < m) :
    (m * m - n * n) * (m * m - n * n) + (2 * m * n) * (2 * m * n) =
      (m * m + n * n) * (m * m + n * n) := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_lt h
  have e : (n + d + 1) * (n + d + 1) - n * n = (d + 1) * (d + 1) + 2 * n * (d + 1) := by
    apply Nat.sub_eq_of_eq_add
    ring
  rw [e]
  ring

#print axioms recipe_gives_triple_aux

theorem triple_has_even_leg_aux (a b c : ℕ) (h : a * a + b * b = c * c) : Even a ∨ Even b := by
  by_contra hc
  simp only [not_or, Nat.not_even_iff_odd] at hc
  obtain ⟨⟨x, hx⟩, ⟨y, hy⟩⟩ := hc
  subst hx hy
  have h4 := congrArg (· % 4) h
  have : c % 4 = 0 ∨ c % 4 = 1 ∨ c % 4 = 2 ∨ c % 4 = 3 := by omega
  have e1 : (2 * x + 1) * (2 * x + 1) + (2 * y + 1) * (2 * y + 1) = 4 * (x*x + x + y*y + y) + 2 := by ring
  rw [e1] at h4
  have hm := Nat.mul_mod c c 4
  rcases this with h0 | h0 | h0 | h0 <;> rw [h0] at hm <;> omega

#print axioms triple_has_even_leg_aux

theorem prim_aux (a b c : ℕ) (ha : 0 < a) (hb : 0 < b) (hco : Nat.Coprime a b) (hodd : a % 2 = 1)
    (h : a * a + b * b = c * c) :
    ∃ m n : ℕ, 0 < n ∧ n < m ∧ Nat.Coprime m n ∧ ((Odd m ∧ Even n) ∨ (Even m ∧ Odd n)) ∧
      a = m * m - n * n ∧ b = 2 * m * n ∧ c = m * m + n * n := by
  have hT : PythagoreanTriple (a : ℤ) (b : ℤ) (c : ℤ) := by
    unfold PythagoreanTriple; exact_mod_cast h
  have hg : Int.gcd (a : ℤ) (b : ℤ) = 1 := by simpa using hco
  have hc : (0 : ℤ) < c := by
    have : 0 < c * c := by rw [← h]; positivity
    have : 0 < c := Nat.pos_of_mul_pos_left this  
    exact_mod_cast this
  obtain ⟨m, n, h1, h2, h3, h4, h5, h6⟩ :=
    hT.coprime_classification' hg (by omega) hc
  have hbpos : (0 : ℤ) < b := by exact_mod_cast hb
  have hn : 0 ≤ n := by
    by_contra hneg
    simp only [not_le] at hneg
    have : m * n ≤ 0 := mul_nonpos_of_nonneg_of_nonpos h6 hneg.le
    nlinarith
  lift m to ℕ using h6
  lift n to ℕ using hn
  have hpa : a = m * m - n * n := by
    have : (a : ℤ) = (m : ℤ) * m - n * n := by rw [h1]; ring
    have h' : n * n ≤ m * m := by
      have : (0 : ℤ) < a := by exact_mod_cast ha
      have : ((n * n : ℕ) : ℤ) ≤ ((m * m : ℕ) : ℤ) := by push_cast; nlinarith
      exact_mod_cast this
    omega
  have hpb : b = 2 * m * n := by
    have : (b : ℤ) = 2 * m * n := h2
    exact_mod_cast this
  have hpc : c = m * m + n * n := by
    have : (c : ℤ) = m * m + n * n := by rw [h3]; ring
    exact_mod_cast this
  have hN0 : 0 < n := by
    rcases Nat.eq_zero_or_pos n with h0 | h0
    · rw [h0] at hpb; simp at hpb; omega
    · exact h0
  have hNM : n < m := by
    by_contra hh
    simp only [not_lt] at hh
    have : m * m ≤ n * n := Nat.mul_le_mul hh hh
    omega
  refine ⟨m, n, hN0, hNM, ?_, ?_, hpa, hpb, hpc⟩
  · exact h4
  · simp only [Nat.odd_iff, Nat.even_iff]; omega

#print axioms prim_aux

/-- The card's main claim. Three positive whole numbers `a`, `b`, `c` with
`a * a + b * b = c * c` (the two legs of a whole-number right triangle and its long side) are a
triple exactly when they come out of the recipe, scaled up if need be: there are seeds `m` and
`n`, bigger first, sharing no factor but 1, one odd and one even, and a whole number `k ≥ 1`
such that the legs are `k` times `m * m - n * n` and `k` times `2 * m * n` (in either order) and
the long side is `k` times `m * m + n * n`. -/
theorem pythagorean_triple_iff_scaled_recipe (a b c : ℕ) (ha : 0 < a) (hb : 0 < b) :
    a * a + b * b = c * c ↔
      ∃ k m n : ℕ, 0 < k ∧ 0 < n ∧ n < m ∧ Nat.Coprime m n ∧
        ((Odd m ∧ Even n) ∨ (Even m ∧ Odd n)) ∧
        ((a = k * (m * m - n * n) ∧ b = k * (2 * m * n)) ∨
          (a = k * (2 * m * n) ∧ b = k * (m * m - n * n))) ∧
        c = k * (m * m + n * n) := by
  constructor
  · intro h
    set g := Nat.gcd a b with hg
    have hgpos : 0 < g := Nat.gcd_pos_of_pos_left b ha
    obtain ⟨a', ha'⟩ : g ∣ a := Nat.gcd_dvd_left a b
    obtain ⟨b', hb'⟩ : g ∣ b := Nat.gcd_dvd_right a b
    have hco : Nat.Coprime a' b' := by
      have := Nat.coprime_div_gcd_div_gcd (m := a) (n := b) hgpos
      have e1 : a / g = a' := by rw [ha']; exact Nat.mul_div_cancel_left a' hgpos
      have e2 : b / g = b' := by rw [hb']; exact Nat.mul_div_cancel_left b' hgpos
      rwa [e1, e2] at this
    have ha'pos : 0 < a' := by
      rcases Nat.eq_zero_or_pos a' with h0 | h0
      · rw [h0] at ha'; omega
      · exact h0
    have hb'pos : 0 < b' := by
      rcases Nat.eq_zero_or_pos b' with h0 | h0
      · rw [h0] at hb'; omega
      · exact h0
    have hcc : c * c = (g * g) * (a' * a' + b' * b') := by
      rw [← h, ha', hb']; ring
    have hdvd : g ∣ c := by
      have h1 : g ^ 2 ∣ c ^ 2 := ⟨a' * a' + b' * b', by rw [sq, sq, hcc]⟩
      exact (Nat.pow_dvd_pow_iff (by norm_num)).mp h1
    obtain ⟨c', hc'⟩ := hdvd
    have hsum : a' * a' + b' * b' = c' * c' := by
      have : (g * g) * (a' * a' + b' * b') = (g * g) * (c' * c') := by
        rw [← hcc, hc']; ring
      exact Nat.eq_of_mul_eq_mul_left (Nat.mul_pos hgpos hgpos) this
    have heven := triple_has_even_leg_aux a' b' c' hsum
    have hnotboth : ¬ (Even a' ∧ Even b') := by
      rintro ⟨⟨x, hx⟩, ⟨y, hy⟩⟩
      have h2 : 2 ∣ Nat.gcd a' b' := Nat.dvd_gcd ⟨x, by omega⟩ ⟨y, by omega⟩
      rw [hco] at h2
      omega
    rcases Nat.even_or_odd a' with hae | hao
    · have hbo : b' % 2 = 1 := by
        rcases Nat.even_or_odd b' with hbe | hbo
        · exact absurd ⟨hae, hbe⟩ hnotboth
        · exact Nat.odd_iff.mp hbo
      obtain ⟨m, n, hn, hnm, hmn, hpar, e1, e2, e3⟩ :=
        prim_aux b' a' c' hb'pos ha'pos hco.symm hbo (by rw [← hsum]; ring)
      refine ⟨g, m, n, hgpos, hn, hnm, hmn, hpar, Or.inr ⟨?_, ?_⟩, ?_⟩
      · rw [ha', e2]
      · rw [hb', e1]
      · rw [hc', e3]
    · have hao' : a' % 2 = 1 := Nat.odd_iff.mp hao
      obtain ⟨m, n, hn, hnm, hmn, hpar, e1, e2, e3⟩ :=
        prim_aux a' b' c' ha'pos hb'pos hco hao' hsum
      refine ⟨g, m, n, hgpos, hn, hnm, hmn, hpar, Or.inl ⟨?_, ?_⟩, ?_⟩
      · rw [ha', e1]
      · rw [hb', e2]
      · rw [hc', e3]
  · rintro ⟨k, m, n, hk, hn, hnm, hmn, hpar, hab, hc⟩
    have key := recipe_gives_triple_aux m n hnm
    generalize m * m - n * n = X at *
    generalize 2 * m * n = Y at *
    generalize m * m + n * n = Z at *
    subst hc
    rcases hab with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · calc k * X * (k * X) + k * Y * (k * Y) = k * k * (X * X + Y * Y) := by ring
        _ = k * k * (Z * Z) := by rw [key]
        _ = k * Z * (k * Z) := by ring
    · calc k * Y * (k * Y) + k * X * (k * X) = k * k * (X * X + Y * Y) := by ring
        _ = k * k * (Z * Z) := by rw [key]
        _ = k * Z * (k * Z) := by ring

/-- The recipe always gives a triple. Pick any two whole numbers, bigger first. The difference
of their squares, twice their product, and the sum of their squares pass the test: the first
two, each multiplied by itself, add to the third multiplied by itself. -/
theorem recipe_gives_triple (m n : ℕ) (h : n < m) :
    (m * m - n * n) * (m * m - n * n) + (2 * m * n) * (2 * m * n) =
      (m * m + n * n) * (m * m + n * n) := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_lt h
  have e : (n + d + 1) * (n + d + 1) - n * n = (d + 1) * (d + 1) + 2 * n * (d + 1) := by
    apply Nat.sub_eq_of_eq_add
    ring
  rw [e]
  ring

/-- One leg is always even: no triple has two odd legs. -/
theorem triple_has_even_leg (a b c : ℕ) (h : a * a + b * b = c * c) : Even a ∨ Even b := by
  by_contra hc
  simp only [not_or, Nat.not_even_iff_odd] at hc
  obtain ⟨⟨x, hx⟩, ⟨y, hy⟩⟩ := hc
  subst hx hy
  have h4 := congrArg (· % 4) h
  have : c % 4 = 0 ∨ c % 4 = 1 ∨ c % 4 = 2 ∨ c % 4 = 3 := by omega
  have e1 : (2 * x + 1) * (2 * x + 1) + (2 * y + 1) * (2 * y + 1) = 4 * (x*x + x + y*y + y) + 2 := by ring
  rw [e1] at h4
  have hm := Nat.mul_mod c c 4
  rcases this with h0 | h0 | h0 | h0 <;> rw [h0] at hm <;> omega

-- The rope: 3 × 3 + 4 × 4 = 9 + 16 = 25 = 5 × 5.
example : 3 * 3 = 9 ∧ 4 * 4 = 16 ∧ 9 + 16 = 25 ∧ 5 * 5 = 25 := by decide
example : 3 * 3 + 4 * 4 = 5 * 5 := by decide
-- Seeds 3 and 2: 9 − 4 = 5, 2 × 3 × 2 = 12, 9 + 4 = 13.
example : 3 * 3 - 2 * 2 = 5 ∧ 2 * 3 * 2 = 12 ∧ 3 * 3 + 2 * 2 = 13 := by decide
-- The check: 5 × 5 + 12 × 12 = 25 + 144 = 169 = 13 × 13.
example : 5 * 5 = 25 ∧ 12 * 12 = 144 ∧ 25 + 144 = 169 ∧ 13 * 13 = 169 := by decide
example : 5 * 5 + 12 * 12 = 13 * 13 := by decide
-- Seeds 4 and 1: 2 × 4 × 1 = 8, 16 − 1 = 15, 16 + 1 = 17, and 64 + 225 = 289 = 17 × 17.
example : 2 * 4 * 1 = 8 ∧ 4 * 4 - 1 * 1 = 15 ∧ 4 * 4 + 1 * 1 = 17 := by decide
example : 8 * 8 + 15 * 15 = 17 * 17 ∧ 64 + 225 = 289 := by decide
-- Seeds 2 and 1 give the rope: 3, 4, 5.
example : 2 * 2 - 1 * 1 = 3 ∧ 2 * 2 * 1 = 4 ∧ 2 * 2 + 1 * 1 = 5 := by decide
-- Step 2: 169 − 25 = 144, and (13 + 5) × (13 − 5) = 18 × 8 = 144 = 12 × 12.
example : 169 - 25 = 144 ∧ (13 + 5) * (13 - 5) = 18 * 8 ∧ 18 * 8 = 144 ∧ 12 * 12 = 144 := by
  decide
-- In seeds: 18 = 2 × 9 and 8 = 2 × 4, and 18 × 8 = 4 × (9 × 4).
example : 3 * 3 + 2 * 2 + (3 * 3 - 2 * 2) = 2 * 9 ∧
    3 * 3 + 2 * 2 - (3 * 3 - 2 * 2) = 2 * 4 ∧ 18 * 8 = 4 * (9 * 4) := by decide
-- Step 3: odd squares 9 and 25 sit one above a multiple of 4.
example : 9 % 4 = 1 ∧ 25 % 4 = 1 := by decide
-- Step 4: halves 9 and 4 share no factor but 1, multiply to 6 × 6, and are 3 × 3 and 2 × 2.
example : Nat.Coprime 9 4 ∧ 9 * 4 = 6 * 6 ∧ 9 = 3 * 3 ∧ 4 = 2 * 2 := by decide
-- Missing legs by counting up: 5 and 13 need 12; 8 and 17 need 15.
example : 5 * 5 + 12 * 12 = 13 * 13 ∧ 8 * 8 + 15 * 15 = 17 * 17 := by decide
-- Seeds 3 and 1, both odd: 6, 8, 10, shared factor 2, the rope doubled.
example : 2 * 3 * 1 = 6 ∧ 3 * 3 - 1 * 1 = 8 ∧ 3 * 3 + 1 * 1 = 10 := by decide
example : Nat.gcd (Nat.gcd 6 8) 10 = 2 ∧ 6 = 2 * 3 ∧ 8 = 2 * 4 ∧ 10 = 2 * 5 := by decide
-- Seeds 6 and 3: 27, 36, 45, the rope times 9.
example : 6 * 6 - 3 * 3 = 27 ∧ 2 * 6 * 3 = 36 ∧ 6 * 6 + 3 * 3 = 45 ∧
    27 = 9 * 3 ∧ 36 = 9 * 4 ∧ 45 = 9 * 5 := by decide
-- Smaller seed first, 2 and 3: a leg comes out at −5.
example : (2 * 2 - 3 * 3 : ℤ) = -5 := by norm_num
-- Adding the sides, not the squares: 3 + 4 = 7, not 5.
example : 3 + 4 = 7 ∧ 3 + 4 ≠ 5 := by decide
-- Try changing: seeds 5 and 2 give 21, 20, 29.
example : 5 * 5 - 2 * 2 = 21 ∧ 2 * 5 * 2 = 20 ∧ 5 * 5 + 2 * 2 = 29 ∧
    21 * 21 + 20 * 20 = 29 * 29 := by decide
-- Break the recipe: dropping the 2 gives 5, 6, 13, which is not a triple.
example : 3 * 2 = 6 ∧ 5 * 5 + 6 * 6 ≠ 13 * 13 := by decide
-- The Plimpton tablet's 45, 60, 75: the rope times 15.
example : 45 * 45 + 60 * 60 = 75 * 75 ∧ 45 = 15 * 3 ∧ 60 = 15 * 4 ∧ 75 = 15 * 5 := by decide

#print axioms pythagorean_triple_iff_scaled_recipe
#print axioms recipe_gives_triple
#print axioms triple_has_even_leg
