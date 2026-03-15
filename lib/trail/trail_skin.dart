import 'package:flutter/material.dart';

enum TrailRenderType {
  basic,
  smoke,
  fire,
  water,
  laser,
  plasma,
  glitch,
  ink,
  magma,
  ice,
  galaxy,
  speedForce,
  electric,
  comic,
  punkRiff,
  graffiti,
  halftoneExplosion,
  stickerBomb,
  glitchPrint,
  web,
  inkBrush,
  electricArc,
  goldenThread,
  goldenAura,
  holidaySpark,
  upside,
  binaryRain,
}

class TrailParticleConfig {
  const TrailParticleConfig({
    this.enabled = false,
    this.count = 0,
    this.minRadius = 1.5,
    this.maxRadius = 5,
    this.lifetimeSeconds = 0.8,
    this.spread = 10,
    this.jitter = 0.5,
    this.speed = 1,
  });

  final bool enabled;
  final int count;
  final double minRadius;
  final double maxRadius;
  final double lifetimeSeconds;
  final double spread;
  final double jitter;
  final double speed;
}

class TrailSkinConfig {
  const TrailSkinConfig({
    required this.id,
    required this.name,
    required this.renderType,
    required this.primaryColor,
    required this.secondaryColor,
    this.thickness = 1.0,
    this.opacity = 1.0,
    this.glow = false,
    this.headAssetPath,
    this.effectIntensity = 1.0,
    this.particle = const TrailParticleConfig(),
    this.visualStepFps = 12,
    this.snapshotCount = 5,
    this.chromaOffsetPx = 1.8,
    this.web = const WebTrailConfig(),
    this.ink = const InkBrushTrailConfig(),
    this.arc = const ElectricArcTrailConfig(),
    this.golden = const GoldenThreadTrailConfig(),
    this.aura = const GoldenAuraTrailConfig(),
    this.smoke = const SmokeTrailConfig(),
    this.plasma = const PlasmaTrailConfig(),
    this.glitch = const GlitchTrailConfig(),
    this.inkLiquid = const InkTrailConfig(),
    this.magma = const MagmaTrailConfig(),
    this.ice = const IceTrailConfig(),
    this.galaxy = const GalaxyTrailConfig(),
    this.speedForce = const SpeedForceTrailConfig(),
    this.holidaySpark = const HolidaySparkTrailConfig(),
    this.upside = const UpsideTrailConfig(),
    this.binaryRain = const BinaryRainTrailConfig(),
    this.punkRiff = const PunkRiffTrailConfig(),
    this.graffiti = const GraffitiTrailConfig(),
    this.halftoneExplosion = const HalftoneExplosionTrailConfig(),
    this.stickerBomb = const StickerBombTrailConfig(),
    this.glitchPrint = const GlitchPrintTrailConfig(),
  });

  final String id;
  final String name;
  final TrailRenderType renderType;
  final Color primaryColor;
  final Color secondaryColor;
  final double thickness;
  final double opacity;
  final bool glow;
  final String? headAssetPath;
  final double effectIntensity;
  final TrailParticleConfig particle;
  final int visualStepFps;
  final int snapshotCount;
  final double chromaOffsetPx;
  final WebTrailConfig web;
  final InkBrushTrailConfig ink;
  final ElectricArcTrailConfig arc;
  final GoldenThreadTrailConfig golden;
  final GoldenAuraTrailConfig aura;
  final SmokeTrailConfig smoke;
  final PlasmaTrailConfig plasma;
  final GlitchTrailConfig glitch;
  final InkTrailConfig inkLiquid;
  final MagmaTrailConfig magma;
  final IceTrailConfig ice;
  final GalaxyTrailConfig galaxy;
  final SpeedForceTrailConfig speedForce;
  final HolidaySparkTrailConfig holidaySpark;
  final UpsideTrailConfig upside;
  final BinaryRainTrailConfig binaryRain;
  final PunkRiffTrailConfig punkRiff;
  final GraffitiTrailConfig graffiti;
  final HalftoneExplosionTrailConfig halftoneExplosion;
  final StickerBombTrailConfig stickerBomb;
  final GlitchPrintTrailConfig glitchPrint;
}

