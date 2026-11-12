-- Interval arithmetic: applying the card's end-point rules, with outward rounding, to every step of a formula gives an interval that contains the true value, the interval is exact when each input appears once, and the as-written solver update widens its interval 1.5 times a step while the true spread halves.
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Data.Set.Prod
import Mathlib.Logic.Function.Iterate
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.GCongr
import Mathlib.Tactic.Ring

/-! An interval `X = [x_lo, x_hi]` is stored as the pair `(x_lo, x_hi) : ℝ × ℝ` and stands for
the set `Set.Icc x_lo x_hi`. The card's four rules act only on the ends:

* `X + Y = [x_lo + y_lo, x_hi + y_hi]`
* `X - Y = [x_lo - y_hi, x_hi - y_lo]`
* `X × Y = [min of the four end products, max of the four end products]`
* `X ÷ Y = X × [1/y_hi, 1/y_lo]`, used only when `0 ∉ Y`. -/

/-- Interval addition: add the low ends and add the high ends. -/
def ivAdd (X Y : ℝ × ℝ) : ℝ × ℝ := (X.1 + Y.1, X.2 + Y.2)

/-- Interval subtraction: low end minus the other high end, high end minus the other low end. -/
def ivSub (X Y : ℝ × ℝ) : ℝ × ℝ := (X.1 - Y.2, X.2 - Y.1)

/-- Interval multiplication: try all four end products, keep the smallest and the largest. -/
noncomputable def ivMul (X Y : ℝ × ℝ) : ℝ × ℝ :=
  (min (min (X.1 * Y.1) (X.1 * Y.2)) (min (X.2 * Y.1) (X.2 * Y.2)),
   max (max (X.1 * Y.1) (X.1 * Y.2)) (max (X.2 * Y.1) (X.2 * Y.2)))

/-- Interval division `X ÷ Y = X × [1/y_hi, 1/y_lo]` (meant only for `0 ∉ Y`). -/
noncomputable def ivDiv (X Y : ℝ × ℝ) : ℝ × ℝ := ivMul X (1 / Y.2, 1 / Y.1)

/-- A formula in `n` inputs: a chain of `+`, `-`, `×`, `÷` built from inputs and constants. -/
inductive Formula (n : ℕ) : Type
  | input : Fin n → Formula n
  | const : ℝ → Formula n
  | add : Formula n → Formula n → Formula n
  | sub : Formula n → Formula n → Formula n
  | mul : Formula n → Formula n → Formula n
  | div : Formula n → Formula n → Formula n

namespace Formula

variable {n : ℕ}

/-- The formula's value at single input values `v`. -/
noncomputable def eval (v : Fin n → ℝ) : Formula n → ℝ
  | input i => v i
  | const c => c
  | add f g => f.eval v + g.eval v
  | sub f g => f.eval v - g.eval v
  | mul f g => f.eval v * g.eval v
  | div f g => f.eval v / g.eval v

/-- The formula run in interval arithmetic: input `i` is the interval `box i`, a constant `c` is
`[c, c]`, and each operation applies the card's rule to the ends and then `round`s the result.
When a divisor interval contains zero the run stops (`none`), as the card's code does. -/
noncomputable def ieval (round : ℝ × ℝ → ℝ × ℝ) (box : Fin n → ℝ × ℝ) :
    Formula n → Option (ℝ × ℝ)
  | input i => some (box i)
  | const c => some (c, c)
  | add f g => do
      let X ← f.ieval round box
      let Y ← g.ieval round box
      pure (round (ivAdd X Y))
  | sub f g => do
      let X ← f.ieval round box
      let Y ← g.ieval round box
      pure (round (ivSub X Y))
  | mul f g => do
      let X ← f.ieval round box
      let Y ← g.ieval round box
      pure (round (ivMul X Y))
  | div f g => do
      let X ← f.ieval round box
      let Y ← g.ieval round box
      if Y.1 ≤ 0 ∧ 0 ≤ Y.2 then none else pure (round (ivDiv X Y))

/-- The inputs the formula uses, with repeats: an input used twice is listed twice. -/
def inputs : Formula n → List (Fin n)
  | input i => [i]
  | const _ => []
  | add f g => f.inputs ++ g.inputs
  | sub f g => f.inputs ++ g.inputs
  | mul f g => f.inputs ++ g.inputs
  | div f g => f.inputs ++ g.inputs

