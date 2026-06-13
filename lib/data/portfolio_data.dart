/// =============================================================
/// THE BIG BANG PORTFOLIO — CONTENT
/// =============================================================
/// Every word the site displays lives in this file, extracted from
/// Manish Talreja's resume. Edit text here; the rendering engine
/// never hardcodes content.
///
/// Pure Dart on purpose (no Flutter imports) so it stays trivially
/// testable and portable. Visual properties derived from content
/// (planet palettes, star positions) are computed by the engine
/// using these strings as seeds.
library;

// ---------------------------------------------------------------
// Identity
// ---------------------------------------------------------------

const String kName = 'Manish Talreja';
const String kHeroName = 'MANISH'; // assembled from particles in the Big Bang
const String kTitle = 'Mobile Application Developer · Flutter';
const String kLocation = 'Indore, India';

/// NOTE (privacy): the phone number from the resume is intentionally
/// omitted from this file and must never appear on the public site.
const String kEmail = 'manishtalreja0510@gmail.com';

// ---------------------------------------------------------------
// Era copy — the narrative voice of the universe
// ---------------------------------------------------------------

const String kSingularityLine = 'In the beginning, there was an idea.';
const String kScrollHint = 'Scroll to begin time';
const String kContactLine =
    'Every universe begins with a single point. Start one with me.';

// ---------------------------------------------------------------
// Headline stats — drift as "cosmic facts" in the Stellar era
// ---------------------------------------------------------------

class CosmicFact {
  final String value;
  final String label;
  const CosmicFact(this.value, this.label);
}

const List<CosmicFact> kCosmicFacts = [
  CosmicFact('5+', 'years of experience'),
  CosmicFact('50+', 'projects delivered'),
  CosmicFact('20+', 'live apps in production'),
];

// ---------------------------------------------------------------
// Skills — stars grouped into constellations
// ---------------------------------------------------------------
// `mass` (0..1) drives star size + glow. The resume lists skills
// without proficiency levels, so these weights are editorial:
// core Flutter stack brightest, secondary skills dimmer.
// `detail` is the one-liner shown when a star flares.

class Skill {
  final String name;
  final String detail;
  final double mass;
  const Skill(this.name, this.detail, this.mass);
}

class Constellation {
  final String name;
  final List<Skill> stars;
  const Constellation(this.name, this.stars);
}

const List<Constellation> kConstellations = [
  Constellation('The Flutter Constellation', [
    Skill('Flutter', '4+ years building production apps across domains', 1.0),
    Skill('Dart', 'Primary language — clean, idiomatic, optimized', 0.95),
    Skill('Provider', 'State management tuned for performance (+30% gains)', 0.9),
    Skill('Clean Architecture', 'Layered, testable app structure as a habit', 0.85),
  ]),
  Constellation('The Data Nebula', [
    Skill('Firebase', 'Auth, storage, analytics & real-time features', 0.85),
    Skill('REST APIs', 'Seamless integration incl. a published Dio package', 0.8),
    Skill('SQL', 'Relational data modeling and queries', 0.65),
    Skill('MongoDB', 'Document storage for app backends', 0.6),
  ]),
  Constellation('The Integration Cluster', [
    Skill('Google Maps & Geolocation', 'Location-based discovery and live tracking', 0.8),
    Skill('Payment Gateways', 'Robust in-app payment flows', 0.75),
    Skill('IAP & Ads', 'Monetization that respects the user', 0.7),
  ]),
  Constellation('Outer Orbits', [
    Skill('React Native', 'Cross-platform breadth beyond Flutter', 0.55),
    Skill('Git', 'Disciplined version control & collaboration', 0.7),
  ]),
];

// ---------------------------------------------------------------
// Projects — the planets
// ---------------------------------------------------------------

class StoreLink {
  final String label; // 'Play Store' | 'App Store' | 'pub.dev'
  final String url;
  const StoreLink(this.label, this.url);
}

class Project {
  /// Also the seed for the planet's procedural look.
  final String name;
  final String tagline;

  /// Short text for the holographic info panel.
  final String summary;

  /// Full bullets for the zoomed-in case study.
  final List<String> caseStudy;
  final List<String> tech; // rendered as orbiting moons/tags
  final String duration;
  final List<StoreLink> links;