class PunkRiffTrailConfig {
  const PunkRiffTrailConfig({
    this.coreWidth = 0.86,
    this.pinkMassOpacity = 0.78,
    this.yellowBoltFrequency = 0.36,
    this.paperFragmentFrequency = 0.3,
    this.inkSplashFrequency = 0.24,
    this.iconStampFrequency = 0.26,
    this.iconStampSpacing = 0.62,
    this.iconStampLifetime = 0.95,
    this.iconStampScaleMin = 0.2,
    this.iconStampScaleMax = 0.34,
    this.iconStampOpacity = 0.9,
    this.iconStampRotationJitter = 0.24,
    this.glitchStrength = 0.18,
    this.glitchOffset = 0.08,
    this.halftoneOpacity = 0.2,
    this.pulseStrength = 0.12,
    this.pulseSpeed = 1.8,
    this.visualFps = 12,
  });

  final double coreWidth;
  final double pinkMassOpacity;
  final double yellowBoltFrequency;
  final double paperFragmentFrequency;
  final double inkSplashFrequency;
  final double iconStampFrequency;
  final double iconStampSpacing;
  final double iconStampLifetime;
  final double iconStampScaleMin;
  final double iconStampScaleMax;
  final double iconStampOpacity;
  final double iconStampRotationJitter;
  final double glitchStrength;
  final double glitchOffset;
  final double halftoneOpacity;
  final double pulseStrength;
  final double pulseSpeed;
  final int visualFps;
}

class GraffitiTrailConfig {
  const GraffitiTrailConfig({
    this.coreWidth = 0.9,
    this.sprayParticleFrequency = 0.34,
    this.sprayParticleLifetime = 0.62,
    this.splashFrequency = 0.24,
    this.dripFrequency = 0.16,
    this.colorPalette = const <Color>[
      Color(0xFFFF2EC9), // magenta
      Color(0xFF22D3EE), // cyan
      Color(0xFFFFE84A), // yellow
      Color(0xFFA3FF12), // acid green
      Color(0xFFF8FAFC), // white
    ],
  });

  final double coreWidth;
  final double sprayParticleFrequency;
  final double sprayParticleLifetime;
  final double splashFrequency;
  final double dripFrequency;
  final List<Color> colorPalette;
}

class HalftoneExplosionTrailConfig {
  const HalftoneExplosionTrailConfig({
    this.coreWidth = 0.88,
    this.halftoneSize = 0.04,
    this.burstFrequency = 0.24,
    this.burstLifetime = 0.58,
    this.impactFlashFrequency = 0.2,
  });

  final double coreWidth;
  final double halftoneSize;
  final double burstFrequency;
  final double burstLifetime;
  final double impactFlashFrequency;
}

class StickerBombTrailConfig {
  const StickerBombTrailConfig({
    this.coreWidth = 0.86,
    this.stickerFrequency = 0.28,
    this.stickerLifetime = 0.72,
    this.rotationVariance = 0.4,
    this.scaleVariance = 0.26,
  });

  final double coreWidth;
  final double stickerFrequency;
  final double stickerLifetime;
  final double rotationVariance;
  final double scaleVariance;
}

class GlitchPrintTrailConfig {
  const GlitchPrintTrailConfig({
    this.coreWidth = 0.82,
    this.glitchOffset = 0.08,
    this.rgbShift = 0.06,
    this.fragmentFrequency = 0.34,
    this.fragmentSize = 0.08,
    this.noiseIntensity = 0.22,
  });

  final double coreWidth;
  final double glitchOffset;
  final double rgbShift;
  final double fragmentFrequency;
  final double fragmentSize;
  final double noiseIntensity;
}

class WebTrailConfig {
  const WebTrailConfig({
    this.mainStrandWidth = 0.22,
    this.strandGap = 0.18,
    this.bridgeSpacing = 0.35,
    this.bridgeJitter = 0.12,
    this.bridgeOpacity = 0.55,
    this.strandOpacity = 0.9,
    this.highlightStrength = 0.35,
  });

