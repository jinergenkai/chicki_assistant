# Chicky Buddy Design System

> Modern, clean, and accessible design system for Chicky Buddy language learning app.

## 🎨 Design Principles

1. **Modern & Clean**: Subtle gradients, soft shadows, and generous white space
2. **Consistent**: Unified design language across all screens
3. **Accessible**: Clear typography, sufficient contrast, and intuitive interactions
4. **Delightful**: Smooth animations and thoughtful micro-interactions

---

## 📐 Layout & Spacing

### Grid System
- **Base unit**: 4px
- **Common spacing**: 8px, 12px, 16px, 20px, 24px, 32px
- **Container padding**: 16px (mobile), 24px (tablet+)

### Border Radius
- **Small**: 12px - Input fields, small buttons
- **Medium**: 14-16px - Cards, nav items, progress bars
- **Large**: 20-24px - Large cards, modals
- **Extra Large**: 28-32px - Bottom navigation, hero sections

---

## 🎭 Colors

### Primary Colors
- **Blue 400**: `Colors.blue.shade400` - Primary gradient start
- **Blue 600**: `Colors.blue.shade600` - Primary gradient end, primary actions
- **Blue 700**: `Colors.blue.shade700` - Text on light backgrounds

### Neutral Colors
- **White**: `Colors.white` - Primary background
- **Grey 50**: `Colors.grey.shade50` - Secondary background, subtle gradients
- **Grey 100**: `Colors.grey.shade100` - Dividers, inactive backgrounds
- **Grey 600**: `Colors.grey.shade600` - Secondary text
- **Grey 900**: `Colors.grey.shade900` - Primary text
- **Black 87**: `Colors.black87` - High emphasis text

### Status Colors
- **Green**: Success, mastered items
- **Orange**: Warning, learning items
- **Red**: Error, items needing review
- **Amber**: Premium features, achievements

---

## 🔤 Typography

### Font Family
- **Primary**: DMSans (configured in main.dart)

### Font Weights
- **Regular**: `FontWeight.normal` (400)
- **Medium**: `FontWeight.w600` (600)
- **Bold**: `FontWeight.w700` (700)

### Font Sizes & Letter Spacing

#### Headers
```dart
// Large Title (Screen Headers)
TextStyle(
  fontSize: 36,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  color: Colors.white,
)

// Medium Title
TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
)

// Section Header
TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
)

// Card Title
TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
)

// Small Header
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
)
```

#### Body Text
```dart
// Body Large
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: Colors.grey.shade900,
)

// Body Medium
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
)

// Body Small
TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
)

// Caption
TextStyle(
  fontSize: 12,
  color: Colors.grey.shade600,
)
```

#### Button Text
```dart
// Primary Button
TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.3,
  color: Colors.white,
)

// Secondary Button
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.3,
)
```

---

## 🎨 Shadows

### Layered Shadow System
For elevated components, use multiple shadows for depth:

```dart
// Double Shadow (Cards, Containers)
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
]

// Single Shadow (Small Components)
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
]

// Colored Shadow (Buttons, Active States)
boxShadow: [
  BoxShadow(
    color: Colors.blue.withOpacity(0.3),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
]
```

---

## 🎨 Gradients

### Primary Gradient (Buttons, Active States)
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Colors.blue.shade400,
    Colors.blue.shade600,
  ],
)
```

### Subtle Background Gradient
```dart
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Colors.white,
    Colors.grey.shade50,
  ],
)
```

### Overlay Gradient
```dart
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Colors.black.withOpacity(0.1),
    Colors.transparent,
  ],
)
```

---

## 🔘 Components

### Buttons

#### Primary Button (Gradient)
```dart
Container(
  height: 56,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.blue.shade400, Colors.blue.shade600],
    ),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: // Button content
    ),
  ),
)
```

#### Secondary Button (Outlined)
```dart
OutlinedButton.icon(
  onPressed: onPressed,
  icon: Icon(icon, size: 20),
  label: Text(
    label,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.3,
    ),
  ),
  style: OutlinedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
  ),
)
```

#### Icon Button (Glass Effect)
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: IconButton(
    icon: Icon(icon, color: Colors.white, size: 20),
    onPressed: onPressed,
  ),
)
```

### Cards

#### Standard Card
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: // Card content
)
```

#### Elevated Card (More Prominence)
```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: // Card content
)
```

### Progress Bars

#### Standard Progress Bar
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.2),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: LinearProgressIndicator(
      value: value,
      minHeight: 12,
      backgroundColor: Colors.grey.shade100,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ),
  ),
)
```

### Navigation Items

