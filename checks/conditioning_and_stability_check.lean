-- Conditioning and stability: for two roads that cross, a method whose answer is exact for data off by a small relative amount δ is off by at most about κδ in relative terms, κ is the worst such ratio, the crossing formula is backward stable, and the card's fork numbers check out.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.GCongr

/-! Road 1 is `y = m₁ x + c₁` and road 2 is `y = m₂ x + c₂`, with slopes `m₁, m₂` and
intercepts `c₁, c₂`. A datum `d` "off by a relative amount `e`" is `d * (1 + e)`. -/

/-- The east coordinate where the two roads cross: `x = (c₂ − c₁) / (m₁ − m₂)`, the gap at the
start divided by how fast the gap closes. -/
noncomputable def crossing (m₁ c₁ m₂ c₂ : ℝ) : ℝ := (c₂ - c₁) / (m₁ - m₂)

/-- The card's relative condition number of the crossing:
`κ = (|m₁| + |m₂|) / |m₁ − m₂| + (|c₁| + |c₂|) / |c₂ − c₁|`. -/
noncomputable def kappa (m₁ c₁ m₂ c₂ : ℝ) : ℝ :=
  (|m₁| + |m₂|) / |m₁ - m₂| + (|c₁| + |c₂|) / |c₂ - c₁|

/-- Helper. -/
theorem abs_mul_sub_mul_le (a b e f δ : ℝ) (he : |e| ≤ δ) (hf : |f| ≤ δ) :
    |a * e - b * f| ≤ (|a| + |b|) * δ := by
  calc |a * e - b * f| ≤ |a * e| + |b * f| := abs_sub _ _
    _ = |a| * |e| + |b| * |f| := by rw [abs_mul, abs_mul]
    _ ≤ |a| * δ + |b| * δ := by gcongr
    _ = (|a| + |b|) * δ := by ring

#print axioms abs_mul_sub_mul_le

/-- Helper. -/
theorem exists_unit_mul_eq_abs (c : ℝ) : ∃ s : ℝ, (s = 1 ∨ s = -1) ∧ c * s = |c| := by
  rcases le_or_gt 0 c with h | h
  · exact ⟨1, Or.inl rfl, by rw [abs_of_nonneg h]; ring⟩
  · exact ⟨-1, Or.inr rfl, by rw [abs_of_neg h]; ring⟩

#print axioms exists_unit_mul_eq_abs

/-- Helper. -/
theorem unit_abs_le_one {s : ℝ} (h : s = 1 ∨ s = -1) : |s| ≤ 1 := by
  rcases h with rfl | rfl <;> norm_num

#print axioms unit_abs_le_one

/-- Helper. -/
theorem unit_mul_unit {s r : ℝ} (hs : s = 1 ∨ s = -1) (hr : r = 1 ∨ r = -1) :
    s * r = 1 ∨ s * r = -1 := by
  rcases hs with rfl | rfl <;> rcases hr with rfl | rfl <;> norm_num

#print axioms unit_mul_unit

