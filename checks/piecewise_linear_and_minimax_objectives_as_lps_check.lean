-- Modelling tricks: minimising the highest of several straight-line pieces over a polyhedron is the same linear program as minimising one extra number held above every piece, and the card's workshop week and five-week fits come out exactly as stated.
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Real.Archimedean
import Mathlib.Order.ConditionallyCompleteLattice.Indexed
import Mathlib.Order.Filter.Extr
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- The epigraph trick. Let the allowed plans `P` be cut out by straight-line limits
`A i ⬝ᵥ x ≤ c i`, and let the cost `F x` be the highest of `K ≥ 1` straight-line pieces
`a k ⬝ᵥ x + b k`. Add one number `z` that must sit on or above every piece, and minimise `z`.
Then the two programs have the same best value (the same lower bounds, and a least value of one
is a least value of the other), and the same best plans: `(x, z)` is best for the new program
exactly when `x` is best for the old one and `z = F x`. -/
theorem min_max_of_lines_eq_epigraph_lp {n m K : ℕ} (hK : 0 < K)
    (A : Fin m → Fin n → ℝ) (c : Fin m → ℝ) (a : Fin K → Fin n → ℝ) (b : Fin K → ℝ) :
    let P : Set (Fin n → ℝ) := {x | ∀ i, A i ⬝ᵥ x ≤ c i}
    let F : (Fin n → ℝ) → ℝ := fun x => ⨆ k, a k ⬝ᵥ x + b k
    let E : Set ((Fin n → ℝ) × ℝ) := {p | p.1 ∈ P ∧ ∀ k, a k ⬝ᵥ p.1 + b k ≤ p.2}
    lowerBounds (F '' P) = lowerBounds (Prod.snd '' E) ∧
    (∀ v, IsLeast (F '' P) v ↔ IsLeast (Prod.snd '' E) v) ∧
    (∀ x z, ((x, z) ∈ E ∧ IsMinOn Prod.snd E (x, z)) ↔ (x ∈ P ∧ IsMinOn F P x ∧ z = F x)) := by
  intro P F E
  have : Nonempty (Fin K) := ⟨⟨0, hK⟩⟩
  have hle : ∀ x k, a k ⬝ᵥ x + b k ≤ F x := fun x k =>
    le_ciSup (Set.finite_range (fun k => a k ⬝ᵥ x + b k)).bddAbove k
  have hsup : ∀ x z, (∀ k, a k ⬝ᵥ x + b k ≤ z) → F x ≤ z := fun x z h => ciSup_le h
  have hmemE : ∀ x, x ∈ P → (x, F x) ∈ E := fun x hx => ⟨hx, fun k => hle x k⟩
  have hlb : lowerBounds (F '' P) = lowerBounds (Prod.snd '' E) := by
    ext v
    constructor
    · rintro hv _ ⟨⟨x, z⟩, ⟨hx, hz⟩, rfl⟩
      exact le_trans (hv ⟨x, hx, rfl⟩) (hsup x z hz)
    · rintro hv _ ⟨x, hx, rfl⟩
      exact hv ⟨(x, F x), hmemE x hx, rfl⟩
  refine ⟨hlb, ?_, ?_⟩
  · intro v
    constructor
    · rintro ⟨⟨x, hx, rfl⟩, hv⟩
      exact ⟨⟨(x, F x), hmemE x hx, rfl⟩, hlb ▸ hv⟩
    · rintro ⟨⟨⟨x, z⟩, ⟨hx, hz⟩, rfl⟩, hv⟩
      have h1 : F x ≤ z := hsup x z hz
      have h2 : z ≤ F x := (hlb ▸ hv : z ∈ lowerBounds (Prod.snd '' E)) ⟨(x, F x), hmemE x hx, rfl⟩
      refine ⟨⟨x, hx, le_antisymm h1 h2⟩, ?_⟩
      exact hlb ▸ hv
  · intro x z
    constructor
    · rintro ⟨⟨hx, hz⟩, hmin⟩
      rw [isMinOn_iff] at hmin
      have h1 : F x ≤ z := hsup x z hz
      have h2 : z ≤ F x := hmin (x, F x) (hmemE x hx)
      have hzF : z = F x := le_antisymm h2 h1
      refine ⟨hx, ?_, hzF⟩
      rw [isMinOn_iff]
      intro y hy
      have := hmin (y, F y) (hmemE y hy)
      simp only at this
      linarith
    · rintro ⟨hx, hmin, rfl⟩
      rw [isMinOn_iff] at hmin
      refine ⟨hmemE x hx, ?_⟩
      rw [isMinOn_iff]
      rintro ⟨y, w⟩ ⟨hy, hw⟩
      exact le_trans (hmin y hy) (hsup y w hw)

