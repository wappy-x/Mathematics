-- Torsion points: on y² = x³ + ax + b with whole a, b, a torsion point has whole coordinates with y = 0 or y² dividing 4a³ + 27b², a point has order dividing 3 exactly when 3x⁴ + 6ax² + 12bx − a² = 0, and y² = x³ − 2 has no rational torsion point but O.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.Padics.PadicNorm
import Mathlib.Tactic

open WeierstrassCurve

/-- The short Weierstrass curve `y² = x³ + a x + b` over the rationals. -/
def shortCurve (a b : ℚ) : WeierstrassCurve ℚ :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := a, a₆ := b }

lemma core_identity (l n x1 x2 a b : ℚ)
    (ha : a = x1 * x2 + (x1 + x2) * (l ^ 2 - x1 - x2) + 2 * l * n)
    (hb : b = n ^ 2 - x1 * x2 * (l ^ 2 - x1 - x2))
    (hy1 : l * x1 + n ≠ 0) (hy2 : l * x2 + n ≠ 0)
    (hD : n ^ 3 + a * l ^ 2 * n - b * l ^ 3 ≠ 0) :
    l ^ 2 - x1 - x2 = (l * (l ^ 2 - x1 - x2) + n) *
      (-(x1 / (l * x1 + n)) - x2 / (l * x2 + n) -
        (3 * b * l ^ 2 - 2 * a * l * n) / (n ^ 3 + a * l ^ 2 * n - b * l ^ 3)) := by
  generalize hDd : n ^ 3 + a * l ^ 2 * n - b * l ^ 3 = D at hD ⊢
  generalize hy1d : l * x1 + n = y1 at hy1 ⊢
  generalize hy2d : l * x2 + n = y2 at hy2 ⊢
  field_simp
  subst ha hb hy1d hy2d hDd
  ring

section padic
variable {p : ℕ} [Fact p.Prime]

lemma pn_add_le {q r c : ℚ} (hq : padicNorm p q ≤ c) (hr : padicNorm p r ≤ c) :
    padicNorm p (q + r) ≤ c :=
  padicNorm.nonarchimedean.trans (max_le hq hr)

lemma pn_sub_le {q r c : ℚ} (hq : padicNorm p q ≤ c) (hr : padicNorm p r ≤ c) :
    padicNorm p (q - r) ≤ c :=
  padicNorm.sub.trans (max_le hq hr)

lemma pn_mul_le {q r c d : ℚ} (hq : padicNorm p q ≤ c) (hr : padicNorm p r ≤ d) :
    padicNorm p (q * r) ≤ c * d := by
  rw [padicNorm.mul]
  exact mul_le_mul hq hr (padicNorm.nonneg _) ((padicNorm.nonneg _).trans hq)

lemma pn_pow (q : ℚ) (n : ℕ) : padicNorm p (q ^ n) = padicNorm p q ^ n := by
  induction n with
  | zero => simp
  | succ n ih => rw [pow_succ, padicNorm.mul, ih, pow_succ]

lemma pn_pow_le {q c : ℚ} (hq : padicNorm p q ≤ c) (n : ℕ) : padicNorm p (q ^ n) ≤ c ^ n := by
  rw [pn_pow]; exact pow_le_pow_left₀ (padicNorm.nonneg _) hq n

lemma pn_one_sub {z : ℚ} (hz : padicNorm p z < 1) : padicNorm p (1 - z) = 1 := by
  have hne : padicNorm p 1 ≠ padicNorm p (-z) := by
    rw [padicNorm.one, padicNorm.neg]; exact hz.ne'
  rw [sub_eq_add_neg, padicNorm.add_eq_max_of_ne hne, padicNorm.one, padicNorm.neg,
    max_eq_left hz.le]

lemma pn_two : padicNorm p (2 : ℚ) ≤ 1 := by simpa using padicNorm.of_nat (p := p) 2

lemma pn_three : padicNorm p (3 : ℚ) ≤ 1 := by simpa using padicNorm.of_nat (p := p) 3

/-- On `y² = x³ + a x + b` with `|a|, |b| ≤ 1` and `|x| > 1`, `|y|² = |x|³`. -/
lemma pn_curve {a b x y : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1)
    (he : y ^ 2 = x ^ 3 + a * x + b) (hx : 1 < padicNorm p x) :
    padicNorm p y ^ 2 = padicNorm p x ^ 3 := by
  have h0 := padicNorm.nonneg (p := p) x
  have h1 : padicNorm p (a * x + b) ≤ padicNorm p x := by
    apply pn_add_le
    · rw [padicNorm.mul]; nlinarith [padicNorm.nonneg (p := p) a]
    · linarith
  have h3 : padicNorm p x < padicNorm p x ^ 3 := by
    have h2 : 1 < padicNorm p x ^ 2 := one_lt_pow₀ hx two_ne_zero
    calc padicNorm p x = padicNorm p x * 1 := (mul_one _).symm
      _ < padicNorm p x * padicNorm p x ^ 2 := mul_lt_mul_of_pos_left h2 (by linarith)
      _ = padicNorm p x ^ 3 := by ring
  have hne : padicNorm p (x ^ 3) ≠ padicNorm p (a * x + b) := by
    rw [pn_pow]; exact (lt_of_le_of_lt h1 h3).ne'
  rw [← pn_pow, he, add_assoc, padicNorm.add_eq_max_of_ne hne, pn_pow, max_eq_left]
  linarith

lemma pn_ts {a b x y : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1)
    (he : y ^ 2 = x ^ 3 + a * x + b) (hx : 1 < padicNorm p x) :
    y ≠ 0 ∧ x / y ≠ 0 ∧ padicNorm p (x / y) < 1 ∧
      padicNorm p (1 / y) = padicNorm p (x / y) ^ 3 := by
  have hc := pn_curve ha hb he hx
  have hv0 := padicNorm.nonneg (p := p) y
  have hv : 0 < padicNorm p y := by
    rcases hv0.lt_or_eq with h | h
    · exact h
    · rw [← h] at hc
      have := one_lt_pow₀ hx (by norm_num : (3 : ℕ) ≠ 0)
      simp at hc; linarith
  have hy : y ≠ 0 := fun h => by simp [h, padicNorm.zero] at hv
  have hx0 : x ≠ 0 := fun h => by simp [h, padicNorm.zero] at hx; linarith
  refine ⟨hy, div_ne_zero hx0 hy, ?_, ?_⟩
  · rw [padicNorm.div, div_lt_one hv]
    have h2 : padicNorm p x ^ 2 < padicNorm p x ^ 3 := pow_lt_pow_right₀ hx (by norm_num)
    by_contra hle
    have := pow_le_pow_left₀ hv0 (not_lt.1 hle) 2
    linarith
  · rw [padicNorm.div, padicNorm.div, padicNorm.one, div_pow]
    field_simp
    nlinarith