end Formula

/-- Moving `x` inside `[a, b]` keeps `x * y` between the two end products. -/
lemma iv_mul_between {a b x y : ℝ} (hax : a ≤ x) (hxb : x ≤ b) :
    min (a * y) (b * y) ≤ x * y ∧ x * y ≤ max (a * y) (b * y) := by
  rcases le_total 0 y with h | h
  · exact ⟨(min_le_left _ _).trans (mul_le_mul_of_nonneg_right hax h),
      (mul_le_mul_of_nonneg_right hxb h).trans (le_max_right _ _)⟩
  · exact ⟨(min_le_right _ _).trans (mul_le_mul_of_nonpos_right hxb h),
      (mul_le_mul_of_nonpos_right hax h).trans (le_max_left _ _)⟩

/-- The multiplication rule encloses every product of points of the two intervals. -/
lemma iv_mul_mem {a b c d x y : ℝ} (hx : x ∈ Set.Icc a b) (hy : y ∈ Set.Icc c d) :
    x * y ∈ Set.Icc (ivMul (a, b) (c, d)).1 (ivMul (a, b) (c, d)).2 := by
  obtain ⟨hax, hxb⟩ := hx
  obtain ⟨hcy, hyd⟩ := hy
  have h1 := iv_mul_between (y := y) hax hxb
  have h2 : min (a * c) (a * d) ≤ a * y ∧ a * y ≤ max (a * c) (a * d) := by
    rw [mul_comm a c, mul_comm a d, mul_comm a y]; exact iv_mul_between hcy hyd
  have h3 : min (b * c) (b * d) ≤ b * y ∧ b * y ≤ max (b * c) (b * d) := by
    rw [mul_comm b c, mul_comm b d, mul_comm b y]; exact iv_mul_between hcy hyd
  simp only [ivMul, Set.mem_Icc]
  exact ⟨le_trans (le_min (le_trans (min_le_left _ _) h2.1) (le_trans (min_le_right _ _) h3.1)) h1.1,
    h1.2.trans (max_le (h2.2.trans (le_max_left _ _)) (h3.2.trans (le_max_right _ _)))⟩

/-- If `0 ∉ [c, d]` and `y ∈ [c, d]` then `y ≠ 0` and `1 / y ∈ [1 / d, 1 / c]`. -/
lemma iv_inv_mem {c d y : ℝ} (hy : y ∈ Set.Icc c d) (h0 : ¬(c ≤ 0 ∧ 0 ≤ d)) :
    y ≠ 0 ∧ 1 / y ∈ Set.Icc (1 / d) (1 / c) := by
  obtain ⟨hcy, hyd⟩ := hy
  by_cases hc : c ≤ 0
  · have hd : d < 0 := by
      by_contra hd; exact h0 ⟨hc, le_of_not_gt hd⟩
    have hy0 : y < 0 := lt_of_le_of_lt hyd hd
    exact ⟨hy0.ne, one_div_le_one_div_of_neg_of_le hd hyd, one_div_le_one_div_of_neg_of_le hy0 hcy⟩
  · have hc' : 0 < c := lt_of_not_ge hc
    have hy0 : 0 < y := lt_of_lt_of_le hc' hcy
    exact ⟨hy0.ne', one_div_le_one_div_of_le hy0 hyd, one_div_le_one_div_of_le hc' hcy⟩

/-- The division rule encloses every quotient of points of the two intervals, when `0 ∉ [c, d]`. -/
lemma iv_div_mem {a b c d x y : ℝ} (hx : x ∈ Set.Icc a b) (hy : y ∈ Set.Icc c d)
    (h0 : ¬(c ≤ 0 ∧ 0 ≤ d)) :
    x / y ∈ Set.Icc (ivDiv (a, b) (c, d)).1 (ivDiv (a, b) (c, d)).2 := by
  rw [div_eq_mul_one_div]
  exact iv_mul_mem hx (iv_inv_mem hy h0).2

/-- The smallest of four numbers is one of them. -/
lemma min4_choice (p q r s : ℝ) :
    min (min p q) (min r s) = p ∨ min (min p q) (min r s) = q ∨
      min (min p q) (min r s) = r ∨ min (min p q) (min r s) = s := by
  simp only [min_def]; split_ifs <;> simp

