-- Translation invariance and the Vitali set: sliding or stretching a set of reals keeps or scales its length, and a set holding one point from each group of reals that differ by a fraction has no length.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.Nat.Totient

open MeasureTheory

theorem slide_aux (E : Set ℝ) (t : ℝ) :
    volume ((fun x => x + t) '' E) = volume E ∧
    (NullMeasurableSet E volume → NullMeasurableSet ((fun x => x + t) '' E) volume) := by
  have h1 : (fun x => x + t) '' E = (fun x => x + -t) ⁻¹' E := by
    ext y; constructor
    · rintro ⟨x, hx, rfl⟩; simpa using hx
    · intro hy; exact ⟨y + -t, hy, by ring⟩
  rw [h1]
  exact ⟨measure_preimage_add_right volume (-t) E,
    fun hE => hE.preimage (measurePreserving_add_right volume (-t)).quasiMeasurePreserving⟩

#print axioms slide_aux

/-- The Vitali set has no length. Take any set `V` inside the wheel `[0, 1)` that holds exactly
one point from each group, where two points share a group when their gap is a fraction. Then `V`
is not Lebesgue measurable, and its outer measure is still positive. In Mathlib, `volume` on `ℝ`
is Lebesgue outer measure on every set, and `NullMeasurableSet V volume` says `V` is Lebesgue
measurable. -/
theorem vitali_set_not_measurable (V : Set ℝ) (hV : V ⊆ Set.Ico 0 1)
    (hone : ∀ x ∈ Set.Ico (0 : ℝ) 1, ∃! v, v ∈ V ∧ ∃ q : ℚ, x - v = q) :
    ¬ NullMeasurableSet V volume ∧ 0 < volume V := by
  set T : ℚ → Set ℝ := fun q => (fun x => x + (q : ℝ)) '' V with hT
  have hcover : Set.Ico (0 : ℝ) 1 ⊆ ⋃ q : ℚ, T q := by
    intro x hx
    obtain ⟨v, ⟨hv, q, hq⟩, -⟩ := hone x hx
    exact Set.mem_iUnion.2 ⟨q, v, hv, by simp only; linarith⟩
  have hdisj : ∀ q₁ q₂ : ℚ, q₁ ≠ q₂ → Disjoint (T q₁) (T q₂) := by
    intro q₁ q₂ hne
    rw [Set.disjoint_left]
    rintro y ⟨v₁, hv₁, rfl⟩ ⟨v₂, hv₂, h⟩
    have hu := (hone v₁ (hV hv₁)).unique (y₁ := v₁) (y₂ := v₂)
      ⟨hv₁, 0, by simp⟩ ⟨hv₂, q₂ - q₁, by push_cast; simp only at h; linarith⟩
    subst hu
    apply hne
    exact_mod_cast (show (q₁ : ℝ) = q₂ by simp only at h; linarith)
  have hpos : 0 < volume V := by
    rw [pos_iff_ne_zero]
    intro h0
    have : volume (⋃ q : ℚ, T q) = 0 :=
      measure_iUnion_null fun q => by rw [(slide_aux V q).1, h0]
    have h1 := measure_mono_null hcover this
    simp at h1
  refine ⟨?_, hpos⟩
  intro hmeas
  set S : ℕ → Set ℝ := fun n => T ((1 : ℚ) / (n + 1)) with hS
  have hSdisj : Pairwise (Function.onFun (AEDisjoint volume) S) := by
    intro m n hmn
    apply Disjoint.aedisjoint
    apply hdisj
    intro h
    apply hmn
    have : ((m : ℚ) + 1) = n + 1 := by
      have hm : (0 : ℚ) < m + 1 := by positivity
      have hn : (0 : ℚ) < n + 1 := by positivity
      field_simp at h
      linarith
    exact_mod_cast (by linarith : (m : ℚ) = n)
  have hSm : ∀ n, NullMeasurableSet (S n) volume := fun n => (slide_aux V _).2 hmeas
  have hsum := measure_iUnion₀ hSdisj hSm
  have hconst : ∀ n, volume (S n) = volume V := fun n => (slide_aux V _).1
  simp only [hconst, ENNReal.tsum_const_eq_top_of_ne_zero hpos.ne'] at hsum
  have hsub : (⋃ n, S n) ⊆ Set.Ioo (0 : ℝ) 2 := by
    intro y hy
    obtain ⟨n, v, hv, rfl⟩ := Set.mem_iUnion.1 hy
    have hv' := hV hv
    have h1 : (0 : ℝ) < ((1 : ℚ) / (n + 1) : ℚ) := by
      have : (0 : ℚ) < 1 / (n + 1) := by positivity
      exact_mod_cast this
    have h2 : (((1 : ℚ) / (n + 1) : ℚ) : ℝ) ≤ 1 := by
      have : (1 : ℚ) / (n + 1) ≤ 1 := by
        rw [div_le_one (by positivity)]; linarith [(n.cast_nonneg : (0 : ℚ) ≤ n)]
      exact_mod_cast this
    simp only [Set.mem_Ico] at hv'
    constructor <;> simp only <;> linarith [hv'.1, hv'.2]
  have := measure_mono (μ := volume) hsub
  rw [hsum] at this
  simp at this

/-- Vitali's theorem: the axiom of choice gives a set inside `[0, 1)` with exactly one point from
each group of points that differ by a fraction, and that set is not Lebesgue measurable while its
outer measure is positive. -/
theorem exists_set_with_no_length :
    ∃ V : Set ℝ, V ⊆ Set.Ico 0 1 ∧
      (∀ x ∈ Set.Ico (0 : ℝ) 1, ∃! v, v ∈ V ∧ ∃ q : ℚ, x - v = q) ∧
      ¬ NullMeasurableSet V volume ∧ 0 < volume V := by
  let s : Setoid ℝ :=
    { r := fun x y => ∃ q : ℚ, x - y = q
      iseqv := ⟨fun x => ⟨0, by simp⟩,
        fun ⟨q, hq⟩ => ⟨-q, by push_cast; linarith⟩,
        fun ⟨q, hq⟩ ⟨p, hp⟩ => ⟨q + p, by push_cast; linarith⟩⟩ }
  have hex : ∀ c : Quotient s, ∃ y ∈ Set.Ico (0 : ℝ) 1, Quotient.mk s y = c := by
    intro c
    induction c using Quotient.inductionOn with
    | h x =>
      refine ⟨Int.fract x, ⟨Int.fract_nonneg x, Int.fract_lt_one x⟩, ?_⟩
      apply Quotient.sound
      exact ⟨-(⌊x⌋ : ℚ), by rw [Int.fract]; push_cast; ring⟩
  choose g hg hgc using hex
  have hV : Set.range g ⊆ Set.Ico 0 1 := by
    rintro _ ⟨c, rfl⟩; exact hg c
  have hone : ∀ x ∈ Set.Ico (0 : ℝ) 1, ∃! v, v ∈ Set.range g ∧ ∃ q : ℚ, x - v = q := by
    intro x _
    refine ⟨g (Quotient.mk s x), ⟨⟨_, rfl⟩, ?_⟩, ?_⟩
    · have : s.r x (g (Quotient.mk s x)) := Quotient.exact (hgc _).symm
      exact this
    · rintro w ⟨⟨c, rfl⟩, hq⟩
      have h1 : Quotient.mk s x = Quotient.mk s (g c) := Quotient.sound hq
      rw [h1, hgc]
  exact ⟨Set.range g, hV, hone, vitali_set_not_measurable _ hV hone⟩

/-- The slide and stretch rules. For every set `E` of reals, every slide `t` and every nonzero
stretch `c`: sliding `E` by `t` leaves its outer measure unchanged, and stretching it by `c`
multiplies its outer measure by `|c|`. If `E` is Lebesgue measurable, so are the slid and the
stretched sets (so the same rules hold for Lebesgue measure). -/
theorem length_ignores_slides_and_scales_with_stretches (E : Set ℝ) (t c : ℝ) (hc : c ≠ 0) :
    volume ((fun x => x + t) '' E) = volume E ∧
    volume ((fun x => c * x) '' E) = ENNReal.ofReal |c| * volume E ∧
    (NullMeasurableSet E volume →
      NullMeasurableSet ((fun x => x + t) '' E) volume ∧
      NullMeasurableSet ((fun x => c * x) '' E) volume) := by
  have h1 : (fun x => x + t) '' E = (fun x => x + -t) ⁻¹' E := by
    ext y; constructor
    · rintro ⟨x, hx, rfl⟩; simpa using hx
    · intro hy; exact ⟨y + -t, hy, by ring⟩
  have h2 : (fun x => c * x) '' E = (fun x => c⁻¹ * x) ⁻¹' E := by
    ext y; constructor
    · rintro ⟨x, hx, rfl⟩; simpa [hc] using hx
    · intro hy; exact ⟨c⁻¹ * y, hy, by field_simp⟩
  refine ⟨?_, ?_, ?_⟩
  · rw [h1]; exact measure_preimage_add_right volume (-t) E
  · rw [h2, Real.volume_preimage_mul_left (inv_ne_zero hc), inv_inv]
  · intro hE
    refine ⟨?_, ?_⟩
    · rw [h1]
      exact hE.preimage (measurePreserving_add_right volume (-t)).quasiMeasurePreserving
    · rw [h2]
      refine hE.preimage ⟨measurable_const_mul _, ?_⟩
      rw [Real.map_volume_mul_left (inv_ne_zero hc)]
      exact Measure.smul_absolutelyContinuous

-- Worked numbers, row 5: stretching length 3/5 by 3 gives 9/5. Row 6: by -2 gives |-2| * 3/5 = 6/5.
example : (3 : ℚ) * (3 / 5) = 9 / 5 ∧ |(-2 : ℚ)| * (3 / 5) = 6 / 5 := by norm_num

-- Row 7: Euler's totient for denominators 1 to 10 is 1, 1, 2, 2, 4, 2, 6, 4, 6, 4, adding to 32.
example : (List.range' 1 10).map Nat.totient = [1, 1, 2, 2, 4, 2, 6, 4, 6, 4] := by decide
example : (Finset.Icc 1 10).sum Nat.totient = 32 := by decide

-- K(10) = 32: there are 32 distinct fractions a/d in [0, 1) with denominator d at most 10.
example : ((Finset.Icc 1 10).biUnion fun d =>
    (Finset.range d).image fun a : ℕ => (a : ℚ) / d).card = 32 := by decide +kernel

-- Row 9: K(100) = 3044, by counting numerators a < d that share no factor with d, d at most 100,
-- and by summing the totient.
example : ((Finset.Icc 1 100).sum fun d =>
    ((Finset.range d).filter fun a => Nat.Coprime a d).card) = 3044 := by decide +kernel
example : (Finset.Icc 1 100).sum Nat.totient = 3044 := by decide +kernel

-- Giving V the size 1/1000: 1000 copies reach only 1, the 1001st copy passes 1.
example : (1000 : ℚ) * (1 / 1000) ≤ 1 ∧ 1 < (1001 : ℚ) * (1 / 1000) := by norm_num

-- The finite wheel of 360 positions: the choice set {0, ..., 29}, turned by 30 * j for
-- j = 0, ..., 11, covers every position exactly once.
example : ∀ x ∈ Finset.range 360,
    ((Finset.range 30 ×ˢ Finset.range 12).filter
      fun p => (p.1 + 30 * p.2) % 360 = x).card = 1 := by
  decide +kernel

-- The scrambled choice r + 30 * ((7 * r) mod 12) also tiles the finite wheel exactly once.
example : ∀ x ∈ Finset.range 360,
    ((Finset.range 30 ×ˢ Finset.range 12).filter
      fun p => (p.1 + 30 * ((7 * p.1) % 12) + 30 * p.2) % 360 = x).card = 1 := by
  decide +kernel

#print axioms vitali_set_not_measurable
#print axioms exists_set_with_no_length
#print axioms length_ignores_slides_and_scales_with_stretches
