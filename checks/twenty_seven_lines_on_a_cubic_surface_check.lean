-- The 27 lines on a cubic surface: exactly 27 classes aH - b1E1 - ... - b6E6 on the plane blown up at six points have square -1 and meet the canonical class -1, each meets exactly 10 others, and the Fermat lines lie on x^3 + y^3 + z^3 + w^3 = 0.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Set.Card
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.LinearCombination


/-- The 27 line classes, written out. -/
def lineClasses : Finset (ℤ × (Fin 6 → ℤ)) :=
  {((0 : ℤ), (![-1, 0, 0, 0, 0, 0] : Fin 6 → ℤ)),
    ((0 : ℤ), (![0, -1, 0, 0, 0, 0] : Fin 6 → ℤ)),
    ((0 : ℤ), (![0, 0, -1, 0, 0, 0] : Fin 6 → ℤ)),
    ((0 : ℤ), (![0, 0, 0, -1, 0, 0] : Fin 6 → ℤ)),
    ((0 : ℤ), (![0, 0, 0, 0, -1, 0] : Fin 6 → ℤ)),
    ((0 : ℤ), (![0, 0, 0, 0, 0, -1] : Fin 6 → ℤ)),
    ((1 : ℤ), (![1, 1, 0, 0, 0, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![1, 0, 1, 0, 0, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![1, 0, 0, 1, 0, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![1, 0, 0, 0, 1, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![1, 0, 0, 0, 0, 1] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 1, 1, 0, 0, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 1, 0, 1, 0, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 1, 0, 0, 1, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 1, 0, 0, 0, 1] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 0, 1, 1, 0, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 0, 1, 0, 1, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 0, 1, 0, 0, 1] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 0, 0, 1, 1, 0] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 0, 0, 1, 0, 1] : Fin 6 → ℤ)),
    ((1 : ℤ), (![0, 0, 0, 0, 1, 1] : Fin 6 → ℤ)),
    ((2 : ℤ), (![0, 1, 1, 1, 1, 1] : Fin 6 → ℤ)),
    ((2 : ℤ), (![1, 0, 1, 1, 1, 1] : Fin 6 → ℤ)),
    ((2 : ℤ), (![1, 1, 0, 1, 1, 1] : Fin 6 → ℤ)),
    ((2 : ℤ), (![1, 1, 1, 0, 1, 1] : Fin 6 → ℤ)),
    ((2 : ℤ), (![1, 1, 1, 1, 0, 1] : Fin 6 → ℤ)),
    ((2 : ℤ), (![1, 1, 1, 1, 1, 0] : Fin 6 → ℤ))}

theorem lineClasses_card : lineClasses.card = 27 := by decide +kernel

#print axioms lineClasses_card

theorem lineClasses_sat : ∀ p ∈ lineClasses,
    p.1 ^ 2 - (p.2 0 ^ 2 + p.2 1 ^ 2 + p.2 2 ^ 2 + p.2 3 ^ 2 + p.2 4 ^ 2 + p.2 5 ^ 2) = -1 ∧ -3 * p.1 + (p.2 0 + p.2 1 + p.2 2 + p.2 3 + p.2 4 + p.2 5) = -1 := by
  decide +kernel

#print axioms lineClasses_sat

theorem lineClasses_pairs : ∀ p ∈ lineClasses, ∀ q ∈ lineClasses, q ≠ p →
    (p.1 * q.1 - (p.2 0 * q.2 0 + p.2 1 * q.2 1 + p.2 2 * q.2 2 + p.2 3 * q.2 3 + p.2 4 * q.2 4 + p.2 5 * q.2 5) = 0 ∨ p.1 * q.1 - (p.2 0 * q.2 0 + p.2 1 * q.2 1 + p.2 2 * q.2 2 + p.2 3 * q.2 3 + p.2 4 * q.2 4 + p.2 5 * q.2 5) = 1) := by
  decide +kernel

#print axioms lineClasses_pairs

