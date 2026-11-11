-- Partial derivatives: when both mixed partials of a two-input function exist and are continuous near a point they agree there (Clairaut's theorem), the card's G gives -1 and +1 without that continuity, and the card's house has board rate -125, glass rate 40 and mixed rate 5/4 both ways.
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Pow

open Filter Topology

theorem pd_double_mvt (f fx fxy : ℝ × ℝ → ℝ) (a b h : ℝ) (hh : 0 < h)
    (H1 : ∀ x ∈ Set.Icc a (a + h), ∀ y ∈ Set.Icc b (b + h),
      HasDerivAt (fun x => f (x, y)) (fx (x, y)) x)
    (H2 : ∀ x ∈ Set.Icc a (a + h), ∀ y ∈ Set.Icc b (b + h),
      HasDerivAt (fun y => fx (x, y)) (fxy (x, y)) y) :
    ∃ x ∈ Set.Ioo a (a + h), ∃ y ∈ Set.Ioo b (b + h),
      fxy (x, y) * h ^ 2 = f (a + h, b + h) - f (a + h, b) - f (a, b + h) + f (a, b) := by
  have hb1 : b ∈ Set.Icc b (b + h) := ⟨le_refl _, by linarith⟩
  have hb2 : b + h ∈ Set.Icc b (b + h) := ⟨by linarith, le_refl _⟩
  have hd : ∀ x ∈ Set.Icc a (a + h), HasDerivAt (fun x => f (x, b + h) - f (x, b))
      (fx (x, b + h) - fx (x, b)) x := fun x hx => (H1 x hx _ hb2).sub (H1 x hx _ hb1)
  obtain ⟨ξ, hξ, eξ⟩ := exists_hasDerivAt_eq_slope (fun x => f (x, b + h) - f (x, b))
    (fun x => fx (x, b + h) - fx (x, b)) (by linarith)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => hd x (Set.Ioo_subset_Icc_self hx))
  have hξ' := Set.Ioo_subset_Icc_self hξ
  obtain ⟨η, hη, eη⟩ := exists_hasDerivAt_eq_slope (fun y => fx (ξ, y))
    (fun y => fxy (ξ, y)) (by linarith : b < b + h)
    (fun y hy => (H2 ξ hξ' y hy).continuousAt.continuousWithinAt)
    (fun y hy => H2 ξ hξ' y (Set.Ioo_subset_Icc_self hy))
  refine ⟨ξ, hξ, η, hη, ?_⟩
  simp only [add_sub_cancel_left] at eξ eη
  rw [eη, eξ]
  have : h ≠ 0 := hh.ne'
  field_simp
  ring

#print axioms pd_double_mvt

/-- Mixed partials agree (Clairaut's theorem). Let `f` be a function of two inputs `(x, y)`. Near the
point `(a, b)`, suppose the x-rate `fx` (y frozen) and the y-rate `fy` (x frozen) exist, the mixed
partial `fxy` (the x-rate, then its rate in y) and `fyx` (the y-rate, then its rate in x) exist, and
both mixed partials are continuous. Then the two mixed partials are equal at `(a, b)`. -/
theorem mixed_partials_agree (f fx fy fxy fyx : ℝ × ℝ → ℝ) (a b : ℝ)
    (hfirst : ∀ᶠ p in 𝓝 (a, b),
      HasDerivAt (fun x => f (x, p.2)) (fx p) p.1 ∧ HasDerivAt (fun y => f (p.1, y)) (fy p) p.2)
    (hsecond : ∀ᶠ p in 𝓝 (a, b),
      HasDerivAt (fun y => fx (p.1, y)) (fxy p) p.2 ∧ HasDerivAt (fun x => fy (x, p.2)) (fyx p) p.1)
    (hcont : ∀ᶠ p in 𝓝 (a, b), ContinuousAt fxy p ∧ ContinuousAt fyx p) :
    fxy (a, b) = fyx (a, b) := by
  obtain ⟨ε, εpos, hε⟩ := Metric.eventually_nhds_iff.1 (hfirst.and hsecond)
  have key : ∀ h, 0 < h → h < ε → ∃ p q : ℝ × ℝ,
      dist p (a, b) < h ∧ dist q (a, b) < h ∧ fxy p = fyx q := by
    intro h hh hhε
    have mem : ∀ x ∈ Set.Icc a (a + h), ∀ y ∈ Set.Icc b (b + h), dist (x, y) (a, b) < ε := by
      intro x hx y hy
      rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq, max_lt_iff]
      constructor <;> rw [abs_lt] <;> constructor <;> linarith [hx.1, hx.2, hy.1, hy.2]
    obtain ⟨x1, hx1, y1, hy1, e1⟩ := pd_double_mvt f fx fxy a b h hh
      (fun x hx y hy => (hε (mem x hx y hy)).1.1) (fun x hx y hy => (hε (mem x hx y hy)).2.1)
    obtain ⟨y2, hy2, x2, hx2, e2⟩ := pd_double_mvt (fun p => f (p.2, p.1))
      (fun p => fy (p.2, p.1)) (fun p => fyx (p.2, p.1)) b a h hh
      (fun y hy x hx => (hε (mem x hx y hy)).1.2) (fun y hy x hx => (hε (mem x hx y hy)).2.2)
    have dmem : ∀ x ∈ Set.Ioo a (a + h), ∀ y ∈ Set.Ioo b (b + h), dist (x, y) (a, b) < h := by
      intro x hx y hy
      rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq, max_lt_iff]
      constructor <;> rw [abs_lt] <;> constructor <;> linarith [hx.1, hx.2, hy.1, hy.2]
    refine ⟨(x1, y1), (x2, y2), dmem _ hx1 _ hy1, dmem _ hx2 _ hy2, ?_⟩
    simp only at e2
    have : fxy (x1, y1) * h ^ 2 = fyx (x2, y2) * h ^ 2 := by rw [e1, e2]; ring
    exact mul_right_cancel₀ (by positivity) this
  have c1 := hcont.self_of_nhds.1
  have c2 := hcont.self_of_nhds.2
  by_contra hne
  have d : 0 < |fxy (a, b) - fyx (a, b)| := abs_pos.2 (sub_ne_zero.2 hne)
  obtain ⟨δ1, δ1pos, hδ1⟩ := Metric.continuousAt_iff.1 c1 _ (half_pos d)
  obtain ⟨δ2, δ2pos, hδ2⟩ := Metric.continuousAt_iff.1 c2 _ (half_pos d)
  have hm : 0 < min (min δ1 δ2) ε := lt_min (lt_min δ1pos δ2pos) εpos
  obtain ⟨p, q, hp, hq, he⟩ := key (min (min δ1 δ2) ε / 2) (by positivity)
    (by linarith [min_le_right (min δ1 δ2) ε])
  have l1 : min (min δ1 δ2) ε / 2 < δ1 := by
    linarith [min_le_left (min δ1 δ2) ε, min_le_left δ1 δ2]
  have l2 : min (min δ1 δ2) ε / 2 < δ2 := by
    linarith [min_le_left (min δ1 δ2) ε, min_le_right δ1 δ2]
  have h1 := hδ1 (hp.trans l1)
  have h2 := hδ2 (hq.trans l2)
  rw [Real.dist_eq, he] at h1
  rw [Real.dist_eq] at h2
  have := abs_sub_le (fxy (a, b)) (fyx q) (fyx (a, b))
  rw [abs_sub_comm (fxy (a, b)) (fyx q)] at this
  linarith

/-- Without continuity the orders can disagree. Take `G(x, y) = xy(x² - y²)/(x² + y²)`, with
`G = 0` at the origin. Its x-rate along the y-axis is `-y` and its y-rate along the x-axis is `x`,
so the mixed partial is `-1` taking x first, then y, and `+1` taking y first, then x. -/
theorem clairaut_counterexample :
    let G : ℝ × ℝ → ℝ := fun p =>
      if p = (0, 0) then 0 else p.1 * p.2 * (p.1 ^ 2 - p.2 ^ 2) / (p.1 ^ 2 + p.2 ^ 2)
    (∀ y : ℝ, HasDerivAt (fun x => G (x, y)) (-y) 0) ∧
      (∀ x : ℝ, HasDerivAt (fun y => G (x, y)) x 0) ∧
      HasDerivAt (fun y => deriv (fun x => G (x, y)) 0) (-1) 0 ∧
      HasDerivAt (fun x => deriv (fun y => G (x, y)) 0) 1 0 := by
  intro G
  have hx : ∀ y : ℝ, HasDerivAt (fun x => G (x, y)) (-y) 0 := by
    intro y
    by_cases hy : y = 0
    · subst hy
      have : (fun x => G (x, 0)) = fun _ => 0 := by
        funext x; simp [G]
      rw [this]; simpa using hasDerivAt_const (0 : ℝ) (0 : ℝ)
    · have : (fun x => G (x, y)) = fun x => x * y * (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) := by
        funext x; simp [G, hy]
      rw [this]
      have hd : (0 : ℝ) ^ 2 + y ^ 2 ≠ 0 := by positivity
      have := ((((hasDerivAt_id (0 : ℝ)).mul_const y).mul
        ((hasDerivAt_pow 2 (0 : ℝ)).sub_const (y ^ 2))).div
        ((hasDerivAt_pow 2 (0 : ℝ)).add_const (y ^ 2)) hd)
      convert this using 1
      · funext x; simp
      · field_simp; ring
  have hy : ∀ x : ℝ, HasDerivAt (fun y => G (x, y)) x 0 := by
    intro x
    by_cases hx0 : x = 0
    · subst hx0
      have : (fun y => G (0, y)) = fun _ => 0 := by
        funext y; simp [G]
      rw [this]; simpa using hasDerivAt_const (0 : ℝ) (0 : ℝ)
    · have : (fun y => G (x, y)) = fun y => x * y * (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) := by
        funext y; simp [G, hx0]
      rw [this]
      have hd : x ^ 2 + (0 : ℝ) ^ 2 ≠ 0 := by positivity
      have := ((((hasDerivAt_id (0 : ℝ)).const_mul x).mul
        ((hasDerivAt_pow 2 (0 : ℝ)).const_sub (x ^ 2))).div
        ((hasDerivAt_pow 2 (0 : ℝ)).const_add (x ^ 2)) hd)
      convert this using 1
      · funext y; simp
      · field_simp; ring
  refine ⟨hx, hy, ?_, ?_⟩
  · have : (fun y => deriv (fun x => G (x, y)) 0) = fun y => -y := by
      funext y; exact (hx y).deriv
    rw [this]; convert (hasDerivAt_id' (0 : ℝ)).neg using 1
  · have : (fun x => deriv (fun y => G (x, y)) 0) = fun x => x := by
      funext x; exact (hy x).deriv
    rw [this]; exact hasDerivAt_id' 0

/-- The house's wall resistance with `t` cm of board: `R(t) = 0.5 + t/4`. -/
noncomputable def houseR (t : ℝ) : ℝ := 1 / 2 + t / 4

/-- The house's heat loss in watts with `t` cm of board and `g` m² of glass:
`Q(t, g) = ΔT ((A - g)/R(t) + U g)` with `A = 120`, `ΔT = 20`, `U = 2.5`. -/
noncomputable def houseQ (t g : ℝ) : ℝ := 20 * ((120 - g) / houseR t + 5 / 2 * g)

/-- The card's house at 6 cm of board and 20 m² of glass: the board rate is -125 W per cm, the
glass rate is 40 W per m², and the mixed rate is 1.25 W per cm per m² in both orders. -/
theorem house_partials_at_6_20 :
    HasDerivAt (fun t => houseQ t 20) (-125) 6 ∧
      HasDerivAt (fun g => houseQ 6 g) 40 20 ∧
      HasDerivAt (fun g => deriv (fun t => houseQ t g) 6) (5 / 4) 20 ∧
      HasDerivAt (fun t => deriv (fun g => houseQ t g) 20) (5 / 4) 6 := by
  have hR : HasDerivAt houseR (1 / 4) 6 := by
    have := ((hasDerivAt_id' (6 : ℝ)).div_const 4).const_add (1 / 2)
    convert this using 1
    funext t; rfl
  have hR6 : houseR 6 ≠ 0 := by norm_num [houseR]
  -- t-rate for every g
  have ht : ∀ g : ℝ, HasDerivAt (fun t => houseQ t g) (-(120 - g) * 5 / 4) 6 := by
    intro g
    have := (((hasDerivAt_const (6 : ℝ) (120 - g)).div hR hR6).add_const (5 / 2 * g)).const_mul 20
    convert this using 1
    · funext t; simp [houseQ]
    · norm_num [houseR]; ring
  -- g-rate for every t
  have hg : ∀ t : ℝ, HasDerivAt (fun g => houseQ t g)
      (20 * (-(houseR t)⁻¹ + 5 / 2)) 20 := by
    intro t
    have := ((((hasDerivAt_id (20 : ℝ)).const_sub 120).mul_const (houseR t)⁻¹).add
      ((hasDerivAt_id (20 : ℝ)).const_mul (5 / 2))).const_mul 20
    convert this using 1
    · funext g; simp [houseQ, div_eq_mul_inv]
    · simp
  refine ⟨?_, ?_, ?_, ?_⟩
  · convert ht 20 using 1; norm_num
  · convert hg 6 using 1; norm_num [houseR]
  · have : (fun g => deriv (fun t => houseQ t g) 6) = fun g => -(120 - g) * 5 / 4 := by
      funext g; exact (ht g).deriv
    rw [this]
    have := (((hasDerivAt_id (20 : ℝ)).const_sub 120).neg.mul_const 5).div_const 4
    convert this using 1
    · funext g; simp
    · norm_num
  · have : (fun t => deriv (fun g => houseQ t g) 20) = fun t => 20 * (-(houseR t)⁻¹ + 5 / 2) := by
      funext t; exact (hg t).deriv
    rw [this]
    have := ((hR.inv hR6).neg.add_const (5 / 2)).const_mul 20
    convert this using 1; norm_num [houseR]

/-! The card's worked numbers, checked with exact fractions. -/

-- wall resistance at 6 cm: 0.5 + 6/4 = 2
example : houseR 6 = 2 := by norm_num [houseR]
-- wall loss 20 × 100 / 2 = 1000 W, glass loss 20 × 2.5 × 20 = 1000 W, total 2000 W
example : (20 : ℚ) * 100 / 2 = 1000 ∧ (20 : ℚ) * (5 / 2) * 20 = 1000 := by norm_num
example : houseQ 6 20 = 2000 := by norm_num [houseQ, houseR]
-- board step of 1 cm: the quotient is -1000/9 W per cm (about -111.11)
example : (houseQ 7 20 - houseQ 6 20) / 1 = -1000 / 9 := by norm_num [houseQ, houseR]
-- board rate -1000/8 = -125; glass rate 20 × (2.5 - 1/2) = 40; mixed rate 20/(4 × 2 × 2) = 1.25
example : (-1000 : ℚ) / 8 = -125 := by norm_num
example : (20 : ℚ) * (5 / 2 - 1 / 2) = 40 := by norm_num
example : (20 : ℚ) / (4 * 2 * 2) = 5 / 4 := by norm_num
-- glass step of 1 m²: the quotient is exactly 40
example : (houseQ 6 21 - houseQ 6 20) / 1 = 40 := by norm_num [houseQ, houseR]
-- four corners at h = k = 1: 10/9 (about 1.111111)
example : houseQ 7 21 - houseQ 7 20 - houseQ 6 21 + houseQ 6 20 = 10 / 9 := by
  norm_num [houseQ, houseR]
-- at 14 cm: board rate -20 × 100 / (4 × 4²) = -31.25, glass rate 20 × (2.5 - 1/4) = 45
example : -(20 : ℚ) * 100 / (4 * (1 / 2 + 14 / 4) ^ 2) = -125 / 4 := by norm_num
example : (20 : ℚ) * (5 / 2 - 1 / (1 / 2 + 14 / 4)) = 45 := by norm_num
-- the mistake, brick area frozen at 120 m²: glass costs 20 × 2.5 = 50 W per m²
example : (20 : ℚ) * (120 / 2 + 5 / 2 * 21) - 20 * (120 / 2 + 5 / 2 * 20) = 50 := by norm_num

#print axioms mixed_partials_agree
#print axioms clairaut_counterexample
#print axioms house_partials_at_6_20