/-- The largest of four numbers is one of them. -/
lemma max4_choice (p q r s : ℝ) :
    max (max p q) (max r s) = p ∨ max (max p q) (max r s) = q ∨
      max (max p q) (max r s) = r ∨ max (max p q) (max r s) = s := by
  simp only [max_def]; split_ifs <;> simp

/-- A formula's value depends only on the inputs it uses. -/
lemma Formula.eval_congr {n : ℕ} (f : Formula n) (v w : Fin n → ℝ)
    (h : ∀ i ∈ f.inputs, v i = w i) : f.eval v = f.eval w := by
  induction f with
  | input i => exact h i (by simp [Formula.inputs])
  | const c => rfl
  | add f g ihf ihg =>
      simp only [Formula.eval]
      rw [ihf fun i hi => h i (by simp [Formula.inputs, hi]),
        ihg fun i hi => h i (by simp [Formula.inputs, hi])]
  | sub f g ihf ihg =>
      simp only [Formula.eval]
      rw [ihf fun i hi => h i (by simp [Formula.inputs, hi]),
        ihg fun i hi => h i (by simp [Formula.inputs, hi])]
  | mul f g ihf ihg =>
      simp only [Formula.eval]
      rw [ihf fun i hi => h i (by simp [Formula.inputs, hi]),
        ihg fun i hi => h i (by simp [Formula.inputs, hi])]
  | div f g ihf ihg =>
      simp only [Formula.eval]
      rw [ihf fun i hi => h i (by simp [Formula.inputs, hi]),
        ihg fun i hi => h i (by simp [Formula.inputs, hi])]

/-- Two formulas with no input in common take their values independently: over a box, the pairs
of values they reach are all pairs of a value of each. -/
lemma Formula.image_pair {n : ℕ} (f g : Formula n) (B : Fin n → Set ℝ)
    (hdisj : ∀ i ∈ f.inputs, i ∉ g.inputs) (op : ℝ → ℝ → ℝ) :
    (fun v => op (f.eval v) (g.eval v)) '' (Set.univ.pi B) =
      (fun p : ℝ × ℝ => op p.1 p.2) '' (((fun v => f.eval v) '' Set.univ.pi B) ×ˢ
        ((fun v => g.eval v) '' Set.univ.pi B)) := by
  ext z
  constructor
  · rintro ⟨v, hv, rfl⟩
    exact ⟨(f.eval v, g.eval v), ⟨⟨v, hv, rfl⟩, ⟨v, hv, rfl⟩⟩, rfl⟩
  · rintro ⟨⟨x, y⟩, ⟨⟨v1, hv1, rfl⟩, ⟨v2, hv2, rfl⟩⟩, rfl⟩
    classical
    refine ⟨fun i => if i ∈ f.inputs then v1 i else v2 i, ?_, ?_⟩
    · intro i _
      by_cases hi : i ∈ f.inputs
      · simp only [hi, ↓reduceIte]; exact hv1 i (Set.mem_univ _)
      · simp only [hi, ↓reduceIte]; exact hv2 i (Set.mem_univ _)
    · simp only
      rw [f.eval_congr _ v1 (fun i hi => by simp [hi]),
        g.eval_congr _ v2 (fun i hi => by simp [show i ∉ f.inputs from fun hif => hdisj i hif hi])]

lemma iv_add_mem {a b c d x y : ℝ} (hx : x ∈ Set.Icc a b) (hy : y ∈ Set.Icc c d) :
    x + y ∈ Set.Icc (ivAdd (a, b) (c, d)).1 (ivAdd (a, b) (c, d)).2 :=
  ⟨add_le_add hx.1 hy.1, add_le_add hx.2 hy.2⟩

lemma iv_sub_mem {a b c d x y : ℝ} (hx : x ∈ Set.Icc a b) (hy : y ∈ Set.Icc c d) :
    x - y ∈ Set.Icc (ivSub (a, b) (c, d)).1 (ivSub (a, b) (c, d)).2 :=
  ⟨sub_le_sub hx.1 hy.2, sub_le_sub hx.2 hy.1⟩

