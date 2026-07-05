class SkincareTipSection {
  final String title;
  final String content;
  final bool isHighlight;

  const SkincareTipSection({
    required this.title,
    required this.content,
    this.isHighlight = false,
  });
}

class SkincareTip {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String readTime;
  final String imageUrl;
  final List<SkincareTipSection> sections;

  const SkincareTip({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readTime,
    required this.imageUrl,
    required this.sections,
  });

  static List<SkincareTip> get sampleTips => [
        const SkincareTip(
          id: 'double-cleansing',
          title: 'The Art of Double Cleansing: Why You Need It',
          subtitle: 'Why washing your face once might not be enough for clear skin.',
          category: 'Cleansing',
          readTime: '4 min read',
          imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=600&auto=format&fit=crop',
          sections: [
            SkincareTipSection(
              title: 'What is Double Cleansing?',
              content: 'Double cleansing is a method of cleansing your face twice: first with an oil-based cleanser, and then with a water-based cleanser. The concept is based on a simple chemistry principle: "like dissolves like". Oil-based impurities require oil to dissolve, while water-based impurities are easily washed away by water.',
            ),
            SkincareTipSection(
              title: 'Step 1: Oil-Based Cleanser',
              content: 'Use a cleansing oil, cleansing balm, or micellar water. This step breaks down stubborn, oil-soluble impurities such as sebum (excess oil), makeup, and waterproof sunscreen. Apply it on dry skin, massage gently for 60 seconds, emulsify with a splash of lukewarm water, and rinse off.',
            ),
            SkincareTipSection(
              title: 'Step 2: Water-Based Cleanser',
              content: 'Follow up with a gentle water-based cleanser (like a foaming, gel, or cream cleanser). This step removes remaining water-based sweat, environmental pollution, dirt, and any leftover residue from the first cleanse, ensuring your pores are completely clear.',
            ),
            SkincareTipSection(
              title: 'Pro Tip',
              content: 'Double cleansing is best done only in your evening routine. In the morning, a simple rinse with water or a single gentle water-based cleanser is sufficient to preserve your skin\'s natural moisture barrier.',
              isHighlight: true,
            ),
          ],
        ),
        const SkincareTip(
          id: 'hydration-vs-moisture',
          title: 'Hydration vs. Moisture: What\'s the Difference?',
          subtitle: 'Learn why dehydrated skin needs water, dry skin needs oil, and how to treat both.',
          category: 'Hydration',
          readTime: '5 min read',
          imageUrl: 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=600&auto=format&fit=crop',
          sections: [
            SkincareTipSection(
              title: 'Understanding the Core Difference',
              content: 'Hydration refers to the water content within the skin cells, making them plump and bouncy. Moisture is about your skin\'s ability to lock in that water using oils/lipids. Skin can be dry (lacking oil) or dehydrated (lacking water). Yes, even oily skin can be dehydrated!',
            ),
            SkincareTipSection(
              title: 'For Hydration (Water)',
              content: 'If your skin feels tight, looks dull, or shows fine lines, it lacks hydration. You should look for humectants—ingredients that draw water into the skin. Key ingredients include Hyaluronic Acid, Glycerin, Aloe Vera, and Panthenol (Vitamin B5).',
            ),
            SkincareTipSection(
              title: 'For Moisture (Oil)',
              content: 'If your skin is flaky, rough, or peeling, it lacks oil. You need emollients and occlusives—ingredients that seal the skin barrier to prevent water loss. Look for Ceramides, Squalane, Jojoba Oil, and Shea Butter.',
            ),
            SkincareTipSection(
              title: 'The Golden Rule',
              content: 'Hydrate first, then moisturize. Apply your lightweight hydrating serums on damp skin first, then lock them in with a thicker moisturizer or oil to create a protective seal.',
              isHighlight: true,
            ),
          ],
        ),
        const SkincareTip(
          id: 'sunscreen-101',
          title: 'Sunscreen 101: Chemical, Physical, or Hybrid?',
          subtitle: 'The ultimate guide to choosing the perfect sunscreen for your skin type.',
          category: 'Protection',
          readTime: '6 min read',
          imageUrl: 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?q=80&w=600&auto=format&fit=crop',
          sections: [
            SkincareTipSection(
              title: 'Why Sunscreen is Non-Negotiable',
              content: 'Sunscreen is the single most important step in any skincare routine. It protects against ultraviolet (UV) radiation, which causes 80% of visible skin aging (wrinkles, saggy skin), hyperpigmentation, and increases the risk of skin cancer.',
            ),
            SkincareTipSection(
              title: 'Physical (Mineral) Sunscreens',
              content: 'Physical sunscreens use active mineral ingredients like Zinc Oxide or Titanium Dioxide. They sit on top of the skin and reflect UV rays away like a shield. They are gentle and excellent for sensitive or acne-prone skin, but they can sometimes leave a white cast.',
            ),
            SkincareTipSection(
              title: 'Chemical Sunscreens',
              content: 'Chemical sunscreens contain organic compounds like Avobenzone, Octisalate, or newer filters. They absorb UV rays, convert them into heat, and release them. They are lightweight, absorb invisibly with no white cast, but can sometimes irritate sensitive skin.',
            ),
            SkincareTipSection(
              title: 'The Two-Finger Rule',
              content: 'To achieve the SPF rating on the label, you must apply enough product. The standard guideline is the "Two-Finger Rule": squeeze two full strips of sunscreen onto your index and middle fingers to cover your entire face and neck.',
              isHighlight: true,
            ),
          ],
        ),
        const SkincareTip(
          id: 'active-ingredients',
          title: 'Mastering Actives: Retinol, Vitamin C & Niacinamide',
          subtitle: 'A beginner\'s guide to using active ingredients safely and effectively.',
          category: 'Actives',
          readTime: '7 min read',
          imageUrl: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=600&auto=format&fit=crop',
          sections: [
            SkincareTipSection(
              title: 'Vitamin C (Brightening & Antioxidant)',
              content: 'Vitamin C (specifically L-Ascorbic Acid or derivatives) is a powerful antioxidant that neutralizes free radicals, boosts collagen production, and fades dark spots. It is best applied in the morning under your sunscreen to boost UV protection.',
            ),
            SkincareTipSection(
              title: 'Niacinamide (Oil Control & Barrier Support)',
              content: 'Niacinamide (Vitamin B3) is a versatile ingredient suitable for almost all skin types. It regulates sebum production, minimizes pore appearance, calms redness, and strengthens the skin\'s moisture barrier. It can be used morning and night.',
            ),
            SkincareTipSection(
              title: 'Retinol (Anti-Aging & Cell Renewal)',
              content: 'Retinol accelerates cell turnover, smooths texture, and reduces wrinkles. It must be introduced slowly (1-2 times a week), used only at night, and always paired with sunscreen the next day as it makes skin more sensitive to the sun.',
            ),
            SkincareTipSection(
              title: 'Combining Actives Safely',
              content: 'Avoid using Retinol and Vitamin C at the exact same time, as they operate at different pH levels and can cause severe irritation. Use Vitamin C in the morning and Retinol in the evening. Niacinamide can generally be safely paired with both!',
              isHighlight: true,
            ),
          ],
        ),
        const SkincareTip(
          id: 'barrier-repair',
          title: 'How to Repair a Damaged Skin Barrier',
          subtitle: 'Step-by-step guide to soothe redness, flakiness, and sudden breakouts.',
          category: 'Barrier Care',
          readTime: '5 min read',
          imageUrl: 'https://images.unsplash.com/photo-1617897903246-719242758050?q=80&w=600&auto=format&fit=crop',
          sections: [
            SkincareTipSection(
              title: 'Signs of a Damaged Barrier',
              content: 'When your skin barrier is compromised, moisture escapes and irritants easily penetrate. Classic signs include constant redness, a burning or stinging sensation when applying regular products, flakiness, tightness, and sudden, unexpected breakouts.',
            ),
            SkincareTipSection(
              title: 'Common Causes',
              content: 'Over-exfoliating (using chemical exfoliants or physical scrubs too frequently), using high-strength actives without buffering, washing with hot water, and exposure to dry or harsh weather are typical culprits.',
            ),
            SkincareTipSection(
              title: 'The Recovery Routine',
              content: 'Strip your routine down to the absolute basics. Wash with a gentle, non-foaming cleanser. Use a rich moisturizer formulated with Ceramides, Squalane, or Centella Asiatica (Cica) to rebuild lipids. Always protect with a gentle sunscreen during the day.',
            ),
            SkincareTipSection(
              title: 'What to Avoid',
              content: 'Stop using all chemical exfoliants (AHA, BHA, PHA), physical scrubs, retinoids, Vitamin C, and heavily fragranced products immediately. Wait at least 2 to 4 weeks for your skin to heal before slowly reintroducing them.',
              isHighlight: true,
            ),
          ],
        ),
      ];
}