/-- Helper. -/
theorem crossing_hasDerivAt_line (m₁ c₁ m₂ c₂ s₁ s₂ s₃ s₄ : ℝ) (hm : m₁ ≠ m₂) :
    HasDerivAt
      (fun t : ℝ => crossing (m₁ * (1 + t * s₁)) (c₁ * (1 + t * s₂))
        (m₂ * (1 + t * s₃)) (c₂ * (1 + t * s₄)))
      (((c₂ * s₄ - c₁ * s₂) * (m₁ - m₂) - (c₂ - c₁) * (m₁ * s₁ - m₂ * s₃)) / (m₁ - m₂) ^ 2) 0 := by
  have hD : m₁ - m₂ ≠ 0 := sub_ne_zero.mpr hm
  have hn : HasDerivAt (fun t : ℝ => c₂ * (1 + t * s₄) - c₁ * (1 + t * s₂))
      (c₂ * s₄ - c₁ * s₂) 0 := by
    have := (((hasDerivAt_id' (0:ℝ)).mul_const s₄).const_add 1).const_mul c₂ |>.sub
      ((((hasDerivAt_id' (0:ℝ)).mul_const s₂).const_add 1).const_mul c₁)
    convert this using 1; ring
  have hd : HasDerivAt (fun t : ℝ => m₁ * (1 + t * s₁) - m₂ * (1 + t * s₃))
      (m₁ * s₁ - m₂ * s₃) 0 := by
    have := (((hasDerivAt_id' (0:ℝ)).mul_const s₁).const_add 1).const_mul m₁ |>.sub
      ((((hasDerivAt_id' (0:ℝ)).mul_const s₃).const_add 1).const_mul m₂)
    convert this using 1; ring
  have := hn.div hd (by simpa using hD)
  unfold crossing
  convert this using 1
  simp

#print axioms crossing_hasDerivAt_line

/-- **A stable method's relative error is at most about κ times its data error.** Take two roads
that really cross (the slopes differ, so the data are not at a breakdown) at a crossing that is not
zero (the intercepts differ). Suppose a method is stable: its answer `x̂` (`xhat`) is the exact crossing for
data each off by a relative amount at most `δ`. Then, to first order in `δ`, the relative error of
`x̂` is at most `κ δ`: for every margin `ε > 0` there is a size `δ₀ > 0` of data error below which
`|x̂ − x| ≤ (κ + ε) δ |x|`. -/
theorem stable_crossing_rel_error_le_kappa_mul_delta
    (m₁ c₁ m₂ c₂ : ℝ) (hm : m₁ ≠ m₂) (hc : c₁ ≠ c₂) :
    ∀ ε > 0, ∃ δ₀ > 0, ∀ δ : ℝ, 0 ≤ δ → δ < δ₀ → ∀ xhat : ℝ,
      (∃ e₁ e₂ e₃ e₄ : ℝ, |e₁| ≤ δ ∧ |e₂| ≤ δ ∧ |e₃| ≤ δ ∧ |e₄| ≤ δ ∧
        xhat = crossing (m₁ * (1 + e₁)) (c₁ * (1 + e₂)) (m₂ * (1 + e₃)) (c₂ * (1 + e₄))) →
      |xhat - crossing m₁ c₁ m₂ c₂| ≤
        (kappa m₁ c₁ m₂ c₂ + ε) * δ * |crossing m₁ c₁ m₂ c₂| := by
  intro ε hε
  have hD0 : m₁ - m₂ ≠ 0 := sub_ne_zero.mpr hm
  have hN0 : c₂ - c₁ ≠ 0 := sub_ne_zero.mpr (Ne.symm hc)
  have hD : 0 < |m₁ - m₂| := abs_pos.mpr hD0
  have hN : 0 < |c₂ - c₁| := abs_pos.mpr hN0
  obtain ⟨A, hAdef⟩ : ∃ A, A = |c₁| + |c₂| := ⟨_, rfl⟩
  obtain ⟨B, hBdef⟩ : ∃ B, B = |m₁| + |m₂| := ⟨_, rfl⟩
  have hA : 0 ≤ A := by rw [hAdef]; positivity
  have hB : 0 ≤ B := by rw [hBdef]; positivity
  obtain ⟨S, hSdef⟩ : ∃ S, S = A * |m₁ - m₂| + B * |c₂ - c₁| := ⟨_, rfl⟩
  obtain ⟨T, hTdef⟩ : ∃ T, T = ε * |c₂ - c₁| * |m₁ - m₂| := ⟨_, rfl⟩
  have hS : 0 ≤ S := by rw [hSdef]; positivity
  have hT : 0 < T := by rw [hTdef]; positivity
  refine ⟨|m₁ - m₂| * T / ((S + T) * (B + 1)), by positivity, ?_⟩
  rintro δ hδ0 hδ xhat ⟨e₁, e₂, e₃, e₄, h1, h2, h3, h4, rfl⟩
  -- the perturbed numerator and denominator
  have hDd : |(m₁ * (1 + e₁) - m₂ * (1 + e₃)) - (m₁ - m₂)| ≤ B * δ := by
    have := abs_mul_sub_mul_le m₁ m₂ e₁ e₃ δ h1 h3
    rw [hBdef]; convert this using 2; ring
  have hNd : |(c₂ * (1 + e₄) - c₁ * (1 + e₂)) - (c₂ - c₁)| ≤ A * δ := by
    have := abs_mul_sub_mul_le c₂ c₁ e₄ e₂ δ h4 h2
    rw [hAdef]; convert this using 2 <;> ring
  have hBδ : B * δ < |m₁ - m₂| * T / (S + T) := by
    have hST : 0 < S + T := by linarith
    have : δ * (B + 1) < |m₁ - m₂| * T / (S + T) := by
      rw [lt_div_iff₀ (by positivity)] at hδ
      rw [lt_div_iff₀ hST]
      calc δ * (B + 1) * (S + T) = δ * ((S + T) * (B + 1)) := by ring
        _ < |m₁ - m₂| * T := hδ
    nlinarith
  have hTle : |m₁ - m₂| * T / (S + T) ≤ |m₁ - m₂| := by
    rw [div_le_iff₀ (by linarith)]; nlinarith
  -- lower bound on the perturbed denominator
  set D' := m₁ * (1 + e₁) - m₂ * (1 + e₃) with hD'def
  set N' := c₂ * (1 + e₄) - c₁ * (1 + e₂) with hN'def
  have hD'low : |m₁ - m₂| * S / (S + T) ≤ |D'| := by
    have h := abs_sub_abs_le_abs_sub (m₁ - m₂) D'
    rw [abs_sub_comm (m₁ - m₂) D'] at h
    have : |m₁ - m₂| * S / (S + T) = |m₁ - m₂| - |m₁ - m₂| * T / (S + T) := by
      field_simp; ring
    rw [this]; linarith
  have hST : 0 < S + T := by linarith
  have hD'pos : 0 < |D'| := by
    have h := abs_sub_abs_le_abs_sub (m₁ - m₂) D'
    rw [abs_sub_comm (m₁ - m₂) D'] at h
    linarith
  have hD'0 : D' ≠ 0 := abs_pos.mp hD'pos
  have key : |m₁ - m₂| * S ≤ |D'| * (S + T) := by
    rwa [div_le_iff₀ hST] at hD'low
  have hdiff : N' / D' - (c₂ - c₁) / (m₁ - m₂)
      = ((N' - (c₂ - c₁)) * (m₁ - m₂) - (c₂ - c₁) * (D' - (m₁ - m₂))) / ((m₁ - m₂) * D') := by
    field_simp; ring
  have hnum : |(N' - (c₂ - c₁)) * (m₁ - m₂) - (c₂ - c₁) * (D' - (m₁ - m₂))| ≤ δ * S := by
    calc _ ≤ |(N' - (c₂ - c₁)) * (m₁ - m₂)| + |(c₂ - c₁) * (D' - (m₁ - m₂))| := abs_sub _ _
      _ = |N' - (c₂ - c₁)| * |m₁ - m₂| + |c₂ - c₁| * |D' - (m₁ - m₂)| := by
          rw [abs_mul, abs_mul]
      _ ≤ (A * δ) * |m₁ - m₂| + |c₂ - c₁| * (B * δ) := by gcongr
      _ = δ * S := by rw [hSdef]; ring
  have hrhs : (kappa m₁ c₁ m₂ c₂ + ε) * δ * |crossing m₁ c₁ m₂ c₂|
      = δ * (S + T) / |m₁ - m₂| ^ 2 := by
    unfold kappa crossing
    rw [abs_div, ← hAdef, ← hBdef, hSdef, hTdef]
    field_simp
    ring
  show |N' / D' - (c₂ - c₁) / (m₁ - m₂)| ≤ _
  rw [hrhs, hdiff, abs_div, abs_mul]
  calc _ ≤ δ * S / (|m₁ - m₂| * |D'|) := by gcongr
    _ ≤ δ * (S + T) / |m₁ - m₂| ^ 2 := by
      rw [div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith [mul_le_mul_of_nonneg_left key (mul_nonneg hδ0 hD.le)]

/-- **κ is the worst ratio, so the bound cannot be lowered.** For the same two roads there is a way
to put relative errors of size at most `t` on the four data (each datum moved by `t` times a fixed
amount between −1 and 1) along which the crossing changes at rate exactly `κ x` at `t = 0`: the
relative change in the answer is `κ` times the relative change in the data, to first order. -/
theorem kappa_is_attained_to_first_order
    (m₁ c₁ m₂ c₂ : ℝ) (hm : m₁ ≠ m₂) (hc : c₁ ≠ c₂) :
    ∃ s₁ s₂ s₃ s₄ : ℝ, |s₁| ≤ 1 ∧ |s₂| ≤ 1 ∧ |s₃| ≤ 1 ∧ |s₄| ≤ 1 ∧
      HasDerivAt
        (fun t : ℝ => crossing (m₁ * (1 + t * s₁)) (c₁ * (1 + t * s₂))
          (m₂ * (1 + t * s₃)) (c₂ * (1 + t * s₄)))
        (kappa m₁ c₁ m₂ c₂ * crossing m₁ c₁ m₂ c₂) 0 := by
  have hD : m₁ - m₂ ≠ 0 := sub_ne_zero.mpr hm
  have hN : c₂ - c₁ ≠ 0 := sub_ne_zero.mpr (Ne.symm hc)
  obtain ⟨σ₁, hσ₁, e₁⟩ := exists_unit_mul_eq_abs c₁
  obtain ⟨σ₂, hσ₂, e₂⟩ := exists_unit_mul_eq_abs c₂
  obtain ⟨μ₁, hμ₁, f₁⟩ := exists_unit_mul_eq_abs m₁
  obtain ⟨μ₂, hμ₂, f₂⟩ := exists_unit_mul_eq_abs m₂
  obtain ⟨σN, hσN, eN⟩ := exists_unit_mul_eq_abs (c₂ - c₁)
  obtain ⟨σD, hσD, eD⟩ := exists_unit_mul_eq_abs (m₁ - m₂)
  have hneg : ∀ {s : ℝ}, (s = 1 ∨ s = -1) → (-s = 1 ∨ -s = -1) := by
    intro s hs; rcases hs with rfl | rfl <;> norm_num
  refine ⟨-(μ₁ * σD), -(σ₁ * σN), μ₂ * σD, σ₂ * σN,
    unit_abs_le_one (hneg (unit_mul_unit hμ₁ hσD)),
    unit_abs_le_one (hneg (unit_mul_unit hσ₁ hσN)),
    unit_abs_le_one (unit_mul_unit hμ₂ hσD),
    unit_abs_le_one (unit_mul_unit hσ₂ hσN), ?_⟩
  convert crossing_hasDerivAt_line m₁ c₁ m₂ c₂ _ _ _ _ hm using 1
  have sN : σN * σN = 1 := by rcases hσN with rfl | rfl <;> norm_num
  have sD : σD * σD = 1 := by rcases hσD with rfl | rfl <;> norm_num
  unfold kappa crossing
  rw [← e₁, ← e₂, ← f₁, ← f₂, ← eN, ← eD]
  have hσN0 : σN ≠ 0 := by rcases hσN with rfl | rfl <;> norm_num
  have hσD0 : σD ≠ 0 := by rcases hσD with rfl | rfl <;> norm_num
  field_simp
  linear_combination (-σD * (m₁ - m₂) * (c₂ * σ₂ + c₁ * σ₁)) * sN + (-σN * (c₂ - c₁) * (m₁ * μ₁ + m₂ * μ₂)) * sD

/-- **The crossing formula is backward stable.** Computed in floating point, the formula does two
subtractions and a division, each off by a factor `1 + δᵢ` with `|δᵢ| ≤ u`. The computed answer is
then the exact crossing for slopes moved by the factor `1 + δ₂` (relative change at most `u`) and
intercepts moved by the factor `(1 + δ₁)(1 + δ₃)` (relative change at most `2u + u²`). -/
theorem crossing_formula_backward_stable
    (m₁ c₁ m₂ c₂ u δ₁ δ₂ δ₃ : ℝ) (h₁ : |δ₁| ≤ u) (h₂ : |δ₂| ≤ u) (h₃ : |δ₃| ≤ u) :
    (c₂ - c₁) * (1 + δ₁) / ((m₁ - m₂) * (1 + δ₂)) * (1 + δ₃) =
        crossing (m₁ * (1 + δ₂)) (c₁ * ((1 + δ₁) * (1 + δ₃)))
          (m₂ * (1 + δ₂)) (c₂ * ((1 + δ₁) * (1 + δ₃))) ∧
      |(1 + δ₂) - 1| ≤ u ∧ |(1 + δ₁) * (1 + δ₃) - 1| ≤ 2 * u + u ^ 2 := by
  refine ⟨?_, by simpa using h₂, ?_⟩
  · unfold crossing
    rw [show c₂ * ((1 + δ₁) * (1 + δ₃)) - c₁ * ((1 + δ₁) * (1 + δ₃))
          = (c₂ - c₁) * (1 + δ₁) * (1 + δ₃) by ring,
        show m₁ * (1 + δ₂) - m₂ * (1 + δ₂) = (m₁ - m₂) * (1 + δ₂) by ring]
    rw [div_mul_eq_mul_div]
  · have hu : 0 ≤ u := (abs_nonneg _).trans h₁
    calc |(1 + δ₁) * (1 + δ₃) - 1| = |δ₁ + δ₃ + δ₁ * δ₃| := by ring_nf
      _ ≤ |δ₁ + δ₃| + |δ₁ * δ₃| := abs_add_le _ _
      _ ≤ |δ₁| + |δ₃| + |δ₁| * |δ₃| := by
          rw [abs_mul]; gcongr; exact abs_add_le _ _
      _ ≤ u + u + u * u := by gcongr
      _ = 2 * u + u ^ 2 := by ring

/-! ### The card's worked numbers -/

-- The fork: old road y = 0.1x, bypass y = 0.101x − 2. They cross at 2,000 m, and
-- κ = 201 + 1 = 202, made of 100 (m₁), 101 (m₂), 0 (c₁) and 1 (c₂).
example : crossing (1 / 10) 0 (101 / 1000) (-2) = 2000 ∧ kappa (1 / 10) 0 (101 / 1000) (-2) = 202 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

example : |(1 / 10 : ℝ)| / |1 / 10 - 101 / 1000| = 100 ∧ |(101 / 1000 : ℝ)| / |1 / 10 - 101 / 1000| = 101 ∧
    |(0 : ℝ)| / |(-2) - 0| = 0 ∧ |(-2 : ℝ)| / |(-2) - 0| = 1 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

-- Bypass slope read 0.1% high (0.101101): the crossing is 2,000,000/1,101 m (1,816.53 m), a move of
-- −202,000/1,101 m (−183.47 m); the first-order rule predicted 101 × 0.1% × 2,000 = 202 m.
example : crossing (1 / 10) 0 (101101 / 1000000) (-2) = 2000000 / 1101 ∧
    (2000000 / 1101 : ℝ) - 2000 = -202000 / 1101 ∧ (101 : ℝ) * (1 / 1000) * 2000 = 202 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

-- All four data 0.1% off, worst case: from 1,998,000/1,201 m (1,663.61 m) to 2,002,000/799 m
-- (2,505.63 m), against the first-order 2,000(1 ∓ 202 × 0.001) = 1,596 m to 2,404 m.
example : crossing (1 / 10 * (1 - 1 / 1000)) 0 (101 / 1000 * (1 + 1 / 1000)) (-2 * (1 - 1 / 1000)) =
      1998000 / 1201 ∧
    crossing (1 / 10 * (1 + 1 / 1000)) 0 (101 / 1000 * (1 - 1 / 1000)) (-2 * (1 + 1 / 1000)) =
      2002000 / 799 ∧
    (2000 : ℝ) * (1 - 202 / 1000) = 1596 ∧ (2000 : ℝ) * (1 + 202 / 1000) = 2404 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

-- Bypass slope read 1% low (0.09999): the roads cross 200 km behind, at −200,000 m, where first
-- order predicted 2,000 × (1 + 101 × 0.01) = 4,020 m.
example : crossing (1 / 10) 0 (101 / 1000 * (1 - 1 / 100)) (-2) = -200000 ∧
    (2000 : ℝ) * (1 + 101 * (1 / 100)) = 4020 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

-- The absolute slope |dx/dm₂| = |x / (m₁ − m₂)| is 2,000,000 m per unit slope, not κ.
example : |(2000 : ℝ) / (1 / 10 - 101 / 1000)| = 2000000 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

-- The 45-degree crossing of y = 1 and x + y = 2 (slopes 0 and −1, intercepts 1 and 2): κ = 1 + 3 = 4,
-- and the roads cross at x = 1.
example : kappa 0 1 (-1) 2 = 4 ∧ crossing 0 1 (-1) 2 = 1 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

-- Tries: a bypass of slope 0.2 gives κ = 4 and x = 20 m; slope 0.1001 gives κ = 2,002 and x = 20,000 m.
example : kappa (1 / 10) 0 (1 / 5) (-2) = 4 ∧ crossing (1 / 10) 0 (1 / 5) (-2) = 20 ∧
    kappa (1 / 10) 0 (1001 / 10000) (-2) = 2002 ∧ crossing (1 / 10) 0 (1001 / 10000) (-2) = 20000 := by
  norm_num [crossing, kappa, abs_of_pos, abs_of_neg]

#print axioms stable_crossing_rel_error_le_kappa_mul_delta
#print axioms kappa_is_attained_to_first_order
#print axioms crossing_formula_backward_stable