/-- A continuous two-input operation maps a rectangle onto `[lo, hi]` when it stays in `[lo, hi]`
and reaches both ends. -/
lemma image_rect_eq (op : ℝ → ℝ → ℝ) {a b c d lo hi : ℝ}
    (hcont : ContinuousOn (fun p : ℝ × ℝ => op p.1 p.2) (Set.Icc a b ×ˢ Set.Icc c d))
    (hsub : ∀ x ∈ Set.Icc a b, ∀ y ∈ Set.Icc c d, op x y ∈ Set.Icc lo hi)
    (hlo : ∃ x ∈ Set.Icc a b, ∃ y ∈ Set.Icc c d, op x y = lo)
    (hhi : ∃ x ∈ Set.Icc a b, ∃ y ∈ Set.Icc c d, op x y = hi) :
    (fun p : ℝ × ℝ => op p.1 p.2) '' (Set.Icc a b ×ˢ Set.Icc c d) = Set.Icc lo hi := by
  apply Set.Subset.antisymm
  · rintro _ ⟨⟨x, y⟩, ⟨hx, hy⟩, rfl⟩
    exact hsub x hx y hy
  · have hpc := (isPreconnected_Icc.prod isPreconnected_Icc).image _ hcont
    obtain ⟨x1, hx1, y1, hy1, h1⟩ := hlo
    obtain ⟨x2, hx2, y2, hy2, h2⟩ := hhi
    exact hpc.Icc_subset ⟨(x1, y1), ⟨hx1, hy1⟩, h1⟩ ⟨(x2, y2), ⟨hx2, hy2⟩, h2⟩

/-- The multiplication rule's two ends are products of corners. -/
lemma iv_mul_corners {a b c d : ℝ} (hab : a ≤ b) (hcd : c ≤ d) :
    (∃ x ∈ Set.Icc a b, ∃ y ∈ Set.Icc c d, x * y = (ivMul (a, b) (c, d)).1) ∧
    (∃ x ∈ Set.Icc a b, ∃ y ∈ Set.Icc c d, x * y = (ivMul (a, b) (c, d)).2) := by
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab⟩
  have hb : b ∈ Set.Icc a b := ⟨hab, le_rfl⟩
  have hc : c ∈ Set.Icc c d := ⟨le_rfl, hcd⟩
  have hd : d ∈ Set.Icc c d := ⟨hcd, le_rfl⟩
  simp only [ivMul]
  constructor
  · rcases min4_choice (a * c) (a * d) (b * c) (b * d) with h | h | h | h <;> rw [h]
    exacts [⟨a, ha, c, hc, rfl⟩, ⟨a, ha, d, hd, rfl⟩, ⟨b, hb, c, hc, rfl⟩, ⟨b, hb, d, hd, rfl⟩]
  · rcases max4_choice (a * c) (a * d) (b * c) (b * d) with h | h | h | h <;> rw [h]
    exacts [⟨a, ha, c, hc, rfl⟩, ⟨a, ha, d, hd, rfl⟩, ⟨b, hb, c, hc, rfl⟩, ⟨b, hb, d, hd, rfl⟩]

/-- The division rule's two ends are quotients of corners. -/
lemma iv_div_corners {a b c d : ℝ} (hab : a ≤ b) (hcd : c ≤ d) :
    (∃ x ∈ Set.Icc a b, ∃ y ∈ Set.Icc c d, x / y = (ivDiv (a, b) (c, d)).1) ∧
    (∃ x ∈ Set.Icc a b, ∃ y ∈ Set.Icc c d, x / y = (ivDiv (a, b) (c, d)).2) := by
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab⟩
  have hb : b ∈ Set.Icc a b := ⟨hab, le_rfl⟩
  have hc : c ∈ Set.Icc c d := ⟨le_rfl, hcd⟩
  have hd : d ∈ Set.Icc c d := ⟨hcd, le_rfl⟩
  simp only [ivDiv, ivMul]
  constructor
  · rcases min4_choice (a * (1 / d)) (a * (1 / c)) (b * (1 / d)) (b * (1 / c)) with h | h | h | h <;>
      rw [h]
    exacts [⟨a, ha, d, hd, div_eq_mul_one_div a d⟩, ⟨a, ha, c, hc, div_eq_mul_one_div a c⟩,
      ⟨b, hb, d, hd, div_eq_mul_one_div b d⟩, ⟨b, hb, c, hc, div_eq_mul_one_div b c⟩]
  · rcases max4_choice (a * (1 / d)) (a * (1 / c)) (b * (1 / d)) (b * (1 / c)) with h | h | h | h <;>
      rw [h]
    exacts [⟨a, ha, d, hd, div_eq_mul_one_div a d⟩, ⟨a, ha, c, hc, div_eq_mul_one_div a c⟩,
      ⟨b, hb, d, hd, div_eq_mul_one_div b d⟩, ⟨b, hb, c, hc, div_eq_mul_one_div b c⟩]

