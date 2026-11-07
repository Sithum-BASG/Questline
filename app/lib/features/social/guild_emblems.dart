/// Preset guild crest ids accepted by `createGuild`.
const guildEmblemIds = <String>[
  'crest_1',
  'crest_2',
  'crest_3',
  'crest_4',
  'crest_5',
  'crest_6',
  'crest_7',
  'crest_8',
];

String guildEmblemLabel(String id) {
  final short = id.startsWith('crest_') ? id.substring(6) : id;
  return 'Crest $short';
}