lemma ts_eq {a b x y : ℚ} (he : y ^ 2 = x ^ 3 + a * x + b) (hy : y ≠ 0) :
    1 / y = (x / y) ^ 3 + a * (x / y) * (1 / y) ^ 2 + b * (1 / y) ^ 3 := by
  field_simp
  linear_combination he


lemma chord_ab {a b x1 y1 x2 y2 r : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1)
    (he1 : y1 ^ 2 = x1 ^ 3 + a * x1 + b) (he2 : y2 ^ 2 = x2 ^ 3 + a * x2 + b)
    (hx1 : 1 < padicNorm p x1) (hx2 : 1 < padicNorm p x2) (hne : x1 ≠ x2)
    (hr1 : padicNorm p (x1 / y1) ≤ r) (hr2 : padicNorm p (x2 / y2) ≤ r) (hr : r < 1) :
    ∃ α β : ℚ, (y1 - (y1 - y2) / (x1 - x2) * x1) * β = 1 ∧
      (y1 - y2) / (x1 - x2) = -α * (y1 - (y1 - y2) / (x1 - x2) * x1) ∧
      padicNorm p α ≤ r ^ 2 ∧ padicNorm p β ≤ r ^ 3 := by
  obtain ⟨hy1, -, -, hs1⟩ := pn_ts ha hb he1 hx1
  obtain ⟨hy2, -, -, hs2⟩ := pn_ts ha hb he2 hx2
  have e1 := ts_eq he1 hy1
  have e2 := ts_eq he2 hy2
  have r0 : 0 ≤ r := (padicNorm.nonneg _).trans hr1
  have r1 : r ≤ 1 := hr.le
  have hx1e : x1 = x1 / y1 * y1 := by field_simp
  have hx2e : x2 = x2 / y2 * y2 := by field_simp
  have hs1e : 1 / y1 * y1 = 1 := by field_simp
  have hs2e : 1 / y2 * y2 = 1 := by field_simp
  generalize x1 / y1 = t1 at hr1 hs1 e1 hx1e
  generalize x2 / y2 = t2 at hr2 hs2 e2 hx2e
  generalize hs1d : 1 / y1 = s1 at hs1 e1 hs1e
  generalize hs2d : 1 / y2 = s2 at hs2 e2 hs2e
  have r3 : r ^ 3 ≤ r := by nlinarith [pow_le_one₀ r0 r1 (n := 2)]
  have hs1r : padicNorm p s1 ≤ r ^ 3 := hs1 ▸ pow_le_pow_left₀ (padicNorm.nonneg _) hr1 3
  have hs2r : padicNorm p s2 ≤ r ^ 3 := hs2 ▸ pow_le_pow_left₀ (padicNorm.nonneg _) hr2 3
  have hs1' : padicNorm p s1 ≤ r := hs1r.trans r3
  have hs2' : padicNorm p s2 ≤ r := hs2r.trans r3
  have hs1'' : padicNorm p s1 ≤ 1 := hs1'.trans r1
  have hs2'' : padicNorm p s2 ≤ 1 := hs2'.trans r1
  have hZ : padicNorm p (a * t1 * (s2 + s1) + b * (s2 ^ 2 + s1 * s2 + s1 ^ 2)) ≤ r := by
    apply pn_add_le
    · have := pn_mul_le (pn_mul_le ha hr1) (pn_add_le hs2'' hs1'')
      simpa using this
    · have r2 : r ^ 2 ≤ r := by nlinarith
      have := pn_mul_le hb (pn_add_le (pn_add_le ((pn_pow_le hs2' 2).trans r2)
        ((pn_mul_le hs1' hs2'').trans_eq (mul_one r))) ((pn_pow_le hs1' 2).trans r2))
      simpa using this
  have hU := pn_one_sub (hZ.trans_lt hr)
  have hU0 : 1 - (a * t1 * (s2 + s1) + b * (s2 ^ 2 + s1 * s2 + s1 ^ 2)) ≠ 0 := by
    intro h0; rw [h0, padicNorm.zero] at hU; exact zero_ne_one hU
  have hV : padicNorm p (t2 ^ 2 + t1 * t2 + t1 ^ 2 + a * s2 ^ 2) ≤ r ^ 2 := by
    refine pn_add_le (pn_add_le (pn_add_le (pn_pow_le hr2 2) ?_) (pn_pow_le hr1 2)) ?_
    · exact (pn_mul_le hr1 hr2).trans_eq (by ring)
    · refine (pn_mul_le ha (pn_pow_le hs2r 2)).trans ?_
      rw [one_mul, ← pow_mul]
      exact pow_le_pow_of_le_one r0 r1 (by norm_num)
  have hUV : (1 - (a * t1 * (s2 + s1) + b * (s2 ^ 2 + s1 * s2 + s1 ^ 2))) * (s2 - s1) =
      (t2 ^ 2 + t1 * t2 + t1 ^ 2 + a * s2 ^ 2) * (t2 - t1) := by
    linear_combination e2 - e1
  have ht : t1 ≠ t2 := by
    intro heq
    have h0 : (1 - (a * t1 * (s2 + s1) + b * (s2 ^ 2 + s1 * s2 + s1 ^ 2))) * (s2 - s1) = 0 := by
      rw [hUV, heq, sub_self, mul_zero]
    rcases mul_eq_zero.1 h0 with h | h
    · exact hU0 h
    · have hs : s1 = s2 := (sub_eq_zero.1 h).symm
      rw [← hs1d, ← hs2d, one_div, one_div, inv_inj] at hs
      exact hne (by rw [hx1e, hx2e, heq, hs])
  set U := 1 - (a * t1 * (s2 + s1) + b * (s2 ^ 2 + s1 * s2 + s1 ^ 2)) with hUd
  set V := t2 ^ 2 + t1 * t2 + t1 ^ 2 + a * s2 ^ 2 with hVd
  have hs2α : s2 = V / U * t2 + (s1 - V / U * t1) := by
    field_simp
    linear_combination hUV
  set α := V / U with hαd
  set β := s1 - α * t1 with hβd
  have h1x : α * x1 + β * y1 = 1 := by
    rw [hβd]; linear_combination α * hx1e + hs1e
  have h2x : α * x2 + β * y2 = 1 := by
    linear_combination α * hx2e + hs2e - y2 * hs2α
  have hx : x1 - x2 ≠ 0 := sub_ne_zero.2 hne
  have hβ0 : β ≠ 0 := by
    intro h0
    rw [h0, zero_mul, add_zero] at h1x h2x
    have : α * (x1 - x2) = 0 := by linear_combination h1x - h2x
    rcases mul_eq_zero.1 this with h | h
    · rw [h, zero_mul] at h1x; exact zero_ne_one h1x
    · exact hx h
  have hαr : padicNorm p α ≤ r ^ 2 := by rw [hαd, padicNorm.div, hU, div_one]; exact hV
  have hβr : padicNorm p β ≤ r ^ 3 :=
    pn_sub_le hs1r ((pn_mul_le (c := r ^ 2) hαr hr1).trans_eq (by ring))
  clear_value α β
  refine ⟨α, β, ?_, ?_, hαr, hβr⟩
  · field_simp
    linear_combination x1 * h2x - x2 * h1x
  · have hG : β * ((y1 - y2) + α * (y2 * x1 - y1 * x2)) = 0 := by
      linear_combination (1 - α * x2) * h1x - (1 - α * x1) * h2x
    have hG' := (mul_eq_zero.1 hG).resolve_left hβ0
    field_simp
    linear_combination hG'


lemma tangent_ab {a b x1 y1 r : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1)
    (he1 : y1 ^ 2 = x1 ^ 3 + a * x1 + b) (hx1 : 1 < padicNorm p x1)
    (hr1 : padicNorm p (x1 / y1) ≤ r) (hr : r < 1) :
    ∃ α β : ℚ, (y1 - (3 * x1 ^ 2 + a) / (2 * y1) * x1) * β = 1 ∧
      (3 * x1 ^ 2 + a) / (2 * y1) = -α * (y1 - (3 * x1 ^ 2 + a) / (2 * y1) * x1) ∧
      padicNorm p α ≤ r ^ 2 ∧ padicNorm p β ≤ r ^ 3 := by
  obtain ⟨hy1, -, -, hs1⟩ := pn_ts ha hb he1 hx1
  have r0 : 0 ≤ r := (padicNorm.nonneg _).trans hr1
  have r1 : r ≤ 1 := hr.le
  have r3 : r ^ 3 ≤ r := by nlinarith [pow_le_one₀ r0 r1 (n := 2)]
  have r2 : r ^ 2 ≤ r := by nlinarith
  have hs1r : padicNorm p (1 / y1) ≤ r ^ 3 := hs1 ▸ pow_le_pow_left₀ (padicNorm.nonneg _) hr1 3
  have hs1' : padicNorm p (1 / y1) ≤ r := hs1r.trans r3
  have hs1'' : padicNorm p (1 / y1) ≤ 1 := hs1'.trans r1
  -- W = 1 - (2 a t s + 3 b s²) has norm 1
  have hZ : padicNorm p (2 * a * (x1 / y1) * (1 / y1) + 3 * b * (1 / y1) ^ 2) ≤ r := by
    apply pn_add_le
    · have := pn_mul_le (pn_mul_le (pn_mul_le pn_two ha) hr1) hs1''
      simpa using this
    · have := pn_mul_le (pn_mul_le pn_three hb) ((pn_pow_le hs1' 2).trans r2)
      simpa using this
  have hW1 : padicNorm p (1 - (2 * a * (x1 / y1) * (1 / y1) + 3 * b * (1 / y1) ^ 2)) = 1 :=
    pn_one_sub (hZ.trans_lt hr)
  have hnum : padicNorm p (3 * (x1 / y1) ^ 2 + a * (1 / y1) ^ 2) ≤ r ^ 2 := by
    apply pn_add_le
    · exact (pn_mul_le pn_three (pn_pow_le hr1 2)).trans_eq (one_mul _)
    · refine (pn_mul_le ha (pn_pow_le hs1r 2)).trans ?_
      rw [one_mul, ← pow_mul]
      exact pow_le_pow_of_le_one r0 r1 (by norm_num)
  set K := y1 ^ 2 - 2 * a * x1 - 3 * b with hK
  have hWK : 1 - (2 * a * (x1 / y1) * (1 / y1) + 3 * b * (1 / y1) ^ 2) = K / y1 ^ 2 := by
    rw [hK]; field_simp; ring
  have hK0 : K ≠ 0 := by
    intro h0; rw [hWK, h0, zero_div, padicNorm.zero] at hW1; exact zero_ne_one hW1
  set α := (3 * (x1 / y1) ^ 2 + a * (1 / y1) ^ 2) /
    (1 - (2 * a * (x1 / y1) * (1 / y1) + 3 * b * (1 / y1) ^ 2)) with hαd
  set β := 1 / y1 - α * (x1 / y1) with hβd
  have hαr : padicNorm p α ≤ r ^ 2 := by rw [hαd, padicNorm.div, hW1, div_one]; exact hnum
  have hβr : padicNorm p β ≤ r ^ 3 :=
    pn_sub_le hs1r ((pn_mul_le (c := r ^ 2) hαr hr1).trans_eq (by ring))
  have hα : α = (3 * x1 ^ 2 + a) / K := by
    rw [hαd, hWK]; field_simp
  have hβ : β = -2 * y1 / K := by
    rw [hβd, hα]; field_simp; rw [hK]; linear_combination 3 * he1
  have hν : y1 - (3 * x1 ^ 2 + a) / (2 * y1) * x1 = -K / (2 * y1) := by
    field_simp; rw [hK]; linear_combination 3 * he1
  clear_value α β K
  refine ⟨α, β, ?_, ?_, hαr, hβr⟩
  · rw [hν, hβ]; field_simp
  · rw [hν, hα]; field_simp


lemma finish_step {a b l n x1 y1 x2 y2 α β r X Y : ℚ} (ha : padicNorm p a ≤ 1)
    (hb : padicNorm p b ≤ 1) (hy1 : y1 = l * x1 + n) (hy2 : y2 = l * x2 + n)
    (hy1' : y1 ≠ 0) (hy2' : y2 ≠ 0)
    (hA : a = x1 * x2 + (x1 + x2) * (l ^ 2 - x1 - x2) + 2 * l * n)
    (hB : b = n ^ 2 - x1 * x2 * (l ^ 2 - x1 - x2))
    (hnβ : n * β = 1) (hl : l = -α * n) (hαr : padicNorm p α ≤ r ^ 2)
    (hβr : padicNorm p β ≤ r ^ 3) (r0 : 0 ≤ r) (hr : r < 1)
    (hX : X = l ^ 2 - x1 - x2) (hY : Y = -(l * (X - x1) + y1)) :
    1 < padicNorm p X ∧ padicNorm p (X / Y - x1 / y1 - x2 / y2) ≤ r ^ 3 := by
  have hn : n ≠ 0 := by rintro rfl; rw [zero_mul] at hnβ; exact zero_ne_one hnβ
  have r1 : r ≤ 1 := hr.le
  have r2 : r ^ 2 < 1 := by nlinarith
  have hα1 : padicNorm p α ≤ 1 := hαr.trans r2.le
  -- D = 1 + a α² + b α³ has norm 1
  have hz : padicNorm p (-(a * α ^ 2 + b * α ^ 3)) ≤ r ^ 2 := by
    rw [padicNorm.neg]
    apply pn_add_le
    · exact (pn_mul_le ha (pn_pow_le hαr 2)).trans (by
        rw [one_mul, ← pow_mul]; exact pow_le_pow_of_le_one r0 r1 (by norm_num))
    · exact (pn_mul_le hb (pn_pow_le hαr 3)).trans (by
        rw [one_mul, ← pow_mul]; exact pow_le_pow_of_le_one r0 r1 (by norm_num))
  have hD := pn_one_sub (hz.trans_lt r2)
  rw [sub_neg_eq_add, ← add_assoc] at hD
  have hD0 : 1 + a * α ^ 2 + b * α ^ 3 ≠ 0 := by
    intro h0; rw [h0, padicNorm.zero] at hD; exact zero_ne_one hD
  have hD' : n ^ 3 + a * l ^ 2 * n - b * l ^ 3 = n ^ 3 * (1 + a * α ^ 2 + b * α ^ 3) := by
    rw [hl]; ring
  have hD'0 : n ^ 3 + a * l ^ 2 * n - b * l ^ 3 ≠ 0 := by
    rw [hD']; exact mul_ne_zero (pow_ne_zero 3 hn) hD0
  have core := core_identity l n x1 x2 a b hA hB (hy1 ▸ hy1') (hy2 ▸ hy2') hD'0
  rw [← hy1, ← hy2, ← hX] at core
  set E := (3 * b * l ^ 2 - 2 * a * l * n) / (n ^ 3 + a * l ^ 2 * n - b * l ^ 3) with hEd
  have hE : E = β * (3 * b * α ^ 2 + 2 * a * α) / (1 + a * α ^ 2 + b * α ^ 3) := by
    have hβn : β = 1 / n := by field_simp; linear_combination hnβ
    rw [hEd, hD', hβn, hl]
    field_simp
    ring
  have hEr : padicNorm p E ≤ r ^ 3 := by
    rw [hE, padicNorm.div, hD, div_one]
    refine (pn_mul_le hβr (c := r ^ 3) (d := 1) ?_).trans_eq (mul_one _)
    apply pn_add_le
    · exact (pn_mul_le (pn_mul_le pn_three hb) (pn_pow_le hα1 2)).trans_eq (by ring)
    · exact (pn_mul_le (pn_mul_le pn_two ha) hα1).trans_eq (by ring)
  have hYe : Y = -(l * X + n) := by rw [hY, hy1]; ring
  have hlXn : l * X + n ≠ 0 := by
    intro h0
    rw [h0, zero_mul] at core
    rw [core, mul_zero, zero_add] at h0
    exact hn h0
  constructor
  · by_contra hle
    have hle' : padicNorm p X ≤ 1 := not_lt.1 hle
    have eqY : (l * X + n) ^ 2 = X ^ 3 + a * X + b := by rw [hX, hA, hB]; ring
    have hYn : padicNorm p (l * X + n) ≤ 1 := by
      have h3 : padicNorm p (X ^ 3 + a * X + b) ≤ 1 :=
        pn_add_le (pn_add_le ((pn_pow_le hle' 3).trans_eq (one_pow 3))
          ((pn_mul_le ha hle').trans_eq (one_mul 1))) hb
      rw [← eqY, pn_pow] at h3
      nlinarith [padicNorm.nonneg (p := p) (l * X + n)]
    have line : α * X + β * (l * X + n) = 1 := by
      rw [hl]; linear_combination (1 - α * X) * hnβ
    have h1 : padicNorm p (α * X + β * (l * X + n)) ≤ r ^ 2 :=
      pn_add_le ((pn_mul_le hαr hle').trans_eq (mul_one _))
        ((pn_mul_le hβr hYn).trans (by nlinarith))
    rw [line, padicNorm.one] at h1
    linarith
  · clear_value E
    have hY0 : Y ≠ 0 := by rw [hYe]; exact neg_ne_zero.2 hlXn
    have : X / Y = x1 / y1 + x2 / y2 + E := by
      rw [div_eq_iff hY0, hYe]
      linear_combination core
    have : X / Y - x1 / y1 - x2 / y2 = E := by rw [this]; ring
    rw [this]; exact hEr


lemma sc_equation {a b x y : ℚ} :
    (shortCurve a b).toAffine.Equation x y ↔ y ^ 2 = x ^ 3 + a * x + b := by
  rw [Affine.equation_iff]; simp [shortCurve]

lemma sc_negY (a b x y : ℚ) : (shortCurve a b).toAffine.negY x y = -y := by
  simp [shortCurve]

/-- The parameter `t = x / y` of a point, with `t(O) = 0`. -/
noncomputable def tco {a b : ℚ} : (shortCurve a b).toAffine.Point → ℚ
  | .zero => 0
  | .some x y _ => x / y

/-- The point is `O` or has `p` in the denominator of `x`. -/
def inC (p : ℕ) {a b : ℚ} : (shortCurve a b).toAffine.Point → Prop
  | .zero => True
  | .some x _ _ => 1 < padicNorm p x

lemma tco_zero {a b : ℚ} : tco (0 : (shortCurve a b).toAffine.Point) = 0 := rfl

lemma add_step {a b r : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1) (hr : r < 1)
    (P Q : (shortCurve a b).toAffine.Point) (hP : inC p P) (hQ : inC p Q)
    (hPr : padicNorm p (tco P) ≤ r) (hQr : padicNorm p (tco Q) ≤ r) :
    inC p (P + Q) ∧ padicNorm p (tco (P + Q) - tco P - tco Q) ≤ r ^ 3 := by
  have r0 : 0 ≤ r := (padicNorm.nonneg _).trans hPr
  have r3 : (0 : ℚ) ≤ r ^ 3 := pow_nonneg r0 3
  rcases P with _ | ⟨x1, y1, h1⟩
  · rw [← Affine.Point.zero_def, zero_add]
    refine ⟨hQ, ?_⟩
    simpa [tco_zero] using r3
  rcases Q with _ | ⟨x2, y2, h2⟩
  · rw [← Affine.Point.zero_def, add_zero]
    refine ⟨hP, ?_⟩
    simpa [tco_zero] using r3
  have he1 := sc_equation.1 h1.1
  have he2 := sc_equation.1 h2.1
  simp only [inC] at hP hQ
  simp only [tco] at hPr hQr
  obtain ⟨hy1, -⟩ := pn_ts ha hb he1 hP
  obtain ⟨hy2, -⟩ := pn_ts ha hb he2 hQ
  by_cases hx : x1 = x2
  · by_cases hy : y1 = (shortCurve a b).toAffine.negY x2 y2
    · rw [Affine.Point.add_of_Y_eq hx hy]
      refine ⟨trivial, ?_⟩
      rw [sc_negY] at hy
      simp only [tco]
      rw [hx, hy, div_neg]
      simp [padicNorm.zero, r3]
    · have hyy := Affine.Y_eq_of_Y_ne h1.1 h2.1 hx hy
      subst hx hyy
      rw [Affine.Point.add_self_of_Y_ne hy]
      simp only [inC, tco]
      rw [Affine.slope_of_Y_ne rfl hy]
      obtain ⟨α, β, h1', h2', hα, hβ⟩ := tangent_ab ha hb he1 hP hPr hr
      have hsl : (3 * x1 ^ 2 + 2 * (shortCurve a b).a₂ * x1 + (shortCurve a b).a₄ -
          (shortCurve a b).a₁ * y1) / (y1 - (shortCurve a b).toAffine.negY x1 y1) =
          (3 * x1 ^ 2 + a) / (2 * y1) := by
        rw [sc_negY]; simp [shortCurve]; ring
      rw [hsl]
      set l := (3 * x1 ^ 2 + a) / (2 * y1) with hl
      have hl2 : l * (2 * y1) = 3 * x1 ^ 2 + a := by rw [hl]; field_simp
      clear_value l
      exact finish_step (n := y1 - l * x1) ha hb (by ring) (by ring) hy1 hy1
        (by linear_combination -hl2) (by linear_combination -he1 + x1 * hl2) h1' h2' hα hβ r0 hr
        (by simp [shortCurve]) (by simp [Affine.addY, shortCurve])
  · rw [Affine.Point.add_of_X_ne hx]
    simp only [inC, tco]
    rw [Affine.slope_of_X_ne hx]
    obtain ⟨α, β, h1', h2', hα, hβ⟩ := chord_ab ha hb he1 he2 hP hQ hx hPr hQr hr
    set l := (y1 - y2) / (x1 - x2) with hl
    have hx' : x1 - x2 ≠ 0 := sub_ne_zero.2 hx
    have hl2 : l * (x1 - x2) = y1 - y2 := by rw [hl]; field_simp
    clear_value l
    have hy2e : y2 = l * x2 + (y1 - l * x1) := by linear_combination hl2
    have he2' := he2
    rw [hy2e] at he2'
    have hprod : (x1 - x2) * (a - (x1 * x2 + (x1 + x2) * (l ^ 2 - x1 - x2) +
        2 * l * (y1 - l * x1))) = 0 := by
      linear_combination he2' - he1
    have hA := sub_eq_zero.1 ((mul_eq_zero.1 hprod).resolve_left hx')
    exact finish_step (n := y1 - l * x1) ha hb (by ring) hy2e hy1 hy2
      hA (by linear_combination -he1 - x1 * hA) h1' h2' hα hβ r0 hr
      (by simp [shortCurve]) (by simp [Affine.addY, shortCurve])


lemma tco_lt_one {a b : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1)
    (P : (shortCurve a b).toAffine.Point) (hP : inC p P) : padicNorm p (tco P) < 1 := by
  rcases P with _ | ⟨x, y, h⟩
  · show padicNorm p 0 < 1
    rw [padicNorm.zero]; exact one_pos
  · exact (pn_ts ha hb (sc_equation.1 h.1) hP).2.2.1

lemma nsmul_step {a b : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1)
    (P : (shortCurve a b).toAffine.Point) (hP : inC p P) (n : ℕ) :
    inC p (n • P) ∧ padicNorm p (tco (n • P) - n * tco P) ≤ padicNorm p (tco P) ^ 3 := by
  have hr := tco_lt_one ha hb P hP
  have r0 := padicNorm.nonneg (p := p) (tco P)
  have r3 : padicNorm p (tco P) ^ 3 ≤ padicNorm p (tco P) := by
    nlinarith [pow_le_one₀ r0 hr.le (n := 2)]
  induction n with
  | zero =>
    rw [zero_nsmul]
    refine ⟨trivial, ?_⟩
    simpa [tco_zero] using pow_nonneg r0 3
  | succ n ih =>
    obtain ⟨hC, hB⟩ := ih
    have hn : padicNorm p (tco (n • P)) ≤ padicNorm p (tco P) := by
      have e : tco (n • P) = (tco (n • P) - n * tco P) + n * tco P := by ring
      rw [e]
      exact pn_add_le (hB.trans r3)
        ((pn_mul_le (padicNorm.of_nat n) le_rfl).trans_eq (one_mul _))
    obtain ⟨hC', hB'⟩ := add_step ha hb hr (n • P) P hC hP hn le_rfl
    rw [succ_nsmul]
    refine ⟨hC', ?_⟩
    have e : tco (n • P + P) - ((n + 1 : ℕ) : ℚ) * tco P =
        (tco (n • P + P) - tco (n • P) - tco P) + (tco (n • P) - n * tco P) := by
      push_cast; ring
    rw [e]
    exact pn_add_le hB' hB

lemma torsion_padic_le {a b : ℚ} (ha : padicNorm p a ≤ 1) (hb : padicNorm p b ≤ 1) (x y : ℚ)
    (h : (shortCurve a b).toAffine.Nonsingular x y)
    (htors : IsOfFinAddOrder (Affine.Point.some x y h)) : padicNorm p x ≤ 1 := by
  by_contra hx
  have hx' : 1 < padicNorm p x := not_le.1 hx
  have pp : p.Prime := Fact.out
  have hp2 : (2 : ℚ) ≤ p := by exact_mod_cast pp.two_le
  have hm := htors.addOrderOf_pos
  have hmP := addOrderOf_nsmul_eq_zero (Affine.Point.some x y h)
  generalize hmd : addOrderOf (Affine.Point.some x y h) = m at hm hmP
  obtain ⟨-, hb1⟩ := nsmul_step ha hb _ (show inC p (Affine.Point.some x y h) from hx') m
  rw [hmP, tco_zero, zero_sub, padicNorm.neg, padicNorm.mul] at hb1
  simp only [tco] at hb1
  obtain ⟨-, ht0, htr, -⟩ := pn_ts ha hb (sc_equation.1 h.1) hx'
  have rpos : 0 < padicNorm p (x / y) :=
    lt_of_le_of_ne (padicNorm.nonneg _) (padicNorm.ne_zero ht0).symm
  have hNm : padicNorm p (m : ℚ) < 1 := by
    by_contra hge
    have hge' : 1 ≤ padicNorm p (m : ℚ) := not_lt.1 hge
    have : padicNorm p (x / y) ^ 3 < padicNorm p (x / y) := by
      have : padicNorm p (x / y) ^ 2 < 1 := pow_lt_one₀ (padicNorm.nonneg _) htr two_ne_zero
      nlinarith
    nlinarith
  obtain ⟨k, hk⟩ := (padicNorm.nat_lt_one_iff m).1 hNm
  have hk0 : k ≠ 0 := by rintro rfl; rw [mul_zero] at hk; omega
  have hkm : k < m := by
    rw [hk]; have := pp.two_le; nlinarith [Nat.pos_of_ne_zero hk0]
  have hP'0 : k • Affine.Point.some x y h ≠ 0 :=
    nsmul_ne_zero_of_lt_addOrderOf hk0 (hmd ▸ hkm)
  obtain ⟨hC', -⟩ := nsmul_step ha hb _ (show inC p (Affine.Point.some x y h) from hx') k
  have hpP' : p • (k • Affine.Point.some x y h) = 0 := by
    rw [smul_smul, ← hk, hmP]
  generalize k • Affine.Point.some x y h = Q at hC' hP'0 hpP'
  rcases Q with _ | ⟨x', y', h'⟩
  · exact hP'0 rfl
  obtain ⟨-, hb2⟩ := nsmul_step ha hb _ hC' p
  rw [hpP', tco_zero, zero_sub, padicNorm.neg, padicNorm.mul, padicNorm.padicNorm_p_of_prime]
    at hb2
  simp only [tco] at hb2
  simp only [inC] at hC'
  obtain ⟨-, ht0', htr', -⟩ := pn_ts ha hb (sc_equation.1 h'.1) hC'
  obtain ⟨z, hz⟩ := padicNorm.values_discrete (p := p) ht0'
  have hp1 : (1 : ℚ) ≤ p := by linarith
  have hle : padicNorm p (x' / y') ≤ (p : ℚ)⁻¹ := by
    rw [hz]
    by_cases hz0 : 0 ≤ -z
    · have := one_le_zpow₀ hp1 hz0
      rw [← hz] at this; linarith
    · rw [← zpow_neg_one]
      exact zpow_le_zpow_right₀ hp1 (by omega)
  have rpos' : 0 < padicNorm p (x' / y') :=
    lt_of_le_of_ne (padicNorm.nonneg _) (padicNorm.ne_zero ht0').symm
  have hq : 0 < (p : ℚ)⁻¹ := by positivity
  have hq2 : (p : ℚ)⁻¹ ≤ 1 / 2 := by
    rw [one_div]; exact inv_anti₀ (by norm_num) hp2
  set r := padicNorm p (x' / y')
  set q := (p : ℚ)⁻¹
  -- q * r ≤ r ^ 3, so q ≤ r ^ 2 ≤ q ^ 2
  have h1 : q ≤ r ^ 2 := by
    have : q * r ≤ r ^ 2 * r := by nlinarith
    exact le_of_mul_le_mul_right this rpos'
  have h2 : r ^ 2 ≤ q ^ 2 := pow_le_pow_left₀ rpos'.le hle 2
  nlinarith

end padic

lemma int_of_padicNorm_le (q : ℚ) (h : ∀ p : ℕ, p.Prime → padicNorm p q ≤ 1) :
    ∃ m : ℤ, q = m := by
  by_contra hne
  have hden : q.den ≠ 1 := fun h1 => hne ⟨q.num, (Rat.intCast_num_of_den_eq_one h1).symm⟩
  set p := q.den.minFac with hp
  have pp : p.Prime := Nat.minFac_prime hden
  have : Fact p.Prime := ⟨pp⟩
  have hpd : p ∣ q.den := Nat.minFac_dvd _
  have h1 : padicNorm p (q.den : ℚ) < 1 := (padicNorm.nat_lt_one_iff _).2 hpd
  have h2 : padicNorm p (q.num : ℚ) < 1 := by
    rw [← Rat.mul_den_eq_num, padicNorm.mul]
    calc padicNorm p q * padicNorm p q.den ≤ 1 * padicNorm p q.den :=
          mul_le_mul_of_nonneg_right (h p pp) (padicNorm.nonneg _)
      _ < 1 := by rw [one_mul]; exact h1
  have h3 : (p : ℤ) ∣ q.num := (padicNorm.int_lt_one_iff _).1 h2
  have h4 : p ∣ q.num.natAbs := Int.natCast_dvd.1 h3
  have := Nat.dvd_gcd h4 hpd
  rw [q.reduced] at this
  exact pp.one_lt.ne' (Nat.dvd_one.1 this)

lemma int_of_sq_int (q : ℚ) (z : ℤ) (h : q ^ 2 = z) : ∃ m : ℤ, q = m := by
  refine int_of_padicNorm_le q fun p pp => ?_
  have : Fact p.Prime := ⟨pp⟩
  have := padicNorm.of_int (p := p) z
  rw [← h, pn_pow] at this
  nlinarith [padicNorm.nonneg (p := p) q]

lemma torsion_x_int {a b : ℚ} (a' b' : ℤ) (ha : a = a') (hb : b = b') (x y : ℚ)
    (h : (shortCurve a b).toAffine.Nonsingular x y)
    (htors : IsOfFinAddOrder (Affine.Point.some x y h)) : ∃ m : ℤ, x = m :=
  int_of_padicNorm_le x fun p pp => by
    have : Fact p.Prime := ⟨pp⟩
    exact torsion_padic_le (ha ▸ padicNorm.of_int a') (hb ▸ padicNorm.of_int b') x y h htors

lemma nagell_lutz_aux {a b : ℚ} (a' b' : ℤ) (ha : a = a') (hb : b = b') (x y : ℚ)
    (h : (shortCurve a b).toAffine.Nonsingular x y)
    (htors : IsOfFinAddOrder (Affine.Point.some x y h)) :
    ∃ m n : ℤ, x = m ∧ y = n ∧ (n = 0 ∨ n ^ 2 ∣ 4 * a' ^ 3 + 27 * b' ^ 2) := by
  obtain ⟨m, hm⟩ := torsion_x_int a' b' ha hb x y h htors
  have he := sc_equation.1 h.1
  obtain ⟨n, hn⟩ := int_of_sq_int y (m ^ 3 + a' * m + b') (by rw [he, hm, ha, hb]; push_cast; ring)
  subst hm hn
  refine ⟨m, n, rfl, rfl, ?_⟩
  have heZ : n ^ 2 = m ^ 3 + a' * m + b' := by
    rw [ha, hb] at he; exact_mod_cast he
  by_cases hn0 : n = 0
  · exact Or.inl hn0
  right
  have hy : (n : ℚ) ≠ (shortCurve a b).toAffine.negY m n := by
    rw [sc_negY]; intro h'; apply hn0; exact_mod_cast (by linarith : (n : ℚ) = 0)
  have h2 := Affine.Point.add_self_of_Y_ne (h₁ := h) hy
  have ht2 := htors.add htors
  rw [h2] at ht2
  obtain ⟨k, hk⟩ := torsion_x_int a' b' ha hb _ _ _ ht2
  rw [Affine.slope_of_Y_ne rfl hy] at hk
  have hn0' : (n : ℚ) ≠ 0 := by exact_mod_cast hn0
  have hsl : (3 * (m : ℚ) ^ 2 + 2 * (shortCurve a b).a₂ * m + (shortCurve a b).a₄ -
      (shortCurve a b).a₁ * n) / (n - (shortCurve a b).toAffine.negY m n) =
      (3 * m ^ 2 + a) / (2 * n) := by
    rw [sc_negY]; simp [shortCurve]; ring
  rw [hsl] at hk
  have hl2 : ((3 * m ^ 2 + a) / (2 * n)) ^ 2 = ((k + 2 * m : ℤ) : ℚ) := by
    push_cast; rw [← hk]; simp [shortCurve]; ring
  obtain ⟨j, hj⟩ := int_of_sq_int _ _ hl2
  have hjQ : (j : ℚ) * (2 * n) = 3 * m ^ 2 + a := by
    rw [← hj]; field_simp
  have hjZ : j * (2 * n) = 3 * m ^ 2 + a' := by
    rw [ha] at hjQ; exact_mod_cast hjQ
  exact ⟨(3 * m ^ 2 + 4 * a') * 4 * j ^ 2 - 27 * (m ^ 3 + a' * m - b'), by
    linear_combination (-(3 * m ^ 2 + 4 * a') * (3 * m ^ 2 + a' + 2 * n * j)) * hjZ
      + 27 * (m ^ 3 + a' * m - b') * heZ⟩

/-- Nagell–Lutz: on the elliptic curve `y² = x³ + a x + b` with whole coefficients `a`, `b`
(smooth, so `4a³ + 27b² ≠ 0`), a rational point `P = (x, y) ≠ O` of finite order has whole
coordinates, and either `y = 0` or `y²` divides `4a³ + 27b²`. -/
theorem nagell_lutz (a b : ℤ) (hΔ : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0) (x y : ℚ)
    (h : (shortCurve a b).toAffine.Nonsingular x y)
    (htors : IsOfFinAddOrder (Affine.Point.some x y h)) :
    ∃ m n : ℤ, x = m ∧ y = n ∧ (n = 0 ∨ n ^ 2 ∣ 4 * a ^ 3 + 27 * b ^ 2) := by
  clear hΔ
  exact nagell_lutz_aux a b rfl rfl x y h htors

/-- The order-3 test (the division polynomial `ψ₃`): a rational point `P = (x, y) ≠ O` on
`y² = x³ + a x + b` satisfies `3P = O` exactly when `3x⁴ + 6ax² + 12bx − a² = 0`. -/
theorem three_torsion_iff_psi3_eq_zero (a b x y : ℚ)
    (h : (shortCurve a b).toAffine.Nonsingular x y) :
    3 • Affine.Point.some x y h = 0 ↔ 3 * x ^ 4 + 6 * a * x ^ 2 + 12 * b * x - a ^ 2 = 0 := by
  have he := sc_equation.1 h.1
  have h3 : 3 • Affine.Point.some x y h =
      (Affine.Point.some x y h + Affine.Point.some x y h) + Affine.Point.some x y h := by
    rw [succ_nsmul, two_nsmul]
  rw [h3, add_eq_zero_iff_eq_neg]
  by_cases hy : y = (shortCurve a b).toAffine.negY x y
  · rw [Affine.Point.add_self_of_Y_eq hy]
    have hy0 : y = 0 := by rw [sc_negY] at hy; linarith
    have hns := h.2
    rw [Affine.evalEval_polynomialX, Affine.evalEval_polynomialY] at hns
    simp [shortCurve, hy0] at hns
    constructor
    · intro h0
      exact absurd h0.symm (neg_ne_zero.2 (Affine.Point.some_ne_zero h))
    · intro hψ
      exfalso
      subst hy0
      have : (3 * x ^ 2 + a) ^ 2 = 0 := by linear_combination -hψ - 12 * x * he
      exact hns (by linear_combination -(pow_eq_zero_iff two_ne_zero).1 this)
  · rw [Affine.Point.add_self_of_Y_ne hy, Affine.Point.neg_some, Affine.Point.some.injEq]
    rw [Affine.slope_of_Y_ne rfl hy]
    have hy0 : y ≠ 0 := by intro h0; apply hy; rw [sc_negY, h0, neg_zero]
    have hsl : (3 * x ^ 2 + 2 * (shortCurve a b).a₂ * x + (shortCurve a b).a₄ -
        (shortCurve a b).a₁ * y) / (y - (shortCurve a b).toAffine.negY x y) =
        (3 * x ^ 2 + a) / (2 * y) := by
      rw [sc_negY]; simp [shortCurve]; ring
    rw [hsl]
    simp only [Affine.addY, Affine.negAddY, Affine.addX, sc_negY]
    simp [shortCurve]
    constructor
    · rintro ⟨h1, -⟩
      field_simp at h1
      linear_combination -h1 - 12 * x * he
    · intro hψ
      have h1 : ((3 * x ^ 2 + a) / (2 * y)) ^ 2 - x - x = x := by
        field_simp
        linear_combination -hψ - 12 * x * he
      refine ⟨h1, ?_⟩
      exact Or.inr (by linear_combination h1)

/-- The house answer: on `y² = x³ − 2` the only rational point of finite order is `O`;
in particular `(3, 5)` has infinite order. -/
theorem torsion_of_x_cubed_minus_two_trivial (P : (shortCurve 0 (-2)).toAffine.Point)
    (hP : IsOfFinAddOrder P) : P = 0 := by
  rcases P with _ | ⟨x, y, h⟩
  · rfl
  exfalso
  obtain ⟨m, n, rfl, rfl, hd⟩ := nagell_lutz_aux 0 (-2) (by norm_num) (by norm_num) x y h hP
  have he := sc_equation.1 h.1
  have heZ : n ^ 2 = m ^ 3 - 2 := by
    have : ((n ^ 2 : ℤ) : ℚ) = ((m ^ 3 - 2 : ℤ) : ℚ) := by push_cast; linarith
    exact_mod_cast this
  norm_num at hd
  have hn2 : n ^ 2 ≤ 108 := hd.elim (fun h => by subst h; norm_num)
    (fun h => Int.le_of_dvd (by norm_num) h)
  have hn1 : -10 ≤ n := by nlinarith
  have hn2' : n ≤ 10 := by nlinarith
  have hm1 : 1 ≤ m := by
    by_contra hlt
    have : m ≤ 0 := by omega
    nlinarith [sq_nonneg m, sq_nonneg n, mul_nonneg (neg_nonneg.2 this) (sq_nonneg m)]
  have hm4 : m ≤ 4 := by nlinarith [sq_nonneg m, sq_nonneg (m - 4)]
  interval_cases m <;> interval_cases n <;> revert heZ hd <;> norm_num

-- The Nagell–Lutz test number for y² = x³ − 2 is 108 = 2² · 3³.
example : 4 * (0 : ℤ) ^ 3 + 27 * (-2) ^ 2 = 108 ∧ (108 : ℤ) = 2 ^ 2 * 3 ^ 3 := by norm_num

-- The allowed y: 0, or y² divides 108; so y is 0, 1, 2, 3 or 6.
example : (Finset.range 11).filter (fun y => y = 0 ∨ 108 % (y * y) = 0) = {0, 1, 2, 3, 6} := by
  decide

-- No whole x has x³ − 2 = y² for an allowed y (x³ would be 2, 3, 6, 11 or 38, so |x| ≤ 3).
example : ∀ x ∈ Finset.Icc (-4 : ℤ) 4, ∀ y ∈ ({0, 1, 2, 3, 6} : Finset ℤ), x ^ 3 - 2 ≠ y ^ 2 := by
  decide

-- ψ₃ = 3x⁴ − 24x on y² = x³ − 2 has roots 0 and 2, where x³ − 2 is −2 and 6.
example : 3 * (0 : ℚ) ^ 4 - 24 * 0 = 0 ∧ 3 * (2 : ℚ) ^ 4 - 24 * 2 = 0 ∧
    (0 : ℚ) ^ 3 - 2 = -2 ∧ (2 : ℚ) ^ 3 - 2 = 6 := by norm_num

-- (3, 5) lies on the curve, its tangent slope is 27/10, and 2P = (129/100, −383/1000).
example : (5 : ℚ) ^ 2 = 3 ^ 3 - 2 ∧ (3 * 3 ^ 2 + 0 : ℚ) / (2 * 5) = 27 / 10 ∧
    (27 / 10 : ℚ) ^ 2 - 2 * 3 = 129 / 100 ∧ (27 / 10 : ℚ) * (3 - 129 / 100) - 5 = -383 / 1000 := by
  norm_num

-- 2P and 3P = (164323/29241, −66234835/5000211) lie on y² = x³ − 2.
example : (-383 / 1000 : ℚ) ^ 2 = (129 / 100) ^ 3 - 2 ∧
    (-66234835 / 5000211 : ℚ) ^ 2 = (164323 / 29241) ^ 3 - 2 := by norm_num

-- Points mod 5 and mod 7: 5 and 6 affine points, so N₅ = 6 and N₇ = 7, with gcd 1.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter (fun p => p.2 ^ 2 = p.1 ^ 3 - 2)).card = 5 := by
  decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter (fun p => p.2 ^ 2 = p.1 ^ 3 - 2)).card = 6 := by
  decide

-- The bad prime 3: y² = x³ + 1 mod 3 has 3 affine points, N₃ = 4, though the torsion has 6.
example : ((Finset.univ : Finset (ZMod 3 × ZMod 3)).filter (fun p => p.2 ^ 2 = p.1 ^ 3 + 1)).card = 3 := by
  decide

-- On y² = x³ + 1, the double of (2, 3) has x = 0 (slope 2), and 3² = 9 divides 27.
example : (2 : ℚ) ^ 3 + 1 = 3 ^ 2 ∧ ((3 * 2 ^ 2 : ℚ) / (2 * 3)) ^ 2 - 2 * 2 = 0 ∧ (9 : ℤ) ∣ 27 := by
  norm_num

-- On y² = x³ + 8 (test number 1728), (1, 3) and (2, 4) pass Nagell–Lutz, yet both doubles have x = −7/4.
example : 4 * (0 : ℤ) ^ 3 + 27 * 8 ^ 2 = 1728 ∧ (9 : ℤ) ∣ 1728 ∧ (16 : ℤ) ∣ 1728 ∧
    ((3 * 1 ^ 2 : ℚ) / (2 * 3)) ^ 2 - 2 * 1 = -7 / 4 ∧ ((3 * 2 ^ 2 : ℚ) / (2 * 4)) ^ 2 - 2 * 2 = -7 / 4 := by
  norm_num

-- Rescaling y² = x³ + 1 by 2: (1/2, 3/8) lies on y² = x³ + 1/64.
example : (3 / 8 : ℚ) ^ 2 = (1 / 2) ^ 3 + 1 / 64 := by norm_num

#print axioms nagell_lutz
#print axioms three_torsion_iff_psi3_eq_zero
#print axioms torsion_of_x_cubed_minus_two_trivial
#print axioms core_identity
#print axioms pn_add_le
#print axioms pn_sub_le
#print axioms pn_mul_le
#print axioms pn_pow
#print axioms pn_pow_le
#print axioms pn_one_sub
#print axioms pn_two
#print axioms pn_three
#print axioms pn_curve
#print axioms pn_ts
#print axioms ts_eq
#print axioms chord_ab
#print axioms tangent_ab
#print axioms finish_step
#print axioms sc_equation
#print axioms sc_negY
#print axioms tco_zero
#print axioms add_step
#print axioms tco_lt_one
#print axioms nsmul_step
#print axioms torsion_padic_le
#print axioms int_of_padicNorm_le
#print axioms int_of_sq_int
#print axioms torsion_x_int
#print axioms nagell_lutz_aux