/-- The inclusion property. Run a formula in interval arithmetic: every step applies the card's
rule to the ends and then rounds outward (the low end down, the high end up, by any amount).
If no divisor interval contains zero, so the run returns an interval `[lo, hi]`, and the true
inputs lie in their input intervals, then the formula's true value lies in `[lo, hi]`. -/
theorem interval_evaluation_encloses_true_value {n : ℕ} (round : ℝ × ℝ → ℝ × ℝ)
    (hround : ∀ X : ℝ × ℝ, (round X).1 ≤ X.1 ∧ X.2 ≤ (round X).2)
    (box : Fin n → ℝ × ℝ) (v : Fin n → ℝ)
    (hv : v ∈ Set.univ.pi fun i => Set.Icc (box i).1 (box i).2)
    (f : Formula n) (lo hi : ℝ) (hf : f.ieval round box = some (lo, hi)) :
    f.eval v ∈ Set.Icc lo hi := by
  induction f generalizing lo hi with
  | input i =>
      simp only [Formula.ieval, Option.some.injEq] at hf
      simpa [Formula.eval, hf] using hv i (Set.mem_univ _)
  | const c =>
      simp only [Formula.ieval, Option.some.injEq, Prod.mk.injEq] at hf
      obtain ⟨rfl, rfl⟩ := hf
      exact ⟨le_rfl, le_rfl⟩
  | add f g ihf ihg =>
      cases hX : f.ieval round box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval round box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
            Option.some.injEq] at hf
          have hm := iv_add_mem (ihf a b hX) (ihg c d hY)
          have hr := hround (ivAdd (a, b) (c, d))
          rw [hf] at hr
          exact ⟨hr.1.trans hm.1, hm.2.trans hr.2⟩
  | sub f g ihf ihg =>
      cases hX : f.ieval round box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval round box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
            Option.some.injEq] at hf
          have hm := iv_sub_mem (ihf a b hX) (ihg c d hY)
          have hr := hround (ivSub (a, b) (c, d))
          rw [hf] at hr
          exact ⟨hr.1.trans hm.1, hm.2.trans hr.2⟩
  | mul f g ihf ihg =>
      cases hX : f.ieval round box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval round box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
            Option.some.injEq] at hf
          have hm := iv_mul_mem (ihf a b hX) (ihg c d hY)
          have hr := hround (ivMul (a, b) (c, d))
          rw [hf] at hr
          exact ⟨hr.1.trans hm.1, hm.2.trans hr.2⟩
  | div f g ihf ihg =>
      cases hX : f.ieval round box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval round box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some] at hf
          split_ifs at hf with h0
          simp only [Option.pure_def, Option.some.injEq] at hf
          have hm := iv_div_mem (ihf a b hX) (ihg c d hY) h0
          have hr := hround (ivDiv (a, b) (c, d))
          rw [hf] at hr
          exact ⟨hr.1.trans hm.1, hm.2.trans hr.2⟩

