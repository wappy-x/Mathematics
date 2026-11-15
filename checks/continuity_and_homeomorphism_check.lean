-- Continuity by pre-images, and homeomorphism: maps glued from two closed pieces that agree on the overlap are continuous, the circle is homeomorphic to the square through the push s and the pull r, and no continuous bijection takes the circle onto the interval [0, 1].
import Mathlib.Topology.Homeomorph.Defs
import Mathlib.Topology.Constructions
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Topology.Order.IntermediateValue

lemma max_abs_div_pos (a b t : ℝ) (ht : 0 < t) :
    max |a / t| |b / t| = max |a| |b| / t := by
  rw [abs_div, abs_div, abs_of_pos ht, max_div_div_right ht.le]

lemma sqrt_sq_add_sq_div (a b t : ℝ) (ht : 0 < t) :
    Real.sqrt ((a / t) ^ 2 + (b / t) ^ 2) = Real.sqrt (a ^ 2 + b ^ 2) / t := by
  rw [div_pow, div_pow, ← add_div, Real.sqrt_div' _ (by positivity), Real.sqrt_sq ht.le]

lemma max_abs_pos_of_circle (p : ℝ × ℝ) (hp : p.1 ^ 2 + p.2 ^ 2 = 1) :
    0 < max |p.1| |p.2| := by
  rcases eq_or_ne p.1 0 with h1 | h1
  · have h2 : p.2 ≠ 0 := by
      intro h2; rw [h1, h2] at hp; norm_num at hp
    exact lt_max_of_lt_right (abs_pos.mpr h2)
  · exact lt_max_of_lt_left (abs_pos.mpr h1)

lemma sum_sq_pos_of_square (q : ℝ × ℝ) (hq : max |q.1| |q.2| = 1) :
    0 < q.1 ^ 2 + q.2 ^ 2 := by
  rcases eq_or_ne q.1 0 with h1 | h1
  · have h2 : q.2 ≠ 0 := by
      intro h2; rw [h1, h2] at hq; norm_num at hq
    have := pow_pos (abs_pos.mpr h2) 2
    rw [sq_abs] at this
    positivity
  · have := pow_pos (abs_pos.mpr h1) 2
    rw [sq_abs] at this
    positivity

#print axioms max_abs_div_pos
#print axioms sqrt_sq_add_sq_div
#print axioms max_abs_pos_of_circle
#print axioms sum_sq_pos_of_square

/-- The pasting lemma. Let two closed pieces A and B cover the space X, and let a continuous map
be given on each piece. If the two maps give the same value at every point of the overlap A ∩ B,
then they glue to one continuous map f on all of X that equals the first map on A and the second
map on B. -/
theorem pasting_lemma {X Y : Type*} [TopologicalSpace X] [TopologicalSpace Y]
    (A B : Set X) (hA : IsClosed A) (hB : IsClosed B) (hcover : A ∪ B = Set.univ)
    (fA : A → Y) (fB : B → Y) (hfA : Continuous fA) (hfB : Continuous fB)
    (hagree : ∀ x (ha : x ∈ A) (hb : x ∈ B), fA ⟨x, ha⟩ = fB ⟨x, hb⟩) :
    ∃ f : X → Y, Continuous f ∧ (∀ x : A, f x = fA x) ∧ (∀ x : B, f x = fB x) := by
  classical
  have hmem : ∀ x, x ∉ A → x ∈ B := by
    intro x hx
    have : x ∈ A ∪ B := hcover ▸ Set.mem_univ x
    exact this.resolve_left hx
  let f : X → Y := fun x => if h : x ∈ A then fA ⟨x, h⟩ else fB ⟨x, hmem x h⟩
  have h1 : ∀ x : A, f x = fA x := by
    intro x
    simp [f, x.2]
  have h2 : ∀ x : B, f x = fB x := by
    intro x
    by_cases h : (x : X) ∈ A
    · simp only [f, h, dite_true]
      exact hagree x h x.2
    · simp [f, h]
  refine ⟨f, ?_, h1, h2⟩
  have cA : ContinuousOn f A := by
    rw [continuousOn_iff_continuous_domRestrict]
    have : A.domRestrict f = fA := funext h1
    rw [this]; exact hfA
  have cB : ContinuousOn f B := by
    rw [continuousOn_iff_continuous_domRestrict]
    have : B.domRestrict f = fB := funext h2
    rw [this]; exact hfB
  have := cA.union_of_isClosed cB hA hB
  rw [hcover] at this
  exact continuousOn_univ.mp this

/-- The circle is the square. The circle is every point (x, y) of the plane with x² + y² = 1, and
the square's outline is every point with max(|x|, |y|) = 1, each with the open sets it gets from
the plane. Some homeomorphism between them is the push s(x, y) = (x, y) / max(|x|, |y|), and its
inverse is the pull r(x, y) = (x, y) / √(x² + y²). -/
theorem circle_homeomorphic_to_square :
    ∃ e : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} ≃ₜ {p : ℝ × ℝ | max |p.1| |p.2| = 1},
      (∀ p, (e p : ℝ × ℝ) =
        ((p : ℝ × ℝ).1 / max |(p : ℝ × ℝ).1| |(p : ℝ × ℝ).2|,
         (p : ℝ × ℝ).2 / max |(p : ℝ × ℝ).1| |(p : ℝ × ℝ).2|)) ∧
      (∀ q, (e.symm q : ℝ × ℝ) =
        ((q : ℝ × ℝ).1 / Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2),
         (q : ℝ × ℝ).2 / Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2))) := by
  let s : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} → {p : ℝ × ℝ | max |p.1| |p.2| = 1} :=
    fun p => ⟨((p : ℝ × ℝ).1 / max |(p : ℝ × ℝ).1| |(p : ℝ × ℝ).2|,
         (p : ℝ × ℝ).2 / max |(p : ℝ × ℝ).1| |(p : ℝ × ℝ).2|), by
      have hm := max_abs_pos_of_circle p.1 p.2
      show max |_| |_| = 1
      rw [max_abs_div_pos _ _ _ hm, div_self hm.ne']⟩
  let r : {p : ℝ × ℝ | max |p.1| |p.2| = 1} → {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} :=
    fun q => ⟨((q : ℝ × ℝ).1 / Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2),
         (q : ℝ × ℝ).2 / Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2)), by
      have hn := sum_sq_pos_of_square q.1 q.2
      show (_ : ℝ) ^ 2 + _ ^ 2 = 1
      rw [div_pow, div_pow, Real.sq_sqrt hn.le, ← add_div, div_self hn.ne']⟩
  have hl : Function.LeftInverse r s := by
    intro p
    have hm := max_abs_pos_of_circle p.1 p.2
    have hp : (p : ℝ × ℝ).1 ^ 2 + (p : ℝ × ℝ).2 ^ 2 = 1 := p.2
    apply Subtype.ext
    obtain ⟨⟨x, y⟩, hxy⟩ := p
    simp only [r, s] at hm hp ⊢
    rw [sqrt_sq_add_sq_div _ _ _ hm, hp, Real.sqrt_one]
    ext <;> simp only [] <;> field_simp
  have hrr : Function.RightInverse r s := by
    intro q
    have hn := sum_sq_pos_of_square q.1 q.2
    have hq : max |(q : ℝ × ℝ).1| |(q : ℝ × ℝ).2| = 1 := q.2
    have hsn : 0 < Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2) := Real.sqrt_pos.mpr hn
    apply Subtype.ext
    obtain ⟨⟨x, y⟩, hxy⟩ := q
    simp only [r, s] at hn hq hsn ⊢
    rw [max_abs_div_pos _ _ _ hsn, hq]
    ext <;> simp only [] <;> field_simp
  have hcs : Continuous s := by
    apply Continuous.subtype_mk
    have hv : Continuous (fun p : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} => (p : ℝ × ℝ)) :=
      continuous_subtype_val
    have hm : Continuous (fun p : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} =>
        max |(p : ℝ × ℝ).1| |(p : ℝ × ℝ).2|) :=
      (continuous_fst.comp hv).abs.max (continuous_snd.comp hv).abs
    have hne : ∀ p : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1},
        max |(p : ℝ × ℝ).1| |(p : ℝ × ℝ).2| ≠ 0 :=
      fun p => (max_abs_pos_of_circle p.1 p.2).ne'
    exact ((continuous_fst.comp hv).div hm hne).prodMk ((continuous_snd.comp hv).div hm hne)
  have hcr : Continuous r := by
    apply Continuous.subtype_mk
    have hv : Continuous (fun p : {p : ℝ × ℝ | max |p.1| |p.2| = 1} => (p : ℝ × ℝ)) :=
      continuous_subtype_val
    have hm : Continuous (fun q : {p : ℝ × ℝ | max |p.1| |p.2| = 1} =>
        Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2)) :=
      (((continuous_fst.comp hv).pow 2).add ((continuous_snd.comp hv).pow 2)).sqrt
    have hne : ∀ q : {p : ℝ × ℝ | max |p.1| |p.2| = 1},
        Real.sqrt ((q : ℝ × ℝ).1 ^ 2 + (q : ℝ × ℝ).2 ^ 2) ≠ 0 :=
      fun q => (Real.sqrt_pos.mpr (sum_sq_pos_of_square q.1 q.2)).ne'
    exact ((continuous_fst.comp hv).div hm hne).prodMk ((continuous_snd.comp hv).div hm hne)
  exact ⟨⟨⟨s, r, hl, hrr⟩, hcs, hcr⟩, fun p => rfl, fun q => rfl⟩