  final double mainStrandWidth;
  final double strandGap;
  final double bridgeSpacing;
  final double bridgeJitter;
  final double bridgeOpacity;
  final double strandOpacity;
  final double highlightStrength;
}

class InkBrushTrailConfig {
  const InkBrushTrailConfig({
    this.baseWidth = 0.95,
    this.widthVariance = 0.28,
    this.edgeRoughness = 0.08,
    this.splatterRate = 0.18,
  });

  final double baseWidth;
  final double widthVariance;
  final double edgeRoughness;
  final double splatterRate;
}

class ElectricArcTrailConfig {
  const ElectricArcTrailConfig({
    this.mainWidth = 0.78,
    this.glowStrength = 0.62,
    this.branchFrequency = 0.34,
    this.branchLength = 0.2,
    this.sparkFrequency = 0.28,
  });

  final double mainWidth;
  final double glowStrength;
  final double branchFrequency;
  final double branchLength;
  final double sparkFrequency;
}

class GoldenThreadTrailConfig {
  const GoldenThreadTrailConfig({
    this.threadWidth = 0.76,
    this.highlightStrength = 0.42,
    this.glowOpacity = 0.24,
    this.sparkleFrequency = 0.16,
  });

  final double threadWidth;
  final double highlightStrength;
  final double glowOpacity;
  final double sparkleFrequency;
}

class GoldenAuraTrailConfig {
  const GoldenAuraTrailConfig({
    this.coreWidth = 0.72,
    this.auraWidth = 1.2,
    this.glowWidth = 1.95,
    this.pulseStrength = 0.18,
    this.pulseSpeed = 1.9,
    this.edgeNoiseAmount = 0.11,
    this.edgeNoiseSpeed = 1.6,
    this.sparkFrequency = 0.28,
    this.sparkLifetime = 0.7,
    this.sparkRiseSpeed = 0.8,
    this.coreColor = const Color(0xFFFFF8CC),
    this.auraColor = const Color(0xFFFFD84F),
    this.glowColor = const Color(0xFFFFB300),
  });

  final double coreWidth;
  final double auraWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double edgeNoiseAmount;
  final double edgeNoiseSpeed;
  final double sparkFrequency;
  final double sparkLifetime;
  final double sparkRiseSpeed;
  final Color coreColor;
  final Color auraColor;
  final Color glowColor;
}

class SmokeTrailConfig {
  const SmokeTrailConfig({
    this.spawnRate = 16.0,
    this.minSize = 0.22,
    this.maxSize = 0.46,
    this.minLifetime = 0.6,
    this.maxLifetime = 1.5,
    this.upwardDrift = 0.22,
    this.sidewaysJitter = 0.16,
    this.opacityStart = 0.58,
    this.opacityEnd = 0.0,
    this.emissionOffsetBehindHead = 0.24,
  });

  final double spawnRate;
  final double minSize;
  final double maxSize;
  final double minLifetime;
  final double maxLifetime;
  final double upwardDrift;
  final double sidewaysJitter;
  final double opacityStart;
  final double opacityEnd;
  final double emissionOffsetBehindHead;
}

class PlasmaTrailConfig {
  const PlasmaTrailConfig({
    this.coreWidth = 0.62,
    this.plasmaWidth = 1.02,
    this.glowWidth = 1.6,
    this.pulseStrength = 0.12,
    this.pulseSpeed = 1.6,
    this.innerFlowSpeed = 1.8,
    this.sparkFrequency = 0.26,
    this.sparkLifetime = 0.55,
    this.coreColor = const Color(0xFFEAF7FF),
    this.plasmaColor = const Color(0xFF64D9FF),
    this.glowColor = const Color(0xFF775BFF),
  });

  final double coreWidth;
  final double plasmaWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double innerFlowSpeed;
  final double sparkFrequency;
  final double sparkLifetime;
  final Color coreColor;
  final Color plasmaColor;
  final Color glowColor;
}