theorem lineClasses_ten : ∀ p ∈ lineClasses,
    (lineClasses.filter fun q => p.1 * q.1 - (p.2 0 * q.2 0 + p.2 1 * q.2 1 + p.2 2 * q.2 2 + p.2 3 * q.2 3 + p.2 4 * q.2 4 + p.2 5 * q.2 5) = 1).card = 10 := by
  decide +kernel

#print axioms lineClasses_ten

theorem lineClasses_aux0 : ∀ x0 ∈ ({-1, 0, 1} : Finset ℤ), ∀ x1 ∈ ({-1, 0, 1} : Finset ℤ), ∀ x2 ∈ ({-1, 0, 1} : Finset ℤ), ∀ x3 ∈ ({-1, 0, 1} : Finset ℤ), ∀ x4 ∈ ({-1, 0, 1} : Finset ℤ), ∀ x5 ∈ ({-1, 0, 1} : Finset ℤ),
    (0 : ℤ) ^ 2 - (x0 ^ 2 + x1 ^ 2 + x2 ^ 2 + x3 ^ 2 + x4 ^ 2 + x5 ^ 2) = -1 → -3 * (0 : ℤ) + (x0 + x1 + x2 + x3 + x4 + x5) = -1 →
    ((0 : ℤ), (![x0, x1, x2, x3, x4, x5] : Fin 6 → ℤ)) ∈ lineClasses := by
  decide +kernel

#print axioms lineClasses_aux0

theorem lineClasses_aux1 : ∀ x0 ∈ ({0, 1} : Finset ℤ), ∀ x1 ∈ ({0, 1} : Finset ℤ), ∀ x2 ∈ ({0, 1} : Finset ℤ), ∀ x3 ∈ ({0, 1} : Finset ℤ), ∀ x4 ∈ ({0, 1} : Finset ℤ), ∀ x5 ∈ ({0, 1} : Finset ℤ),
    (1 : ℤ) ^ 2 - (x0 ^ 2 + x1 ^ 2 + x2 ^ 2 + x3 ^ 2 + x4 ^ 2 + x5 ^ 2) = -1 → -3 * (1 : ℤ) + (x0 + x1 + x2 + x3 + x4 + x5) = -1 →
    ((1 : ℤ), (![x0, x1, x2, x3, x4, x5] : Fin 6 → ℤ)) ∈ lineClasses := by
  decide +kernel

#print axioms lineClasses_aux1

theorem lineClasses_aux2 : ∀ x0 ∈ ({0, 1} : Finset ℤ), ∀ x1 ∈ ({0, 1} : Finset ℤ), ∀ x2 ∈ ({0, 1} : Finset ℤ), ∀ x3 ∈ ({0, 1} : Finset ℤ), ∀ x4 ∈ ({0, 1} : Finset ℤ), ∀ x5 ∈ ({0, 1} : Finset ℤ),
    (2 : ℤ) ^ 2 - (x0 ^ 2 + x1 ^ 2 + x2 ^ 2 + x3 ^ 2 + x4 ^ 2 + x5 ^ 2) = -1 → -3 * (2 : ℤ) + (x0 + x1 + x2 + x3 + x4 + x5) = -1 →
    ((2 : ℤ), (![x0, x1, x2, x3, x4, x5] : Fin 6 → ℤ)) ∈ lineClasses := by
  decide +kernel

#print axioms lineClasses_aux2