/-- The circle is not the interval. No continuous map from the circle onto [0, 1] pairs their
points one for one, so certainly the circle and [0, 1] are not homeomorphic. -/
theorem no_continuous_bijection_circle_to_interval :
    ¬ ∃ f : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} → Set.Icc (0 : ℝ) 1,
      Continuous f ∧ Function.Bijective f := by
  rintro ⟨f, hf, hbij⟩
  let c : ℝ → {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} := fun t =>
    ⟨(Real.cos t, Real.sin t), by simp [Real.cos_sq_add_sin_sq]⟩
  have hc : Continuous c := by
    apply Continuous.subtype_mk
    exact Real.continuous_cos.prodMk Real.continuous_sin
  let g : ℝ → ℝ := fun t => (f (c t) : ℝ)
  have hg : Continuous g := continuous_subtype_val.comp (hf.comp hc)
  let h : ℝ → ℝ := fun t => g t - g (t + Real.pi)
  have hh : Continuous h := hg.sub (hg.comp (continuous_id.add continuous_const))
  have h0 : h Real.pi = - h 0 := by
    have hc2 : c (Real.pi + Real.pi) = c 0 := by
      apply Subtype.ext
      have : Real.pi + Real.pi = 0 + 2 * Real.pi := by ring
      simp only [c, this, Real.cos_add_two_pi, Real.sin_add_two_pi]
    simp only [h, g, zero_add, hc2]
    ring
  have hz : (0 : ℝ) ∈ Set.uIcc (h 0) (h Real.pi) := by
    rw [h0, Set.mem_uIcc]
    rcases le_total 0 (h 0) with hle | hle
    · right; constructor <;> linarith
    · left; constructor <;> linarith
  obtain ⟨t, -, ht⟩ := intermediate_value_uIcc hh.continuousOn hz
  have heq : f (c t) = f (c (t + Real.pi)) := by
    apply Subtype.ext
    simp only [h, g] at ht
    linarith
  have := congrArg (fun p : {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = 1} => (p : ℝ × ℝ)) (hbij.1 heq)
  simp only [c, Real.cos_add_pi, Real.sin_add_pi, Prod.mk.injEq] at this
  obtain ⟨e1, e2⟩ := this
  have hcos : Real.cos t = 0 := by linarith
  have hsin : Real.sin t = 0 := by linarith
  have := Real.cos_sq_add_sin_sq t
  rw [hcos, hsin] at this
  norm_num at this