class GlitchTrailConfig {
  const GlitchTrailConfig({
    this.coreWidth = 0.76,
    this.chromaticOffset = 0.08,
    this.glitchFrequency = 0.32,
    this.fragmentSize = 0.12,
    this.fragmentLifetime = 0.42,
    this.flickerStrength = 0.18,
    this.stepVisualFps = 14,
    this.coreColor = const Color(0xFFE2E8F0),
    this.offsetColorA = const Color(0xFF22D3EE),
    this.offsetColorB = const Color(0xFFF472B6),
  });

  final double coreWidth;
  final double chromaticOffset;
  final double glitchFrequency;
  final double fragmentSize;
  final double fragmentLifetime;
  final double flickerStrength;
  final int stepVisualFps;
  final Color coreColor;
  final Color offsetColorA;
  final Color offsetColorB;
}

class InkTrailConfig {
  const InkTrailConfig({
    this.baseWidth = 0.92,
    this.widthVariation = 0.22,
    this.edgeNoiseAmount = 0.05,
    this.dropletFrequency = 0.2,
    this.dropletSize = 0.05,
    this.glossStrength = 0.22,
    this.coreColor = const Color(0xFF0F172A),
    this.highlightColor = const Color(0xFF334155),
  });

  final double baseWidth;
  final double widthVariation;
  final double edgeNoiseAmount;
  final double dropletFrequency;
  final double dropletSize;
  final double glossStrength;
  final Color coreColor;
  final Color highlightColor;
}

class MagmaTrailConfig {
  const MagmaTrailConfig({
    this.coreWidth = 0.5,
    this.magmaWidth = 0.92,
    this.crustWidth = 1.28,
    this.heatPulseStrength = 0.14,
    this.heatPulseSpeed = 1.45,
    this.emberFrequency = 0.28,
    this.emberLifetime = 0.62,
    this.coreColor = const Color(0xFFFFF08A),
    this.magmaColor = const Color(0xFFFF5B1F),
    this.crustColor = const Color(0xFF3A0F08),
    this.glowColor = const Color(0xFFFF8B3D),
  });

  final double coreWidth;
  final double magmaWidth;
  final double crustWidth;
  final double heatPulseStrength;
  final double heatPulseSpeed;
  final double emberFrequency;
  final double emberLifetime;
  final Color coreColor;
  final Color magmaColor;
  final Color crustColor;
  final Color glowColor;
}

class IceTrailConfig {
  const IceTrailConfig({
    this.coreWidth = 0.62,
    this.frostWidth = 1.02,
    this.glowStrength = 0.24,
    this.sparkleFrequency = 0.2,
    this.sparkleLifetime = 0.52,
    this.crystalDetailAmount = 0.12,
    this.coreColor = const Color(0xFFF1F8FF),
    this.frostColor = const Color(0xFFBFE9FF),
    this.glowColor = const Color(0xFF7DD3FC),
  });

  final double coreWidth;
  final double frostWidth;
  final double glowStrength;
  final double sparkleFrequency;
  final double sparkleLifetime;
  final double crystalDetailAmount;
  final Color coreColor;
  final Color frostColor;
  final Color glowColor;
}

class GalaxyTrailConfig {
  const GalaxyTrailConfig({
    this.coreWidth = 0.66,
    this.nebulaWidth = 1.25,
    this.glowWidth = 1.9,
    this.pulseStrength = 0.1,
    this.pulseSpeed = 1.1,
    this.innerDriftSpeed = 1.4,
    this.starDustFrequency = 0.26,
    this.starDustLifetime = 0.7,
    this.sparkleFrequency = 0.16,
    this.sparkleLifetime = 0.44,
    this.coreColor = const Color(0xFF15122B),
    this.nebulaColorA = const Color(0xFF7C3AED),
    this.nebulaColorB = const Color(0xFF22D3EE),
    this.glowColor = const Color(0xFFC084FC),
  });

  final double coreWidth;
  final double nebulaWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double innerDriftSpeed;
  final double starDustFrequency;
  final double starDustLifetime;
  final double sparkleFrequency;
  final double sparkleLifetime;
  final Color coreColor;
  final Color nebulaColorA;
  final Color nebulaColorB;
  final Color glowColor;
}