theorem lineClasses_classify (p : ℤ × (Fin 6 → ℤ))
    (hp : p.1 ^ 2 - ∑ i, (p.2 i) ^ 2 = -1 ∧ -3 * p.1 + ∑ i, p.2 i = -1) :
    p ∈ lineClasses := by
  obtain ⟨a, b⟩ := p
  have hb : b = ![b 0, b 1, b 2, b 3, b 4, b 5] := by
    ext i; fin_cases i <;> rfl
  simp only [Fin.sum_univ_six] at hp
  obtain ⟨h1, h2⟩ := hp
  rw [hb]
  clear hb
  generalize b 0 = x0 at *
  generalize b 1 = x1 at *
  generalize b 2 = x2 at *
  generalize b 3 = x3 at *
  generalize b 4 = x4 at *
  generalize b 5 = x5 at *
  have key : 6 * (x0 ^ 2 + x1 ^ 2 + x2 ^ 2 + x3 ^ 2 + x4 ^ 2 + x5 ^ 2) -
      (x0 + x1 + x2 + x3 + x4 + x5) ^ 2 =
      (x0 - x1) ^ 2 + (x0 - x2) ^ 2 + (x0 - x3) ^ 2 + (x0 - x4) ^ 2 + (x0 - x5) ^ 2 +
      (x1 - x2) ^ 2 + (x1 - x3) ^ 2 + (x1 - x4) ^ 2 + (x1 - x5) ^ 2 + (x2 - x3) ^ 2 +
      (x2 - x4) ^ 2 + (x2 - x5) ^ 2 + (x3 - x4) ^ 2 + (x3 - x5) ^ 2 + (x4 - x5) ^ 2 := by ring
  have e1 : x0 ^ 2 + x1 ^ 2 + x2 ^ 2 + x3 ^ 2 + x4 ^ 2 + x5 ^ 2 = a ^ 2 + 1 := by linarith
  have e2 : x0 + x1 + x2 + x3 + x4 + x5 = 3 * a - 1 := by linarith
  have hcs : (3 * a - 1) ^ 2 ≤ 6 * (a ^ 2 + 1) := by
    rw [← e1, ← e2]
    have := sq_nonneg (x0 - x1); have := sq_nonneg (x0 - x2); have := sq_nonneg (x0 - x3)
    have := sq_nonneg (x0 - x4); have := sq_nonneg (x0 - x5); have := sq_nonneg (x1 - x2)
    have := sq_nonneg (x1 - x3); have := sq_nonneg (x1 - x4); have := sq_nonneg (x1 - x5)
    have := sq_nonneg (x2 - x3); have := sq_nonneg (x2 - x4); have := sq_nonneg (x2 - x5)
    have := sq_nonneg (x3 - x4); have := sq_nonneg (x3 - x5); have := sq_nonneg (x4 - x5)
    linarith
  clear key e1 e2
  have ha0 : 0 ≤ a := by nlinarith
  have ha2 : a ≤ 2 := by nlinarith
  have hq : ∀ x : ℤ, 0 ≤ x ^ 2 - x := fun x => by
    rcases le_or_gt x 0 with h | h <;> nlinarith
  have h01 : ∀ x : ℤ, x ^ 2 - x ≤ 0 → x ∈ ({0, 1} : Finset ℤ) := fun x hx => by
    have : 0 ≤ x := by nlinarith
    have : x ≤ 1 := by nlinarith
    simp only [Finset.mem_insert, Finset.mem_singleton]; omega
  have hm1 : ∀ x : ℤ, x ^ 2 ≤ 1 → x ∈ ({-1, 0, 1} : Finset ℤ) := fun x hx => by
    have : -1 ≤ x := by nlinarith
    have : x ≤ 1 := by nlinarith
    simp only [Finset.mem_insert, Finset.mem_singleton]; omega
  have q0 := hq x0; have q1 := hq x1; have q2 := hq x2
  have q3 := hq x3; have q4 := hq x4; have q5 := hq x5
  have s0 := sq_nonneg x0; have s1 := sq_nonneg x1; have s2 := sq_nonneg x2
  have s3 := sq_nonneg x3; have s4 := sq_nonneg x4; have s5 := sq_nonneg x5
  interval_cases a
  · exact lineClasses_aux0 x0 (hm1 _ (by linarith)) x1 (hm1 _ (by linarith))
      x2 (hm1 _ (by linarith)) x3 (hm1 _ (by linarith)) x4 (hm1 _ (by linarith))
      x5 (hm1 _ (by linarith)) h1 h2
  · exact lineClasses_aux1 x0 (h01 _ (by linarith)) x1 (h01 _ (by linarith))
      x2 (h01 _ (by linarith)) x3 (h01 _ (by linarith)) x4 (h01 _ (by linarith))
      x5 (h01 _ (by linarith)) h1 h2
  · exact lineClasses_aux2 x0 (h01 _ (by linarith)) x1 (h01 _ (by linarith))
      x2 (h01 _ (by linarith)) x3 (h01 _ (by linarith)) x4 (h01 _ (by linarith))
      x5 (h01 _ (by linarith)) h1 h2