#### Bottom Nav Item (Active)
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  width: 44,
  height: 44,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.blue.shade400, Colors.blue.shade600],
    ),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.3),
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Icon(icon, size: 22, color: Colors.white),
)
```

#### Bottom Nav Item (Inactive)
```dart
Container(
  width: 44,
  height: 44,
  alignment: Alignment.center,
  child: Icon(icon, size: 22, color: Colors.grey.shade600),
)
```

---

## 🎬 Animations

### Durations
- **Fast**: 150-200ms - Micro-interactions, hovers
- **Standard**: 250-300ms - State changes, nav transitions
- **Slow**: 400-500ms - Page transitions, complex animations

### Curves
- **easeInOut**: Default for most animations
- **easeOut**: Entry animations
- **easeIn**: Exit animations

### Common Animations

#### Scale Animation (Button Press)
```dart
AnimationController(
  duration: Duration(milliseconds: 200),
  vsync: this,
);
Animation<double> scaleAnimation = Tween<double>(
  begin: 1.0,
  end: 0.95,
).animate(CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
));
```

#### Slide Animation (Bottom Nav)
```dart
AnimationController(
  duration: Duration(milliseconds: 300),
  vsync: this,
);
Animation<Offset> slideAnimation = Tween<Offset>(
  begin: Offset.zero,
  end: Offset(0, 2),
).animate(CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
));
```

---

## 📱 Screen-Specific Patterns

### AppBar (Books Screen, Book Details)
```dart
SliverAppBar(
  expandedHeight: 140,
  toolbarHeight: 68,
  pinned: false,
  backgroundColor: Colors.transparent,
  elevation: 0,
  flexibleSpace: // Gradient background with image overlay
)
```

### Header with Hero (Book Details)
```dart
Hero(
  tag: 'book_${book.id}',
  child: Material(
    color: Colors.transparent,
    child: // Gradient container with content
  ),
)
```

### Bottom Navigation
```dart
FractionallySizedBox(
  widthFactor: 0.68,
  child: Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [/* Layered shadows */],
    ),
    child: // Navigation items with gradient background
  ),
)
```

---

## ✅ Best Practices

### Do's
- ✅ Use consistent spacing (multiples of 4)
- ✅ Layer shadows for depth (2-3 shadows max)
- ✅ Apply letter spacing to headers (-0.5 to -0.3)
- ✅ Use gradients for primary actions
- ✅ Animate state changes (250-300ms)
- ✅ Add subtle overlays to images
- ✅ Use InkWell for ripple effects
- ✅ Keep border radius consistent within component types

### Don'ts
- ❌ Mix different shadow styles in same component
- ❌ Use too many colors (stick to palette)
- ❌ Forget letter spacing on bold headers
- ❌ Use harsh shadows (keep opacity 0.05-0.15)
- ❌ Animate everything (be selective)
- ❌ Use solid colors where gradients shine
- ❌ Ignore accessibility (contrast, touch targets)
- ❌ Overuse borders (prefer shadows)

---

## 🎯 Implementation Examples

### Example: Modern Button
```dart
// ✅ Good - Gradient with shadow
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue.shade400, Colors.blue.shade600],
    ),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12)],
  ),
)

// ❌ Bad - Flat color, no shadow
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
)
```

### Example: Typography
```dart
// ✅ Good - Letter spacing, proper weight
Text(
  'Dashboard',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  ),
)

// ❌ Bad - No letter spacing
Text(
  'Dashboard',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## 📋 Component Checklist

When creating a new component, ensure:
- [ ] Border radius matches component size
- [ ] Shadow is subtle and layered (if needed)
- [ ] Typography uses proper weights and letter spacing
- [ ] Gradients are smooth (2 colors max)
- [ ] Spacing uses 4px grid system
- [ ] Animations are smooth (250-300ms)
- [ ] Touch targets are at least 44x44
- [ ] Colors come from defined palette
- [ ] InkWell/ripple effect for interactive elements

---

## 🔄 Version History

**v1.0** - 2025-01-04
- Initial design system documentation
- Modern UI implementation across Books, Book Details, User screens
- Bottom navigation with auto-hide functionality
- Consistent gradient and shadow system

---

## 📚 References

Applied in:
- `lib/ui/screens/books_screen.dart` - Modern topbar with gradient
- `lib/ui/screens/book_details_screen.dart` - Hero header, gradient buttons
- `lib/ui/screens/user_screen.dart` - Stats cards, progress bars
- `lib/ui/screens/main_screen.dart` - Bottom navigation with animations
- `lib/ui/screens/flash_card_screen2.dart` - Reference for modern AppBar design

---

*This design system is a living document. Update as the app evolves.*