class SpeedForceTrailConfig {
  const SpeedForceTrailConfig({
    this.coreWidth = 0.72,
    this.glowWidth = 1.42,
    this.pulseStrength = 0.17,
    this.pulseSpeed = 2.2,
    this.streakFrequency = 0.34,
    this.streakLength = 0.2,
    this.streakOpacity = 0.34,
    this.sparkFrequency = 0.24,
    this.sparkLifetime = 0.42,
    this.echoTrailCount = 2,
    this.echoTrailOpacity = 0.16,
    this.turnBurstStrength = 0.3,
    this.coreColor = const Color(0xFFFFF7CC),
    this.glowColor = const Color(0xFFFFC53A),
    this.streakColor = const Color(0xFFFF8A00),
    this.sparkColor = const Color(0xFFFFE066),
  });

  final double coreWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double streakFrequency;
  final double streakLength;
  final double streakOpacity;
  final double sparkFrequency;
  final double sparkLifetime;
  final int echoTrailCount;
  final double echoTrailOpacity;
  final double turnBurstStrength;
  final Color coreColor;
  final Color glowColor;
  final Color streakColor;
  final Color sparkColor;
}

class HolidaySparkTrailConfig {
  const HolidaySparkTrailConfig({
    this.coreWidth = 0.74,
    this.glowWidth = 1.52,
    this.sparkleFrequency = 0.22,
    this.sparkleLifetime = 0.58,
    this.ornamentDotFrequency = 0.14,
    this.pulseStrength = 0.12,
    this.pulseSpeed = 1.65,
    this.coreColor = const Color(0xFFC1121F),
    this.glowColor = const Color(0xFFFFE6A0),
    this.sparkleColors = const <Color>[
      Color(0xFFFFF4D2),
      Color(0xFFFFD166),
      Color(0xFFDA1E37),
      Color(0xFF2E7D32),
    ],
  });

  final double coreWidth;
  final double glowWidth;
  final double sparkleFrequency;
  final double sparkleLifetime;
  final double ornamentDotFrequency;
  final double pulseStrength;
  final double pulseSpeed;
  final Color coreColor;
  final Color glowColor;
  final List<Color> sparkleColors;
}

class UpsideTrailConfig {
  const UpsideTrailConfig({
    this.coreWidth = 0.72,
    this.auraWidth = 1.18,
    this.glowWidth = 1.84,
    this.pulseStrength = 0.14,
    this.pulseSpeed = 1.42,
    this.redBoltFrequency = 0.28,
    this.redBoltLength = 0.2,
    this.sporeFrequency = 0.22,
    this.sporeLifetime = 0.9,
    this.coreColor = const Color(0xFF16070A),
    this.auraColor = const Color(0xFF4A0C16),
    this.glowColor = const Color(0xFF9D1121),
    this.boltColor = const Color(0xFFFF3B4D),
  });

  final double coreWidth;
  final double auraWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double redBoltFrequency;
  final double redBoltLength;
  final double sporeFrequency;
  final double sporeLifetime;
  final Color coreColor;
  final Color auraColor;
  final Color glowColor;
  final Color boltColor;
}

class BinaryRainTrailConfig {
  const BinaryRainTrailConfig({
    this.coreWidth = 0.74,
    this.glowWidth = 1.44,
    this.binaryDensity = 0.32,
    this.binarySpeed = 1.9,
    this.binaryOpacity = 0.72,
    this.digitalFragmentFrequency = 0.24,
    this.fragmentLifetime = 0.56,
    this.pulseStrength = 0.11,
    this.pulseSpeed = 1.7,
    this.coreColor = const Color(0xFF031B12),
    this.glowColor = const Color(0xFF22C55E),
    this.binaryColor = const Color(0xFF7DFFB3),
  });

  final double coreWidth;
  final double glowWidth;
  final double binaryDensity;
  final double binarySpeed;
  final double binaryOpacity;
  final double digitalFragmentFrequency;
  final double fragmentLifetime;
  final double pulseStrength;
  final double pulseSpeed;
  final Color coreColor;
  final Color glowColor;
  final Color binaryColor;
}