/-- The workshop's week as one linear program: tables `t`, chairs `c`, overtime hours `h` and a
bill `z` held above both tier lines `2h` and `5h - 30`, with 160 m of timber, 92 regular hours
plus overtime, and 64 l of finish. The best profit `19t + 20c - z` is exactly £872, and the only
plan that earns it is 28 tables, 18 chairs and 10 overtime hours, with a bill of £20. -/
theorem workshop_best_week_is_872 :
    IsGreatest {p : ℝ | ∃ t c h z : ℝ, 0 ≤ t ∧ 0 ≤ c ∧ 0 ≤ h ∧
        4 * t + 2 * c ≤ 160 ∧ 3 * t + c ≤ 92 + h ∧ t + 2 * c ≤ 64 ∧
        2 * h ≤ z ∧ 5 * h - 30 ≤ z ∧ p = 19 * t + 20 * c - z} 872 ∧
    ∀ t c h z : ℝ, 0 ≤ t → 0 ≤ c → 0 ≤ h →
        4 * t + 2 * c ≤ 160 → 3 * t + c ≤ 92 + h → t + 2 * c ≤ 64 →
        2 * h ≤ z → 5 * h - 30 ≤ z → 19 * t + 20 * c - z = 872 →
        t = 28 ∧ c = 18 ∧ h = 10 ∧ z = 20 := by
  refine ⟨⟨⟨28, 18, 10, 20, by norm_num⟩, ?_⟩, ?_⟩
  · rintro p ⟨t, c, h, z, ht, hc, hh, h1, h2, h3, h4, h5, rfl⟩
    linarith
  · intro t c h z ht hc hh h1 h2 h3 h4 h5 h6
    refine ⟨?_, ?_, ?_, ?_⟩ <;> linarith

/-- The five past weeks (10, 30), (30, 90), (20, 80), (25, 75), (15, 46) of tables and hours.
Fitting the hours per table `a` by the total of the absolute errors gives `a = 3` and total 21,
and no other rate does as well. Fitting by the largest error (minimax) gives `a = 17/5` (3.40)
and worst error 12, and no other rate does as well. -/
theorem five_week_fits :
    IsLeast (Set.range fun a : ℝ => |30 - 10 * a| + |90 - 30 * a| + |80 - 20 * a| +
        |75 - 25 * a| + |46 - 15 * a|) 21 ∧
    (∀ a : ℝ, |30 - 10 * a| + |90 - 30 * a| + |80 - 20 * a| + |75 - 25 * a| +
        |46 - 15 * a| = 21 ↔ a = 3) ∧
    IsLeast (Set.range fun a : ℝ => max (max (max (max |30 - 10 * a| |90 - 30 * a|)
        |80 - 20 * a|) |75 - 25 * a|) |46 - 15 * a|) 12 ∧
    (∀ a : ℝ, max (max (max (max |30 - 10 * a| |90 - 30 * a|) |80 - 20 * a|)
        |75 - 25 * a|) |46 - 15 * a| = 12 ↔ a = 17 / 5) := by
  have b1 : ∀ x : ℝ, x ≤ |x| := le_abs_self
  have b2 : ∀ x : ℝ, -x ≤ |x| := neg_le_abs
  refine ⟨⟨⟨3, by norm_num⟩, ?_⟩, ?_, ⟨⟨17 / 5, by norm_num [abs_of_nonneg, abs_of_nonpos]⟩, ?_⟩, ?_⟩
  · rintro _ ⟨a, rfl⟩
    linarith [b1 (80 - 20 * a), b1 (46 - 15 * a), b2 (30 - 10 * a), b2 (75 - 25 * a),
      abs_nonneg (90 - 30 * a)]
  · intro a
    constructor
    · intro h
      refine le_antisymm ?_ ?_
      · linarith [b2 (30 - 10 * a), b2 (90 - 30 * a), b1 (80 - 20 * a), b2 (75 - 25 * a),
          b1 (46 - 15 * a)]
      · linarith [b1 (30 - 10 * a), b1 (90 - 30 * a), b1 (80 - 20 * a), b1 (75 - 25 * a),
          b1 (46 - 15 * a)]
    · rintro rfl
      norm_num [abs_of_nonneg, abs_of_nonpos]
  · rintro _ ⟨a, rfl⟩
    have hB : |90 - 30 * a| ≤ max (max (max (max |30 - 10 * a| |90 - 30 * a|)
        |80 - 20 * a|) |75 - 25 * a|) |46 - 15 * a| :=
      le_max_of_le_left (le_max_of_le_left (le_max_of_le_left (le_max_right _ _)))
    have hC : |80 - 20 * a| ≤ max (max (max (max |30 - 10 * a| |90 - 30 * a|)
        |80 - 20 * a|) |75 - 25 * a|) |46 - 15 * a| :=
      le_max_of_le_left (le_max_of_le_left (le_max_right _ _))
    linarith [b1 (80 - 20 * a), b2 (90 - 30 * a)]
  · intro a
    constructor
    · intro h
      have hB : |90 - 30 * a| ≤ max (max (max (max |30 - 10 * a| |90 - 30 * a|)
          |80 - 20 * a|) |75 - 25 * a|) |46 - 15 * a| :=
        le_max_of_le_left (le_max_of_le_left (le_max_of_le_left (le_max_right _ _)))
      have hC : |80 - 20 * a| ≤ max (max (max (max |30 - 10 * a| |90 - 30 * a|)
          |80 - 20 * a|) |75 - 25 * a|) |46 - 15 * a| :=
        le_max_of_le_left (le_max_of_le_left (le_max_right _ _))
      rw [h] at hB hC
      linarith [b1 (80 - 20 * a), b2 (90 - 30 * a)]
    · rintro rfl
      norm_num [abs_of_nonneg, abs_of_nonpos]