#print axioms lineClasses_classify

theorem lineClasses_iff (p : ℤ × (Fin 6 → ℤ)) :
    (p.1 ^ 2 - ∑ i, (p.2 i) ^ 2 = -1 ∧ -3 * p.1 + ∑ i, p.2 i = -1) ↔ p ∈ lineClasses := by
  refine ⟨lineClasses_classify p, fun h => ?_⟩
  simp only [Fin.sum_univ_six]
  exact lineClasses_sat p h

#print axioms lineClasses_iff

/-- On the plane blown up at six points, write a curve class as
`D = aH - b₁E₁ - ... - b₆E₆` with whole numbers `a, bᵢ`, where `H² = 1`, `Eᵢ² = -1`
and all other products are 0, and `K = -3H + E₁ + ... + E₆`. Then `D² = a² - ∑ bᵢ²`
and `K · D = -3a + ∑ bᵢ`. Exactly 27 classes solve `D² = -1` and `K · D = -1`:
the 6 exceptional curves, the 15 lines through two points and the 6 conics through five. -/
theorem twenty_seven_line_classes :
    {p : ℤ × (Fin 6 → ℤ) |
        p.1 ^ 2 - ∑ i, (p.2 i) ^ 2 = -1 ∧ -3 * p.1 + ∑ i, p.2 i = -1}.ncard = 27 := by
  have h : {p : ℤ × (Fin 6 → ℤ) |
      p.1 ^ 2 - ∑ i, (p.2 i) ^ 2 = -1 ∧ -3 * p.1 + ∑ i, p.2 i = -1} = ↑lineClasses := by
    ext p
    exact lineClasses_iff p
  rw [h, Set.ncard_coe_finset, lineClasses_card]

/-- Each of the 27 line classes `D` meets exactly 10 of the others: two different line
classes have intersection number `D · D' = a a' - ∑ bᵢ b'ᵢ` equal to 0 or 1, and exactly
10 of the 27 classes have intersection number 1 with `D`. -/
theorem each_line_class_meets_exactly_ten (p : ℤ × (Fin 6 → ℤ))
    (hp : p.1 ^ 2 - ∑ i, (p.2 i) ^ 2 = -1 ∧ -3 * p.1 + ∑ i, p.2 i = -1) :
    (∀ q : ℤ × (Fin 6 → ℤ),
        (q.1 ^ 2 - ∑ i, (q.2 i) ^ 2 = -1 ∧ -3 * q.1 + ∑ i, q.2 i = -1) → q ≠ p →
        (p.1 * q.1 - ∑ i, p.2 i * q.2 i = 0 ∨ p.1 * q.1 - ∑ i, p.2 i * q.2 i = 1)) ∧
    {q : ℤ × (Fin 6 → ℤ) |
        (q.1 ^ 2 - ∑ i, (q.2 i) ^ 2 = -1 ∧ -3 * q.1 + ∑ i, q.2 i = -1) ∧
        p.1 * q.1 - ∑ i, p.2 i * q.2 i = 1}.ncard = 10 := by
  have hp' : p ∈ lineClasses := (lineClasses_iff p).1 hp
  refine ⟨fun q hq hqp => ?_, ?_⟩
  · have hq' : q ∈ lineClasses := (lineClasses_iff q).1 hq
    simp only [Fin.sum_univ_six]
    exact lineClasses_pairs p hp' q hq' hqp
  · have h : {q : ℤ × (Fin 6 → ℤ) |
        (q.1 ^ 2 - ∑ i, (q.2 i) ^ 2 = -1 ∧ -3 * q.1 + ∑ i, q.2 i = -1) ∧
        p.1 * q.1 - ∑ i, p.2 i * q.2 i = 1} =
        ↑(lineClasses.filter fun q => p.1 * q.1 - (p.2 0 * q.2 0 + p.2 1 * q.2 1 + p.2 2 * q.2 2 +
          p.2 3 * q.2 3 + p.2 4 * q.2 4 + p.2 5 * q.2 5) = 1) := by
      ext q
      simp only [Finset.coe_filter, Set.mem_ofPred_eq]
      rw [lineClasses_iff, Fin.sum_univ_six]
    rw [h, Set.ncard_coe_finset]
    exact lineClasses_ten p hp'