/-- Exactness when each input appears once. In exact arithmetic (no rounding), if every input
interval is a genuine interval, no divisor interval contains zero, and no input appears twice in
the formula, then the interval the rules return is exactly the set of values the formula takes
as the inputs range over their intervals: every point of `[lo, hi]` is reached. -/
theorem interval_evaluation_exact_of_each_input_once {n : ℕ} (box : Fin n → ℝ × ℝ)
    (hbox : ∀ i, (box i).1 ≤ (box i).2) (f : Formula n) (honce : f.inputs.Nodup)
    (lo hi : ℝ) (hf : f.ieval id box = some (lo, hi)) :
    (fun v => f.eval v) '' (Set.univ.pi fun i => Set.Icc (box i).1 (box i).2) = Set.Icc lo hi := by
  classical
  have hne : (Set.univ.pi fun i => Set.Icc (box i).1 (box i).2).Nonempty :=
    ⟨fun i => (box i).1, fun i _ => ⟨le_rfl, hbox i⟩⟩
  -- the ends of a nonempty image are in order
  have hord : ∀ (g : Formula n) (a b : ℝ),
      (fun v => g.eval v) '' (Set.univ.pi fun i => Set.Icc (box i).1 (box i).2) = Set.Icc a b →
      a ≤ b := by
    intro g a b h
    have := hne.image (fun v => g.eval v)
    rw [h] at this
    exact Set.nonempty_Icc.mp this
  induction f generalizing lo hi with
  | input i =>
      simp only [Formula.ieval, Option.some.injEq] at hf
      simp only [Formula.eval]
      rw [Set.eval_image_univ_pi hne, hf]
  | const c =>
      simp only [Formula.ieval, Option.some.injEq, Prod.mk.injEq] at hf
      obtain ⟨rfl, rfl⟩ := hf
      simp only [Formula.eval]
      rw [hne.image_const, Set.Icc_self]
  | add f g ihf ihg =>
      rw [Formula.inputs, List.nodup_append] at honce
      obtain ⟨hf1, hg1, hdisj⟩ := honce
      cases hX : f.ieval id box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval id box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
            Option.some.injEq, id] at hf
          have e1 : lo = (ivAdd (a, b) (c, d)).1 := by rw [hf]
          have e2 : hi = (ivAdd (a, b) (c, d)).2 := by rw [hf]
          subst e1 e2
          have hfa := ihf hf1 a b hX
          have hgc := ihg hg1 c d hY
          simp only [Formula.eval]
          rw [Formula.image_pair f g _ (fun i hi hig => hdisj i hi i hig rfl) HAdd.hAdd, hfa, hgc]
          have hab := hord f a b hfa
          have hcd := hord g c d hgc
          exact image_rect_eq HAdd.hAdd (continuous_fst.add continuous_snd).continuousOn
            (fun x hx y hy => iv_add_mem hx hy) ⟨a, ⟨le_rfl, hab⟩, c, ⟨le_rfl, hcd⟩, rfl⟩
            ⟨b, ⟨hab, le_rfl⟩, d, ⟨hcd, le_rfl⟩, rfl⟩
  | sub f g ihf ihg =>
      rw [Formula.inputs, List.nodup_append] at honce
      obtain ⟨hf1, hg1, hdisj⟩ := honce
      cases hX : f.ieval id box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval id box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
            Option.some.injEq, id] at hf
          have e1 : lo = (ivSub (a, b) (c, d)).1 := by rw [hf]
          have e2 : hi = (ivSub (a, b) (c, d)).2 := by rw [hf]
          subst e1 e2
          have hfa := ihf hf1 a b hX
          have hgc := ihg hg1 c d hY
          simp only [Formula.eval]
          rw [Formula.image_pair f g _ (fun i hi hig => hdisj i hi i hig rfl) HSub.hSub, hfa, hgc]
          have hab := hord f a b hfa
          have hcd := hord g c d hgc
          exact image_rect_eq HSub.hSub (continuous_fst.sub continuous_snd).continuousOn
            (fun x hx y hy => iv_sub_mem hx hy) ⟨a, ⟨le_rfl, hab⟩, d, ⟨hcd, le_rfl⟩, rfl⟩
            ⟨b, ⟨hab, le_rfl⟩, c, ⟨le_rfl, hcd⟩, rfl⟩
  | mul f g ihf ihg =>
      rw [Formula.inputs, List.nodup_append] at honce
      obtain ⟨hf1, hg1, hdisj⟩ := honce
      cases hX : f.ieval id box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval id box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
            Option.some.injEq, id] at hf
          have e1 : lo = (ivMul (a, b) (c, d)).1 := by rw [hf]
          have e2 : hi = (ivMul (a, b) (c, d)).2 := by rw [hf]
          subst e1 e2
          have hfa := ihf hf1 a b hX
          have hgc := ihg hg1 c d hY
          simp only [Formula.eval]
          rw [Formula.image_pair f g _ (fun i hi hig => hdisj i hi i hig rfl) HMul.hMul, hfa, hgc]
          have hab := hord f a b hfa
          have hcd := hord g c d hgc
          exact image_rect_eq HMul.hMul (continuous_fst.mul continuous_snd).continuousOn
            (fun x hx y hy => iv_mul_mem hx hy) (iv_mul_corners hab hcd).1 (iv_mul_corners hab hcd).2
  | div f g ihf ihg =>
      rw [Formula.inputs, List.nodup_append] at honce
      obtain ⟨hf1, hg1, hdisj⟩ := honce
      cases hX : f.ieval id box with
      | none => simp [Formula.ieval, hX] at hf
      | some X =>
        cases hY : g.ieval id box with
        | none => simp [Formula.ieval, hX, hY] at hf
        | some Y =>
          obtain ⟨a, b⟩ := X
          obtain ⟨c, d⟩ := Y
          simp only [Formula.ieval, hX, hY, Option.bind_eq_bind, Option.bind_some] at hf
          split_ifs at hf with h0
          simp only [Option.pure_def, Option.some.injEq, id] at hf
          have e1 : lo = (ivDiv (a, b) (c, d)).1 := by rw [hf]
          have e2 : hi = (ivDiv (a, b) (c, d)).2 := by rw [hf]
          subst e1 e2
          have hfa := ihf hf1 a b hX
          have hgc := ihg hg1 c d hY
          simp only [Formula.eval]
          rw [Formula.image_pair f g _ (fun i hi hig => hdisj i hi i hig rfl) HDiv.hDiv, hfa, hgc]
          have hab := hord f a b hfa
          have hcd := hord g c d hgc
          exact image_rect_eq HDiv.hDiv
            (continuousOn_fst.div continuousOn_snd fun p hp => (iv_inv_mem hp.2 h0).1)
            (fun x hx y hy => iv_div_mem hx hy h0) (iv_div_corners hab hcd).1
            (iv_div_corners hab hcd).2

