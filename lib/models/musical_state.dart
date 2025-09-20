enum Scale {
  major,
  naturalMinor,
  harmonicMinor,
  dorian,
  mixolydian,
  pentatonicMinor,
  pentatonicMajor,
}

class MusicalState {
  final int tempo; // BPM
  final String key; // 'C', 'Db', 'D', ... 'B'
  final Scale scale;
  final double energy; // 0..1
  final int seed; // for deterministic variation
  final double? binauralHz; // optional

  MusicalState({
    required this.tempo,
    required this.key,
    required this.scale,
    required this.energy,
    required this.seed,
    this.binauralHz,
  });

  MusicalState copyWith({
    int? tempo,
    String? key,
    Scale? scale,
    double? energy,
    int? seed,
    double? binauralHz,
  }) {
    return MusicalState(
      tempo: tempo ?? this.tempo,
      key: key ?? this.key,
      scale: scale ?? this.scale,
      energy: energy ?? this.energy,
      seed: seed ?? this.seed,
      binauralHz: binauralHz ?? this.binauralHz,
    );
  }
}