-- The best week: 28 tables, 18 chairs, 10 overtime hours.
example : 19 * 28 + 20 * 18 - 20 = 872 := by norm_num
example : max (2 * 10 : ℤ) (5 * 10 - 30) = 20 := by norm_num
example : 4 * 28 + 2 * 18 = 148 ∧ 3 * 28 + 18 = 102 ∧ 28 + 2 * 18 = 64 := by norm_num
-- No overtime: 24 tables, 20 chairs, labour and finish both full.
example : 3 * 24 + 20 = 92 ∧ 24 + 2 * 20 = 64 ∧ 19 * 24 + 20 * 20 = 856 := by norm_num
-- All 20 hours: 32 tables, 16 chairs, bill 2 × 10 + 5 × 10.
example : 19 * 32 + 20 * 16 - (2 * 10 + 5 * 10) = 858 := by norm_num
-- The price bound: £18/5 an hour of labour, £41/5 a litre of finish, £8/5 an hour of tier-1 cap.
example : (18 / 5 : ℚ) * 92 + 41 / 5 * 64 + 8 / 5 * 10 = 872 := by norm_num
example : (18 / 5 : ℚ) * 3 + 41 / 5 * 1 = 19 ∧ (18 / 5 : ℚ) * 1 + 41 / 5 * 2 = 20 := by norm_num
-- What breaks: falling tiers (LP 908, real 898) and the dropped tier-1 cap (LP 888).
example : 928 - 1 * 20 = 908 ∧ 928 - (2 * 10 + 1 * 10) = 898 ∧ 928 - 2 * 20 = 888 := by norm_num
-- The absolute fit at a = 3: errors 0, 0, 20, 0, 1, total 21; slopes -100 below and 30 above.
example : |(30 : ℤ) - 3 * 10| + |(90 : ℤ) - 3 * 30| + |(80 : ℤ) - 3 * 20| +
    |(75 : ℤ) - 3 * 25| + |(46 : ℤ) - 3 * 15| = 21 := by decide
example : 10 + 30 + 20 + 25 + 15 = 100 ∧ (10 + 30 + 25) - (20 + 15) = 30 := by norm_num
-- The minimax certificate: weights 3/5 and 2/5 cancel the a terms and leave 12.
example : (3 / 5 : ℚ) * 20 = 2 / 5 * 30 ∧ (3 / 5 : ℚ) * 80 - 2 / 5 * 90 = 12 := by norm_num
example : (80 : ℚ) - 17 / 5 * 20 = 12 ∧ (17 / 5 : ℚ) * 30 - 90 = 12 := by norm_num

#print axioms min_max_of_lines_eq_epigraph_lp
#print axioms workshop_best_week_is_872
#print axioms five_week_fits