/-- One solver update `x ← x - 0.5 (x - 10)` run on an interval by the card's rules, as written,
with `x` used twice. -/
noncomputable def asWrittenUpdate (X : ℝ × ℝ) : ℝ × ℝ :=
  ivSub X (ivMul (1 / 2, 1 / 2) (ivSub X (10, 10)))

/-- Why long computations blow up. Start from `[lo, hi]` with `lo ≤ hi` and repeat the update
`x ← x - 0.5 (x - 10)` `k` times. As written, in interval arithmetic, the width grows 1.5 times
a step, to `1.5^k (hi - lo)`; yet the true values from `[lo, hi]` fill exactly
`[10 + (lo - 10)/2^k, 10 + (hi - 10)/2^k]`, whose width `(hi - lo)/2^k` halves a step. -/
theorem solver_update_interval_widens_while_truth_halves (lo hi : ℝ) (h : lo ≤ hi) (k : ℕ) :
    (asWrittenUpdate^[k] (lo, hi)).2 - (asWrittenUpdate^[k] (lo, hi)).1 = (3 / 2) ^ k * (hi - lo) ∧
    (fun x : ℝ => x - 1 / 2 * (x - 10))^[k] '' Set.Icc lo hi =
      Set.Icc (10 + (lo - 10) / 2 ^ k) (10 + (hi - 10) / 2 ^ k) := by
  constructor
  · have key : ∀ k : ℕ, ∀ l u : ℝ, l ≤ u →
        (asWrittenUpdate^[k] (l, u)).1 ≤ (asWrittenUpdate^[k] (l, u)).2 ∧
        (asWrittenUpdate^[k] (l, u)).2 - (asWrittenUpdate^[k] (l, u)).1 = (3 / 2) ^ k * (u - l) := by
      intro k
      induction k with
      | zero => intro l u hlu; simp [hlu]
      | succ k ih =>
        intro l u hlu
        have step : asWrittenUpdate (l, u) = (l - (u - 10) / 2, u - (l - 10) / 2) := by
          simp only [asWrittenUpdate, ivSub, ivMul, min_self, max_self]
          rw [min_eq_left (by linarith), max_eq_right (by linarith)]
          ext <;> simp only <;> ring
        rw [Function.iterate_succ_apply, step]
        obtain ⟨h1, h2⟩ := ih (l - (u - 10) / 2) (u - (l - 10) / 2) (by linarith)
        exact ⟨h1, by rw [h2, pow_succ]; ring⟩
    exact (key k lo hi h).2
  · have hg : ∀ k : ℕ, (fun x : ℝ => x - 1 / 2 * (x - 10))^[k] = fun x => 10 + (x - 10) / 2 ^ k := by
      intro k
      induction k with
      | zero => funext x; simp
      | succ k ih =>
        funext x
        rw [Function.iterate_succ_apply', ih]
        field_simp
        ring
    rw [hg k]
    have hp : (0 : ℝ) < 2 ^ k := by positivity
    ext z
    simp only [Set.mem_image, Set.mem_Icc]
    constructor
    · rintro ⟨x, ⟨h1, h2⟩, rfl⟩
      exact ⟨by gcongr, by gcongr⟩
    · rintro ⟨h1, h2⟩
      have h1' := (div_le_iff₀ hp).mp (by linarith : (lo - 10) / 2 ^ k ≤ z - 10)
      have h2' := (le_div_iff₀ hp).mp (by linarith : z - 10 ≤ (hi - 10) / 2 ^ k)
      refine ⟨10 + (z - 10) * 2 ^ k, ⟨by linarith, by linarith⟩, ?_⟩
      field_simp
      ring

-- The card's exact worked numbers, with lengths in centimetres so every input is a whole number.

-- Load P = cart + cargo = [29, 31] + [19, 21] = [48, 52] kN.
example : ivAdd (29, 31) (19, 21) = (48, 52) := by norm_num [ivAdd]

-- L - a = [1995, 2005] - [790, 810] = [1185, 1215] cm: width 30 = 10 + 20, widths add.
example : ivSub (1995, 2005) (790, 810) = (1185, 1215) := by norm_num [ivSub]

-- The wrong subtraction, low minus low and high minus high, is upside down: [1205, 1195].
example : ((1995 : ℝ) - 790, (2005 : ℝ) - 810) = (1205, 1195) := by norm_num

-- Moment P × c with c = [-2, 3] cm: four corners -96, 144, -104, 156 give [-104, 156] kN cm,
-- and low × low, high × high alone gives [-96, 156], missing -104.
example : ivMul (48, 52) (-2, 3) = (-104, 156) := by norm_num [ivMul]
example : ((48 : ℝ) * -2, (52 : ℝ) * 3) = (-96, 156) := by norm_num

-- The reaction at A with inputs P (input 0), L (input 1), a (input 2), lengths in cm.
-- Nominal: 50 × (2000 - 800) / 2000 = 30 kN.
example : (50 : ℝ) * (2000 - 800) / 2000 = 30 := by norm_num

-- As written, P (L - a) / L, with L twice: [48 × 1185 / 2005, 52 × 1215 / 1995].
example : (Formula.div (.mul (.input 0) (.sub (.input 1) (.input 2))) (.input 1)).ieval id
    (![(48, 52), (1995, 2005), (790, 810)] : Fin 3 → ℝ × ℝ) =
      some (48 * 1185 / 2005, 52 * 1215 / 1995) := by
  simp only [Formula.ieval, ivMul, ivDiv, ivSub, Matrix.cons_val, id]
  norm_num [min_def, max_def]

-- Rewritten, P (1 - a / L), each input once: [48 × 1185 / 1995, 52 × 1215 / 2005], the exact range.
example : (Formula.mul (.input 0) (.sub (.const 1) (.div (.input 2) (.input 1)))).ieval id
    (![(48, 52), (1995, 2005), (790, 810)] : Fin 3 → ℝ × ℝ) =
      some (48 * 1185 / 1995, 52 * 1215 / 2005) := by
  simp only [Formula.ieval, ivMul, ivDiv, ivSub, Matrix.cons_val, id]
  norm_num [min_def, max_def]

-- The double nearest 0.1 is 3602879701896397 / 2^55, just above 1/10, and the double below it is
-- just below 1/10, so the pair [next double below 0.1, 0.1] really encloses one tenth.
example : 10 * 3602879701896396 < 2 ^ 55 ∧ 2 ^ 55 < 10 * 3602879701896397 := by norm_num

-- After 20 solver steps the as-written width over the true width is 3^20 = 3486784401,
-- the card's "3.4868 billion times too large".
example : ((3 : ℚ) / 2) ^ 20 / (1 / 2) ^ 20 = 3486784401 := by norm_num

#print axioms iv_mul_between
#print axioms iv_mul_mem
#print axioms iv_inv_mem
#print axioms iv_div_mem
#print axioms min4_choice
#print axioms max4_choice
#print axioms Formula.eval_congr
#print axioms Formula.image_pair
#print axioms iv_add_mem
#print axioms iv_sub_mem
#print axioms image_rect_eq
#print axioms iv_mul_corners
#print axioms iv_div_corners
#print axioms interval_evaluation_encloses_true_value
#print axioms interval_evaluation_exact_of_each_input_once
#print axioms solver_update_interval_widens_while_truth_halves