-- The wrap's arc from -30 to 30 degrees is a sixth of the circle: 1200 of 7200 sample angles.
example : 7200 / 6 = 1200 := by decide
-- (4/5, 3/5) is on the circle; s pushes it to (1, 3/4), which has length 5/4; r pulls it back.
example : (4 / 5 : ℚ) ^ 2 + (3 / 5) ^ 2 = 1 := by norm_num
example : (4 / 5 : ℚ) / max |(4 / 5 : ℚ)| |(3 / 5 : ℚ)| = 1 ∧
    (3 / 5 : ℚ) / max |(4 / 5 : ℚ)| |(3 / 5 : ℚ)| = 3 / 4 := by norm_num
example : (1 : ℚ) ^ 2 + (3 / 4) ^ 2 = (5 / 4) ^ 2 := by norm_num
example : (1 : ℚ) / (5 / 4) = 4 / 5 ∧ (3 / 4 : ℚ) / (5 / 4) = 3 / 5 := by norm_num
-- The other piece: s pushes (3/5, 4/5) to (3/4, 1).
example : (3 / 5 : ℚ) / max |(3 / 5 : ℚ)| |(4 / 5 : ℚ)| = 3 / 4 ∧
    (4 / 5 : ℚ) / max |(3 / 5 : ℚ)| |(4 / 5 : ℚ)| = 1 := by norm_num
-- One formula everywhere fails: p / |x| sends (20/29, 21/29), a circle point, to (1, 21/20), off the square.
example : (20 / 29 : ℚ) ^ 2 + (21 / 29) ^ 2 = 1 ∧ (21 / 29 : ℚ) / (20 / 29) = 21 / 20 ∧
    (1 : ℚ) < 21 / 20 := by norm_num
-- The stretch h(x) = x / (1 - |x|): h(1/2) = 1, h(9/10) = 9, h(99/100) = 99, and h-inverse(99) = 99/100.
example : (1 / 2 : ℚ) / (1 - |(1 / 2 : ℚ)|) = 1 ∧ (9 / 10 : ℚ) / (1 - |(9 / 10 : ℚ)|) = 9 ∧
    (99 / 100 : ℚ) / (1 - |(99 / 100 : ℚ)|) = 99 := by norm_num
example : (99 : ℚ) / (1 + |(99 : ℚ)|) = 99 / 100 := by norm_num
-- Flattening the cup: wall depth 9/2 lands at radius 3; the wall's foot and the floor's edge both land at radius 2.
example : (4 : ℚ) - 2 / 9 * (9 / 2) = 3 ∧ (4 : ℚ) - 2 / 9 * 9 = 2 ∧ (4 : ℚ) / 2 = 2 := by norm_num

#print axioms pasting_lemma
#print axioms circle_homeomorphic_to_square
#print axioms no_continuous_bijection_circle_to_interval