  const Project({
    required this.name,
    required this.tagline,
    required this.summary,
    required this.caseStudy,
    required this.tech,
    required this.duration,
    required this.links,
  });
}

const List<Project> kProjects = [
  Project(
    name: 'Simplix',
    tagline: 'On-demand home services marketplace',
    summary:
        'Connects users with qualified professionals — carpentry, locksmithing, '
        'cleaning, electrical and plumbing — with real-time search, booking, and '
        'location-based service discovery.',
    caseStudy: [
      'Spearheaded development end-to-end in Flutter, connecting users with vetted professionals across five service domains.',
      'Implemented real-time search and booking for dramatically faster service matching.',
      'Built dual dashboards: scheduling tools, service history, and earnings tracking for users and providers.',
      'Location-based discovery via geolocation APIs for precise service-locality matching.',
      'Optimized performance for a 20% overall improvement.',
    ],
    tech: ['Flutter', 'Geolocation APIs', 'Real-time booking'],
    duration: '18 months',
    links: [
      StoreLink('Play Store',
          'https://play.google.com/store/apps/details?id=com.app.simplix'),
      StoreLink('App Store',
          'https://apps.apple.com/us/app/simplix-app/id6702024075'),
    ],
  ),
  Project(
    name: 'Learn Play Live',
    tagline: 'Gamified health & wellness tracking',
    summary:
        'Helps users managing diabetes and high blood pressure stay on track — '
        'medication reminders, vitals monitoring, and a virtual "Garden of '
        'Wellness" that grows with their progress.',
    caseStudy: [
      'Leading development of a cross-platform health companion for chronic-condition management.',
      'Medication reminders, vital-signs monitoring (blood pressure, glucose), and progress tracking.',
      'Gamified motivation: a virtual "Garden of Wellness" that boosts retention.',
      'RESTful APIs, secure local storage, and Provider-based state management.',
      'Responsive, accessible, high-performance UI across Android and iOS.',
    ],
    tech: ['Flutter', 'Dart', 'Firebase', 'REST API', 'Provider'],
    duration: '12 months',
    links: [
      StoreLink('Play Store',
          'https://play.google.com/store/apps/details?id=com.learn_play_live.application'),
      StoreLink('App Store',
          'https://apps.apple.com/us/app/learn-play-live-app/id6742144664'),
    ],
  ),
  Project(
    name: 'Versus Hot',
    tagline: 'Truth-or-dare party game',
    summary:
        'A cross-platform party game with category-based truth & dare '
        'challenges, real-time randomizer logic, and a playful animated UI.',
    caseStudy: [
      'Built a party game offering fun truth & dare challenges for groups.',
      'Category-based challenges, customizable options, and real-time randomizer logic.',
      'Modern, responsive UI with animations for a playful experience.',
      'In-app purchases and ads integrated for monetization.',
      'Published on Google Play with positive user feedback.',
    ],
    tech: ['Flutter', 'Dart', 'Firebase', 'Google Play Services'],
    duration: '12 months',
    links: [
      StoreLink('Play Store',
          'https://play.google.com/store/apps/details?id=com.versushot.truthdareapp&hl=en_IN'),
    ],
  ),
  Project(
    name: 'Kamaleon',
    tagline: 'Secure vault & file hider',
    summary:
        'A privacy-first vault that hides sensitive files locally and in the '
        'cloud — with decoy content, secure login, and cloud sync that keeps '
        'data private even if a device is scanned.',
    caseStudy: [
      'Built a cross-platform secure file vault for PDFs, docs, and media.',
      'Decoy content, secure login, and cloud sync for privacy even under device scans.',
      'Ads integration to support monetization.',
      'Published on Google Play with 500+ downloads and growing.',
    ],
    tech: ['Flutter', 'Dart', 'Cloud Storage', 'Secure Auth', 'IAP'],
    duration: '4 months',
    links: [
      StoreLink('Play Store',
          'https://play.google.com/store/apps/details?id=com.kamaleon.app&hl=en_IN'),
    ],
  ),
];

// ---------------------------------------------------------------
// Open-source packages — the comets
// ---------------------------------------------------------------

class PubPackage {
  final String name;
  final String description;
  final String url;
  const PubPackage(this.name, this.description, {required this.url});
}