/-- The Fermat lines lie on the Fermat cubic: split the four coordinates into two pairs
`{x_{σ0}, x_{σ1}}`, `{x_{σ2}, x_{σ3}}` (any ordering `σ`), and pick cube roots of 1,
`ζ³ = 1` and `ζ'³ = 1`. Every point with `x_{σ0} = -ζ x_{σ1}` and `x_{σ2} = -ζ' x_{σ3}`
satisfies `x₀³ + x₁³ + x₂³ + x₃³ = 0`. -/
theorem fermat_lines_lie_on_fermat_cubic {R : Type*} [CommRing R]
    (σ : Equiv.Perm (Fin 4)) (ζ ζ' : R) (hζ : ζ ^ 3 = 1) (hζ' : ζ' ^ 3 = 1)
    (x : Fin 4 → R) (h01 : x (σ 0) = -ζ * x (σ 1)) (h23 : x (σ 2) = -ζ' * x (σ 3)) :
    ∑ i, x i ^ 3 = 0 := by
  have hs : ∑ i, x i ^ 3 = ∑ i, x (σ i) ^ 3 := (Equiv.sum_comp σ (fun i => x i ^ 3)).symm
  rw [hs, Fin.sum_univ_four, h01, h23]
  linear_combination (-(x (σ 1)) ^ 3) * hζ + (-(x (σ 3)) ^ 3) * hζ'

-- 6 exceptional curves + 15 lines through two points + 6 conics through five points = 27.
example : 6 + Nat.choose 6 2 + 6 = 27 := by decide

-- 3 pairings of the coordinates, 3 × 3 choices of cube roots each: 27 Fermat lines.
example : 3 * (3 * 3) = 27 := by decide

-- K = -3H + E₁ + ... + E₆ has K² = 9 - 6 = 3, the degree of the cubic.
example : (-3 : ℤ) ^ 2 - 6 * 1 ^ 2 = 3 := by norm_num

-- L₁₂ = H - E₁ - E₂, that is a = 1, b = (1, 1, 0, 0, 0, 0): square -1 and K · L₁₂ = -1.
example : (1 : ℤ) ^ 2 - (1 ^ 2 + 1 ^ 2) = -1 ∧ -3 * (1 : ℤ) + (1 + 1) = -1 := by norm_num

-- C₁ = 2H - (E₂ + ... + E₆), that is a = 2, b = (0, 1, 1, 1, 1, 1): square -1 and K · C₁ = -1.
example : (2 : ℤ) ^ 2 - 5 = -1 ∧ -3 * (2 : ℤ) + 5 = -1 := by norm_num

-- Cauchy-Schwarz step: (3a - 1)² ≤ 6(a² + 1) leaves only a = 0, 1, 2.
example (a : ℤ) (h : (3 * a - 1) ^ 2 ≤ 6 * (a ^ 2 + 1)) : a = 0 ∨ a = 1 ∨ a = 2 := by
  have h1 : a ≥ 0 := by nlinarith
  have h2 : a ≤ 2 := by nlinarith
  omega

-- p₁, p₂, p₃ on a line: H - E₁ - E₂ - E₃ has square 1 - 3 = -2.
example : (1 : ℤ) ^ 2 - 3 = -2 := by norm_num

-- Plane cubics have 10 coefficients; through six points, 10 - 6 = 4 coordinates of P³.
example : Nat.choose (3 + 2) 2 - 6 = 4 := by decide

-- Mod 7, ω ↦ 2 is a cube root of 1 (2² + 2 + 1 = 7), so x = -2y kills x³ + y³ in 𝔽₇.
example : (2 : ZMod 7) ^ 3 = 1 ∧ ∀ y : ZMod 7, (-2 * y) ^ 3 + y ^ 3 = 0 := by decide

#print axioms twenty_seven_line_classes
#print axioms each_line_class_meets_exactly_ten
#print axioms fermat_lines_lie_on_fermat_cubic