const List<PubPackage> kPackages = [
  PubPackage(
    'custom_styles_package',
    'Reusable, responsive UI widgets — CustomText, CustomButton, '
        'CustomTextField & more — with global style configuration.',
    url: 'https://pub.dev/packages/custom_styles_package',
  ),
  PubPackage(
    'custom_api_services',
    'Dio-powered networking with built-in caching, authentication, '
        'error handling, and offline support.',
    url: 'https://pub.dev/packages/custom_api_services',
  ),
];

// ---------------------------------------------------------------
// Experience — pulsars on the light-stream
// ---------------------------------------------------------------

class Role {
  final String company;
  final String title;
  final String period;
  final List<String> highlights;
  const Role({
    required this.company,
    required this.title,
    required this.period,
    required this.highlights,
  });
}

/// Ordered past → present, matching the flow of the timeline.
const List<Role> kRoles = [
  Role(
    company: 'Aurd Infotech',
    title: 'Software Developer Intern',
    period: 'Aug 2021 – Dec 2021',
    highlights: [
      'Shipped features across multiple mobile app projects with designers and backend teams.',
      'Raised code quality through rigorous testing, debugging, and performance checks.',
      'Customized and deployed client-specific features to high satisfaction.',
    ],
  ),
  Role(
    company: 'Webwiders',
    title: 'Mobile Application Developer',
    period: 'Jan 2022 – Feb 2026',
    highlights: [
      'Delivered 50+ projects — 20+ live apps — across Telehealth, Taxi Booking, Finance, Social Media, and Dating.',
      'Improved overall app performance 30% via clean architecture and Provider-based state management.',
      'Mentored junior developers, lifting team code quality by 20%.',
    ],
  ),
  Role(
    company: 'Zenoti',
    title: 'Software Engineer',
    period: 'Feb 2026 – Present',
    highlights: [
      'Engineering the Point-of-Sale module of Zenoti, a product platform powering salons, spas, and wellness businesses worldwide.',
      'Building checkout, billing, and payment flows where reliability and speed at the counter are non-negotiable.',
      'Working product-first: collaborating with product managers and QA to take POS features from spec to release.',
    ],
  ),
];

// ---------------------------------------------------------------
// About — the Present Moment
// ---------------------------------------------------------------
// Editorial: written first-person from the resume. Review the tone.

const String kAboutStatement =
    "I'm Manish — a Flutter developer from Indore, India. For four-plus years "
    "I've been turning ideas into apps people actually use: fifty-plus projects "
    "shipped, twenty of them live right now, across telehealth, finance, social, "
    "and everything in between. I care about the craft — clean architecture, "
    "smooth motion, and interfaces that feel effortless. Off-screen you'll find "
    "me on a cricket pitch or lost in a chess position.";

const String kEducation = 'B.Tech in Computer Science · RGPV, Bhopal · 2021';
const String kCertification = 'Flutter Development Bootcamp with Dart';
const String kLanguages = 'English · Hindi · Sindhi';

/// Hobbies feed the About-era flourish (tiny knight constellation).
const List<String> kHobbies = ['Cricket', 'Chess'];

// ---------------------------------------------------------------
// Contact — bodies orbiting the new singularity
// ---------------------------------------------------------------
// Email is the primary CTA (clicking the singularity opens it);
// the rest orbit as glowing bodies. Phone is deliberately absent.

class ContactLink {
  final String label;
  final String url;
  const ContactLink(this.label, this.url);
}

const List<ContactLink> kContactLinks = [
  ContactLink('Email', 'mailto:manishtalreja0510@gmail.com'),
  ContactLink('GitHub', 'https://github.com/manishtalreja0510'),
  ContactLink('LinkedIn', 'https://www.linkedin.com/in/manish-talreja/'),
  ContactLink('pub.dev', 'https://pub.dev/publishers/manishtalreja.in/packages'),
  ContactLink('Instagram', 'https://www.instagram.com/manish.talreja.50'),
];

// ---------------------------------------------------------------
// SEO / page meta (mirrored into web/index.html)
// ---------------------------------------------------------------

const String kPageTitle = 'Manish Talreja — Flutter Developer';
const String kMetaDescription =
    'The Big Bang Portfolio of Manish Talreja: 4+ years, 50+ projects, 20+ '
    'live apps. A scroll-driven journey through a universe of Flutter work.';
